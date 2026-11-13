#include "HttpRangeStreamCache.h"

#include <android/log.h>

#include <algorithm>
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
    NativeHttpClient& http_client)
    : http_client_(http_client),
      extra_headers_(std::move(extra_headers)),
      url_refresh_cb_(std::move(url_refresh_cb)),
      urls_(std::move(urls)) {}

HttpRangeStreamCache::~HttpRangeStreamCache() {
    close();
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
    prefetch_abort_.store(true, std::memory_order_release);
    std::lock_guard<std::mutex> lock(mu_);
    block_cv_.notify_all();
    prefetch_cv_.notify_all();
}

void HttpRangeStreamCache::preemptPrefetch() noexcept {
    std::lock_guard<std::mutex> lock(mu_);
    prefetch_abort_.store(true, std::memory_order_release);
    has_prefetch_target_ = false;
    prefetch_cv_.notify_one();
}

void HttpRangeStreamCache::close() noexcept {
    const bool already_closed = closed_.exchange(true, std::memory_order_acq_rel);
    canceled_.store(true, std::memory_order_release);
    prefetch_abort_.store(true, std::memory_order_release);
    {
        std::lock_guard<std::mutex> lock(mu_);
        block_cv_.notify_all();
        prefetch_cv_.notify_all();
    }
    if (!already_closed && prefetch_thread_.joinable()) {
        prefetch_thread_.join();
    }
    std::lock_guard<std::mutex> lock(mu_);
    blocks_.clear();
    lru_order_.clear();
    lru_map_.clear();
    in_flight_.clear();
}

