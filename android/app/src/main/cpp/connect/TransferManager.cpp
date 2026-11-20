// ============================================================================
// Replicated from liborbit-jni-spotify.so (TransferManager lifecycle, timeouts & dedup):
// - Binary symbols / offsets (`liborbit-jni-spotify.so` arm64):
//   - TransferManager become active timer @ 0xdf3ddc..0xdf3e70
//     ("Command sent, starting become active timer", 10000ms @ 0x1595ab8 -> onBecomeActiveTimeout @ 0x3a24a1)
//   - TransferManager::transferToConnectStateDevice @ 0xdf3b2c (30000ms @ 0x7530)
//   - cast_transfer_timeout @ 0xd8f880 (default 30s, range [1, 60])
//   - TransferManager::shouldIgnoreRepeatedTransferRequest @ 0xdf19c0..0xdf1a84
//     (1,000,000us = 0xf4240 scale + interaction_ids)
//   - TransferManager::onClusterUpdate @ 0xdf4b00..0xdf4cf8 ("pending device in cluster but offline")
//   - Secondary Dodo transfer guard @ 0xdf16e8
// - Java / JNI counterpart:
//   - p199p/whd.java
// ============================================================================

#include "TransferManager.h"

#include <algorithm>
#include <utility>

#include "../network/NativeLog.h"

namespace spotify::connectstate {

namespace {

bool interaction_ids_overlap_or_match(
    const std::vector<std::string>& a,
    const std::vector<std::string>& b) {
    if (a.empty() && b.empty()) {
        return true;
    }
    if (a.empty() || b.empty()) {
        return false;
    }
    for (const auto& id : a) {
        for (const auto& other : b) {
            if (id == other) {
                return true;
            }
        }
    }
    return false;
}

}  // namespace

TransferManager::TransferManager(
    ConnectStateClientImpl& client,
    ConnectDevicesImpl& devices,
    Clock clock)
    : client_(client),
      devices_(devices),
      clock_(clock ? std::move(clock) : Clock([]() {
          return std::chrono::steady_clock::now();
      })) {}

TransferManager::~TransferManager() {
    stop();
}

std::chrono::steady_clock::time_point TransferManager::now() const {
    return clock_();
}

void TransferManager::start() {
    std::lock_guard<std::mutex> lock(mutex_);
    if (watcher_running_) {
        return;
    }
    watcher_stop_requested_ = false;
    watcher_running_ = true;
    watcher_thread_ = std::thread(&TransferManager::timeout_loop, this);
}

void TransferManager::stop() {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!watcher_running_ && !watcher_thread_.joinable()) {
            return;
        }
        watcher_stop_requested_ = true;
        ++schedule_version_;
    }
    cv_.notify_all();
    if (watcher_thread_.joinable()) {
        watcher_thread_.join();
    }
    {
        std::lock_guard<std::mutex> lock(mutex_);
        watcher_running_ = false;
        watcher_stop_requested_ = false;
        if (active_intention_.has_value() && !active_intention_->is_finished()) {
            active_intention_->mark_finished(FinishReason::kAborted, "stopped", now());
            record_finished_outcome_locked(TransferOutcome{
                .ok = false,
                .intention_id = active_intention_->intention_id(),
                .target_device_id = active_intention_->target_device_id(),
                .finish_reason = FinishReason::kAborted,
                .ack_id = active_intention_->ack_id(),
                .error_description = "stopped",
                .reasons = {"aborted"},
            });
            release_postponement_if_held(*active_intention_);
            ++schedule_version_;
        }
        active_intention_.reset();
    }
}

void TransferManager::set_completion_callback(CompletionCallback callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    completion_callback_ = std::move(callback);
}

void TransferManager::set_cast_transfer_timeout_sec(int32_t timeout_sec) {
    bool notify = false;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        int32_t bounded = timeout_sec;
        if (bounded < kMinCastTimeoutSec) {
            bounded = kMinCastTimeoutSec;
        } else if (bounded > kMaxCastTimeoutSec) {
            bounded = kMaxCastTimeoutSec;
        }
        if (cast_transfer_timeout_sec_ != bounded) {
            cast_transfer_timeout_sec_ = bounded;
            ++schedule_version_;
            notify = true;
        }
    }
    if (notify) {
        cv_.notify_all();
    }
}

