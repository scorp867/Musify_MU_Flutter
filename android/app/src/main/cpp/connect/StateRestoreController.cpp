// ============================================================================
// Replicated Spotify Connect StateRestoreController (`LoadLastTransferBlob`)
// Sources (`liborbit-jni-spotify.so` arm64):
// - Cluster.transfer_data & transfer_data_timestamp caching @ 0xdb1e78, 0xdf0ba8
// - `LoadLastTransferBlob` recovery path @ 0xdb4758, 0xdb9ef8
// - 5000ms disconnect recovery timer @ 0xdb9e10
// ============================================================================

#include "StateRestoreController.h"

#include <utility>

#include "../network/NativeLog.h"

namespace spotify::connectstate {

StateRestoreController::StateRestoreController(
    int64_t recovery_delay_ms,
    Clock clock)
    : recovery_delay_ms_(recovery_delay_ms > 0 ? recovery_delay_ms : kDefaultRecoveryDelayMs),
      clock_(clock ? std::move(clock) : Clock([]() {
          return std::chrono::steady_clock::now();
      })) {}

StateRestoreController::~StateRestoreController() {
    stop();
}

std::chrono::steady_clock::time_point StateRestoreController::now() const {
    return clock_();
}

void StateRestoreController::start() {
    std::lock_guard<std::mutex> lock(mutex_);
    if (worker_running_) {
        return;
    }
    stop_requested_ = false;
    worker_running_ = true;
    worker_thread_ = std::thread(&StateRestoreController::worker_loop, this);
}

void StateRestoreController::stop() {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!worker_running_ && !worker_thread_.joinable()) {
            recovery_armed_ = false;
            ++recovery_generation_;
            return;
        }
        stop_requested_ = true;
        recovery_armed_ = false;
        ++recovery_generation_;
    }
    cv_.notify_all();
    if (worker_thread_.joinable()) {
        worker_thread_.join();
    }
    {
        std::lock_guard<std::mutex> lock(mutex_);
        worker_running_ = false;
        stop_requested_ = false;
    }
}

void StateRestoreController::reset() {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        cached_blob_.reset();
        recovery_armed_ = false;
        ++recovery_generation_;
    }
    cv_.notify_all();
}

void StateRestoreController::set_restore_callback(RestoreCallback callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    restore_callback_ = std::move(callback);
}

void StateRestoreController::on_cluster_update(const Cluster& cluster) {
    if (cluster.transfer_data.empty()) {
        return;
    }
    std::lock_guard<std::mutex> lock(mutex_);
    const bool should_replace =
        !cached_blob_.has_value() ||
        cluster.transfer_data_timestamp >= cached_blob_->transfer_data_timestamp ||
        cluster.changed_timestamp_ms >= cached_blob_->cluster_changed_timestamp_ms;
    if (!should_replace) {
        return;
    }
    cached_blob_ = CachedTransferBlob{
        .transfer_data = cluster.transfer_data,
        .transfer_data_timestamp = cluster.transfer_data_timestamp,
        .active_device_id = cluster.active_device_id,
        .cluster_changed_timestamp_ms = cluster.changed_timestamp_ms,
    };
    CONNECT_LOGD(
        "StateRestoreController: cached transfer_data (%zu bytes, ts=%llu, active=%s)",
        cached_blob_->transfer_data.size(),
        static_cast<unsigned long long>(cached_blob_->transfer_data_timestamp),
        cached_blob_->active_device_id.c_str());
}

void StateRestoreController::on_dealer_disconnected(bool local_was_active) {
    if (!local_was_active) {
        return;
    }
    bool armed = false;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!worker_running_ || stop_requested_) {
            return;
        }
        if (!cached_blob_.has_value() || cached_blob_->transfer_data.empty()) {
            CONNECT_LOGD(
                "StateRestoreController: Dealer disconnected while local active, "
                "but no cached transfer_data blob available");
            return;
        }
        if (!recovery_armed_) {
            recovery_armed_ = true;
            ++recovery_generation_;
            recovery_deadline_ = now() + std::chrono::milliseconds(recovery_delay_ms_);
            armed = true;
        }
    }
    if (armed) {
        CONNECT_LOGI(
            "StateRestoreController: armed %lldms LoadLastTransferBlob recovery timer",
            static_cast<long long>(recovery_delay_ms_));
        cv_.notify_all();
    }
}

void StateRestoreController::on_dealer_reconnected() {
    cancel_pending_recovery();
}

void StateRestoreController::cancel_pending_recovery() {
    bool cancelled = false;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (recovery_armed_) {
            recovery_armed_ = false;
            ++recovery_generation_;
            cancelled = true;
        }
    }
    if (cancelled) {
        CONNECT_LOGD("StateRestoreController: cancelled pending recovery timer");
        cv_.notify_all();
    }
}

std::optional<CachedTransferBlob> StateRestoreController::cached_transfer_blob() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return cached_blob_;
}

bool StateRestoreController::is_recovery_armed() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return recovery_armed_;
}

void StateRestoreController::worker_loop() {
    while (true) {
        std::optional<CachedTransferBlob> blob_to_restore;
        RestoreCallback cb;

        {
            std::unique_lock<std::mutex> lock(mutex_);
            cv_.wait(lock, [this]() {
                return stop_requested_ || recovery_armed_;
            });
            if (stop_requested_) {
                break;
            }

            const uint64_t gen = recovery_generation_;
            const auto deadline = recovery_deadline_;
            const auto current = now();
            if (deadline > current) {
                const auto wait_ms =
                    std::chrono::duration_cast<std::chrono::milliseconds>(deadline - current);
                cv_.wait_for(
                    lock,
                    wait_ms.count() > 0 ? wait_ms : std::chrono::milliseconds(1),
                    [this, gen]() {
                        return stop_requested_ || !recovery_armed_ ||
                               recovery_generation_ != gen;
                    });
            }

            if (stop_requested_) {
                break;
            }
            if (!recovery_armed_ || recovery_generation_ != gen) {
                continue;
            }
            if (now() < deadline) {
                continue;
            }

            recovery_armed_ = false;
            if (cached_blob_.has_value() && !cached_blob_->transfer_data.empty()) {
                blob_to_restore = cached_blob_;
                cb = restore_callback_;
            }
        }

        if (blob_to_restore.has_value() && cb) {
            CONNECT_LOGI(
                "StateRestoreController: recovery timer elapsed, firing LoadLastTransferBlob "
                "(%zu bytes, ts=%llu)",
                blob_to_restore->transfer_data.size(),
                static_cast<unsigned long long>(blob_to_restore->transfer_data_timestamp));
            cb(*blob_to_restore);
        }
    }
}

}  // namespace spotify::connectstate