bool HttpRangeStreamCache::open() {
    if (canceled_.load(std::memory_order_acquire) || closed_.load(std::memory_order_acquire)) {
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

    if (urls_snapshot.empty()) {
        RSC_LOGE("open() failed: no CDN URLs provided");
        return false;
    }

    size_t seeded_blocks = 1;
    auto openFirstWindow = [&](const std::vector<std::string>& urls, size_t start, bool& saw_expired) -> bool {
        saw_expired = false;
        const size_t count = urls.size();
        const size_t initial_fetch_bytes = kMissFetchBlocks * kBlockSize;
        for (size_t i = 0; i < count; ++i) {
            if (canceled_.load(std::memory_order_acquire)) return false;
            const size_t idx = (start + i) % count;
            const std::string& url = urls[idx];
            if (url.empty()) continue;

            const HttpRangeResult res = http_client_.fetchByteRange(
                url, 0, initial_fetch_bytes, extra_headers_, &canceled_, kConnectTimeoutMs, kReadTimeoutMs);
            if (res.status == RangeFetchStatus::Canceled || canceled_.load(std::memory_order_acquire)) {
                return false;
            }
            const int64_t discovered_total =
                (res.total_size > 0) ? res.total_size : static_cast<int64_t>(res.data.size());
            if (res.isSuccess() && !res.data.empty() && discovered_total > 0) {
                total_size_.store(discovered_total, std::memory_order_release);
                {
                    std::lock_guard<std::mutex> lock(url_mu_);
                    if (url_generation_ == gen_snapshot && idx < urls_.size()) {
                        active_url_index_ = idx;
                    }
                }
                const size_t fetched_len = res.data.size();
                size_t blocks_stored = 0;
                {
                    std::lock_guard<std::mutex> lock(mu_);
                    for (size_t b = 0; b < kMissFetchBlocks; ++b) {
                        const size_t slice_start = b * kBlockSize;
                        if (slice_start >= fetched_len) break;
                        const size_t slice_end = std::min(fetched_len, slice_start + kBlockSize);
                        auto vec = std::make_shared<const std::vector<uint8_t>>(
                            res.data.begin() + static_cast<ptrdiff_t>(slice_start),
                            res.data.begin() + static_cast<ptrdiff_t>(slice_end));
                        insertBlockLocked(b, std::move(vec));
                        ++blocks_stored;
                    }
                }
                seeded_blocks = std::max<size_t>(1, blocks_stored);
                RSC_LOGI("Opened range stream total_size=%lld bytes + cached %zu blocks (%zuB) (cdn_idx=%zu)",
                         static_cast<long long>(discovered_total),
                         blocks_stored,
                         fetched_len,
                         idx);
                return true;
            }

            if (res.status == RangeFetchStatus::ExpiredOrForbidden) {
                saw_expired = true;
            }
            RSC_LOGW("open initial window failed status=%d http=%d length=%lld (cdn_idx=%zu)",
                     static_cast<int>(res.status),
                     static_cast<int>(res.http_status),
                     static_cast<long long>(res.total_size),
                     idx);
        }
        return false;
    };

    auto startPrefetching = [&]() {
        if (!closed_.load(std::memory_order_acquire) && !prefetch_thread_.joinable()) {
            prefetch_thread_ = std::thread(&HttpRangeStreamCache::prefetchWorker, this);
        }
        std::lock_guard<std::mutex> lock(mu_);
        schedulePrefetchLocked(seeded_blocks);
    };

    bool saw_expired = false;
    if (openFirstWindow(urls_snapshot, start_index, saw_expired)) {
        startPrefetching();
        return true;
    }

    if (!canceled_.load(std::memory_order_acquire) && saw_expired && tryRefreshUrls(gen_snapshot, canceled_)) {
        {
            std::lock_guard<std::mutex> lock(url_mu_);
            urls_snapshot = urls_;
            start_index = active_url_index_;
            gen_snapshot = url_generation_;
        }
        bool refreshed_expired = false;
        if (openFirstWindow(urls_snapshot, start_index, refreshed_expired)) {
            startPrefetching();
            return true;
        }
    }

    return false;
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

    const uint64_t remaining_u64 = static_cast<uint64_t>(total - offset);
    const size_t target_bytes = static_cast<size_t>(std::min<uint64_t>(size, remaining_u64));

    uint8_t* dst = static_cast<uint8_t*>(buffer);
    size_t copied = 0;
    int64_t cursor = offset;
    size_t last_block_index = 0;

    while (copied < target_bytes) {
        if (canceled_.load(std::memory_order_acquire) || closed_.load(std::memory_order_acquire)) {
            return -1;
        }

        const size_t block_index = static_cast<size_t>(static_cast<uint64_t>(cursor) / kBlockSize);
        const size_t in_block_offset = static_cast<size_t>(static_cast<uint64_t>(cursor) % kBlockSize);
        last_block_index = block_index;

        auto block_data = acquireBlock(block_index);
        if (!block_data) {
            if (canceled_.load(std::memory_order_acquire) || closed_.load(std::memory_order_acquire)) {
                return -1;
            }
            return copied > 0 ? static_cast<ssize_t>(copied) : -1;
        }

        if (in_block_offset >= block_data->size()) {
            break;
        }

        const size_t available_in_block = block_data->size() - in_block_offset;
        const size_t to_copy = std::min(target_bytes - copied, available_in_block);
        std::memcpy(dst + copied, block_data->data() + in_block_offset, to_copy);

        copied += to_copy;
        cursor += static_cast<int64_t>(to_copy);
    }

    if (copied > 0 && !canceled_.load(std::memory_order_acquire)) {
        std::lock_guard<std::mutex> lock(mu_);
        schedulePrefetchLocked(last_block_index + 1);
    }

    return static_cast<ssize_t>(copied);
}

std::shared_ptr<const std::vector<uint8_t>> HttpRangeStreamCache::acquireBlock(size_t block_index) {
    const int64_t total = total_size_.load(std::memory_order_acquire);
    if (total <= 0) return nullptr;

    const int64_t block_offset = static_cast<int64_t>(static_cast<uint64_t>(block_index) * kBlockSize);
    if (block_offset >= total) return nullptr;

    const size_t total_blocks =
        static_cast<size_t>((static_cast<uint64_t>(total) + kBlockSize - 1) / kBlockSize);

    std::vector<std::pair<size_t, std::shared_ptr<InFlightBlock>>> span_flights;
    for (;;) {
        span_flights.clear();
        {
            std::unique_lock<std::mutex> lock(mu_);
            if (canceled_.load(std::memory_order_acquire) || closed_.load(std::memory_order_acquire)) {
                return nullptr;
            }

            auto cached_it = blocks_.find(block_index);
            if (cached_it != blocks_.end()) {
                touchLruLocked(block_index);
                return cached_it->second;
            }

            auto flight_it = in_flight_.find(block_index);
            if (flight_it != in_flight_.end()) {
                auto shared_flight = flight_it->second;
                block_cv_.wait(lock, [&]() {
                    return shared_flight->done ||
                           canceled_.load(std::memory_order_acquire) ||
                           closed_.load(std::memory_order_acquire);
                });
                if (canceled_.load(std::memory_order_acquire) || closed_.load(std::memory_order_acquire)) {
                    return nullptr;
                }
                if (shared_flight->ok) {
                    return shared_flight->data;
                }
                if (shared_flight->preempted) {
                    continue;
                }
                return nullptr;
            }

            // Coalesce up to kMissFetchBlocks consecutive uncached blocks in a single HTTP RTT
            // so a foreground seek immediately caches the moof + surrounding ~256 KiB of frames.
            const size_t max_blk = std::min(total_blocks, block_index + kMissFetchBlocks);
            for (size_t b = block_index; b < max_blk; ++b) {
                if (blocks_.find(b) != blocks_.end() || in_flight_.find(b) != in_flight_.end()) {
                    break;
                }
                auto flight = std::make_shared<InFlightBlock>();
                in_flight_[b] = flight;
                span_flights.emplace_back(b, std::move(flight));
            }
            break;
        }
    }

    const int64_t span_end_byte = std::min<int64_t>(
        total,
        block_offset + static_cast<int64_t>(span_flights.size() * kBlockSize));
    const size_t span_len = static_cast<size_t>(span_end_byte - block_offset);
    HttpRangeResult fetched = fetchBlockWithFailover(block_offset, span_len, canceled_);

    std::shared_ptr<const std::vector<uint8_t>> primary_result;
    {
        std::lock_guard<std::mutex> lock(mu_);
        const bool aborted_or_closed =
            canceled_.load(std::memory_order_acquire) || closed_.load(std::memory_order_acquire);

        if (fetched.isSuccess() && !fetched.data.empty() && !aborted_or_closed) {
            if (fetched.total_size > 0) {
                total_size_.store(fetched.total_size, std::memory_order_release);
            }
            for (size_t i = 0; i < span_flights.size(); ++i) {
                const size_t b = span_flights[i].first;
                auto& flight = span_flights[i].second;
                in_flight_.erase(b);

                const size_t slice_start = i * kBlockSize;
                if (slice_start < fetched.data.size()) {
                    const size_t slice_end = std::min(fetched.data.size(), slice_start + kBlockSize);
                    auto shared_vec = std::make_shared<const std::vector<uint8_t>>(
                        fetched.data.begin() + static_cast<ptrdiff_t>(slice_start),
                        fetched.data.begin() + static_cast<ptrdiff_t>(slice_end));
                    insertBlockLocked(b, shared_vec);
                    flight->data = shared_vec;
                    flight->ok = true;
                    if (i == 0) {
                        primary_result = std::move(shared_vec);
                    }
                } else {
                    flight->ok = false;
                    flight->preempted = (i > 0);
                }
                flight->done = true;
            }
        } else {
            for (auto& [b, flight] : span_flights) {
                in_flight_.erase(b);
                flight->ok = false;
                flight->done = true;
            }
        }
        block_cv_.notify_all();
    }

    return primary_result;
}

bool HttpRangeStreamCache::acquirePrefetchBatch(size_t start_block, size_t max_blocks) {
    const int64_t total = total_size_.load(std::memory_order_acquire);
    if (total <= 0) return false;

    const size_t total_blocks =
        static_cast<size_t>((static_cast<uint64_t>(total) + kBlockSize - 1) / kBlockSize);
    if (start_block >= total_blocks || max_blocks == 0) return true;

    std::vector<std::pair<size_t, std::shared_ptr<InFlightBlock>>> span_flights;
    {
        std::lock_guard<std::mutex> lock(mu_);
        if (canceled_.load(std::memory_order_acquire) ||
            closed_.load(std::memory_order_acquire) ||
            prefetch_abort_.load(std::memory_order_acquire)) {
            return false;
        }
        const size_t limit = std::min(total_blocks, start_block + max_blocks);
        for (size_t b = start_block; b < limit; ++b) {
            if (blocks_.find(b) != blocks_.end() || in_flight_.find(b) != in_flight_.end()) {
                break;
            }
            auto flight = std::make_shared<InFlightBlock>();
            in_flight_[b] = flight;
            span_flights.emplace_back(b, std::move(flight));
        }
    }

    if (span_flights.empty()) {
        return true;
    }

    const int64_t start_offset =
        static_cast<int64_t>(static_cast<uint64_t>(start_block) * kBlockSize);
    const int64_t end_byte = std::min<int64_t>(
        total,
        start_offset + static_cast<int64_t>(span_flights.size() * kBlockSize));
    const size_t span_len = static_cast<size_t>(end_byte - start_offset);

    HttpRangeResult fetched = fetchBlockWithFailover(start_offset, span_len, prefetch_abort_);

    bool batch_ok = false;
    {
        std::lock_guard<std::mutex> lock(mu_);
        const bool aborted =
            canceled_.load(std::memory_order_acquire) ||
            closed_.load(std::memory_order_acquire) ||
            prefetch_abort_.load(std::memory_order_acquire);

        if (fetched.isSuccess() && !fetched.data.empty() && !aborted) {
            if (fetched.total_size > 0) {
                total_size_.store(fetched.total_size, std::memory_order_release);
            }
            for (size_t i = 0; i < span_flights.size(); ++i) {
                const size_t b = span_flights[i].first;
                auto& flight = span_flights[i].second;
                in_flight_.erase(b);

                const size_t slice_start = i * kBlockSize;
                if (slice_start < fetched.data.size()) {
                    const size_t slice_end = std::min(fetched.data.size(), slice_start + kBlockSize);
                    auto shared_vec = std::make_shared<const std::vector<uint8_t>>(
                        fetched.data.begin() + static_cast<ptrdiff_t>(slice_start),
                        fetched.data.begin() + static_cast<ptrdiff_t>(slice_end));
                    insertBlockLocked(b, shared_vec);
                    flight->data = shared_vec;
                    flight->ok = true;
                } else {
                    flight->ok = false;
                    flight->preempted = true;
                }
                flight->done = true;
            }
            batch_ok = true;
        } else {
            const bool preempted =
                prefetch_abort_.load(std::memory_order_acquire) &&
                !canceled_.load(std::memory_order_acquire) &&
                !closed_.load(std::memory_order_acquire);
            for (auto& [b, flight] : span_flights) {
                in_flight_.erase(b);
                flight->ok = false;
                flight->preempted = preempted;
                flight->done = true;
            }
        }
        block_cv_.notify_all();
    }

    return batch_ok;
}

HttpRangeResult HttpRangeStreamCache::fetchBlockWithFailover(
    int64_t offset,
    size_t length,
    const std::atomic<bool>& cancel_token) {
    std::vector<std::string> urls_snapshot;
    size_t start_index = 0;
    uint64_t gen_snapshot = 0;
    {
        std::lock_guard<std::mutex> lock(url_mu_);
        urls_snapshot = urls_;
        start_index = active_url_index_;
        gen_snapshot = url_generation_;
    }

    if (urls_snapshot.empty()) {
        HttpRangeResult err;
        err.status = RangeFetchStatus::NetworkError;
        return err;
    }

    bool saw_expired = false;
    HttpRangeResult res = tryUrlsLockedSnapshot(
        urls_snapshot, start_index, offset, length, cancel_token, saw_expired);
    if (res.isSuccess() || res.status == RangeFetchStatus::Canceled) {
        return res;
    }

    if (saw_expired && tryRefreshUrls(gen_snapshot, cancel_token)) {
        {
            std::lock_guard<std::mutex> lock(url_mu_);
            urls_snapshot = urls_;
            start_index = active_url_index_;
        }
        bool refreshed_expired = false;
        res = tryUrlsLockedSnapshot(
            urls_snapshot, start_index, offset, length, cancel_token, refreshed_expired);
    }

    return res;
}

HttpRangeResult HttpRangeStreamCache::tryUrlsLockedSnapshot(
    const std::vector<std::string>& urls,
    size_t start_index,
    int64_t offset,
    size_t length,
    const std::atomic<bool>& cancel_token,
    bool& saw_expired_out) {
    saw_expired_out = false;
    HttpRangeResult last_err;
    const size_t count = urls.size();

    for (size_t i = 0; i < count; ++i) {
        if (cancel_token.load(std::memory_order_acquire) ||
            canceled_.load(std::memory_order_acquire)) {
            HttpRangeResult canceled;
            canceled.status = RangeFetchStatus::Canceled;
            return canceled;
        }
        const size_t idx = (start_index + i) % count;
        const std::string& url = urls[idx];
        if (url.empty()) continue;

        HttpRangeResult res = http_client_.fetchByteRange(
            url, offset, length, extra_headers_, &cancel_token, kConnectTimeoutMs, kReadTimeoutMs);

        if (res.isSuccess()) {
            if (i > 0) {
                std::lock_guard<std::mutex> lock(url_mu_);
                if (idx < urls_.size()) {
                    active_url_index_ = idx;
                }
            }
            return res;
        }
        if (res.status == RangeFetchStatus::Canceled) {
            return res;
        }
        if (res.status == RangeFetchStatus::ExpiredOrForbidden) {
            saw_expired_out = true;
        }
        RSC_LOGW("fetchByteRange failed status=%d http=%d off=%lld len=%zu (cdn_idx=%zu)",
                 static_cast<int>(res.status),
                 static_cast<int>(res.http_status),
                 static_cast<long long>(offset),
                 length,
                 idx);
        last_err = std::move(res);
    }
    return last_err;
}

bool HttpRangeStreamCache::tryRefreshUrls(
    uint64_t observed_generation,
    const std::atomic<bool>& cancel_token) {
    if (!url_refresh_cb_ ||
        cancel_token.load(std::memory_order_acquire) ||
        canceled_.load(std::memory_order_acquire)) {
        return false;
    }

    std::lock_guard<std::mutex> refresh_lock(refresh_mu_);
    {
        std::lock_guard<std::mutex> lock(url_mu_);
        if (url_generation_ != observed_generation && !urls_.empty()) {
            return true;
        }
    }

    std::vector<std::string> fresh_urls = url_refresh_cb_();
    if (fresh_urls.empty() ||
        cancel_token.load(std::memory_order_acquire) ||
        canceled_.load(std::memory_order_acquire)) {
        return false;
    }

    std::lock_guard<std::mutex> lock(url_mu_);
    urls_ = std::move(fresh_urls);
    active_url_index_ = 0;
    ++url_generation_;
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
        // Pin first 512 KiB (MP4 ftyp / moov / sidx container index) permanently in RAM.
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

void HttpRangeStreamCache::schedulePrefetchLocked(size_t next_block_index) {
    const int64_t total = total_size_.load(std::memory_order_acquire);
    if (total <= 0) return;
    const size_t total_blocks = static_cast<size_t>((static_cast<uint64_t>(total) + kBlockSize - 1) / kBlockSize);
    if (next_block_index >= total_blocks) return;

    const size_t window_end = std::min(total_blocks, next_block_index + kPrefetchAheadBlocks);
    size_t first_missing = next_block_index;
    while (first_missing < window_end &&
           (blocks_.find(first_missing) != blocks_.end() ||
            in_flight_.find(first_missing) != in_flight_.end())) {
        ++first_missing;
    }
    if (first_missing >= window_end) {
        return;
    }

    prefetch_target_block_ = first_missing;
    has_prefetch_target_ = true;
    prefetch_cv_.notify_one();
}

void HttpRangeStreamCache::prefetchWorker() {
    for (;;) {
        size_t target = 0;
        {
            std::unique_lock<std::mutex> lock(mu_);
            prefetch_cv_.wait(lock, [&]() {
                return has_prefetch_target_ ||
                       canceled_.load(std::memory_order_acquire) ||
                       closed_.load(std::memory_order_acquire);
            });
            if (canceled_.load(std::memory_order_acquire) || closed_.load(std::memory_order_acquire)) {
                return;
            }
            target = prefetch_target_block_;
            has_prefetch_target_ = false;
            prefetch_abort_.store(false, std::memory_order_release);
        }

        const int64_t total = total_size_.load(std::memory_order_acquire);
        if (total <= 0) continue;
        const size_t total_blocks = static_cast<size_t>((static_cast<uint64_t>(total) + kBlockSize - 1) / kBlockSize);
        const size_t limit = std::min(total_blocks, target + kPrefetchAheadBlocks);

        size_t blk = target;
        while (blk < limit) {
            if (canceled_.load(std::memory_order_acquire) ||
                closed_.load(std::memory_order_acquire) ||
                prefetch_abort_.load(std::memory_order_acquire)) {
                break;
            }
            {
                std::lock_guard<std::mutex> lock(mu_);
                if (has_prefetch_target_) {
                    break;
                }
                while (blk < limit &&
                       (blocks_.find(blk) != blocks_.end() ||
                        in_flight_.find(blk) != in_flight_.end())) {
                    ++blk;
                }
            }
            if (blk >= limit) break;

            const size_t batch_blocks = std::min(kPrefetchBatchBlocks, limit - blk);
            if (!acquirePrefetchBatch(blk, batch_blocks)) {
                break;
            }
            blk += batch_blocks;
        }
    }
}

} // namespace spotify::network