int32_t TransferManager::cast_transfer_timeout_sec() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return cast_transfer_timeout_sec_;
}

void TransferManager::set_repeated_transfer_cooldown_sec(int64_t cooldown_sec) {
    std::lock_guard<std::mutex> lock(mutex_);
    repeated_transfer_cooldown_sec_ = cooldown_sec > 0 ? cooldown_sec : 0;
}

void TransferManager::set_allow_secondary_dodo_transfer(bool allow) {
    std::lock_guard<std::mutex> lock(mutex_);
    allow_secondary_dodo_transfer_ = allow;
}

bool TransferManager::allow_secondary_dodo_transfer() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return allow_secondary_dodo_transfer_;
}

bool TransferManager::should_ignore_repeated_transfer_request(
    std::string_view target_device_id,
    const std::vector<std::string>& interaction_ids) const {
    const auto current_time = now();
    std::lock_guard<std::mutex> lock(mutex_);
    if (!has_last_request_ || repeated_transfer_cooldown_sec_ <= 0) {
        return false;
    }
    if (last_request_target_id_ != target_device_id) {
        return false;
    }
    const int64_t elapsed_us =
        std::chrono::duration_cast<std::chrono::microseconds>(
            current_time - last_request_timestamp_)
            .count();
    const int64_t threshold_us =
        repeated_transfer_cooldown_sec_ * kMicrosecondsPerSecond;
    if (elapsed_us < 0 || elapsed_us >= threshold_us) {
        return false;
    }
    return interaction_ids_overlap_or_match(last_request_interaction_ids_, interaction_ids);
}

bool TransferManager::is_device_offline(const DeviceInfo& device) {
    if (device.is_offline) {
        return true;
    }
    const auto it = device.metadata_map.find("is_offline");
    if (it != device.metadata_map.end() && it->second == "true") {
        return true;
    }
    const auto status_it = device.metadata_map.find("offline");
    if (status_it != device.metadata_map.end() && status_it->second == "true") {
        return true;
    }
    return !device.can_play && !device.capabilities.is_controllable;
}

void TransferManager::release_postponement_if_held(TransferIntention& intention) {
    if (intention.postponement_acquired()) {
        intention.set_postponement_acquired(false);
        const int32_t remaining = devices_.release_cluster_update_postponement_block();
        CONNECT_LOGD(
            "TransferManager: released cluster postponement block (remaining=%d, intention=%s)",
            remaining,
            intention.intention_id().c_str());
    }
}

void TransferManager::notify_completion(const TransferOutcome& outcome) {
    CompletionCallback cb;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        cb = completion_callback_;
    }
    if (cb) {
        cb(outcome);
    }
}

