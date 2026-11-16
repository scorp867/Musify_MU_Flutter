// Replicated from liborbit-jni-spotify.so (TransferIntention lifecycle & phase budgets):
// - Binary symbols / offsets:
//   - FinishReason string table @ 0xdf4920 indexing 0x3e1464:
//     0="success", 1="failed", 2="aborted", 3="no_response", 4="login_failed"
//   - ConnectDeviceType string table @ 0x3e1478[0..4]:
//     0="logged_in", 1="zeroconf", 2="dial", 3="cast", 4="pre_login"
//   - TransferIntention phase budgets @ 0xdf1b0c..0xdf1d18:
//     logged_in (30000ms, 3000ms), prelogin (30000ms), dial (30000ms, 3000ms),
//     cast (3000ms), zeroconf (3000ms)
// - Java / JNI counterpart:
//   - p199p/whd.java (transfer telemetry events)

#include "TransferIntention.h"

#include <utility>

namespace spotify::connectstate {

const char* finish_reason_to_string(FinishReason reason) {
    switch (reason) {
        case FinishReason::kSuccess: return "success";
        case FinishReason::kFailed: return "failed";
        case FinishReason::kAborted: return "aborted";
        case FinishReason::kNoResponse: return "no_response";
        case FinishReason::kLoginFailed: return "login_failed";
    }
    return "failed";
}

const char* connect_device_type_to_string(ConnectDeviceType type) {
    switch (type) {
        case ConnectDeviceType::kLoggedIn: return "logged_in";
        case ConnectDeviceType::kZeroconf: return "zeroconf";
        case ConnectDeviceType::kDial: return "dial";
        case ConnectDeviceType::kCast: return "cast";
        case ConnectDeviceType::kPreLogin: return "pre_login";
    }
    return "logged_in";
}

TransferIntention::TransferIntention(
    std::string intention_id,
    std::string target_device_id,
    std::string target_device_name,
    ConnectDeviceType device_type,
    std::string target_alias_id,
    std::vector<std::string> interaction_ids,
    std::chrono::steady_clock::time_point now)
    : intention_id_(std::move(intention_id)),
      target_device_id_(std::move(target_device_id)),
      target_device_name_(std::move(target_device_name)),
      device_type_(device_type),
      target_alias_id_(std::move(target_alias_id)),
      interaction_ids_(std::move(interaction_ids)),
      phase_(TransferPhase::kCreated),
      created_at_(now),
      phase_started_at_(now) {}

int64_t TransferIntention::phase_budget_ms(
    ConnectDeviceType device_type,
    TransferPhase phase) {
    switch (phase) {
        case TransferPhase::kCreated:
            return kShortPhaseBudgetMs;
        case TransferPhase::kDiscovering:
            switch (device_type) {
                case ConnectDeviceType::kLoggedIn:
                case ConnectDeviceType::kPreLogin:
                case ConnectDeviceType::kDial:
                    return kLongPhaseBudgetMs;
                case ConnectDeviceType::kCast:
                case ConnectDeviceType::kZeroconf:
                    return kShortPhaseBudgetMs;
            }
            break;
        case TransferPhase::kTransferring:
            switch (device_type) {
                case ConnectDeviceType::kLoggedIn:
                case ConnectDeviceType::kPreLogin:
                case ConnectDeviceType::kDial:
                case ConnectDeviceType::kCast:
                    return kLongPhaseBudgetMs;
                case ConnectDeviceType::kZeroconf:
                    return kShortPhaseBudgetMs;
            }
            break;
        case TransferPhase::kBecomingActive:
            return kBecomeActiveTimerMs;
        case TransferPhase::kFinished:
            return 0;
    }
    return kLongPhaseBudgetMs;
}

void TransferIntention::enter_phase(
    TransferPhase next_phase,
    std::chrono::steady_clock::time_point now) {
    if (phase_ == TransferPhase::kFinished) {
        return;
    }
    phase_ = next_phase;
    phase_started_at_ = now;
}

void TransferIntention::mark_finished(
    FinishReason reason,
    std::string error_description,
    std::chrono::steady_clock::time_point now) {
    if (phase_ == TransferPhase::kFinished) {
        return;
    }
    phase_ = TransferPhase::kFinished;
    finish_reason_ = reason;
    error_description_ = std::move(error_description);
    finished_at_ = now;
}

void TransferIntention::set_ack_id(std::string ack_id) {
    ack_id_ = std::move(ack_id);
}

void TransferIntention::set_dodo_target(bool is_dodo, std::string dodo_id) {
    is_dodo_target_ = is_dodo;
    dodo_id_ = std::move(dodo_id);
}

void TransferIntention::set_postponement_acquired(bool acquired) {
    postponement_acquired_ = acquired;
}

int64_t TransferIntention::current_phase_budget_ms() const {
    return phase_budget_ms(device_type_, phase_);
}

bool TransferIntention::is_phase_expired(
    std::chrono::steady_clock::time_point now) const {
    return is_phase_expired(now, current_phase_budget_ms());
}

bool TransferIntention::is_phase_expired(
    std::chrono::steady_clock::time_point now,
    int64_t budget_ms_override) const {
    if (phase_ == TransferPhase::kFinished || budget_ms_override <= 0) {
        return false;
    }
    const auto elapsed =
        std::chrono::duration_cast<std::chrono::milliseconds>(now - phase_started_at_)
            .count();
    return elapsed >= budget_ms_override;
}

}  // namespace spotify::connectstate
