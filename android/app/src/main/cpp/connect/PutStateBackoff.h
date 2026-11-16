// Replicated from liborbit-jni-spotify.so (ConnectState PutState backoff state machine):
// - Binary symbols / offsets:
//   - ConnectStateClientImpl::putState response & backoff @ 0xdc5e8c..0xdc6310
//   - Fixed 10000ms (0x2710) backoff literal @ 0x1595ab8 (liborbit-jni-spotify.so)
//   - PutStateReason::PLAYER_STATE_CHANGED (4) + HTTP 429 / gRPC status "8" (0x3e1028, 0x3e1040)
//   - std::error_code values: 9000 (0xdc6134/0xdc6228/0xdc03bc), 9001 (0xdc61e4/0xdc03dc),
//     9002 (0xdc61b0/0xdc0f70), 10 system error (0xdc5e98)
// - Java / Esperanto counterparts:
//   - com/spotify/core/corefullimpl/NativeFullAuthenticatedScopeImpl.java
//   - com/spotify/connectivity/NativeAuthenticatedScope.java
//   - p199p/s77.java (ConnectService.State)

#ifndef MUSIFY_CONNECT_PUT_STATE_BACKOFF_H_
#define MUSIFY_CONNECT_PUT_STATE_BACKOFF_H_

#include <chrono>
#include <cstdint>
#include <functional>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>

#include "ConnectStateProtos.h"

namespace spotify::connectstate {

// std::error_code numeric values observed in liborbit-jni-spotify.so @ 0xdc5e8c..0xdc6310.
// Note: 9000, 9001, 9002, and 10 are error codes, NOT millisecond durations.
enum class BackoffErrorCode : int32_t {
    kNone = 0,
    kSystemError = 10,          // 0xdc5e98 (system/transport error, 0x361077)
    kPutStateFailed = 9000,     // 0xdc6134 / 0xdc6228 / 0xdc03bc
    kPutStateCanceled = 9001,   // 0xdc61e4 / 0xdc03dc (cluster parse / HTTP client error)
    kPutStateRateLimited = 9002,// 0xdc61b0 / 0xdc0f70 (429 or grpc-status "8" on PLAYER_STATE_CHANGED)
};

struct PendingPutState {
    PutStateReason reason{PutStateReason::UNKNOWN_PUT_STATE_REASON};
    Device device;
    bool wake_devices{false};
    std::chrono::steady_clock::time_point captured_at{};
};

struct BackoffEvaluation {
    bool triggered{false};
    BackoffErrorCode error_code{BackoffErrorCode::kNone};
    std::chrono::milliseconds delay{std::chrono::milliseconds::zero()};
};

class PutStateBackoff {
public:
    // Fixed 10000ms (0x2710) backoff duration from liborbit-jni-spotify.so @ 0x1595ab8.
    static constexpr int64_t kBackoffDelayMs = 10000;

    using Clock = std::function<std::chrono::steady_clock::time_point()>;

    explicit PutStateBackoff(Clock clock = {});

    // Returns true if HTTP 429 or gRPC status "8" (RESOURCE_EXHAUSTED).
    [[nodiscard]] static bool is_rate_limited_response(
        int http_status,
        std::string_view grpc_status);

    // Backoff triggers ONLY when reason == PLAYER_STATE_CHANGED (4) AND rate-limited.
    [[nodiscard]] static bool should_trigger_backoff(
        PutStateReason reason,
        int http_status,
        std::string_view grpc_status);

    // Evaluates a completed PutState response and activates the 10000ms backoff window if eligible.
    [[nodiscard]] BackoffEvaluation on_put_state_response(
        PutStateReason reason,
        int http_status,
        std::string_view grpc_status);

    // Returns true if outbound PutState for |reason| should be deferred behind an active backoff.
    // Only PLAYER_STATE_CHANGED is deferred by PutStateBackoff; other reasons pass through.
    [[nodiscard]] bool should_defer_put_state(PutStateReason reason) const;

    // Stores/replaces the latest pending PLAYER_STATE_CHANGED snapshot to replay on expiry.
    void stash_pending_state(PendingPutState pending);

    // Returns true while the 10000ms backoff deadline has not yet elapsed.
    [[nodiscard]] bool is_backoff_active() const;

    // Remaining time until the backoff deadline expires (0ms if inactive or expired).
    [[nodiscard]] std::chrono::milliseconds remaining_backoff() const;

    // Returns the backoff deadline if a backoff window is currently armed.
    [[nodiscard]] std::optional<std::chrono::steady_clock::time_point> backoff_deadline() const;

    // Returns whether a pending state is queued for replay.
    [[nodiscard]] bool has_pending_state() const;

    // If backoff was armed and its 10000ms deadline has elapsed, clears backoff and returns
    // the stashed pending state (if any) for replay.
    [[nodiscard]] std::optional<PendingPutState> take_pending_if_ready();

    // Clears active backoff and any stashed state (e.g. on logout/stop).
    void reset();

private:
    [[nodiscard]] std::chrono::steady_clock::time_point now() const;

    Clock clock_;
    mutable std::mutex mutex_;
    bool backoff_active_{false};
    std::chrono::steady_clock::time_point backoff_until_{};
    std::optional<PendingPutState> pending_state_;
};

}  // namespace spotify::connectstate

#endif  // MUSIFY_CONNECT_PUT_STATE_BACKOFF_H_