TransferOutcome TransferManager::transfer_to_device(const TransferRequest& request) {
    if (request.target_device_id.empty()) {
        CONNECT_LOGW("TransferManager::transfer_to_device rejected: empty target_device_id");
        return TransferOutcome{
            .ok = false,
            .intention_id = {},
            .target_device_id = {},
            .finish_reason = FinishReason::kFailed,
            .ack_id = {},
            .error_description = "Target device ID cannot be empty",
            .reasons = {"empty_target_device_id"},
        };
    }

    if (should_ignore_repeated_transfer_request(
            request.target_device_id, request.interaction_ids)) {
        CONNECT_LOGD(
            "TransferManager: ignoring repeated transfer request for target=%s",
            request.target_device_id.c_str());
        return TransferOutcome{
            .ok = false,
            .intention_id = {},
            .target_device_id = request.target_device_id,
            .finish_reason = FinishReason::kAborted,
            .ack_id = {},
            .error_description = "Ignoring repeated transfer request within cooldown",
            .reasons = {"repeated_transfer_ignored"},
        };
    }

    // Secondary Dodo transfer guard (liborbit @ 0xdf16e8).
    {
        bool allow_secondary = false;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            allow_secondary = allow_secondary_dodo_transfer_;
        }
        const auto dodos = devices_.dodos_snapshot();
        for (const auto& dodo : dodos) {
            if ((dodo.cs_id == request.target_device_id ||
                 (!request.dodo_id.empty() && dodo.dodo_id == request.dodo_id)) &&
                !dodo.is_primary && !allow_secondary) {
                CONNECT_LOGW(
                    "TransferManager: secondary Dodo transfer disallowed target=%s",
                    request.target_device_id.c_str());
                return TransferOutcome{
                    .ok = false,
                    .intention_id = {},
                    .target_device_id = request.target_device_id,
                    .finish_reason = FinishReason::kFailed,
                    .ack_id = {},
                    .error_description = "Secondary Dodo transfer is disallowed",
                    .reasons = {"secondary_dodo_disallowed"},
                };
            }
        }
    }

    std::string intention_id;
    std::optional<TransferOutcome> superseded_outcome;
    const auto current_time = now();

    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (active_intention_.has_value() && !active_intention_->is_finished()) {
            active_intention_->mark_finished(
                FinishReason::kAborted, "Superseded by new transfer request", current_time);
            superseded_outcome = TransferOutcome{
                .ok = false,
                .intention_id = active_intention_->intention_id(),
                .target_device_id = active_intention_->target_device_id(),
                .finish_reason = FinishReason::kAborted,
                .ack_id = active_intention_->ack_id(),
                .error_description = "Superseded by new transfer request",
                .reasons = {"superseded"},
            };
            record_finished_outcome_locked(*superseded_outcome);
            release_postponement_if_held(*active_intention_);
            active_intention_.reset();
            ++schedule_version_;
        }

        intention_id = "transfer-" + std::to_string(next_intention_seq_++);
        TransferIntention intention(
            intention_id,
            request.target_device_id,
            request.target_device_name,
            request.device_type,
            request.target_alias_id,
            request.interaction_ids,
            current_time);
        intention.set_dodo_target(!request.dodo_id.empty(), request.dodo_id);
        intention.enter_phase(TransferPhase::kTransferring, current_time);

        const int32_t block_count = devices_.acquire_cluster_update_postponement_block();
        CONNECT_LOGD(
            "TransferManager: acquired cluster postponement block (count=%d, intention=%s, target=%s)",
            block_count,
            intention_id.c_str(),
            request.target_device_id.c_str());
        intention.set_postponement_acquired(true);
        active_intention_ = std::move(intention);
        ++schedule_version_;

        has_last_request_ = true;
        last_request_target_id_ = request.target_device_id;
        last_request_interaction_ids_ = request.interaction_ids;
        last_request_timestamp_ = current_time;
    }

    cv_.notify_all();
    if (superseded_outcome.has_value()) {
        notify_completion(*superseded_outcome);
    }

    const std::string from_id = !devices_.local_device_id().empty()
                                    ? devices_.local_device_id()
                                    : client_.local_device_id();

    TransferHttpRequest http_req{
        .from_device_id = from_id,
        .to_device_id = request.target_device_id,
        .options = request.options,
        .transfer_intent_id = intention_id,
        .command_id = request.command_id,
        .without_active_device = request.without_active_device,
        .target_alias_id = request.target_alias_id,
        .dodo = request.dodo_id,
    };

    const TransferHttpResult http_res = client_.transfer(http_req);
    const auto post_http_time = now();

    if (!http_res.ok) {
        CONNECT_LOGW(
            "TransferManager: HTTP transfer failed target=%s http=%d desc=%s",
            request.target_device_id.c_str(),
            http_res.http_status,
            http_res.error_description.c_str());
        std::optional<TransferOutcome> fail_outcome;
        std::optional<TransferOutcome> recorded_outcome;
        std::optional<TransferIntention> to_release;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (active_intention_.has_value() &&
                active_intention_->intention_id() == intention_id &&
                !active_intention_->is_finished()) {
                active_intention_->mark_finished(
                    FinishReason::kFailed, http_res.error_description, post_http_time);
                fail_outcome = TransferOutcome{
                    .ok = false,
                    .intention_id = intention_id,
                    .target_device_id = request.target_device_id,
                    .finish_reason = FinishReason::kFailed,
                    .ack_id = {},
                    .error_description = http_res.error_description,
                    .reasons = http_res.reasons,
                };
                record_finished_outcome_locked(*fail_outcome);
                if (active_intention_->postponement_acquired()) {
                    active_intention_->set_postponement_acquired(false);
                    to_release = *active_intention_;
                }
                active_intention_.reset();
                ++schedule_version_;
            } else {
                recorded_outcome = find_finished_outcome_locked(intention_id);
            }
        }
        if (to_release.has_value()) {
            const int32_t remaining = devices_.release_cluster_update_postponement_block();
            CONNECT_LOGD(
                "TransferManager: released postponement block after transfer failure (remaining=%d)",
                remaining);
        }
        if (fail_outcome.has_value()) {
            cv_.notify_all();
            notify_completion(*fail_outcome);
            return *fail_outcome;
        }
        if (recorded_outcome.has_value()) {
            return *recorded_outcome;
        }
        return TransferOutcome{
            .ok = false,
            .intention_id = intention_id,
            .target_device_id = request.target_device_id,
            .finish_reason = FinishReason::kAborted,
            .ack_id = {},
            .error_description = "Transfer aborted during HTTP request",
            .reasons = {},
        };
    }

    // HTTP command succeeded: transition to kBecomingActive (10000ms timer) and release
    // postponement block so stashed & live cluster updates can complete the transfer.
    bool should_release = false;
    bool matched_active = false;
    std::optional<TransferOutcome> recorded_outcome;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (active_intention_.has_value() &&
            active_intention_->intention_id() == intention_id &&
            !active_intention_->is_finished()) {
            matched_active = true;
            active_intention_->set_ack_id(http_res.ack_id);
            active_intention_->enter_phase(TransferPhase::kBecomingActive, post_http_time);
            if (active_intention_->postponement_acquired()) {
                active_intention_->set_postponement_acquired(false);
                should_release = true;
            }
            ++schedule_version_;
        } else {
            recorded_outcome = find_finished_outcome_locked(intention_id);
        }
    }
    if (should_release) {
        const int32_t remaining = devices_.release_cluster_update_postponement_block();
        CONNECT_LOGD(
            "TransferManager: command sent, starting become-active timer (postponement remaining=%d)",
            remaining);
    }
    if (matched_active) {
        cv_.notify_all();
    } else {
        if (recorded_outcome.has_value()) {
            return *recorded_outcome;
        }
        return TransferOutcome{
            .ok = false,
            .intention_id = intention_id,
            .target_device_id = request.target_device_id,
            .finish_reason = FinishReason::kAborted,
            .ack_id = http_res.ack_id,
            .error_description = "Transfer aborted during HTTP request",
            .reasons = {},
        };
    }

    // Check if the cluster snapshot already shows the target active.
    const Cluster cluster = devices_.current_cluster();
    if (cluster.active_device_id == request.target_device_id) {
        on_cluster_update(cluster);
        return TransferOutcome{
            .ok = true,
            .intention_id = intention_id,
            .target_device_id = request.target_device_id,
            .finish_reason = FinishReason::kSuccess,
            .ack_id = http_res.ack_id,
            .error_description = {},
            .reasons = {},
        };
    }

    return TransferOutcome{
        .ok = true,
        .intention_id = intention_id,
        .target_device_id = request.target_device_id,
        .finish_reason = FinishReason::kSuccess,
        .ack_id = http_res.ack_id,
        .error_description = {},
        .reasons = {},
    };
}

