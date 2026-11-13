#include "DiskCache.h"

#include <algorithm>
#include <atomic>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <dirent.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <vector>

namespace spotify::cache {

namespace {

constexpr const char* kFallbackBaseDir = "/data/data/um.musify.mu.musify_mu/cache";
constexpr const char* kFallbackHeadsDir = "/data/data/um.musify.mu.musify_mu/cache/heads";
constexpr const char* kFallbackStreamsDir = "/data/data/um.musify.mu.musify_mu/cache/streams";

void touchFileMtime(const std::string& path) {
    struct timespec times[2];
    times[0].tv_sec = 0;
    times[0].tv_nsec = UTIME_NOW;
    times[1].tv_sec = 0;
    times[1].tv_nsec = UTIME_NOW;
    utimensat(AT_FDCWD, path.c_str(), times, 0);
}

bool endsWith(const char* name, const char* suffix) {
    const size_t nlen = std::strlen(name);
    const size_t slen = std::strlen(suffix);
    if (nlen < slen) return false;
    return std::memcmp(name + (nlen - slen), suffix, slen) == 0;
}

bool containsSubstring(const char* name, const char* sub) {
    return std::strstr(name, sub) != nullptr;
}

bool isHexChar(char c) noexcept {
    return (c >= '0' && c <= '9') ||
           (c >= 'a' && c <= 'f') ||
           (c >= 'A' && c <= 'F');
}

uint64_t nextTempSuffix() noexcept {
    static std::atomic<uint64_t> s_counter{1};
    return s_counter.fetch_add(1, std::memory_order_relaxed);
}

bool writeAllBytesAtomic(const std::string& final_path, const void* data, size_t len) {
    if (final_path.empty() || (!data && len > 0)) return false;

    const std::string tmp_path =
        final_path + ".tmp." + std::to_string(nextTempSuffix());

    const int fd = ::open(tmp_path.c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0600);
    if (fd < 0) {
        return false;
    }

    const auto* bytes = static_cast<const uint8_t*>(data);
    size_t written = 0;
    while (written < len) {
        const ssize_t n = ::write(fd, bytes + written, len - written);
        if (n <= 0) {
            ::close(fd);
            ::unlink(tmp_path.c_str());
            return false;
        }
        written += static_cast<size_t>(n);
    }
    ::close(fd);

    if (::rename(tmp_path.c_str(), final_path.c_str()) != 0) {
        ::unlink(tmp_path.c_str());
        return false;
    }
    return true;
}

} // namespace

DiskCache::DiskCache(uint64_t max_head_bytes, uint64_t max_stream_bytes)
    : heads_dir_(kFallbackHeadsDir),
      streams_dir_(kFallbackStreamsDir),
      max_head_bytes_(max_head_bytes),
      max_stream_bytes_(max_stream_bytes) {
    mkdir(kFallbackBaseDir, 0700);
    ensureDirsLocked();
}

DiskCache& DiskCache::defaultInstance() {
    static DiskCache s_instance;
    return s_instance;
}

void DiskCache::setBaseCacheDir(const std::string& cache_dir) {
    if (cache_dir.empty()) return;
    std::lock_guard<std::mutex> lock(mutex_);
    std::string base = cache_dir;
    while (!base.empty() && base.back() == '/') {
        base.pop_back();
    }
    if (base.empty()) return;

    std::string next_heads = base + "/heads";
    std::string next_streams = base + "/streams";
    if (heads_dir_ != next_heads || streams_dir_ != next_streams) {
        heads_dir_ = std::move(next_heads);
        streams_dir_ = std::move(next_streams);
        ensureDirsLocked();
    }
}

void DiskCache::ensureDirsLocked() const {
    if (!heads_dir_.empty()) {
        mkdir(heads_dir_.c_str(), 0700);
    }
    if (!streams_dir_.empty()) {
        mkdir(streams_dir_.c_str(), 0700);
    }
}

std::string DiskCache::resolveHeadPath(const std::string& file_id_hex) const {
    std::lock_guard<std::mutex> lock(mutex_);
    ensureDirsLocked();
    return heads_dir_ + "/" + file_id_hex + ".ogg";
}

std::string DiskCache::lookupValidHead(const std::string& file_id_hex) {
    if (file_id_hex.empty()) return {};

    std::string path;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        ensureDirsLocked();
        path = heads_dir_ + "/" + file_id_hex + ".ogg";
    }

