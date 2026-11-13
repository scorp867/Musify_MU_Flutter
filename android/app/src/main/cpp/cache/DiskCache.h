#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

namespace spotify::cache {

/// Thread-safe POSIX two-tier LRU disk cache for:
/// 1. Chunk 0 Ogg Vorbis head files (`<cache_dir>/heads/<fileId>.ogg`)
/// 2. Fixed-size 64 KiB random-access stream blocks (`<cache_dir>/streams/<streamKey>_<blockIdx>.blk`)
///    and stream length metadata (`<cache_dir>/streams/<streamKey>.meta`).
class DiskCache {
public:
    static constexpr uint64_t kDefaultMaxBytes = 64ULL * 1024ULL * 1024ULL;         // 64 MiB for heads
    static constexpr uint64_t kDefaultMaxStreamBytes = 256ULL * 1024ULL * 1024ULL;  // 256 MiB for stream blocks
    static constexpr int64_t kMinValidHeadBytes = 512;

    explicit DiskCache(uint64_t max_head_bytes = kDefaultMaxBytes,
                       uint64_t max_stream_bytes = kDefaultMaxStreamBytes);
    ~DiskCache() = default;

    DiskCache(const DiskCache&) = delete;
    DiskCache& operator=(const DiskCache&) = delete;

    [[nodiscard]] static DiskCache& defaultInstance();

    void setBaseCacheDir(const std::string& cache_dir);

    // --- Tier 1: Chunk 0 Head Files ---

    [[nodiscard]] std::string resolveHeadPath(const std::string& file_id_hex) const;

    /// Returns non-empty path and updates mtime if a valid head file (`>= 512` bytes) exists on disk.
    [[nodiscard]] std::string lookupValidHead(const std::string& file_id_hex);

    /// Touches a newly downloaded head file and evicts oldest files if total size exceeds budget.
    void onHeadStored(const std::string& file_id_hex);

    // --- Tier 2: Full-Track Stream Blocks (64 KiB sparse blocks) ---

    /// Extracts a canonical cache key from a CDN URL (40-char hex Spotify fileId when present,
    /// or deterministic FNV-1a hash of the URL path without volatile query tokens).
    [[nodiscard]] static std::string extractStreamCacheKey(const std::string& url);

    /// Reads persisted total stream byte length for `stream_key`, or -1 if not cached.
    [[nodiscard]] int64_t readStreamTotalSize(const std::string& stream_key);

    /// Atomically persists total stream byte length for `stream_key`.
    void writeStreamTotalSize(const std::string& stream_key, int64_t total_size);

    /// Reads a cached stream block from disk if present and matching `expected_size` (when > 0).
    /// Updates file mtime on hit for LRU tracking.
    [[nodiscard]] std::shared_ptr<const std::vector<uint8_t>> readStreamBlock(
        const std::string& stream_key,
        size_t block_index,
        size_t expected_size = 0);

    /// Atomically writes a stream block to disk and triggers periodic LRU eviction.
    void writeStreamBlock(
        const std::string& stream_key,
        size_t block_index,
        const uint8_t* data,
        size_t len);

private:
    void ensureDirsLocked() const;
    void evictHeadsIfNeededLocked();
    void evictStreamsIfNeededLocked();
    static void evictDirectoryLocked(const std::string& dir_path,
                                     uint64_t max_bytes,
                                     bool is_heads_dir);

    mutable std::mutex mutex_;
    std::string heads_dir_;
    std::string streams_dir_;
    uint64_t max_head_bytes_;
    uint64_t max_stream_bytes_;
    uint32_t head_writes_since_prune_{0};
    uint32_t stream_writes_since_prune_{0};
};

} // namespace spotify::cache