TransferOutcome TransferManager::transfer_to_connect_state_device(
    const std::string& target_device_id,
    const std::string& target_device_name,
    const TransferOptionsParams& options,
    const std::vector<std::string>& interaction_ids) {
    TransferRequest req;
    req.target_device_id = target_device_id;
    req.target_device_name = target_device_name;
    req.device_type = ConnectDeviceType::kLoggedIn;
    req.options = options;
    req.interaction_ids = interaction_ids;
    return transfer_to_device(req);
}

void TransferManager::abort_active_transfer(std::string reason) {
    std::optional<TransferOutcome> outcome;
    bool should_release = false;
    const auto current_time = now();
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!active_intention_.has_value() || active_intention_->is_finished()) {
            return;
        }
        active_intention_->mark_finished(FinishReason::kAborted, reason, current_time);
        outcome = TransferOutcome{
            .ok = false,
            .intention_id = active_intention_->intention_id(),
            .target_device_id = active_intention_->target_device_id(),
            .finish_reason = FinishReason::kAborted,
            .ack_id = active_intention_->ack_id(),
            .error_description = std::move(reason),
            .reasons = {"aborted"},
        };
        record_finished_outcome_locked(*outcome);
        if (active_intention_->postponement_acquired()) {
            active_intention_->set_postponement_acquired(false);
            should_release = true;
        }
        active_intention_.reset();
        ++schedule_version_;
    }
    if (should_release) {
        const int32_t remaining = devices_.release_cluster_update_postponement_block();
        CONNECT_LOGD(
            "TransferManager: released postponement block after abort (remaining=%d)",
            remaining);
    }
    if (outcome.has_value()) {
        cv_.notify_all();
        notify_completion(*outcome);
    }
}

