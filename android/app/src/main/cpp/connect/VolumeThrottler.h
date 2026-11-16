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

#ifndef MUSIFY_CONNECT_VOLUME_THROTTLER_H_
#define MUSIFY_CONNECT_VOLUME_THROTTLER_H_

#include <chrono>
#include <cstdint>
#include <functional>
#include <mutex>
#include <optional>
#include <string>

#include "ConnectStateProtos.h"

namespace spotify::connectstate {

enum class ThrottleAction : uint8_t {
    kSendImmediate = 0,
    kThrottled = 1,
};

struct VolumeCommandDecision {
    ThrottleAction action{ThrottleAction::kSendImmediate};
    uint32_t volume{0};
    std::string target_device_id;
    std::chrono::milliseconds retry_after{std::chrono::milliseconds::zero()};
};

struct PendingVolumeCommand {
    uint32_t volume{0};
    std::string target_device_id;
};

struct PutStateThrottleDecision {
    ThrottleAction action{ThrottleAction::kSendImmediate};
    std::chrono::milliseconds retry_after{std::chrono::milliseconds::zero()};
};

class VolumeThrottler {
public:
    // liborbit-jni-spotify.so @ 0xdca2d4..0xdca6fc: elapsed <= 199ms is throttled; >= 200ms fires.
    static constexpr int64_t kVolumeThrottleWindowMs = 200;
    // liborbit-jni-spotify.so @ 0x15b5cec: wanted_volume expires after 2000ms (0x7d0).
    static constexpr int64_t kWantedVolumeExpiryMs = 2000;
    // liborbit-jni-spotify.so @ 0xd8fef0..0xd8ff48: PLAYER_STATE_CHANGED throttle defaults to 0ms.
    static constexpr int64_t kDefaultPlayerStateChangedThrottleMs = 0;

    using Clock = std::function<std::chrono::steady_clock::time_point()>;

    explicit VolumeThrottler(
        Clock clock = {},
        int64_t player_state_changed_throttle_ms = kDefaultPlayerStateChangedThrottleMs);

    void set_player_state_changed_throttle_ms(int64_t throttle_ms);
    [[nodiscard]] int64_t player_state_changed_throttle_ms() const;

    // Evaluates an outbound setVolume command against the 200ms throttle window and
    // records wanted_volume for 2000ms.
    [[nodiscard]] VolumeCommandDecision submit_volume_command(
        uint32_t volume,
        std::string target_device_id);

    // Flushes any coalesced pending setVolume command if >= 200ms has elapsed.
    [[nodiscard]] std::optional<PendingVolumeCommand> take_pending_volume_if_ready();

    // Returns time remaining before a pending volume command becomes eligible.
    [[nodiscard]] std::optional<std::chrono::milliseconds> pending_volume_delay() const;

    // Returns the active wanted_volume if within its 2000ms expiry window.
    [[nodiscard]] std::optional<uint32_t> active_wanted_volume() const;

    // Checks whether an incoming remote/cluster volume should be applied or ignored while
    // a local wanted_volume is still fresh within the 2000ms expiry window.
    [[nodiscard]] bool should_apply_remote_volume(uint32_t remote_volume);

    // Explicitly clears wanted_volume (e.g., on cluster device switch or disconnect).
    void clear_wanted_volume();

    // Evaluates PutStateReason::VOLUME_CHANGED against the 200ms throttle window
    // (0xdb7750..0xdb7828).
    [[nodiscard]] PutStateThrottleDecision evaluate_put_state_volume_changed();

    // Evaluates PutStateReason::PLAYER_STATE_CHANGED against the configurable throttle
    // window (default 0ms, 0xd8fef0..0xd8ff48).
    [[nodiscard]] PutStateThrottleDecision evaluate_put_state_player_state_changed();

    // Marks whether a deferred PutStateReason::VOLUME_CHANGED needs replay after 200ms.
    [[nodiscard]] bool has_pending_volume_put_state() const;
    [[nodiscard]] std::optional<std::chrono::milliseconds> pending_volume_put_state_delay() const;
    [[nodiscard]] bool take_pending_volume_put_state_if_ready();

    // Marks whether a deferred PutStateReason::PLAYER_STATE_CHANGED needs replay.
    [[nodiscard]] bool has_pending_player_put_state() const;
    [[nodiscard]] std::optional<std::chrono::milliseconds> pending_player_put_state_delay() const;
    [[nodiscard]] bool take_pending_player_put_state_if_ready();

    void reset();

private:
    [[nodiscard]] std::chrono::steady_clock::time_point now() const;

    Clock clock_;
    mutable std::mutex mutex_;

    // Outbound setVolume (200ms) + wanted_volume (2000ms)
    bool has_sent_volume_{false};
    std::chrono::steady_clock::time_point last_volume_sent_at_{};
    std::optional<PendingVolumeCommand> pending_volume_;

    std::optional<uint32_t> wanted_volume_;
    std::chrono::steady_clock::time_point wanted_volume_expires_at_{};

    // PutStateReason::VOLUME_CHANGED (200ms)
    bool has_sent_volume_put_state_{false};
    std::chrono::steady_clock::time_point last_volume_put_state_at_{};
    bool pending_volume_put_state_{false};

    // PutStateReason::PLAYER_STATE_CHANGED (default 0ms)
    int64_t player_state_changed_throttle_ms_{kDefaultPlayerStateChangedThrottleMs};
    bool has_sent_player_put_state_{false};
    std::chrono::steady_clock::time_point last_player_put_state_at_{};
    bool pending_player_put_state_{false};
};

}  // namespace spotify::connectstate

#endif  // MUSIFY_CONNECT_VOLUME_THROTTLER_H_
