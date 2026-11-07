#include "DiskCache.h"

#include <algorithm>
#include <cstdio>
#include <cstring>
#include <dirent.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <vector>

namespace spotify::cache {

namespace {
constexpr const char* kFallbackHeadsDir = "/data/data/um.musify.mu.musify_mu/cache/heads";

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
} // namespace

DiskCache::DiskCache(uint64_t max_bytes)
    : heads_dir_(kFallbackHeadsDir),
      max_bytes_(max_bytes) {}

void DiskCache::setBaseCacheDir(const std::string& cache_dir) {
    if (cache_dir.empty()) return;
    std::lock_guard<std::mutex> lock(mutex_);
    std::string next_dir = cache_dir;
    if (next_dir.back() == '/') {
        next_dir += "heads";
    } else {
        next_dir += "/heads";
    }
    if (heads_dir_ != next_dir) {
        heads_dir_ = std::move(next_dir);
        ensureHeadsDirLocked();
    }
}

void DiskCache::ensureHeadsDirLocked() const {
    if (heads_dir_.empty()) return;
    mkdir(heads_dir_.c_str(), 0700);
}

std::string DiskCache::resolveHeadPath(const std::string& file_id_hex) const {
    std::lock_guard<std::mutex> lock(mutex_);
    ensureHeadsDirLocked();
    return heads_dir_ + "/" + file_id_hex + ".ogg";
}

std::string DiskCache::lookupValidHead(const std::string& file_id_hex) {
    if (file_id_hex.empty()) return {};

    std::string path;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        ensureHeadsDirLocked();
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
    ensureHeadsDirLocked();
    const std::string path = heads_dir_ + "/" + file_id_hex + ".ogg";
    touchFileMtime(path);
    writes_since_prune_ += 1;
    if (writes_since_prune_ >= 8) {
        writes_since_prune_ = 0;
        evictIfNeededLocked();
    }
}

void DiskCache::evictIfNeededLocked() {
    if (heads_dir_.empty()) return;

    DIR* dir = opendir(heads_dir_.c_str());
    if (!dir) return;

    struct FileEntry {
        std::string path;
        uint64_t size{0};
        int64_t mtime_sec{0};
        int64_t mtime_nsec{0};
    };

    std::vector<FileEntry> files;
    uint64_t total_bytes = 0;

    while (struct dirent* ent = readdir(dir)) {
        if (ent->d_name[0] == '.') continue;
        const std::string full_path = heads_dir_ + "/" + ent->d_name;

        if (endsWith(ent->d_name, ".part")) {
            struct stat pst {};
            if (stat(full_path.c_str(), &pst) == 0) {
                const time_t now_s = std::time(nullptr);
                if (now_s - pst.st_mtime > 120) {
                    std::remove(full_path.c_str());
                }
            }
            continue;
        }

        if (!endsWith(ent->d_name, ".ogg")) continue;

        struct stat st {};
        if (stat(full_path.c_str(), &st) != 0) continue;

        if (st.st_size < kMinValidHeadBytes) {
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

    if (total_bytes <= max_bytes_) return;

    std::sort(files.begin(), files.end(), [](const FileEntry& a, const FileEntry& b) {
        if (a.mtime_sec != b.mtime_sec) return a.mtime_sec < b.mtime_sec;
        return a.mtime_nsec < b.mtime_nsec;
    });

    for (const auto& f : files) {
        if (total_bytes <= max_bytes_) break;
        if (std::remove(f.path.c_str()) == 0) {
            total_bytes = (total_bytes > f.size) ? (total_bytes - f.size) : 0;
        }
    }
}

} // namespace spotify::cache
