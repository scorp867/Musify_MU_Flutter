// Replicated from liborbit-jni-spotify.so (ConnectState VolumeThrottler & PutState rate windows):
// - Binary symbols / offsets:
//   - VolumeThrottler::setVolume / 200ms throttle window @ 0xdca2d4..0xdca6fc
//   - 2000ms (0x7d0 @ 0xdca4c4) wanted_volume expiry & >199ms check (0x15b5cec)
//   - PutStateReason::VOLUME_CHANGED 200ms throttle @ 0xdb7750..0xdb7828
//   - PutStateReason::PLAYER_STATE_CHANGED configurable throttle (default 0ms) @ 0xd8fef0..0xd8ff48
// - Java / Esperanto counterparts:
//   - p199p/C2086nd.java (ConnectVolumeService.Volume)
//   - p199p/a0f1.java (ConnectVolumeService.VolumeSet)
//   - p199p/lw51.java (ConnectVolumeService.VolumeUp / VolumeDown)

#include "VolumeThrottler.h"

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
    std::string target_device_id) {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);

    wanted_volume_ = volume;
    wanted_volume_expires_at_ =
        current_time + std::chrono::milliseconds(kWantedVolumeExpiryMs);

    if (has_sent_volume_) {
        const auto elapsed_ms =
            std::chrono::duration_cast<std::chrono::milliseconds>(
                current_time - last_volume_sent_at_)
                .count();
        // Exact liborbit comparison: elapsed <= 199ms is throttled; >= 200ms executes.
        if (elapsed_ms < kVolumeThrottleWindowMs) {
            const int64_t remaining_ms =
                elapsed_ms >= 0 ? (kVolumeThrottleWindowMs - elapsed_ms)
                                : kVolumeThrottleWindowMs;
            pending_volume_ = PendingVolumeCommand{
                .volume = volume,
                .target_device_id = std::move(target_device_id),
            };
            return VolumeCommandDecision{
                .action = ThrottleAction::kThrottled,
                .volume = volume,
                .target_device_id = pending_volume_->target_device_id,
                .retry_after = std::chrono::milliseconds(remaining_ms),
            };
        }
    }

    has_sent_volume_ = true;
    last_volume_sent_at_ = current_time;
    pending_volume_.reset();
    return VolumeCommandDecision{
        .action = ThrottleAction::kSendImmediate,
        .volume = volume,
        .target_device_id = std::move(target_device_id),
        .retry_after = std::chrono::milliseconds::zero(),
    };
}

std::optional<PendingVolumeCommand> VolumeThrottler::take_pending_volume_if_ready() {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);
    if (!pending_volume_.has_value()) {
        return std::nullopt;
    }
    if (has_sent_volume_) {
        const auto elapsed_ms =
            std::chrono::duration_cast<std::chrono::milliseconds>(
                current_time - last_volume_sent_at_)
                .count();
        if (elapsed_ms < kVolumeThrottleWindowMs) {
            return std::nullopt;
        }
    }
    has_sent_volume_ = true;
    last_volume_sent_at_ = current_time;
    auto ready = std::move(*pending_volume_);
    pending_volume_.reset();
    return ready;
}

std::optional<std::chrono::milliseconds> VolumeThrottler::pending_volume_delay() const {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);
    if (!pending_volume_.has_value()) {
        return std::nullopt;
    }
    if (!has_sent_volume_) {
        return std::chrono::milliseconds::zero();
    }
    const auto elapsed_ms =
        std::chrono::duration_cast<std::chrono::milliseconds>(
            current_time - last_volume_sent_at_)
            .count();
    if (elapsed_ms >= kVolumeThrottleWindowMs) {
        return std::chrono::milliseconds::zero();
    }
    const int64_t remaining_ms =
        elapsed_ms >= 0 ? (kVolumeThrottleWindowMs - elapsed_ms) : kVolumeThrottleWindowMs;
    return std::chrono::milliseconds(remaining_ms);
}

std::optional<uint32_t> VolumeThrottler::active_wanted_volume() const {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);
    if (!wanted_volume_.has_value() || current_time >= wanted_volume_expires_at_) {
        return std::nullopt;
    }
    return wanted_volume_;
}

bool VolumeThrottler::should_apply_remote_volume(uint32_t remote_volume) {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);
    if (!wanted_volume_.has_value()) {
        return true;
    }
    if (current_time >= wanted_volume_expires_at_) {
        wanted_volume_.reset();
        wanted_volume_expires_at_ = {};
        return true;
    }
    if (*wanted_volume_ == remote_volume) {
        wanted_volume_.reset();
        wanted_volume_expires_at_ = {};
        return true;
    }
    return false;
}

void VolumeThrottler::clear_wanted_volume() {
    std::lock_guard<std::mutex> lock(mutex_);
    wanted_volume_.reset();
    wanted_volume_expires_at_ = {};
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
    has_sent_volume_ = false;
    last_volume_sent_at_ = {};
    pending_volume_.reset();
    wanted_volume_.reset();
    wanted_volume_expires_at_ = {};
    has_sent_volume_put_state_ = false;
    last_volume_put_state_at_ = {};
    pending_volume_put_state_ = false;
    has_sent_player_put_state_ = false;
    last_player_put_state_at_ = {};
    pending_player_put_state_ = false;
}

}  // namespace spotify::connectstate
