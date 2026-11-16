// Replicated from liborbit-jni-spotify.so (TransferManager lifecycle, timeouts & dedup):
// - Binary symbols / offsets:
//   - TransferManager become active timer @ 0xdf3ddc..0xdf3e70 ("Command sent, starting become active timer", 10000ms @ 0x1595ab8 -> onBecomeActiveTimeout @ 0x3a24a1)
//   - TransferManager::transferToConnectStateDevice @ 0xdf3b2c (30000ms @ 0x7530)
//   - cast_transfer_timeout @ 0xd8f880 (default 30s, range [1, 60])
//   - TransferManager::shouldIgnoreRepeatedTransferRequest @ 0xdf19c0..0xdf1a84 (1,000,000us = 0xf4240 scale + interaction_ids)
//   - TransferManager::onClusterUpdate @ 0xdf4b00..0xdf4cf8 ("pending device in cluster but offline")
//   - Secondary Dodo transfer guard @ 0xdf16e8
// - Java / JNI counterpart:
//   - p199p/whd.java

#ifndef MUSIFY_CONNECT_TRANSFER_MANAGER_H_
#define MUSIFY_CONNECT_TRANSFER_MANAGER_H_

#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <deque>
#include <functional>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <thread>
#include <vector>

#include "ConnectDevicesImpl.h"
#include "ConnectStateClientImpl.h"
#include "TransferIntention.h"

namespace spotify::connectstate {

struct TransferOutcome {
    bool ok{false};
    std::string intention_id;
    std::string target_device_id;
    FinishReason finish_reason{FinishReason::kFailed};
    std::string ack_id;
    std::string error_description;
    std::vector<std::string> reasons;
};

struct TransferRequest {
    std::string target_device_id;
    std::string target_device_name;
    ConnectDeviceType device_type{ConnectDeviceType::kLoggedIn};
    std::string target_alias_id;
    TransferOptionsParams options;
    std::vector<std::string> interaction_ids;
    std::string command_id;
    std::string dodo_id;
    bool without_active_device{false};
};

class TransferManager {
public:
    static constexpr int64_t kBecomeActiveTimeoutMs = 10000;
    static constexpr int64_t kTransferTimeoutMs = 30000;
    static constexpr int32_t kDefaultCastTimeoutSec = 30;
    static constexpr int32_t kMinCastTimeoutSec = 1;
    static constexpr int32_t kMaxCastTimeoutSec = 60;
    static constexpr int64_t kMicrosecondsPerSecond = 1000000;
    static constexpr int64_t kDefaultRepeatedTransferCooldownSec = 1;

    using Clock = std::function<std::chrono::steady_clock::time_point()>;
    using CompletionCallback = std::function<void(const TransferOutcome&)>;

    TransferManager(
        ConnectStateClientImpl& client,
        ConnectDevicesImpl& devices,
        Clock clock = {});

    ~TransferManager();

    TransferManager(const TransferManager&) = delete;
    TransferManager& operator=(const TransferManager&) = delete;

    void start();
    void stop();

    void set_completion_callback(CompletionCallback callback);
    void set_cast_transfer_timeout_sec(int32_t timeout_sec);
    [[nodiscard]] int32_t cast_transfer_timeout_sec() const;

    void set_repeated_transfer_cooldown_sec(int64_t cooldown_sec);
    void set_allow_secondary_dodo_transfer(bool allow);
    [[nodiscard]] bool allow_secondary_dodo_transfer() const;

    // Checks whether an incoming transfer request duplicates a recent request within
    // N * 1,000,000 microseconds for matching target and interaction IDs (0xdf19c0..0xdf1a84).
    [[nodiscard]] bool should_ignore_repeated_transfer_request(
        std::string_view target_device_id,
        const std::vector<std::string>& interaction_ids) const;

    // Initiates a general Connect transfer using full TransferRequest parameters.
    // The synchronous return reflects HTTP transfer acceptance (or a pre-unlock outcome recorded
    // in recent_finished_outcomes_ if completed, aborted, or timed out during client_.transfer()).
    // Registered CompletionCallback is authoritative for asynchronous kBecomingActive transitions
    // and any concurrent post-unlock abort_active_transfer(), on_cluster_update(), or
    // check_timeouts() completion.
    TransferOutcome transfer_to_device(const TransferRequest& request);

    // Convenience helper matching ConnectService::Transfer / ConnectDevices Connect-State target
    // (`30000ms` timeout at 0xdf3b2c). Shares the same synchronous HTTP acceptance vs
    // authoritative CompletionCallback contract as transfer_to_device().
    TransferOutcome transfer_to_connect_state_device(
        const std::string& target_device_id,
        const std::string& target_device_name = {},
        const TransferOptionsParams& options = {},
        const std::vector<std::string>& interaction_ids = {});

    // Aborts any active transfer intention with FinishReason::kAborted.
    void abort_active_transfer(std::string reason = "aborted");

    // Processes an incoming cluster state snapshot to complete or continue awaiting
    // the pending target device (`0xdf4b00..0xdf4cf8`).
    void on_cluster_update(const Cluster& cluster);

    // Evaluates active intention phase/become-active timers; triggers onBecomeActiveTimeout()
    // when elapsed >= budget (10000ms for become-active, 30000ms for Connect-State transfer).
    void check_timeouts();

    [[nodiscard]] std::optional<TransferIntention> active_intention() const;
    [[nodiscard]] bool has_active_transfer() const;

    [[nodiscard]] static bool is_device_offline(const DeviceInfo& device);

private:
    static constexpr size_t kMaxRecentFinishedOutcomes = 32;

    [[nodiscard]] int64_t effective_phase_budget_ms_locked(
        const TransferIntention& intention) const;
    void record_finished_outcome_locked(const TransferOutcome& outcome);
    [[nodiscard]] std::optional<TransferOutcome> find_finished_outcome_locked(
        std::string_view intention_id) const;
    void on_become_active_timeout_locked(
        std::optional<TransferOutcome>& out_outcome,
        bool* should_release = nullptr);
    void release_postponement_if_held(TransferIntention& intention);
    void notify_completion(const TransferOutcome& outcome);
    void timeout_loop();
    [[nodiscard]] std::chrono::steady_clock::time_point now() const;

    ConnectStateClientImpl& client_;
    ConnectDevicesImpl& devices_;
    Clock clock_;

    mutable std::mutex mutex_;
    std::condition_variable cv_;
    CompletionCallback completion_callback_;

    int32_t cast_transfer_timeout_sec_{kDefaultCastTimeoutSec};
    int64_t repeated_transfer_cooldown_sec_{kDefaultRepeatedTransferCooldownSec};
    bool allow_secondary_dodo_transfer_{false};

    uint64_t next_intention_seq_{1};
    uint64_t schedule_version_{0};
    std::optional<TransferIntention> active_intention_;
    std::deque<TransferOutcome> recent_finished_outcomes_;

    std::string last_request_target_id_;
    std::vector<std::string> last_request_interaction_ids_;
    std::chrono::steady_clock::time_point last_request_timestamp_{};
    bool has_last_request_{false};

    bool watcher_running_{false};
    bool watcher_stop_requested_{false};
    std::thread watcher_thread_;
};

}  // namespace spotify::connectstate

#endif  // MUSIFY_CONNECT_TRANSFER_MANAGER_H_
