#include "HeadFileManager.h"

#include <android/log.h>
#include <cerrno>
#include <chrono>
#include <condition_variable>
#include <cstdio>
#include <cstring>
#include <fcntl.h>
#include <memory>
#include <mutex>
#include <sys/stat.h>
#include <thread>
#include <unistd.h>
#include <unordered_map>
#include <vector>

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

/// Deterministic state machine for an in-flight Chunk 0 Ogg head download.
enum class HeadDownloadPhase : uint8_t {
    Connecting = 0,
    StreamingHeaderReady = 1, // >= 4 KiB flushed to disk; decoder can open immediately
    Completed = 2,            // Full head file flushed and atomically renamed
    Failed = 3,               // Network or I/O failure
};

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

std::string normalizeTargetPath(const std::string& path) {
    if (path.size() > 5 && path.compare(path.size() - 5, 5, ".part") == 0) {
        return path.substr(0, path.size() - 5);
    }
    return path;
}

struct InFlightHeadState {
    std::mutex mutex;
    std::condition_variable cv;
    HeadDownloadPhase phase{HeadDownloadPhase::Connecting};
    int64_t written_bytes{0};
};

std::mutex& registryMutex() {
    static std::mutex m;
    return m;
}

std::unordered_map<std::string, std::shared_ptr<InFlightHeadState>>& activeDownloadsById() {
    static std::unordered_map<std::string, std::shared_ptr<InFlightHeadState>> map;
    return map;
}

std::unordered_map<std::string, std::shared_ptr<InFlightHeadState>>& activeDownloadsByPath() {
    static std::unordered_map<std::string, std::shared_ptr<InFlightHeadState>> map;
    return map;
}

void unregisterDownload(const std::string& file_id_hex, const std::string& target_path) {
    std::lock_guard<std::mutex> reg_lk(registryMutex());
    activeDownloadsById().erase(file_id_hex);
    activeDownloadsByPath().erase(target_path);
}

