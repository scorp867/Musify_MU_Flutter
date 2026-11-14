#include "HttpRangeStreamCache.h"

#include <android/log.h>

#include <algorithm>
#include <chrono>
#include <cstring>

#define RSC_LOG_TAG "MusifyRangeCache"
#define RSC_LOGI(...) __android_log_print(ANDROID_LOG_INFO, RSC_LOG_TAG, __VA_ARGS__)
#define RSC_LOGW(...) __android_log_print(ANDROID_LOG_WARN, RSC_LOG_TAG, __VA_ARGS__)
#define RSC_LOGE(...) __android_log_print(ANDROID_LOG_ERROR, RSC_LOG_TAG, __VA_ARGS__)

namespace spotify::network {

namespace {
constexpr int kConnectTimeoutMs = 8000;
constexpr int kReadTimeoutMs = 15000;
} // namespace

HttpRangeStreamCache::HttpRangeStreamCache(
    std::vector<std::string> urls,
    std::vector<std::pair<std::string, std::string>> extra_headers,
    UrlRefreshCallback url_refresh_cb,
    NativeHttpClient& http_client,
    cache::DiskCache& disk_cache)
    : http_client_(http_client),
      disk_cache_(disk_cache),
      extra_headers_(std::move(extra_headers)),
      url_refresh_cb_(std::move(url_refresh_cb)),
      urls_(std::move(urls)) {
    if (!urls_.empty()) {
        stream_key_ = cache::DiskCache::extractStreamCacheKey(urls_.front());
    }
}

HttpRangeStreamCache::~HttpRangeStreamCache() {
    close();
}

bool HttpRangeStreamCache::isOfflineSyntheticUrl(const std::string& url) noexcept {
    const size_t prefix_len = std::strlen(kOfflineSyntheticUrlPrefix);
    return url.size() >= prefix_len &&
           std::memcmp(url.data(), kOfflineSyntheticUrlPrefix, prefix_len) == 0;
}

std::string HttpRangeStreamCache::primaryUrl() const {
    std::lock_guard<std::mutex> lock(url_mu_);
    if (urls_.empty()) return {};
    return urls_[active_url_index_ % urls_.size()];
}

int64_t HttpRangeStreamCache::getSize() const noexcept {
    return total_size_.load(std::memory_order_acquire);
}

void HttpRangeStreamCache::cancel() noexcept {
    canceled_.store(true, std::memory_order_release);
    seek_epoch_.fetch_add(1, std::memory_order_acq_rel);
    if (!stream_key_.empty()) {
        NativeTrafficController::instance().cancelByTagPrefix("stream:" + stream_key_);
    } else {
        NativeTrafficController::instance().notifyAllWaiters();
    }
    std::lock_guard<std::mutex> lock(mu_);
    fg_queue_.clear();
    block_cv_.notify_all();
    fg_cv_.notify_all();
}

void HttpRangeStreamCache::onSeek() noexcept {
    seek_epoch_.fetch_add(1, std::memory_order_acq_rel);
    if (!stream_key_.empty()) {
        NativeTrafficController::instance().cancelByTagPrefix("stream:" + stream_key_);
    } else {
        NativeTrafficController::instance().notifyAllWaiters();
    }
    std::lock_guard<std::mutex> lock(mu_);
    fg_queue_.clear();
    block_cv_.notify_all();
    fg_cv_.notify_all();
}

void HttpRangeStreamCache::preemptPrefetch() noexcept {
    onSeek();
}

void HttpRangeStreamCache::close() noexcept {
    const bool already_closed = closed_.exchange(true, std::memory_order_acq_rel);
    canceled_.store(true, std::memory_order_release);
    seek_epoch_.fetch_add(1, std::memory_order_acq_rel);
    if (!stream_key_.empty()) {
        NativeTrafficController::instance().cancelByTagPrefix("stream:" + stream_key_);
    } else {
        NativeTrafficController::instance().notifyAllWaiters();
    }
    {
        std::lock_guard<std::mutex> lock(mu_);
        fg_queue_.clear();
        block_cv_.notify_all();
        fg_cv_.notify_all();
    }
    if (!already_closed) {
        for (auto& t : fg_threads_) {
            if (t.joinable()) {
                t.join();
            }
        }
    }
    std::lock_guard<std::mutex> lock(mu_);
    blocks_.clear();
    lru_order_.clear();
    lru_map_.clear();
    in_flight_.clear();
    fg_queue_.clear();
}

void HttpRangeStreamCache::startWorkersIfNeeded() {
    std::lock_guard<std::mutex> lock(mu_);
    if (closed_.load(std::memory_order_acquire) ||
        worker_pool_state_ != WorkerPoolState::Unstarted) {
        return;
    }
    worker_pool_state_ = WorkerPoolState::Running;
    for (size_t i = 0; i < kForegroundWorkers; ++i) {
        fg_threads_[i] = std::thread(&HttpRangeStreamCache::foregroundWorker, this);
    }
}

bool HttpRangeStreamCache::open() {
    if (canceled_.load(std::memory_order_acquire) || closed_.load(std::memory_order_acquire)) {
        return false;
    }

    {
        std::lock_guard<std::mutex> lock(url_mu_);
        if (urls_.empty() && !url_refresh_cb_) {
            RSC_LOGE("open() failed: no CDN URLs and no URL refresh callback provided");
            return false;
        }
    }

    // 1. Fast path: check persistent DiskCache for stream metadata + Block 0
    if (!stream_key_.empty()) {
        const int64_t disk_total = disk_cache_.readStreamTotalSize(stream_key_);
        if (disk_total > 0) {
            const size_t expected_blk0 =
                static_cast<size_t>(std::min<int64_t>(kBlockSize, disk_total));
            auto blk0 = disk_cache_.readStreamBlock(stream_key_, 0, expected_blk0);
            if (blk0) {
                total_size_.store(disk_total, std::memory_order_release);
                const size_t total_blocks = static_cast<size_t>(
                    (static_cast<uint64_t>(disk_total) + kBlockSize - 1) / kBlockSize);
                const size_t header_limit = std::min(total_blocks, kPinnedHeaderBlocks);
                size_t loaded_header_blocks = 1;
                {
                    std::lock_guard<std::mutex> lock(mu_);
                    insertBlockLocked(0, std::move(blk0));
                }
                for (size_t b = 1; b < header_limit; ++b) {
                    const int64_t b_off = static_cast<int64_t>(b * kBlockSize);
                    const size_t exp_b =
                        static_cast<size_t>(std::min<int64_t>(kBlockSize, disk_total - b_off));
                    auto blk_b = disk_cache_.readStreamBlock(stream_key_, b, exp_b);
                    if (!blk_b) break;
                    std::lock_guard<std::mutex> lock(mu_);
                    insertBlockLocked(b, std::move(blk_b));
                    ++loaded_header_blocks;
                }
                startWorkersIfNeeded();
                RSC_LOGI("Opened range stream from DiskCache HIT total_size=%lld bytes (%zu header blocks warm, key=%s)",
                         static_cast<long long>(disk_total),
                         loaded_header_blocks,
                         stream_key_.c_str());
                return true;
            }
        }
    }

    // 2. Network path: enqueue Block 0 on P0_PlaybackCritical (waits in NativeTrafficController
    // if the device is currently offline, and auto-resumes as soon as connectivity returns).
    startWorkersIfNeeded();

    const uint64_t epoch = seek_epoch_.load(std::memory_order_acquire);
    auto flight0 = std::make_shared<InFlightBlock>();
    flight0->expected_size = kBlockSize;
    flight0->buffer.resize(kBlockSize);
    flight0->foreground_waiters = 1;

    {
        std::lock_guard<std::mutex> lock(mu_);
        in_flight_[0] = flight0;
        fg_queue_.push_back(ForegroundRequest{0, epoch, flight0});
        fg_cv_.notify_one();
    }

    bool open_ok = false;
    {
        std::unique_lock<std::mutex> lock(mu_);
        block_cv_.wait(lock, [&]() {
            return (total_size_.load(std::memory_order_acquire) > 0 && flight0->filled_bytes > 0) ||
                   flight0->phase != BlockTransferPhase::Streaming ||
                   canceled_.load(std::memory_order_acquire) ||
                   closed_.load(std::memory_order_acquire);
        });
        if (flight0->foreground_waiters > 0) {
            --flight0->foreground_waiters;
        }
        const int64_t discovered_total = total_size_.load(std::memory_order_acquire);
        open_ok = !canceled_.load(std::memory_order_acquire) &&
                  !closed_.load(std::memory_order_acquire) &&
                  discovered_total > 0 &&
                  (flight0->filled_bytes > 0 || flight0->phase == BlockTransferPhase::CompletedOk);
    }

    if (open_ok) {
        RSC_LOGI("Opened range stream progressively total_size=%lld bytes (key=%s)",
                 static_cast<long long>(total_size_.load(std::memory_order_acquire)),
                 stream_key_.c_str());
    }
    return open_ok;
}

ssize_t HttpRangeStreamCache::readAt(int64_t offset, void* buffer, size_t size) {
    if (canceled_.load(std::memory_order_acquire) || closed_.load(std::memory_order_acquire)) {
        return -1;
    }
    if (offset < 0 || buffer == nullptr) {
        return -1;
    }

    const int64_t total = total_size_.load(std::memory_order_acquire);
    if (total <= 0 || offset >= total) {
        return 0;
    }
    if (size == 0) {
        return 0;
    }

    const uint64_t caller_epoch = seek_epoch_.load(std::memory_order_acquire);
    const uint64_t remaining_u64 = static_cast<uint64_t>(total - offset);
    const size_t target_bytes = static_cast<size_t>(std::min<uint64_t>(size, remaining_u64));

    auto* dst = static_cast<uint8_t*>(buffer);
    size_t copied = 0;
    int64_t cursor = offset;

    while (copied < target_bytes) {
        if (canceled_.load(std::memory_order_acquire) ||
            closed_.load(std::memory_order_acquire) ||
            seek_epoch_.load(std::memory_order_acquire) != caller_epoch) {
            return -1;
        }

        const size_t block_index = static_cast<size_t>(static_cast<uint64_t>(cursor) / kBlockSize);
        const size_t in_block_offset = static_cast<size_t>(static_cast<uint64_t>(cursor) % kBlockSize);
        const int64_t block_start_byte = static_cast<int64_t>(static_cast<uint64_t>(block_index) * kBlockSize);
        if (block_start_byte >= total) {
            break;
        }
        const size_t expected_block_len =
            static_cast<size_t>(std::min<int64_t>(kBlockSize, total - block_start_byte));
        if (in_block_offset >= expected_block_len) {
            break;
        }

        const size_t avail_in_block = expected_block_len - in_block_offset;
        const size_t wanted_from_block = std::min(target_bytes - copied, avail_in_block);

        const ssize_t n = readFromBlock(
            block_index,
            in_block_offset,
            dst + copied,
            wanted_from_block,
            caller_epoch);

        if (n <= 0) {
            if (canceled_.load(std::memory_order_acquire) ||
                closed_.load(std::memory_order_acquire) ||
                seek_epoch_.load(std::memory_order_acquire) != caller_epoch) {
                return -1;
            }
            return copied > 0 ? static_cast<ssize_t>(copied) : -1;
        }

        copied += static_cast<size_t>(n);
        cursor += static_cast<int64_t>(n);
    }

    return static_cast<ssize_t>(copied);
}

ssize_t HttpRangeStreamCache::readFromBlock(
    size_t block_index,
    size_t in_block_offset,
    uint8_t* dst,
    size_t wanted_len,
    uint64_t caller_seek_epoch) {
    const int64_t total = total_size_.load(std::memory_order_acquire);
    if (total <= 0) return -1;

    const int64_t block_offset = static_cast<int64_t>(static_cast<uint64_t>(block_index) * kBlockSize);
    if (block_offset >= total) return 0;

    const size_t expected_block_len =
        static_cast<size_t>(std::min<int64_t>(kBlockSize, total - block_offset));
    if (in_block_offset >= expected_block_len) return 0;
    const size_t safe_wanted = std::min(wanted_len, expected_block_len - in_block_offset);

    for (;;) {
        std::shared_ptr<InFlightBlock> flight;
        bool check_disk = false;
        {
            std::unique_lock<std::mutex> lock(mu_);
            if (canceled_.load(std::memory_order_acquire) ||
                closed_.load(std::memory_order_acquire) ||
                seek_epoch_.load(std::memory_order_acquire) != caller_seek_epoch) {
                return -1;
            }

            // Tier 1: Hot RAM LRU cache hit
            auto cached_it = blocks_.find(block_index);
            if (cached_it != blocks_.end()) {
                touchLruLocked(block_index);
                const auto& vec = cached_it->second;
                if (in_block_offset >= vec->size()) return 0;
                const size_t to_copy = std::min(safe_wanted, vec->size() - in_block_offset);
                std::memcpy(dst, vec->data() + in_block_offset, to_copy);
                return static_cast<ssize_t>(to_copy);
            }

            // Active in-flight block hit
            auto flight_it = in_flight_.find(block_index);
            if (flight_it != in_flight_.end()) {
                flight = flight_it->second;
                flight->foreground_waiters += 1;
            } else {
                check_disk = !stream_key_.empty();
                if (!check_disk) {
                    flight = std::make_shared<InFlightBlock>();
                    flight->expected_size = expected_block_len;
                    flight->buffer.resize(expected_block_len);
                    flight->foreground_waiters = 1;
                    in_flight_[block_index] = flight;
                    fg_queue_.push_back(ForegroundRequest{block_index, caller_seek_epoch, flight});
                    fg_cv_.notify_one();
                }
            }
        }

        // Tier 2: Persistent DiskCache lookup (performed outside mu_ lock)
        if (check_disk) {
            auto disk_vec = disk_cache_.readStreamBlock(stream_key_, block_index, expected_block_len);
            std::unique_lock<std::mutex> lock(mu_);
            if (canceled_.load(std::memory_order_acquire) ||
                closed_.load(std::memory_order_acquire) ||
                seek_epoch_.load(std::memory_order_acquire) != caller_seek_epoch) {
                return -1;
            }

            if (disk_vec) {
                insertBlockLocked(block_index, disk_vec);
                if (in_block_offset >= disk_vec->size()) return 0;
                const size_t to_copy = std::min(safe_wanted, disk_vec->size() - in_block_offset);
                std::memcpy(dst, disk_vec->data() + in_block_offset, to_copy);
                return static_cast<ssize_t>(to_copy);
            }

            // Re-check RAM and in_flight_ after disk miss
            auto cached_it = blocks_.find(block_index);
            if (cached_it != blocks_.end()) {
                touchLruLocked(block_index);
                const auto& vec = cached_it->second;
                if (in_block_offset >= vec->size()) return 0;
                const size_t to_copy = std::min(safe_wanted, vec->size() - in_block_offset);
                std::memcpy(dst, vec->data() + in_block_offset, to_copy);
                return static_cast<ssize_t>(to_copy);
            }

            auto flight_it = in_flight_.find(block_index);
            if (flight_it != in_flight_.end()) {
                flight = flight_it->second;
                flight->foreground_waiters += 1;
            } else {
                // Enqueue on foreground worker; if offline, worker parks in NativeTrafficController
                // (P0_PlaybackCritical, WaitForOnline) until connectivity returns or user seeks/skips.
                flight = std::make_shared<InFlightBlock>();
                flight->expected_size = expected_block_len;
                flight->buffer.resize(expected_block_len);
                flight->foreground_waiters = 1;
                in_flight_[block_index] = flight;
                fg_queue_.push_back(ForegroundRequest{block_index, caller_seek_epoch, flight});
                fg_cv_.notify_one();
            }
        }

        // Progressive wait: unblock as soon as `[in_block_offset, in_block_offset + safe_wanted)`
        // bytes have arrived in `flight->buffer`, without waiting for the entire 64 KiB block.
        const size_t required_fill = in_block_offset + safe_wanted;
        {
            std::unique_lock<std::mutex> lock(mu_);
            block_cv_.wait(lock, [&]() {
                return flight->filled_bytes >= required_fill ||
                       flight->phase != BlockTransferPhase::Streaming ||
                       canceled_.load(std::memory_order_acquire) ||
                       closed_.load(std::memory_order_acquire) ||
                       seek_epoch_.load(std::memory_order_acquire) != caller_seek_epoch;
            });

            if (flight->foreground_waiters > 0) {
                --flight->foreground_waiters;
            }

            if (canceled_.load(std::memory_order_acquire) ||
                closed_.load(std::memory_order_acquire) ||
                seek_epoch_.load(std::memory_order_acquire) != caller_seek_epoch) {
                return -1;
            }

            if (flight->filled_bytes >= required_fill) {
                std::memcpy(dst, flight->buffer.data() + in_block_offset, safe_wanted);
                return static_cast<ssize_t>(safe_wanted);
            }

            switch (flight->phase) {
                case BlockTransferPhase::CompletedOk: {
                    if (flight->filled_bytes > in_block_offset) {
                        const size_t avail = std::min(safe_wanted, flight->filled_bytes - in_block_offset);
                        std::memcpy(dst, flight->buffer.data() + in_block_offset, avail);
                        return static_cast<ssize_t>(avail);
                    }
                    return -1;
                }
                case BlockTransferPhase::PreemptedBySeek:
                    continue;
                case BlockTransferPhase::Aborted:
                case BlockTransferPhase::Streaming:
                    return -1;
            }
        }
    }
}

void HttpRangeStreamCache::foregroundWorker() {
    for (;;) {
        ForegroundRequest req;
        {
            std::unique_lock<std::mutex> lock(mu_);
            fg_cv_.wait(lock, [&]() {
                return !fg_queue_.empty() ||
                       canceled_.load(std::memory_order_acquire) ||
                       closed_.load(std::memory_order_acquire);
            });
            if (canceled_.load(std::memory_order_acquire) || closed_.load(std::memory_order_acquire)) {
                return;
            }
            req = std::move(fg_queue_.front());
            fg_queue_.pop_front();
        }

        executeForegroundRequest(req);
    }
}

void HttpRangeStreamCache::executeForegroundRequest(const ForegroundRequest& req) {
    if (!req.flight) return;

    const int64_t start_offset =
        static_cast<int64_t>(static_cast<uint64_t>(req.block_index) * kBlockSize);
    const size_t span_len = req.flight->expected_size > 0 ? req.flight->expected_size : kBlockSize;

    std::vector<std::pair<size_t, std::shared_ptr<InFlightBlock>>> span_flights;
    span_flights.emplace_back(req.block_index, req.flight);

    const CancelPredicate cancel_pred = [this, req_epoch = req.seek_epoch]() -> bool {
        if (canceled_.load(std::memory_order_acquire) || closed_.load(std::memory_order_acquire)) {
            return true;
        }
        return seek_epoch_.load(std::memory_order_acquire) != req_epoch;
    };

    const bool ok = streamSpanWithFailover(start_offset, span_len, span_flights, cancel_pred);

    std::shared_ptr<const std::vector<uint8_t>> to_persist;
    {
        std::lock_guard<std::mutex> lock(mu_);
        in_flight_.erase(req.block_index);
        if (req.flight->phase == BlockTransferPhase::Streaming) {
            const bool canceled_or_stale = cancel_pred();
            if (ok && req.flight->filled_bytes > 0 && !canceled_or_stale) {
                req.flight->buffer.resize(req.flight->filled_bytes);
                auto shared_vec = std::make_shared<const std::vector<uint8_t>>(req.flight->buffer);
                insertBlockLocked(req.block_index, shared_vec);
                req.flight->data = shared_vec;
                req.flight->phase = BlockTransferPhase::CompletedOk;
                to_persist = std::move(shared_vec);
            } else if (canceled_or_stale &&
                       !canceled_.load(std::memory_order_acquire) &&
                       !closed_.load(std::memory_order_acquire)) {
                req.flight->phase = BlockTransferPhase::PreemptedBySeek;
            } else {
                req.flight->phase = BlockTransferPhase::Aborted;
            }
        }
        block_cv_.notify_all();
    }

    if (to_persist && !stream_key_.empty()) {
        disk_cache_.writeStreamBlock(stream_key_, req.block_index, to_persist->data(), to_persist->size());
    }
}

bool HttpRangeStreamCache::streamSpanWithFailover(
    int64_t start_offset,
    size_t span_len,
    const std::vector<std::pair<size_t, std::shared_ptr<InFlightBlock>>>& span_flights,
    const CancelPredicate& cancel_pred) {
    const std::string tag = !stream_key_.empty()
        ? ("stream:" + stream_key_)
        : std::string("stream:active");

    while (!cancel_pred() && !canceled_.load(std::memory_order_acquire)) {
        // Acquire a P0_PlaybackCritical permit; if offline, parks cleanly in NativeTrafficController
        // until the Linux kernel route monitor detects connectivity restoration or cancel_pred fires.
        auto permit = NativeTrafficController::instance().acquirePermit(
            RequestPriority::P0_PlaybackCritical,
            OfflinePolicy::WaitForOnline,
            tag,
            &canceled_,
            cancel_pred);
        if (!permit) {
            return false;
        }

        std::vector<std::string> urls_snapshot;
        size_t start_index = 0;
        uint64_t gen_snapshot = 0;
        {
            std::lock_guard<std::mutex> lock(url_mu_);
            urls_snapshot = urls_;
            start_index = active_url_index_;
            gen_snapshot = url_generation_;
        }

        const bool only_synthetic_url =
            urls_snapshot.empty() ||
            (urls_snapshot.size() == 1 && isOfflineSyntheticUrl(urls_snapshot.front()));
        if (only_synthetic_url) {
            if (!tryRefreshUrls(gen_snapshot, cancel_pred)) {
                permit.complete(TransferOutcome::TransportFailure);
                if (cancel_pred() || canceled_.load(std::memory_order_acquire)) {
                    return false;
                }
                if (!NativeTrafficController::instance().waitForOnline(&canceled_, cancel_pred)) {
                    return false;
                }
                std::this_thread::sleep_for(std::chrono::milliseconds(200));
                continue;
            }
            std::lock_guard<std::mutex> lock(url_mu_);
            urls_snapshot = urls_;
            start_index = active_url_index_;
            gen_snapshot = url_generation_;
        }

        if (urls_snapshot.empty()) {
            permit.complete(TransferOutcome::TransportFailure);
            return false;
        }

        bool saw_expired = false;
        HttpRangeResult res = tryStreamUrlsLockedSnapshot(
            urls_snapshot, start_index, start_offset, span_len, span_flights, cancel_pred, saw_expired);
        if (res.isSuccess()) {
            permit.complete(TransferOutcome::Success);
            return true;
        }
        if (res.status == RangeFetchStatus::Canceled || cancel_pred() ||
            canceled_.load(std::memory_order_acquire)) {
            permit.complete(TransferOutcome::TransportFailure);
            return false;
        }

        if (saw_expired && tryRefreshUrls(gen_snapshot, cancel_pred)) {
            {
                std::lock_guard<std::mutex> lock(url_mu_);
                urls_snapshot = urls_;
                start_index = active_url_index_;
            }
            bool refreshed_expired = false;
            res = tryStreamUrlsLockedSnapshot(
                urls_snapshot, start_index, start_offset, span_len, span_flights, cancel_pred, refreshed_expired);
            if (res.isSuccess()) {
                permit.complete(TransferOutcome::Success);
                return true;
            }
            if (res.status == RangeFetchStatus::Canceled || cancel_pred() ||
                canceled_.load(std::memory_order_acquire)) {
                permit.complete(TransferOutcome::TransportFailure);
                return false;
            }
        }

        const TransferOutcome outcome = (res.status == RangeFetchStatus::NetworkError)
            ? TransferOutcome::TimedOut
            : TransferOutcome::TransportFailure;
        permit.complete(outcome);

        if (cancel_pred() || canceled_.load(std::memory_order_acquire)) {
            return false;
        }

        // If the connection dropped mid-stream or had a transient failure, hold for online
        // route restoration instead of returning -1 (which would trigger a false EOS in NativeDecoder).
        if (!NativeTrafficController::instance().waitForOnline(&canceled_, cancel_pred)) {
            return false;
        }

        // Brief cancellable backoff when route is nominally up but CDN socket failed transiently.
        for (int slice = 0; slice < 10; ++slice) {
            if (cancel_pred() || canceled_.load(std::memory_order_acquire)) {
                return false;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(30));
        }
    }

    return false;
}

HttpRangeResult HttpRangeStreamCache::tryStreamUrlsLockedSnapshot(
    const std::vector<std::string>& urls,
    size_t start_index,
    int64_t start_offset,
    size_t span_len,
    const std::vector<std::pair<size_t, std::shared_ptr<InFlightBlock>>>& span_flights,
    const CancelPredicate& cancel_pred,
    bool& saw_expired_out) {
    saw_expired_out = false;
    HttpRangeResult last_err;
    if (!NativeHttpClient::hasActiveNetworkRoute()) {
        last_err.status = RangeFetchStatus::Offline;
        return last_err;
    }

    const size_t count = urls.size();

    for (size_t i = 0; i < count; ++i) {
        if (cancel_pred() || canceled_.load(std::memory_order_acquire)) {
            HttpRangeResult canceled;
            canceled.status = RangeFetchStatus::Canceled;
            return canceled;
        }
        if (!NativeHttpClient::hasActiveNetworkRoute()) {
            HttpRangeResult offline;
            offline.status = RangeFetchStatus::Offline;
            return offline;
        }

        const size_t idx = (start_index + i) % count;
        const std::string& url = urls[idx];
        if (url.empty() || isOfflineSyntheticUrl(url)) continue;

        // Reset partial fill on retry if any block was not yet finalized
        {
            std::lock_guard<std::mutex> lock(mu_);
            for (const auto& [b_idx, fl] : span_flights) {
                (void)b_idx;
                if (fl->phase == BlockTransferPhase::Streaming) {
                    fl->filled_bytes = 0;
                }
            }
        }

        size_t stream_cursor = 0;
        bool persisted_total_size = false;

        HttpRangeResult res = http_client_.streamByteRange(
            url,
            start_offset,
            span_len,
            [&](const uint8_t* chunk_data, size_t chunk_len, int64_t total_resource_size) -> bool {
                if (cancel_pred() || canceled_.load(std::memory_order_acquire)) {
                    return false;
                }

                int64_t total_to_persist = -1;
                if (total_resource_size > 0) {
                    const int64_t prev_total =
                        total_size_.exchange(total_resource_size, std::memory_order_acq_rel);
                    if (prev_total <= 0 && !persisted_total_size && !stream_key_.empty()) {
                        persisted_total_size = true;
                        total_to_persist = total_resource_size;
                    }
                }
                if (total_to_persist > 0) {
                    disk_cache_.writeStreamTotalSize(stream_key_, total_to_persist);
                }

                std::vector<std::pair<size_t, std::shared_ptr<const std::vector<uint8_t>>>> completed_blocks;
                size_t chunk_pos = 0;
                while (chunk_pos < chunk_len && stream_cursor < span_len) {
                    const size_t span_idx = stream_cursor / kBlockSize;
                    const size_t offset_in_block = stream_cursor % kBlockSize;
                    if (span_idx >= span_flights.size()) {
                        break;
                    }

                    const size_t b_idx = span_flights[span_idx].first;
                    auto& flight = span_flights[span_idx].second;

                    if (total_resource_size > 0) {
                        const int64_t b_byte_start =
                            static_cast<int64_t>(static_cast<uint64_t>(b_idx) * kBlockSize);
                        if (b_byte_start < total_resource_size) {
                            const size_t true_exp = static_cast<size_t>(
                                std::min<int64_t>(kBlockSize, total_resource_size - b_byte_start));
                            if (true_exp < flight->expected_size) {
                                std::lock_guard<std::mutex> lock(mu_);
                                flight->expected_size = true_exp;
                            }
                        }
                    }

                    const size_t max_in_this_block = kBlockSize - offset_in_block;
                    const size_t to_copy = std::min(chunk_len - chunk_pos, max_in_this_block);
                    if (offset_in_block + to_copy <= flight->buffer.size()) {
                        std::memcpy(
                            flight->buffer.data() + offset_in_block,
                            chunk_data + chunk_pos,
                            to_copy);
                    }

                    chunk_pos += to_copy;
                    stream_cursor += to_copy;

                    {
                        std::lock_guard<std::mutex> lock(mu_);
                        const size_t new_fill = std::min(offset_in_block + to_copy, flight->expected_size);
                        if (new_fill > flight->filled_bytes) {
                            flight->filled_bytes = new_fill;
                        }
                        if (flight->phase == BlockTransferPhase::Streaming &&
                            flight->expected_size > 0 &&
                            flight->filled_bytes >= flight->expected_size) {
                            flight->buffer.resize(flight->expected_size);
                            auto shared_vec = std::make_shared<const std::vector<uint8_t>>(flight->buffer);
                            insertBlockLocked(b_idx, shared_vec);
                            flight->data = shared_vec;
                            flight->phase = BlockTransferPhase::CompletedOk;
                            in_flight_.erase(b_idx);
                            completed_blocks.emplace_back(b_idx, std::move(shared_vec));
                        }
                        block_cv_.notify_all();
                    }
                }

                if (!stream_key_.empty()) {
                    for (const auto& [b_idx, vec] : completed_blocks) {
                        disk_cache_.writeStreamBlock(stream_key_, b_idx, vec->data(), vec->size());
                    }
                }
                return true;
            },
            extra_headers_,
            &canceled_,
            cancel_pred,
            kConnectTimeoutMs,
            kReadTimeoutMs);

        if (res.isSuccess()) {
            if (res.total_size > 0) {
                const int64_t prev_total =
                    total_size_.exchange(res.total_size, std::memory_order_acq_rel);
                if (prev_total <= 0 && !persisted_total_size && !stream_key_.empty()) {
                    disk_cache_.writeStreamTotalSize(stream_key_, res.total_size);
                }
            } else if (start_offset == 0 && !res.data.empty() && total_size_.load(std::memory_order_acquire) <= 0) {
                total_size_.store(static_cast<int64_t>(res.data.size()), std::memory_order_release);
            }
            if (i > 0) {
                std::lock_guard<std::mutex> lock(url_mu_);
                if (idx < urls_.size()) {
                    active_url_index_ = idx;
                }
            }
            return res;
        }
        if (res.status == RangeFetchStatus::Canceled || res.status == RangeFetchStatus::Offline) {
            return res;
        }
        if (res.status == RangeFetchStatus::ExpiredOrForbidden) {
            saw_expired_out = true;
        }
        RSC_LOGW("streamByteRange failed status=%d http=%d off=%lld len=%zu (cdn_idx=%zu)",
                 static_cast<int>(res.status),
                 static_cast<int>(res.http_status),
                 static_cast<long long>(start_offset),
                 span_len,
                 idx);
        last_err = std::move(res);
    }
    return last_err;
}

bool HttpRangeStreamCache::tryRefreshUrls(
    uint64_t observed_generation,
    const CancelPredicate& cancel_pred) {
    if (!url_refresh_cb_ ||
        cancel_pred() ||
        canceled_.load(std::memory_order_acquire) ||
        !NativeHttpClient::hasActiveNetworkRoute()) {
        return false;
    }

    std::lock_guard<std::mutex> refresh_lock(refresh_mu_);
    {
        std::lock_guard<std::mutex> lock(url_mu_);
        if (url_generation_ != observed_generation && !urls_.empty() &&
            !isOfflineSyntheticUrl(urls_.front())) {
            return true;
        }
    }

    std::vector<std::string> fresh_urls = url_refresh_cb_();
    if (fresh_urls.empty() ||
        cancel_pred() ||
        canceled_.load(std::memory_order_acquire)) {
        return false;
    }

    std::lock_guard<std::mutex> lock(url_mu_);
    urls_ = std::move(fresh_urls);
    active_url_index_ = 0;
    ++url_generation_;
    if (stream_key_.empty() && !urls_.empty()) {
        stream_key_ = cache::DiskCache::extractStreamCacheKey(urls_.front());
    }
    RSC_LOGI("Refreshed CDN URLs (%zu candidates, gen=%llu)",
             urls_.size(), static_cast<unsigned long long>(url_generation_));
    return true;
}

void HttpRangeStreamCache::insertBlockLocked(
    size_t block_index,
    std::shared_ptr<const std::vector<uint8_t>> data) {
    blocks_[block_index] = std::move(data);
    touchLruLocked(block_index);

    while (blocks_.size() > kMaxCachedBlocks && !lru_order_.empty()) {
        const size_t evict_idx = lru_order_.front();
        lru_order_.pop_front();
        lru_map_.erase(evict_idx);
        if (evict_idx >= kPinnedHeaderBlocks) {
            blocks_.erase(evict_idx);
        }
    }
}

void HttpRangeStreamCache::touchLruLocked(size_t block_index) {
    if (block_index < kPinnedHeaderBlocks) {
        // Pin first 256 KiB (MP4 ftyp / moov / sidx container index) permanently in RAM.
        return;
    }
    auto it = lru_map_.find(block_index);
    if (it != lru_map_.end()) {
        lru_order_.splice(lru_order_.end(), lru_order_, it->second);
        return;
    }
    lru_order_.push_back(block_index);
    auto end_it = lru_order_.end();
    --end_it;
    lru_map_[block_index] = end_it;
}

} // namespace spotify::network
