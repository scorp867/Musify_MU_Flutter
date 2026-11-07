#pragma once

#include <cstdint>
#include <mutex>
#include <string>

namespace spotify::cache {

/// Thread-safe POSIX LRU disk cache for Chunk 0 Ogg Vorbis head files (`<cache_dir>/heads/<fileId>.ogg`).
class DiskCache {
public:
    static constexpr uint64_t kDefaultMaxBytes = 64ULL * 1024ULL * 1024ULL; // 64 MiB
    static constexpr int64_t kMinValidHeadBytes = 512;

    explicit DiskCache(uint64_t max_bytes = kDefaultMaxBytes);
    ~DiskCache() = default;

    DiskCache(const DiskCache&) = delete;
    DiskCache& operator=(const DiskCache&) = delete;

    void setBaseCacheDir(const std::string& cache_dir);

    [[nodiscard]] std::string resolveHeadPath(const std::string& file_id_hex) const;

    /// Returns non-empty path and updates mtime if a valid head file (`>= 512` bytes) exists on disk.
    [[nodiscard]] std::string lookupValidHead(const std::string& file_id_hex);

    /// Touches a newly downloaded head file and evicts oldest files if total size exceeds budget.
    void onHeadStored(const std::string& file_id_hex);

private:
    void ensureHeadsDirLocked() const;
    void evictIfNeededLocked();

    mutable std::mutex mutex_;
    std::string heads_dir_;
    uint64_t max_bytes_;
    uint32_t writes_since_prune_{0};
};

} // namespace spotify::cache
