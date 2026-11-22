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

#include "PutStateBackoff.h"

#include <utility>

namespace spotify::connectstate {

namespace {

std::string_view trim_ascii(std::string_view value) {
    while (!value.empty() &&
           (value.front() == ' ' || value.front() == '\t' ||
            value.front() == '\r' || value.front() == '\n')) {
        value.remove_prefix(1);
    }
    while (!value.empty() &&
           (value.back() == ' ' || value.back() == '\t' ||
            value.back() == '\r' || value.back() == '\n')) {
        value.remove_suffix(1);
    }
    return value;
}

}  // namespace

PutStateBackoff::PutStateBackoff(Clock clock)
    : clock_(clock ? std::move(clock) : Clock([]() {
          return std::chrono::steady_clock::now();
      })) {}

std::chrono::steady_clock::time_point PutStateBackoff::now() const {
    return clock_();
}

bool PutStateBackoff::is_rate_limited_response(
    int http_status,
    std::string_view grpc_status) {
    if (http_status == 429) {
        return true;
    }
    return trim_ascii(grpc_status) == "8";
}

bool PutStateBackoff::should_trigger_backoff(
    PutStateReason reason,
    int http_status,
    std::string_view grpc_status) {
    return reason == PutStateReason::PLAYER_STATE_CHANGED &&
           is_rate_limited_response(http_status, grpc_status);
}

BackoffEvaluation PutStateBackoff::on_put_state_response(
    PutStateReason reason,
    int http_status,
    std::string_view grpc_status) {
    const bool rate_limited = is_rate_limited_response(http_status, grpc_status);
    if (!should_trigger_backoff(reason, http_status, grpc_status)) {
        if (http_status >= 200 && http_status < 300 && !rate_limited) {
            return BackoffEvaluation{
                .triggered = false,
                .error_code = BackoffErrorCode::kNone,
                .delay = std::chrono::milliseconds::zero(),
            };
        }
        return BackoffEvaluation{
            .triggered = false,
            .error_code = BackoffErrorCode::kPutStateFailed,
            .delay = std::chrono::milliseconds::zero(),
        };
    }

    const auto current_time = now();
    const auto delay = std::chrono::milliseconds(kBackoffDelayMs);
    {
        std::lock_guard<std::mutex> lock(mutex_);
        backoff_active_ = true;
        backoff_until_ = current_time + delay;
    }

    return BackoffEvaluation{
        .triggered = true,
        .error_code = BackoffErrorCode::kPutStateRateLimited,
        .delay = delay,
    };
}

bool PutStateBackoff::should_defer_put_state(PutStateReason reason) const {
    if (reason != PutStateReason::PLAYER_STATE_CHANGED) {
        return false;
    }
    return is_backoff_active();
}

void PutStateBackoff::stash_pending_state(PendingPutState pending) {
    const auto current_time = now();
    pending.captured_at = current_time;
    if (pending.reason == PutStateReason::PLAYER_STATE_CHANGED) {
        // liborbit @ 0xdc0ec4: deferred PLAYER_STATE_CHANGED (4) rewrites reason to PUT_STATE_RATE_LIMITED (12).
        pending.reason = PutStateReason::PUT_STATE_RATE_LIMITED;
    }
    std::lock_guard<std::mutex> lock(mutex_);
    pending_state_ = std::move(pending);
}

bool PutStateBackoff::is_backoff_active() const {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);
    return backoff_active_ && current_time < backoff_until_;
}

std::chrono::milliseconds PutStateBackoff::remaining_backoff() const {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);
    if (!backoff_active_ || current_time >= backoff_until_) {
        return std::chrono::milliseconds::zero();
    }
    return std::chrono::duration_cast<std::chrono::milliseconds>(
        backoff_until_ - current_time);
}

std::optional<std::chrono::steady_clock::time_point> PutStateBackoff::backoff_deadline() const {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!backoff_active_) {
        return std::nullopt;
    }
    return backoff_until_;
}

bool PutStateBackoff::has_pending_state() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return pending_state_.has_value();
}

std::optional<PendingPutState> PutStateBackoff::take_pending_if_ready() {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);
    if (!backoff_active_ || current_time < backoff_until_) {
        return std::nullopt;
    }
    backoff_active_ = false;
    backoff_until_ = {};
    if (!pending_state_.has_value()) {
        return std::nullopt;
    }
    auto pending = std::move(*pending_state_);
    pending_state_.reset();
    return pending;
}

void PutStateBackoff::reset() {
    std::lock_guard<std::mutex> lock(mutex_);
    backoff_active_ = false;
    backoff_until_ = {};
    pending_state_.reset();
}

}  // namespace spotify::connectstate