    struct stat st {};
    if (stat(path.c_str(), &st) == 0) {
        if (st.st_size >= kMinValidHeadBytes) {
            touchFileMtime(path);
            return path;
        }
        std::remove(path.c_str());
    }
    return {};
}

void DiskCache::onHeadStored(const std::string& file_id_hex) {
    if (file_id_hex.empty()) return;
    std::lock_guard<std::mutex> lock(mutex_);
    ensureDirsLocked();
    const std::string path = heads_dir_ + "/" + file_id_hex + ".ogg";
    touchFileMtime(path);
    head_writes_since_prune_ += 1;
    if (head_writes_since_prune_ >= 8) {
        head_writes_since_prune_ = 0;
        evictHeadsIfNeededLocked();
    }
}

std::string DiskCache::extractStreamCacheKey(const std::string& url) {
    if (url.empty()) return {};

    const char* patterns[2] = {"/audio/", "/head/"};
    for (const char* pat : patterns) {
        const size_t pos = url.find(pat);
        if (pos != std::string::npos) {
            const size_t start = pos + std::strlen(pat);
            if (start + 40 <= url.size()) {
                bool valid_hex = true;
                std::string hex_id;
                hex_id.reserve(40);
                for (size_t i = 0; i < 40; ++i) {
                    const char c = url[start + i];
                    if (!isHexChar(c)) {
                        valid_hex = false;
                        break;
                    }
                    hex_id.push_back(static_cast<char>(std::tolower(static_cast<unsigned char>(c))));
                }
                if (valid_hex) {
                    return hex_id;
                }
            }
        }
    }

    // Fallback: deterministic 64-bit FNV-1a hash of the URL path (excluding query string).
    const size_t qpos = url.find('?');
    const size_t len = (qpos != std::string::npos) ? qpos : url.size();
    uint64_t hash = 14695981039346656037ULL;
    for (size_t i = 0; i < len; ++i) {
        hash ^= static_cast<uint8_t>(url[i]);
        hash *= 1099511628211ULL;
    }
    char buf[32];
    std::snprintf(buf, sizeof(buf), "url_%016llx", static_cast<unsigned long long>(hash));
    return std::string(buf);
}

int64_t DiskCache::readStreamTotalSize(const std::string& stream_key) {
    if (stream_key.empty()) return -1;

    std::string meta_path;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        ensureDirsLocked();
        meta_path = streams_dir_ + "/" + stream_key + ".meta";
    }

    const int fd = ::open(meta_path.c_str(), O_RDONLY);
    if (fd < 0) return -1;

    int64_t total_size = -1;
    const ssize_t n = ::read(fd, &total_size, sizeof(total_size));
    ::close(fd);

    if (n != static_cast<ssize_t>(sizeof(total_size)) || total_size <= 0) {
        ::unlink(meta_path.c_str());
        return -1;
    }

    touchFileMtime(meta_path);
    return total_size;
}

void DiskCache::writeStreamTotalSize(const std::string& stream_key, int64_t total_size) {
    if (stream_key.empty() || total_size <= 0) return;

    std::string meta_path;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        ensureDirsLocked();
        meta_path = streams_dir_ + "/" + stream_key + ".meta";
    }

    (void)writeAllBytesAtomic(meta_path, &total_size, sizeof(total_size));
}

std::shared_ptr<const std::vector<uint8_t>> DiskCache::readStreamBlock(
    const std::string& stream_key,
    size_t block_index,
    size_t expected_size) {
    if (stream_key.empty()) return nullptr;

    std::string blk_path;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        ensureDirsLocked();
        blk_path = streams_dir_ + "/" + stream_key + "_" + std::to_string(block_index) + ".blk";
    }

    const int fd = ::open(blk_path.c_str(), O_RDONLY);
    if (fd < 0) return nullptr;

    struct stat st {};
    if (::fstat(fd, &st) != 0 || st.st_size <= 0) {
        ::close(fd);
        ::unlink(blk_path.c_str());
        return nullptr;
    }

    const size_t file_size = static_cast<size_t>(st.st_size);
    if (expected_size > 0 && file_size != expected_size) {
        ::close(fd);
        ::unlink(blk_path.c_str());
        return nullptr;
    }

    auto buffer = std::make_shared<std::vector<uint8_t>>(file_size);
    size_t total_read = 0;
    while (total_read < file_size) {
        const ssize_t n = ::pread(
            fd,
            buffer->data() + total_read,
            file_size - total_read,
            static_cast<off_t>(total_read));
        if (n <= 0) {
            ::close(fd);
            return nullptr;
        }
        total_read += static_cast<size_t>(n);
    }
    ::close(fd);

    touchFileMtime(blk_path);
    return buffer;
}

