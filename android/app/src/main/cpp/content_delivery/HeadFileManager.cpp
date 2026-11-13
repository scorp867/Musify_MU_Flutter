#include "HeadFileManager.h"

#include <android/log.h>
#include <cerrno>
#include <chrono>
#include <condition_variable>
#include <cstdio>
#include <fcntl.h>
#include <memory>
#include <mutex>
#include <sys/stat.h>
#include <thread>
#include <unistd.h>
#include <unordered_map>

#define HF_LOG_TAG "MusifyHeadFile"
#define HF_LOGI(...) __android_log_print(ANDROID_LOG_INFO, HF_LOG_TAG, __VA_ARGS__)
#define HF_LOGW(...) __android_log_print(ANDROID_LOG_WARN, HF_LOG_TAG, __VA_ARGS__)
#define HF_LOGE(...) __android_log_print(ANDROID_LOG_ERROR, HF_LOG_TAG, __VA_ARGS__)

namespace spotify::content_delivery {

namespace {

constexpr const char* kHeadCdnBase = "https://heads-fa-tls13.spotifycdn.com/head/";
constexpr off_t kMinHeadFileSize = 512;
constexpr int64_t kInitialReadyBytes = 4096;
constexpr auto kReadyWaitTimeout = std::chrono::milliseconds(1500);

void ensureParentDirectories(const std::string& file_path) {
    const size_t last_slash = file_path.find_last_of('/');
    if (last_slash == std::string::npos || last_slash == 0) return;

    const std::string dir = file_path.substr(0, last_slash);
    std::string current;
    current.reserve(dir.size());
    for (size_t i = 0; i < dir.size(); ++i) {
        current.push_back(dir[i]);
        if (dir[i] == '/' || i + 1 == dir.size()) {
            if (!current.empty() && current != "/") {
                ::mkdir(current.c_str(), 0755);
            }
        }
    }
}

struct InFlightHeadState {
    std::mutex mutex;
    std::condition_variable cv;
    bool ready{false};
    bool completed{false};
    bool failed{false};
    int64_t written_bytes{0};
};

std::mutex& registryMutex() {
    static std::mutex m;
    return m;
}

std::unordered_map<std::string, std::shared_ptr<InFlightHeadState>>& activeDownloads() {
    static std::unordered_map<std::string, std::shared_ptr<InFlightHeadState>> map;
    return map;
}

void runHeadDownloadWorker(network::NativeHttpClient* http_client,
                           std::string file_id_hex,
                           std::string target_path,
                           std::shared_ptr<InFlightHeadState> state) {
    const std::string part_path = target_path + ".part";
    bool success = false;
    int fd = -1;

    struct stat existing_st{};
    if (::stat(target_path.c_str(), &existing_st) == 0 && existing_st.st_size >= kMinHeadFileSize) {
        std::lock_guard<std::mutex> lk(state->mutex);
        state->ready = true;
        state->completed = true;
        state->failed = false;
        state->cv.notify_all();
        std::lock_guard<std::mutex> reg_lk(registryMutex());
        activeDownloads().erase(file_id_hex);
        return;
    }

    ensureParentDirectories(target_path);
    fd = ::open(part_path.c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0) {
        HF_LOGE("Failed to open part file %s (errno=%d)", part_path.c_str(), errno);
        {
            std::lock_guard<std::mutex> lk(state->mutex);
            state->failed = true;
            state->completed = true;
            state->cv.notify_all();
        }
        std::lock_guard<std::mutex> reg_lk(registryMutex());
        activeDownloads().erase(file_id_hex);
        return;
    }

    const std::string url = std::string(kHeadCdnBase) + file_id_hex;
    HF_LOGI("Streaming head file natively: %s -> %s", url.c_str(), target_path.c_str());

    int64_t total_written = 0;
    const auto res = http_client->downloadToStream(
        url,
        [&](const uint8_t* data, size_t len, int64_t /*expected_total*/) -> bool {
            size_t offset = 0;
            while (offset < len) {
                const ssize_t n = ::write(fd, data + offset, len - offset);
                if (n < 0) {
                    if (errno == EINTR) continue;
                    return false;
                }
                offset += static_cast<size_t>(n);
            }
            total_written += static_cast<int64_t>(len);
            if (total_written >= kInitialReadyBytes || total_written >= kMinHeadFileSize) {
                std::lock_guard<std::mutex> lk(state->mutex);
                state->written_bytes = total_written;
                if (total_written >= kInitialReadyBytes && !state->ready) {
                    state->ready = true;
                    state->cv.notify_all();
                }
            }
            return true;
        },
        {},
        nullptr,
        5000,
        10000);

    ::close(fd);
    fd = -1;

    struct stat part_st{};
    const bool part_ok = (::stat(part_path.c_str(), &part_st) == 0);
    const int64_t final_len = part_ok ? static_cast<int64_t>(part_st.st_size) : 0;
    const bool expected_match =
        res.ok && part_ok &&
        (res.content_length > 0 ? (final_len == res.content_length) : (final_len >= kMinHeadFileSize));

    if (expected_match) {
        if (::rename(part_path.c_str(), target_path.c_str()) == 0) {
            success = true;
            HF_LOGI("Head file complete: %s (size=%lld)",
                    target_path.c_str(), static_cast<long long>(final_len));
        } else {
            HF_LOGE("Failed to rename %s -> %s (errno=%d)",
                    part_path.c_str(), target_path.c_str(), errno);
            ::unlink(part_path.c_str());
        }
    } else {
        HF_LOGE("Head stream invalid/failed for %s (http=%d, len=%lld, expected=%lld)",
                file_id_hex.c_str(),
                res.status_code,
                static_cast<long long>(final_len),
                static_cast<long long>(res.content_length));
        ::unlink(part_path.c_str());
    }

    {
        std::lock_guard<std::mutex> lk(state->mutex);
        state->written_bytes = final_len;
        state->ready = success;
        state->failed = !success;
        state->completed = true;
        state->cv.notify_all();
    }

    {
        std::lock_guard<std::mutex> reg_lk(registryMutex());
        activeDownloads().erase(file_id_hex);
    }
}

} // namespace

HeadFileManager::HeadFileManager(cache::DiskCache& disk_cache,
                                 network::AuthSessionStore& auth_store,
                                 network::NativeHttpClient& http_client)
    : disk_cache_(disk_cache),
      auth_store_(auth_store),
      http_client_(http_client) {}

bool HeadFileManager::streamHeadFile(network::NativeHttpClient& http_client,
                                     const std::string& file_id_hex,
                                     const std::string& target_path) {
    if (file_id_hex.empty() || target_path.empty()) return false;

    struct stat st{};
    if (::stat(target_path.c_str(), &st) == 0) {
        if (st.st_size >= kMinHeadFileSize) {
            return true;
        }
        ::unlink(target_path.c_str());
    }

    std::shared_ptr<InFlightHeadState> state;
    bool spawn_worker = false;
    {
        std::lock_guard<std::mutex> reg_lk(registryMutex());
        auto it = activeDownloads().find(file_id_hex);
        if (it != activeDownloads().end()) {
            state = it->second;
        } else {
            state = std::make_shared<InFlightHeadState>();
            activeDownloads()[file_id_hex] = state;
            spawn_worker = true;
        }
    }

    if (spawn_worker) {
        std::thread(
            &runHeadDownloadWorker,
            &http_client,
            file_id_hex,
            target_path,
            state).detach();
    }

    std::unique_lock<std::mutex> lk(state->mutex);
    const bool signaled = state->cv.wait_for(lk, kReadyWaitTimeout, [&]() {
        return state->ready || state->completed || state->failed;
    });
    if (!signaled) {
        return false;
    }
    if (state->failed) {
        return false;
    }
    return state->ready || (state->completed && !state->failed);
}

void HeadFileManager::syncCacheDir() {
    const auto creds = auth_store_.snapshot();
    if (!creds.cache_dir.empty()) {
        disk_cache_.setBaseCacheDir(creds.cache_dir);
    }
}

std::string HeadFileManager::currentCacheDir() const {
    const auto creds = auth_store_.snapshot();
    if (!creds.cache_dir.empty()) {
        return creds.cache_dir;
    }
    return "/data/data/um.musify.mu.musify_mu/cache";
}

std::string HeadFileManager::acquireHeadFile(const std::string& file_id_hex) {
    if (file_id_hex.empty()) return {};
    syncCacheDir();

    std::string existing = disk_cache_.lookupValidHead(file_id_hex);
    if (!existing.empty()) {
        return existing;
    }

    const std::string target_path = disk_cache_.resolveHeadPath(file_id_hex);
    if (streamHeadFile(http_client_, file_id_hex, target_path)) {
        disk_cache_.onHeadStored(file_id_hex);
        return target_path;
    }
    return {};
}

void HeadFileManager::prefetchHeadAsync(const std::string& file_id_hex) {
    if (file_id_hex.empty()) return;
    syncCacheDir();

    if (!disk_cache_.lookupValidHead(file_id_hex).empty()) {
        return;
    }

    const std::string target_path = disk_cache_.resolveHeadPath(file_id_hex);
    std::thread([this, file_id_hex, target_path]() {
        if (streamHeadFile(http_client_, file_id_hex, target_path)) {
            disk_cache_.onHeadStored(file_id_hex);
        }
    }).detach();
}

} // namespace spotify::content_delivery
