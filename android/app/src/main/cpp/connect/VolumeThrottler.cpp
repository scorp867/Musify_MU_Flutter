// ============================================================================
// Replicated from liborbit-jni-spotify.so (Per-Target Connect VolumeThrottler
// & PutState rate windows):
// - Binary symbols / offsets:
//   - VolumeThrottler::setVolume / 200ms throttle window @ 0xdca2d4..0xdca6fc
//   - Per-group-device independent volume throttling @ 0xdca8fc..0xdcaec4
//   - 2000ms (0x7d0 @ 0xdca4c4) wanted_volume expiry & >199ms check (0x15b5cec)
//   - PutStateReason::VOLUME_CHANGED 200ms throttle @ 0xdb7750..0xdb7828
//   - PutStateReason::PLAYER_STATE_CHANGED configurable throttle (default 0ms) @ 0xd8fef0..0xd8ff48
// ============================================================================

#include "VolumeThrottler.h"

#include <algorithm>
#include <utility>

namespace spotify::connectstate {

VolumeThrottler::VolumeThrottler(
    Clock clock,
    int64_t player_state_changed_throttle_ms)
    : clock_(clock ? std::move(clock) : Clock([]() {
          return std::chrono::steady_clock::now();
      })),
      player_state_changed_throttle_ms_(
          player_state_changed_throttle_ms > 0 ? player_state_changed_throttle_ms : 0) {}

std::chrono::steady_clock::time_point VolumeThrottler::now() const {
    return clock_();
}

void VolumeThrottler::set_player_state_changed_throttle_ms(int64_t throttle_ms) {
    std::lock_guard<std::mutex> lock(mutex_);
    player_state_changed_throttle_ms_ = throttle_ms > 0 ? throttle_ms : 0;
}

int64_t VolumeThrottler::player_state_changed_throttle_ms() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return player_state_changed_throttle_ms_;
}

VolumeCommandDecision VolumeThrottler::submit_volume_command(
    uint32_t volume,
    std::string target_device_id,
    std::string target_key) {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);

    TargetBucket& bucket = target_buckets_[target_key];
    bucket.wanted_volume = volume;
    bucket.wanted_volume_expires_at =
        current_time + std::chrono::milliseconds(kWantedVolumeExpiryMs);

    if (bucket.has_sent_volume) {
        const auto elapsed_ms =
            std::chrono::duration_cast<std::chrono::milliseconds>(
                current_time - bucket.last_volume_sent_at)
                .count();
        // Exact liborbit comparison: elapsed <= 199ms is throttled; >= 200ms executes.
        if (elapsed_ms < kVolumeThrottleWindowMs) {
            const int64_t remaining_ms =
                elapsed_ms >= 0 ? (kVolumeThrottleWindowMs - elapsed_ms)
                                : kVolumeThrottleWindowMs;
            bucket.pending_volume = PendingVolumeCommand{
                .volume = volume,
                .target_device_id = std::move(target_device_id),
                .target_key = target_key,
            };
            return VolumeCommandDecision{
                .action = ThrottleAction::kThrottled,
                .volume = volume,
                .target_device_id = bucket.pending_volume->target_device_id,
                .target_key = std::move(target_key),
                .retry_after = std::chrono::milliseconds(remaining_ms),
            };
        }
    }

    bucket.has_sent_volume = true;
    bucket.last_volume_sent_at = current_time;
    bucket.pending_volume.reset();
    return VolumeCommandDecision{
        .action = ThrottleAction::kSendImmediate,
        .volume = volume,
        .target_device_id = std::move(target_device_id),
        .target_key = std::move(target_key),
        .retry_after = std::chrono::milliseconds::zero(),
    };
}

std::optional<PendingVolumeCommand> VolumeThrottler::take_pending_volume_if_ready(
    std::string_view target_key) {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);
    const auto it = target_buckets_.find(std::string(target_key));
    if (it == target_buckets_.end() || !it->second.pending_volume.has_value()) {
        return std::nullopt;
    }
    TargetBucket& bucket = it->second;
    if (bucket.has_sent_volume) {
        const auto elapsed_ms =
            std::chrono::duration_cast<std::chrono::milliseconds>(
                current_time - bucket.last_volume_sent_at)
                .count();
        if (elapsed_ms < kVolumeThrottleWindowMs) {
            return std::nullopt;
        }
    }
    bucket.has_sent_volume = true;
    bucket.last_volume_sent_at = current_time;
    auto ready = std::move(*bucket.pending_volume);
    bucket.pending_volume.reset();
    return ready;
}