void TransferManager::on_cluster_update(const Cluster& cluster) {
    std::optional<TransferOutcome> completed_outcome;
    bool should_release = false;
    const auto current_time = now();

    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!active_intention_.has_value() || active_intention_->is_finished()) {
            return;
        }

        const std::string& pending_id = active_intention_->target_device_id();
        if (cluster.active_device_id == pending_id) {
            active_intention_->mark_finished(FinishReason::kSuccess, {}, current_time);
            completed_outcome = TransferOutcome{
                .ok = true,
                .intention_id = active_intention_->intention_id(),
                .target_device_id = pending_id,
                .finish_reason = FinishReason::kSuccess,
                .ack_id = active_intention_->ack_id(),
                .error_description = {},
                .reasons = {},
            };
            record_finished_outcome_locked(*completed_outcome);
            if (active_intention_->postponement_acquired()) {
                active_intention_->set_postponement_acquired(false);
                should_release = true;
            }
            active_intention_.reset();
            ++schedule_version_;
        } else {
            const auto dev_it = cluster.devices.find(pending_id);
            if (dev_it != cluster.devices.end() && is_device_offline(dev_it->second)) {
                // Pending device in cluster is offline: remain in kBecomingActive until
                // device wakes up or 10000ms become-active timeout expires (0xdf4cd8).
                return;
            }
        }
    }

    if (should_release) {
        const int32_t remaining = devices_.release_cluster_update_postponement_block();
        CONNECT_LOGD(
            "TransferManager: released postponement block on transfer completion (remaining=%d)",
            remaining);
    }
    if (completed_outcome.has_value()) {
        CONNECT_LOGI(
            "TransferManager: transfer completed target=%s",
            completed_outcome->target_device_id.c_str());
        cv_.notify_all();
        notify_completion(*completed_outcome);
    }
}

int64_t TransferManager::effective_phase_budget_ms_locked(
    const TransferIntention& intention) const {
    if (intention.device_type() == ConnectDeviceType::kCast &&
        intention.phase() == TransferPhase::kTransferring) {
        return static_cast<int64_t>(cast_transfer_timeout_sec_) * 1000LL;
    }
    return intention.current_phase_budget_ms();
}

void TransferManager::record_finished_outcome_locked(const TransferOutcome& outcome) {
    if (outcome.intention_id.empty()) {
        return;
    }
    recent_finished_outcomes_.push_back(outcome);
    while (recent_finished_outcomes_.size() > kMaxRecentFinishedOutcomes) {
        recent_finished_outcomes_.pop_front();
    }
}