void runHeadDownloadWorker(network::NativeHttpClient* http_client,
                           std::string file_id_hex,
                           std::string target_path,
                           std::shared_ptr<InFlightHeadState> state,
                           network::AcquisitionIntent intent) {
    const std::string part_path = target_path + ".part";
    int fd = -1;

    struct stat existing_st{};
    if (::stat(target_path.c_str(), &existing_st) == 0 && existing_st.st_size >= kMinHeadFileSize) {
        {
            std::lock_guard<std::mutex> lk(state->mutex);
            state->written_bytes = static_cast<int64_t>(existing_st.st_size);
            state->phase = HeadDownloadPhase::Completed;
            state->cv.notify_all();
        }
        unregisterDownload(file_id_hex, target_path);
        return;
    }

    auto& traffic_ctrl = network::NativeTrafficController::instance();
    auto permit = traffic_ctrl.acquirePermit(
        intent == network::AcquisitionIntent::BackgroundPrefetch
            ? network::RequestPriority::P3_BackgroundBatch
            : network::RequestPriority::P0_PlaybackCritical,
        network::OfflinePolicy::FailFastOffline,
        "head:" + file_id_hex);
    if (!permit) {
        {
            std::lock_guard<std::mutex> lk(state->mutex);
            state->phase = HeadDownloadPhase::Failed;
            state->cv.notify_all();
        }
        unregisterDownload(file_id_hex, target_path);
        return;
    }

    ensureParentDirectories(target_path);
    fd = ::open(part_path.c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0) {
        HF_LOGE("Failed to open part file %s (errno=%d)", part_path.c_str(), errno);
        permit.complete(network::TransferOutcome::TransportFailure);
        {
            std::lock_guard<std::mutex> lk(state->mutex);
            state->phase = HeadDownloadPhase::Failed;
            state->cv.notify_all();
        }
        unregisterDownload(file_id_hex, target_path);
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
            {
                std::lock_guard<std::mutex> lk(state->mutex);
                state->written_bytes = total_written;
                if (total_written >= kInitialReadyBytes &&
                    state->phase == HeadDownloadPhase::Connecting) {
                    state->phase = HeadDownloadPhase::StreamingHeaderReady;
                }
                state->cv.notify_all();
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

    HeadDownloadPhase final_phase = HeadDownloadPhase::Failed;
    if (expected_match) {
        if (::rename(part_path.c_str(), target_path.c_str()) == 0) {
            final_phase = HeadDownloadPhase::Completed;
            cache::DiskCache::defaultInstance().onHeadStored(file_id_hex);
            permit.complete(network::TransferOutcome::Success);
            HF_LOGI("Head file complete: %s (size=%lld)",
                    target_path.c_str(), static_cast<long long>(final_len));
        } else {
            permit.complete(network::TransferOutcome::TransportFailure);
            HF_LOGE("Failed to rename %s -> %s (errno=%d)",
                    part_path.c_str(), target_path.c_str(), errno);
            ::unlink(part_path.c_str());
        }
    } else {
        permit.complete(network::TransferOutcome::TransportFailure);
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
        state->phase = final_phase;
        state->cv.notify_all();
    }

    unregisterDownload(file_id_hex, target_path);
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
                                     const std::string& target_path,
                                     network::AcquisitionIntent intent) {
    if (file_id_hex.empty() || target_path.empty()) return false;

    const std::string norm_target = normalizeTargetPath(target_path);

    struct stat st{};
    if (::stat(norm_target.c_str(), &st) == 0) {
        if (st.st_size >= kMinHeadFileSize) {
            return true;
        }
        ::unlink(norm_target.c_str());
    }

    if (!network::NativeTrafficController::instance().isOnline()) {
        return false;
    }

    std::shared_ptr<InFlightHeadState> state;
    bool spawn_worker = false;
    {
        std::lock_guard<std::mutex> reg_lk(registryMutex());
        auto it = activeDownloadsById().find(file_id_hex);
        if (it != activeDownloadsById().end()) {
            state = it->second;
            activeDownloadsByPath()[norm_target] = state;
        } else {
            state = std::make_shared<InFlightHeadState>();
            activeDownloadsById()[file_id_hex] = state;
            activeDownloadsByPath()[norm_target] = state;
            spawn_worker = true;
        }
    }

    if (spawn_worker) {
        std::thread(
            &runHeadDownloadWorker,
            &http_client,
            file_id_hex,
            norm_target,
            state,
            intent).detach();
    }

    std::unique_lock<std::mutex> lk(state->mutex);
    const bool signaled = state->cv.wait_for(lk, kReadyWaitTimeout, [&]() {
        return state->phase != HeadDownloadPhase::Connecting;
    });
    if (!signaled) {
        return false;
    }
    switch (state->phase) {
        case HeadDownloadPhase::StreamingHeaderReady:
        case HeadDownloadPhase::Completed:
            return true;
        case HeadDownloadPhase::Connecting:
        case HeadDownloadPhase::Failed:
            return false;
    }
    return false;
}

bool HeadFileManager::waitForHeadBytes(const std::string& part_or_target_path,
                                       int64_t required_bytes,
                                       int timeout_ms,
                                       const std::atomic<bool>& cancel_flag) {
    if (cancel_flag.load(std::memory_order_acquire)) {
        return false;
    }

    const std::string norm_target = normalizeTargetPath(part_or_target_path);
    std::shared_ptr<InFlightHeadState> state;
    {
        std::lock_guard<std::mutex> reg_lk(registryMutex());
        auto it = activeDownloadsByPath().find(norm_target);
        if (it != activeDownloadsByPath().end()) {
            state = it->second;
        }
    }

    if (!state) {
        return true;
    }

    std::unique_lock<std::mutex> lk(state->mutex);
    state->cv.wait_for(lk, std::chrono::milliseconds(std::max(1, timeout_ms)), [&]() {
        return cancel_flag.load(std::memory_order_acquire) ||
               state->written_bytes >= required_bytes ||
               state->phase == HeadDownloadPhase::Completed ||
               state->phase == HeadDownloadPhase::Failed;
    });
    return !cancel_flag.load(std::memory_order_acquire) &&
           state->phase != HeadDownloadPhase::Failed;
}

void HeadFileManager::wakeAllWaiters() {
    std::vector<std::shared_ptr<InFlightHeadState>> snapshot;
    {
        std::lock_guard<std::mutex> reg_lk(registryMutex());
        snapshot.reserve(activeDownloadsById().size());
        for (const auto& [id, st] : activeDownloadsById()) {
            (void)id;
            if (st) snapshot.push_back(st);
        }
    }
    for (const auto& st : snapshot) {
        std::lock_guard<std::mutex> lk(st->mutex);
        st->cv.notify_all();
    }
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

std::string HeadFileManager::lookupCachedHeadFile(const std::string& file_id_hex) {
    if (file_id_hex.empty()) return {};
    syncCacheDir();
    return disk_cache_.lookupValidHead(file_id_hex);
}

std::string HeadFileManager::acquireHeadFile(const std::string& file_id_hex) {
    if (file_id_hex.empty()) return {};
    syncCacheDir();

    std::string existing = disk_cache_.lookupValidHead(file_id_hex);
    if (!existing.empty()) {
        return existing;
    }

    const std::string target_path = disk_cache_.resolveHeadPath(file_id_hex);
    if (streamHeadFile(
            http_client_,
            file_id_hex,
            target_path,
            network::AcquisitionIntent::InteractivePlayback)) {
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

    if (!network::NativeTrafficController::instance().isOnline()) {
        return;
    }

    const std::string target_path = disk_cache_.resolveHeadPath(file_id_hex);
    std::thread([this, file_id_hex, target_path]() {
        if (streamHeadFile(
                http_client_,
                file_id_hex,
                target_path,
                network::AcquisitionIntent::BackgroundPrefetch)) {
            disk_cache_.onHeadStored(file_id_hex);
        }
    }).detach();
}

} // namespace spotify::content_delivery