std::vector<PendingVolumeCommand> VolumeThrottler::take_all_pending_volumes_if_ready() {
    const auto current_time = now();
    std::vector<PendingVolumeCommand> ready_list;
    std::lock_guard<std::mutex> lock(mutex_);
    for (auto& [key, bucket] : target_buckets_) {
        if (!bucket.pending_volume.has_value()) {
            continue;
        }
        if (bucket.has_sent_volume) {
            const auto elapsed_ms =
                std::chrono::duration_cast<std::chrono::milliseconds>(
                    current_time - bucket.last_volume_sent_at)
                    .count();
            if (elapsed_ms < kVolumeThrottleWindowMs) {
                continue;
            }
        }
        bucket.has_sent_volume = true;
        bucket.last_volume_sent_at = current_time;
        ready_list.push_back(std::move(*bucket.pending_volume));
        bucket.pending_volume.reset();
    }
    return ready_list;
}

std::optional<std::chrono::milliseconds> VolumeThrottler::pending_volume_delay() const {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);
    std::optional<std::chrono::milliseconds> min_delay;
    for (const auto& [key, bucket] : target_buckets_) {
        if (!bucket.pending_volume.has_value()) {
            continue;
        }
        std::chrono::milliseconds delay(0);
        if (bucket.has_sent_volume) {
            const auto elapsed_ms =
                std::chrono::duration_cast<std::chrono::milliseconds>(
                    current_time - bucket.last_volume_sent_at)
                    .count();
            if (elapsed_ms < kVolumeThrottleWindowMs) {
                const int64_t remaining_ms =
                    elapsed_ms >= 0 ? (kVolumeThrottleWindowMs - elapsed_ms)
                                    : kVolumeThrottleWindowMs;
                delay = std::chrono::milliseconds(remaining_ms);
            }
        }
        if (!min_delay.has_value() || delay < *min_delay) {
            min_delay = delay;
        }
    }
    return min_delay;
}

std::optional<uint32_t> VolumeThrottler::active_wanted_volume(
    std::string_view target_key) const {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);
    const auto it = target_buckets_.find(std::string(target_key));
    if (it == target_buckets_.end()) {
        return std::nullopt;
    }
    const TargetBucket& bucket = it->second;
    if (!bucket.wanted_volume.has_value() || current_time >= bucket.wanted_volume_expires_at) {
        return std::nullopt;
    }
    return bucket.wanted_volume;
}

bool VolumeThrottler::should_apply_remote_volume(
    uint32_t remote_volume,
    std::string_view target_key) {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);
    const auto it = target_buckets_.find(std::string(target_key));
    if (it == target_buckets_.end()) {
        return true;
    }
    TargetBucket& bucket = it->second;
    if (!bucket.wanted_volume.has_value()) {
        return true;
    }
    if (current_time >= bucket.wanted_volume_expires_at) {
        bucket.wanted_volume.reset();
        bucket.wanted_volume_expires_at = {};
        return true;
    }
    if (*bucket.wanted_volume == remote_volume) {
        bucket.wanted_volume.reset();
        bucket.wanted_volume_expires_at = {};
        return true;
    }
    return false;
}

void VolumeThrottler::clear_target(std::string_view target_key) {
    std::lock_guard<std::mutex> lock(mutex_);
    target_buckets_.erase(std::string(target_key));
}

void VolumeThrottler::clear_all() {
    std::lock_guard<std::mutex> lock(mutex_);
    target_buckets_.clear();
}

void VolumeThrottler::clear_wanted_volume() {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = target_buckets_.find(std::string{});
    if (it != target_buckets_.end()) {
        it->second.wanted_volume.reset();
        it->second.wanted_volume_expires_at = {};
    }
}

PutStateThrottleDecision VolumeThrottler::evaluate_put_state_volume_changed() {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);
    if (has_sent_volume_put_state_) {
        const auto elapsed_ms =
            std::chrono::duration_cast<std::chrono::milliseconds>(
                current_time - last_volume_put_state_at_)
                .count();
        if (elapsed_ms < kVolumeThrottleWindowMs) {
            pending_volume_put_state_ = true;
            const int64_t remaining_ms =
                elapsed_ms >= 0 ? (kVolumeThrottleWindowMs - elapsed_ms)
                                : kVolumeThrottleWindowMs;
            return PutStateThrottleDecision{
                .action = ThrottleAction::kThrottled,
                .retry_after = std::chrono::milliseconds(remaining_ms),
            };
        }
    }
    has_sent_volume_put_state_ = true;
    last_volume_put_state_at_ = current_time;
    pending_volume_put_state_ = false;
    return PutStateThrottleDecision{
        .action = ThrottleAction::kSendImmediate,
        .retry_after = std::chrono::milliseconds::zero(),
    };
}

