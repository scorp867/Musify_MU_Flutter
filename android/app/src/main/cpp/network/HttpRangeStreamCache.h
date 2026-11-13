#pragma once

#include "NativeHttpClient.h"

#include <atomic>
#include <condition_variable>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <list>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <unordered_map>
#include <utility>
#include <vector>

namespace spotify::network {

/// Optional callback invoked when all known CDN URLs return an authorization/expiry error
/// (HTTP 401/403/404/410). Returns a fresh list of signed CDN URLs, or empty on failure.
using UrlRefreshCallback = std::function<std::vector<std::string>()>;

/// Thread-safe, block-aligned HTTPS byte-range stream cache implementing random-access reads
/// for Android NDK AMediaDataSource without spawning Java Binder/MediaHTTP connections.
///
/// Design properties:
/// - Aligned 128 KiB sparse blocks with pinned 512 KiB header window (Blocks 0..3 for MP4 moov/sidx)
/// - Coalesced 256 KiB foreground miss / open() fetches (1 RTT loads 2 blocks at once)
/// - Bounded 192-block LRU cache (24 MiB cap; holds entire track in RAM once buffered)
/// - Single-flight per-block request deduplication across extractor & prefetcher threads
/// - Preemptible 3 MiB background read-ahead in 512 KiB coalesced batches over keep-alive HTTP/2
/// - Backup CDN URL rotation + single-flight URL refresh callback on 401/403/404/410
/// - Immediate non-blocking cancel() & preemptPrefetch() waking blocked readers cleanly
class HttpRangeStreamCache {
public:
    static constexpr size_t kBlockSize = 128 * 1024;
    static constexpr size_t kPinnedHeaderBlocks = 4;
    static constexpr size_t kMaxCachedBlocks = 192;
    static constexpr size_t kMissFetchBlocks = 2;
    static constexpr size_t kPrefetchBatchBlocks = 4;
    static constexpr size_t kPrefetchAheadBlocks = 24;

    HttpRangeStreamCache(
        std::vector<std::string> urls,
        std::vector<std::pair<std::string, std::string>> extra_headers = {},
        UrlRefreshCallback url_refresh_cb = nullptr,
        NativeHttpClient& http_client = NativeHttpClient::defaultInstance());

    ~HttpRangeStreamCache();

    HttpRangeStreamCache(const HttpRangeStreamCache&) = delete;
    HttpRangeStreamCache& operator=(const HttpRangeStreamCache&) = delete;

    /// Probes remote stream length via Range/HEAD request and starts the prefetch worker.
    /// Must be called before readAt(). Safe to cancel concurrently via cancel().
    [[nodiscard]] bool open();

    /// Synchronous random-access read adhering strictly to AMediaDataSource::readAt contract:
    /// - Returns > 0: exact byte count copied into `buffer`
    /// - Returns   0: strict EOF (offset >= totalSize) or zero-length request
    /// - Returns  -1: canceled or unrecoverable transport/HTTP error
    [[nodiscard]] ssize_t readAt(int64_t offset, void* buffer, size_t size);

    /// Total resource byte length discovered during open(), or -1 if unknown/unopened.
    [[nodiscard]] int64_t getSize() const noexcept;

    /// Signals cancellation immediately. Wakes all threads blocked in readAt()/open() and
    /// aborts any active libcurl transfers without waiting on network sockets.
    void cancel() noexcept;

    /// Aborts any active background read-ahead transfer without affecting foreground
    /// extractor reads, freeing the HTTP/2 worker immediately after a user seek.
    void preemptPrefetch() noexcept;

    /// Cancels active work, joins the background prefetch thread, and releases cached blocks.
    void close() noexcept;

    [[nodiscard]] bool isCanceled() const noexcept {
        return canceled_.load(std::memory_order_acquire);
    }

    [[nodiscard]] std::string primaryUrl() const;

private:
    struct InFlightBlock {
        std::shared_ptr<const std::vector<uint8_t>> data;
        bool done{false};
        bool ok{false};
        bool preempted{false};
    };

    [[nodiscard]] std::shared_ptr<const std::vector<uint8_t>> acquireBlock(size_t block_index);
    bool acquirePrefetchBatch(size_t start_block, size_t max_blocks);
    [[nodiscard]] HttpRangeResult fetchBlockWithFailover(
        int64_t offset,
        size_t length,
        const std::atomic<bool>& cancel_token);
    [[nodiscard]] HttpRangeResult tryUrlsLockedSnapshot(
        const std::vector<std::string>& urls,
        size_t start_index,
        int64_t offset,
        size_t length,
        const std::atomic<bool>& cancel_token,
        bool& saw_expired_out);
    [[nodiscard]] bool tryRefreshUrls(
        uint64_t observed_generation,
        const std::atomic<bool>& cancel_token);

    void insertBlockLocked(size_t block_index, std::shared_ptr<const std::vector<uint8_t>> data);
    void touchLruLocked(size_t block_index);
    void schedulePrefetchLocked(size_t next_block_index);
    void prefetchWorker();

    NativeHttpClient& http_client_;
    std::vector<std::pair<std::string, std::string>> extra_headers_;
    UrlRefreshCallback url_refresh_cb_;

    mutable std::mutex url_mu_;
    std::vector<std::string> urls_;
    size_t active_url_index_{0};
    uint64_t url_generation_{0};
    std::mutex refresh_mu_;

    std::atomic<int64_t> total_size_{-1};
    std::atomic<bool> canceled_{false};
    std::atomic<bool> closed_{false};
    std::atomic<bool> prefetch_abort_{false};

    mutable std::mutex mu_;
    std::condition_variable block_cv_;
    std::condition_variable prefetch_cv_;

    std::unordered_map<size_t, std::shared_ptr<const std::vector<uint8_t>>> blocks_;
    std::list<size_t> lru_order_;
    std::unordered_map<size_t, std::list<size_t>::iterator> lru_map_;
    std::unordered_map<size_t, std::shared_ptr<InFlightBlock>> in_flight_;

    bool has_prefetch_target_{false};
    size_t prefetch_target_block_{0};
    std::thread prefetch_thread_;
};

} // namespace spotify::network