void DiskCache::writeStreamBlock(
    const std::string& stream_key,
    size_t block_index,
    const uint8_t* data,
    size_t len) {
    if (stream_key.empty() || !data || len == 0) return;

    std::string blk_path;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        ensureDirsLocked();
        blk_path = streams_dir_ + "/" + stream_key + "_" + std::to_string(block_index) + ".blk";
    }

    if (!writeAllBytesAtomic(blk_path, data, len)) {
        return;
    }

    std::lock_guard<std::mutex> lock(mutex_);
    stream_writes_since_prune_ += 1;
    if (stream_writes_since_prune_ >= 32) {
        stream_writes_since_prune_ = 0;
        evictStreamsIfNeededLocked();
    }
}

void DiskCache::evictHeadsIfNeededLocked() {
    evictDirectoryLocked(heads_dir_, max_head_bytes_, true);
}

void DiskCache::evictStreamsIfNeededLocked() {
    evictDirectoryLocked(streams_dir_, max_stream_bytes_, false);
}

void DiskCache::evictDirectoryLocked(const std::string& dir_path,
                                     uint64_t max_bytes,
                                     bool is_heads_dir) {
    if (dir_path.empty()) return;

    DIR* dir = opendir(dir_path.c_str());
    if (!dir) return;

    struct FileEntry {
        std::string path;
        uint64_t size{0};
        int64_t mtime_sec{0};
        int64_t mtime_nsec{0};
    };

    std::vector<FileEntry> files;
    uint64_t total_bytes = 0;
    const time_t now_s = std::time(nullptr);

    while (struct dirent* ent = readdir(dir)) {
        if (ent->d_name[0] == '.') continue;
        const std::string full_path = dir_path + "/" + ent->d_name;

        if (endsWith(ent->d_name, ".part") || containsSubstring(ent->d_name, ".tmp.")) {
            struct stat pst {};
            if (stat(full_path.c_str(), &pst) == 0) {
                if (now_s - pst.st_mtime > 120) {
                    std::remove(full_path.c_str());
                }
            }
            continue;
        }

        if (is_heads_dir) {
            if (!endsWith(ent->d_name, ".ogg")) continue;
        } else {
            if (!endsWith(ent->d_name, ".blk") && !endsWith(ent->d_name, ".meta")) continue;
        }

        struct stat st {};
        if (stat(full_path.c_str(), &st) != 0) continue;

        if (is_heads_dir && st.st_size < kMinValidHeadBytes) {
            std::remove(full_path.c_str());
            continue;
        }

        const auto fsize = static_cast<uint64_t>(st.st_size);
        total_bytes += fsize;
        files.push_back(FileEntry{
            full_path,
            fsize,
            static_cast<int64_t>(st.st_mtim.tv_sec),
            static_cast<int64_t>(st.st_mtim.tv_nsec),
        });
    }
    closedir(dir);

    if (total_bytes <= max_bytes) return;

    std::sort(files.begin(), files.end(), [](const FileEntry& a, const FileEntry& b) {
        if (a.mtime_sec != b.mtime_sec) return a.mtime_sec < b.mtime_sec;
        return a.mtime_nsec < b.mtime_nsec;
    });

    // Prune down to 90% of max_bytes so eviction does not thrash on consecutive writes.
    const uint64_t target_bytes = (max_bytes * 9ULL) / 10ULL;
    for (const auto& f : files) {
        if (total_bytes <= target_bytes) break;
        if (std::remove(f.path.c_str()) == 0) {
            total_bytes = (total_bytes > f.size) ? (total_bytes - f.size) : 0;
        }
    }
}

} // namespace spotify::cache
