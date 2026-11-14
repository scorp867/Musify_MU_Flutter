#pragma once

#include "../cache/DiskCache.h"
#include "NativeHttpClient.h"
#include "NativeTrafficController.h"

#include <array>
#include <atomic>
#include <condition_variable>
#include <cstddef>
#include <cstdint>
#include <deque>
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
/// (HTTP 401/403/404/410) or when a stream opened offline from DiskCache needs live CDN URLs.
using UrlRefreshCallback = std::function<std::vector<std::string>()>;

/// Thread-safe, two-tier (RAM + Disk) block-aligned HTTPS byte-range stream cache implementing
/// strictly demand-driven progressive sub-block random-access reads for Android NDK AMediaDataSource.
///
/// Design properties:
/// - Aligned 64 KiB sparse blocks with pinned 256 KiB header window (Blocks 0..3 for MP4 moov/sidx)
/// - Two-tier lookup: 12 MiB in-memory hot LRU (`blocks_`) backed by 256 MiB persistent `DiskCache`
/// - Governed by `NativeTrafficController` at `P0_PlaybackCritical` with `OfflinePolicy::WaitForOnline`:
///   when offline, cached 64 KiB blocks are served in <1ms from DiskCache, while uncached blocks park
///   cleanly in the P0 queue without returning -1 (preventing false EOS / unwanted track skips) and
///   automatically resume the instant connectivity returns or cancel in <1ms on seek/track-switch.
class HttpRangeStreamCache {
public:
    static constexpr size_t kBlockSize = 64 * 1024;
    static constexpr size_t kPinnedHeaderBlocks = 4;
    static constexpr size_t kMaxCachedBlocks = 192;
    static constexpr size_t kForegroundWorkers = 2;
    static constexpr const char* kOfflineSyntheticUrlPrefix =
        "https://offline-cache.spotify.local/audio/";

    HttpRangeStreamCache(
        std::vector<std::string> urls,
        std::vector<std::pair<std::string, std::string>> extra_headers = {},
        UrlRefreshCallback url_refresh_cb = nullptr,
        NativeHttpClient& http_client = NativeHttpClient::defaultInstance(),
        cache::DiskCache& disk_cache = cache::DiskCache::defaultInstance());

    ~HttpRangeStreamCache();

    HttpRangeStreamCache(const HttpRangeStreamCache&) = delete;
    HttpRangeStreamCache& operator=(const HttpRangeStreamCache&) = delete;

    /// Opens the stream (from DiskCache in <1ms if cached, or via a P0 64 KiB Range request
    /// that waits for connectivity if offline) and starts the on-demand streaming workers.
    [[nodiscard]] bool open();

    /// Synchronous random-access read adhering strictly to AMediaDataSource::readAt contract:
    /// - Returns > 0: exact byte count copied into `buffer`
    /// - Returns   0: strict EOF (offset >= totalSize) or zero-length request
    /// - Returns  -1: canceled or superseded by a newer seek epoch
    [[nodiscard]] ssize_t readAt(int64_t offset, void* buffer, size_t size);

    /// Total resource byte length discovered during open(), or -1 if unknown/unopened.
    [[nodiscard]] int64_t getSize() const noexcept;

    /// Signals cancellation immediately. Wakes all threads blocked in readAt()/open() and
    /// aborts any active libcurl transfers or P0 queue waits without waiting on network sockets.
    void cancel() noexcept;

    /// Increments the seek epoch, aborts stale transfers/waits from prior seeks, and wakes any
    /// thread blocked on a superseded seek read.
    void onSeek() noexcept;

    /// Alias for onSeek() used by IAudioDataSource::preemptPrefetch().
    void preemptPrefetch() noexcept;

    /// Cancels active work, joins worker threads, and releases in-memory blocks.
    void close() noexcept;

    [[nodiscard]] bool isCanceled() const noexcept {
        return canceled_.load(std::memory_order_acquire);
    }

    [[nodiscard]] std::string primaryUrl() const;

private:
    enum class BlockTransferPhase : uint8_t {
        Streaming = 0,
        CompletedOk = 1,
        PreemptedBySeek = 2,
        Aborted = 3,
    };

    enum class WorkerPoolState : uint8_t {
        Unstarted = 0,
        Running = 1,
        Stopped = 2,
    };

    struct InFlightBlock {
        std::vector<uint8_t> buffer;
        size_t expected_size{0};
        size_t filled_bytes{0};
        std::shared_ptr<const std::vector<uint8_t>> data;
        BlockTransferPhase phase{BlockTransferPhase::Streaming};
        uint32_t foreground_waiters{0};
    };

    struct ForegroundRequest {
        size_t block_index{0};
        uint64_t seek_epoch{0};
        std::shared_ptr<InFlightBlock> flight;
    };

    [[nodiscard]] ssize_t readFromBlock(
        size_t block_index,
        size_t in_block_offset,
        uint8_t* dst,
        size_t wanted_len,
        uint64_t caller_seek_epoch);

    void executeForegroundRequest(const ForegroundRequest& req);

    [[nodiscard]] bool streamSpanWithFailover(
        int64_t start_offset,
        size_t span_len,
        const std::vector<std::pair<size_t, std::shared_ptr<InFlightBlock>>>& span_flights,
        const CancelPredicate& cancel_pred);

    [[nodiscard]] HttpRangeResult tryStreamUrlsLockedSnapshot(
        const std::vector<std::string>& urls,
        size_t start_index,
        int64_t start_offset,
        size_t span_len,
        const std::vector<std::pair<size_t, std::shared_ptr<InFlightBlock>>>& span_flights,
        const CancelPredicate& cancel_pred,
        bool& saw_expired_out);

    [[nodiscard]] bool tryRefreshUrls(
        uint64_t observed_generation,
        const CancelPredicate& cancel_pred);

    [[nodiscard]] static bool isOfflineSyntheticUrl(const std::string& url) noexcept;

    void insertBlockLocked(size_t block_index, std::shared_ptr<const std::vector<uint8_t>> data);
    void touchLruLocked(size_t block_index);
    void startWorkersIfNeeded();
    void foregroundWorker();

    NativeHttpClient& http_client_;
    cache::DiskCache& disk_cache_;
    std::vector<std::pair<std::string, std::string>> extra_headers_;
    UrlRefreshCallback url_refresh_cb_;
    std::string stream_key_;

    mutable std::mutex url_mu_;
    std::vector<std::string> urls_;
    size_t active_url_index_{0};
    uint64_t url_generation_{0};
    std::mutex refresh_mu_;

    std::atomic<int64_t> total_size_{-1};
    std::atomic<bool> canceled_{false};
    std::atomic<bool> closed_{false};
    std::atomic<uint64_t> seek_epoch_{0};

    mutable std::mutex mu_;
    std::condition_variable block_cv_;
    std::condition_variable fg_cv_;

    std::unordered_map<size_t, std::shared_ptr<const std::vector<uint8_t>>> blocks_;
    std::list<size_t> lru_order_;
    std::unordered_map<size_t, std::list<size_t>::iterator> lru_map_;
    std::unordered_map<size_t, std::shared_ptr<InFlightBlock>> in_flight_;
    std::deque<ForegroundRequest> fg_queue_;

    WorkerPoolState worker_pool_state_{WorkerPoolState::Unstarted};
    std::array<std::thread, kForegroundWorkers> fg_threads_;
};

} // namespace spotify::network