std::optional<TransferOutcome> TransferManager::find_finished_outcome_locked(
    std::string_view intention_id) const {
    for (auto it = recent_finished_outcomes_.rbegin();
         it != recent_finished_outcomes_.rend();
         ++it) {
        if (it->intention_id == intention_id) {
            return *it;
        }
    }
    return std::nullopt;
}

void TransferManager::on_become_active_timeout_locked(
    std::optional<TransferOutcome>& out_outcome,
    bool* should_release) {
    if (!active_intention_.has_value() || active_intention_->is_finished()) {
        return;
    }
    const auto current_time = now();
    const int64_t budget_ms = effective_phase_budget_ms_locked(*active_intention_);
    if (!active_intention_->is_phase_expired(current_time, budget_ms)) {
        return;
    }
    active_intention_->mark_finished(
        FinishReason::kNoResponse, "Transfer become-active timed out", current_time);
    out_outcome = TransferOutcome{
        .ok = false,
        .intention_id = active_intention_->intention_id(),
        .target_device_id = active_intention_->target_device_id(),
        .finish_reason = FinishReason::kNoResponse,
        .ack_id = active_intention_->ack_id(),
        .error_description = "Transfer become-active timed out",
        .reasons = {"no_response"},
    };
    record_finished_outcome_locked(*out_outcome);
    if (active_intention_->postponement_acquired()) {
        active_intention_->set_postponement_acquired(false);
        if (should_release != nullptr) {
            *should_release = true;
        }
    }
    active_intention_.reset();
    ++schedule_version_;
}

void TransferManager::check_timeouts() {
    std::optional<TransferOutcome> timeout_outcome;
    bool should_release = false;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        on_become_active_timeout_locked(timeout_outcome, &should_release);
    }
    if (should_release) {
        const int32_t remaining = devices_.release_cluster_update_postponement_block();
        CONNECT_LOGD(
            "TransferManager: released postponement block after timeout (remaining=%d)",
            remaining);
    }
    if (timeout_outcome.has_value()) {
        CONNECT_LOGW(
            "TransferManager: become-active timed out target=%s",
            timeout_outcome->target_device_id.c_str());
        cv_.notify_all();
        notify_completion(*timeout_outcome);
    }
}

std::optional<TransferIntention> TransferManager::active_intention() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return active_intention_;
}

bool TransferManager::has_active_transfer() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return active_intention_.has_value() && !active_intention_->is_finished();
}

void TransferManager::timeout_loop() {
    while (true) {
        check_timeouts();

        std::unique_lock<std::mutex> lock(mutex_);
        if (watcher_stop_requested_) {
            break;
        }
        const uint64_t observed_schedule_version = schedule_version_;
        if (active_intention_.has_value() && !active_intention_->is_finished()) {
            const int64_t budget_ms = effective_phase_budget_ms_locked(*active_intention_);
            const auto elapsed_ms =
                std::chrono::duration_cast<std::chrono::milliseconds>(
                    now() - active_intention_->phase_started_at())
                    .count();
            if (budget_ms > 0 && elapsed_ms >= budget_ms) {
                continue;
            }
            if (budget_ms > 0) {
                const int64_t remaining = budget_ms - elapsed_ms;
                cv_.wait_for(
                    lock,
                    std::chrono::milliseconds(remaining),
                    [this, observed_schedule_version]() {
                        return watcher_stop_requested_ ||
                               schedule_version_ != observed_schedule_version;
                    });
            } else {
                cv_.wait(lock, [this, observed_schedule_version]() {
                    return watcher_stop_requested_ ||
                           schedule_version_ != observed_schedule_version;
                });
            }
        } else {
            cv_.wait(lock, [this, observed_schedule_version]() {
                return watcher_stop_requested_ ||
                       schedule_version_ != observed_schedule_version ||
                       (active_intention_.has_value() && !active_intention_->is_finished());
            });
        }
        if (watcher_stop_requested_) {
            break;
        }
    }
}

}  // namespace spotify::connectstate
