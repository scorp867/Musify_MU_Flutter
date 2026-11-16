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

#ifndef MUSIFY_CONNECT_TRANSFER_INTENTION_H_
#define MUSIFY_CONNECT_TRANSFER_INTENTION_H_

#include <chrono>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace spotify::connectstate {

enum class FinishReason : uint8_t {
    kSuccess = 0,
    kFailed = 1,
    kAborted = 2,
    kNoResponse = 3,
    kLoginFailed = 4,
};

enum class ConnectDeviceType : uint8_t {
    kLoggedIn = 0,
    kZeroconf = 1,
    kDial = 2,
    kCast = 3,
    kPreLogin = 4,
};

enum class TransferPhase : uint8_t {
    kCreated = 0,
    kDiscovering = 1,
    kTransferring = 2,
    kBecomingActive = 3,
    kFinished = 4,
};

[[nodiscard]] const char* finish_reason_to_string(FinishReason reason);
[[nodiscard]] const char* connect_device_type_to_string(ConnectDeviceType type);

class TransferIntention {
public:
    static constexpr int64_t kLongPhaseBudgetMs = 30000;
    static constexpr int64_t kShortPhaseBudgetMs = 3000;
    static constexpr int64_t kBecomeActiveTimerMs = 10000;

    TransferIntention(
        std::string intention_id,
        std::string target_device_id,
        std::string target_device_name,
        ConnectDeviceType device_type,
        std::string target_alias_id,
        std::vector<std::string> interaction_ids,
        std::chrono::steady_clock::time_point now = std::chrono::steady_clock::now());

    [[nodiscard]] static int64_t phase_budget_ms(
        ConnectDeviceType device_type,
        TransferPhase phase);

    void enter_phase(
        TransferPhase next_phase,
        std::chrono::steady_clock::time_point now = std::chrono::steady_clock::now());

    void mark_finished(
        FinishReason reason,
        std::string error_description = {},
        std::chrono::steady_clock::time_point now = std::chrono::steady_clock::now());

    void set_ack_id(std::string ack_id);
    void set_dodo_target(bool is_dodo, std::string dodo_id = {});
    void set_postponement_acquired(bool acquired);

    [[nodiscard]] bool is_finished() const { return phase_ == TransferPhase::kFinished; }
    [[nodiscard]] bool is_phase_expired(std::chrono::steady_clock::time_point now) const;
    [[nodiscard]] bool is_phase_expired(
        std::chrono::steady_clock::time_point now,
        int64_t budget_ms_override) const;
    [[nodiscard]] int64_t current_phase_budget_ms() const;

    [[nodiscard]] const std::string& intention_id() const { return intention_id_; }
    [[nodiscard]] const std::string& target_device_id() const { return target_device_id_; }
    [[nodiscard]] const std::string& target_device_name() const { return target_device_name_; }
    [[nodiscard]] ConnectDeviceType device_type() const { return device_type_; }
    [[nodiscard]] const std::string& target_alias_id() const { return target_alias_id_; }
    [[nodiscard]] const std::vector<std::string>& interaction_ids() const {
        return interaction_ids_;
    }
    [[nodiscard]] TransferPhase phase() const { return phase_; }
    [[nodiscard]] std::optional<FinishReason> finish_reason() const { return finish_reason_; }
    [[nodiscard]] const std::string& ack_id() const { return ack_id_; }
    [[nodiscard]] const std::string& error_description() const { return error_description_; }
    [[nodiscard]] bool is_dodo_target() const { return is_dodo_target_; }
    [[nodiscard]] const std::string& dodo_id() const { return dodo_id_; }
    [[nodiscard]] bool postponement_acquired() const { return postponement_acquired_; }
    [[nodiscard]] std::chrono::steady_clock::time_point created_at() const { return created_at_; }
    [[nodiscard]] std::chrono::steady_clock::time_point phase_started_at() const {
        return phase_started_at_;
    }

private:
    std::string intention_id_;
    std::string target_device_id_;
    std::string target_device_name_;
    ConnectDeviceType device_type_{ConnectDeviceType::kLoggedIn};
    std::string target_alias_id_;
    std::vector<std::string> interaction_ids_;
    TransferPhase phase_{TransferPhase::kCreated};
    std::optional<FinishReason> finish_reason_;
    std::string ack_id_;
    std::string error_description_;
    bool is_dodo_target_{false};
    std::string dodo_id_;
    bool postponement_acquired_{false};
    std::chrono::steady_clock::time_point created_at_{};
    std::chrono::steady_clock::time_point phase_started_at_{};
    std::chrono::steady_clock::time_point finished_at_{};
};

}  // namespace spotify::connectstate

#endif  // MUSIFY_CONNECT_TRANSFER_INTENTION_H_