PutStateThrottleDecision VolumeThrottler::evaluate_put_state_player_state_changed() {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);
    if (player_state_changed_throttle_ms_ <= 0) {
        has_sent_player_put_state_ = true;
        last_player_put_state_at_ = current_time;
        pending_player_put_state_ = false;
        return PutStateThrottleDecision{
            .action = ThrottleAction::kSendImmediate,
            .retry_after = std::chrono::milliseconds::zero(),
        };
    }
    if (has_sent_player_put_state_) {
        const auto elapsed_ms =
            std::chrono::duration_cast<std::chrono::milliseconds>(
                current_time - last_player_put_state_at_)
                .count();
        if (elapsed_ms < player_state_changed_throttle_ms_) {
            pending_player_put_state_ = true;
            const int64_t remaining_ms =
                elapsed_ms >= 0 ? (player_state_changed_throttle_ms_ - elapsed_ms)
                                : player_state_changed_throttle_ms_;
            return PutStateThrottleDecision{
                .action = ThrottleAction::kThrottled,
                .retry_after = std::chrono::milliseconds(remaining_ms),
            };
        }
    }
    has_sent_player_put_state_ = true;
    last_player_put_state_at_ = current_time;
    pending_player_put_state_ = false;
    return PutStateThrottleDecision{
        .action = ThrottleAction::kSendImmediate,
        .retry_after = std::chrono::milliseconds::zero(),
    };
}

bool VolumeThrottler::has_pending_volume_put_state() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return pending_volume_put_state_;
}

std::optional<std::chrono::milliseconds> VolumeThrottler::pending_volume_put_state_delay() const {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);
    if (!pending_volume_put_state_) {
        return std::nullopt;
    }
    if (!has_sent_volume_put_state_) {
        return std::chrono::milliseconds::zero();
    }
    const auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
        current_time - last_volume_put_state_at_);
    if (elapsed.count() >= kVolumeThrottleWindowMs) {
        return std::chrono::milliseconds::zero();
    }
    return std::chrono::milliseconds(kVolumeThrottleWindowMs) - elapsed;
}

bool VolumeThrottler::take_pending_volume_put_state_if_ready() {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);
    if (!pending_volume_put_state_) {
        return false;
    }
    if (has_sent_volume_put_state_) {
        const auto elapsed_ms =
            std::chrono::duration_cast<std::chrono::milliseconds>(
                current_time - last_volume_put_state_at_)
                .count();
        if (elapsed_ms < kVolumeThrottleWindowMs) {
            return false;
        }
    }
    has_sent_volume_put_state_ = true;
    last_volume_put_state_at_ = current_time;
    pending_volume_put_state_ = false;
    return true;
}

bool VolumeThrottler::has_pending_player_put_state() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return pending_player_put_state_;
}

std::optional<std::chrono::milliseconds> VolumeThrottler::pending_player_put_state_delay() const {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);
    if (!pending_player_put_state_) {
        return std::nullopt;
    }
    if (player_state_changed_throttle_ms_ <= 0 || !has_sent_player_put_state_) {
        return std::chrono::milliseconds::zero();
    }
    const auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
        current_time - last_player_put_state_at_);
    if (elapsed.count() >= player_state_changed_throttle_ms_) {
        return std::chrono::milliseconds::zero();
    }
    return std::chrono::milliseconds(player_state_changed_throttle_ms_) - elapsed;
}

bool VolumeThrottler::take_pending_player_put_state_if_ready() {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);
    if (!pending_player_put_state_) {
        return false;
    }
    if (player_state_changed_throttle_ms_ > 0 && has_sent_player_put_state_) {
        const auto elapsed_ms =
            std::chrono::duration_cast<std::chrono::milliseconds>(
                current_time - last_player_put_state_at_)
                .count();
        if (elapsed_ms < player_state_changed_throttle_ms_) {
            return false;
        }
    }
    has_sent_player_put_state_ = true;
    last_player_put_state_at_ = current_time;
    pending_player_put_state_ = false;
    return true;
}

void VolumeThrottler::reset() {
    std::lock_guard<std::mutex> lock(mutex_);
    target_buckets_.clear();
    has_sent_volume_put_state_ = false;
    last_volume_put_state_at_ = {};
    pending_volume_put_state_ = false;
    has_sent_player_put_state_ = false;
    last_player_put_state_at_ = {};
    pending_player_put_state_ = false;
}

}  // namespace spotify::connectstate
