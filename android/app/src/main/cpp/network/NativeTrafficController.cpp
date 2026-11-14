#include "NativeTrafficController.h"

#include <android/log.h>
#include <fcntl.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>
#include <poll.h>
#include <sys/socket.h>
#include <unistd.h>

#include <algorithm>
#include <cstring>

#define NTC_LOG_TAG "MusifyTrafficCtrl"
#define NTC_LOGI(...) __android_log_print(ANDROID_LOG_INFO, NTC_LOG_TAG, __VA_ARGS__)
#define NTC_LOGW(...) __android_log_print(ANDROID_LOG_WARN, NTC_LOG_TAG, __VA_ARGS__)

namespace spotify::network {

namespace {

[[nodiscard]] bool isCanceledNow(
    const std::atomic<bool>* cancel_flag,
    const CancelPredicate& cancel_pred) noexcept {
    if (cancel_flag && cancel_flag->load(std::memory_order_acquire)) {
        return true;
    }
    if (cancel_pred && cancel_pred()) {
        return true;
    }
    return false;
}

[[nodiscard]] bool isLowPriority(RequestPriority priority) noexcept {
    return priority == RequestPriority::P2_InteractiveMetadata ||
           priority == RequestPriority::P3_BackgroundBatch;
}

} // namespace

// ===========================================================================
// TrafficPermit implementation
// ===========================================================================

void TrafficPermit::complete(TransferOutcome outcome) noexcept {
    if (state_ != PermitLifecycleState::GrantedActive || !controller_) {
        return;
    }
    state_ = PermitLifecycleState::CompletedWithTelemetry;
    const auto elapsed_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::steady_clock::now() - acquired_at_).count();
    controller_->reportTransferOutcome(std::max<int64_t>(1, elapsed_ms), outcome);
    release();
}

void TrafficPermit::release() noexcept {
    if ((state_ != PermitLifecycleState::GrantedActive &&
         state_ != PermitLifecycleState::CompletedWithTelemetry) ||
        !controller_) {
        return;
    }
    NativeTrafficController* ctrl = controller_;
    const RequestPriority prio = priority_;
    const auto acquired = acquired_at_;
    const PermitLifecycleState prev_state = state_;
    controller_ = nullptr;
    state_ = PermitLifecycleState::ReleasedSlot;
    ctrl->releaseSlot(prio, acquired, prev_state);
}

// ===========================================================================
// NativeTrafficController implementation
// ===========================================================================

NativeTrafficController& NativeTrafficController::instance() {
    static NativeTrafficController ctrl;
    return ctrl;
}

NativeTrafficController::NativeTrafficController() {
    const bool initial_online = NativeHttpClient::hasActiveNetworkRoute();
    quality_.store(
        initial_online ? NetworkQuality::Fast : NetworkQuality::Offline,
        std::memory_order_release);

    if (::pipe2(wake_pipe_, O_CLOEXEC | O_NONBLOCK) != 0) {
        wake_pipe_[0] = -1;
        wake_pipe_[1] = -1;
    }

    monitor_thread_ = std::thread(&NativeTrafficController::routeMonitorLoop, this);
}

NativeTrafficController::~NativeTrafficController() {
    lifecycle_.store(ControllerLifecycle::ShuttingDown, std::memory_order_release);
    if (wake_pipe_[1] >= 0) {
        const uint8_t byte = 1;
        (void)::write(wake_pipe_[1], &byte, sizeof(byte));
    }
    cv_.notify_all();

    if (monitor_thread_.joinable()) {
        monitor_thread_.join();
    }

    if (wake_pipe_[0] >= 0) {
        ::close(wake_pipe_[0]);
        wake_pipe_[0] = -1;
    }
    if (wake_pipe_[1] >= 0) {
        ::close(wake_pipe_[1]);
        wake_pipe_[1] = -1;
    }
}

TrafficPermit NativeTrafficController::acquirePermit(
    RequestPriority priority,
    OfflinePolicy offline_policy,
    std::string tag,
    const std::atomic<bool>* cancel_flag,
    const CancelPredicate& cancel_pred) {
    if (lifecycle_.load(std::memory_order_acquire) == ControllerLifecycle::ShuttingDown ||
        isCanceledNow(cancel_flag, cancel_pred)) {
        return {};
    }

    // Sync live kernel route state before deciding whether to grant immediately or park.
    refreshRouteState();

    std::unique_lock<std::mutex> lock(mu_);
    if (lifecycle_.load(std::memory_order_acquire) == ControllerLifecycle::ShuttingDown ||
        isCanceledNow(cancel_flag, cancel_pred)) {
        return {};
    }

    const NetworkQuality current_quality = quality_.load(std::memory_order_acquire);
    if (current_quality == NetworkQuality::Offline &&
        offline_policy == OfflinePolicy::FailFastOffline) {
        return {};
    }

    // Fast path: if online, no higher-or-equal priority waiters are queued ahead, and a slot is free.
    if (current_quality != NetworkQuality::Offline && canGrantSlotLocked(priority)) {
        bool higher_or_equal_waiting = false;
        for (const auto& w : wait_queue_) {
            if (w->state == WaiterState::Queued &&
                static_cast<uint8_t>(w->priority) <= static_cast<uint8_t>(priority)) {
                higher_or_equal_waiting = true;
                break;
            }
        }
        if (!higher_or_equal_waiting) {
            ++active_total_;
            if (isLowPriority(priority)) {
                ++active_low_priority_;
            }
            return TrafficPermit(this, priority, std::chrono::steady_clock::now());
        }
    }

    auto waiter = std::make_shared<Waiter>();
    waiter->sequence = next_sequence_++;
    waiter->priority = priority;
    waiter->offline_policy = offline_policy;
    waiter->tag = std::move(tag);
    waiter->state = WaiterState::Queued;

    auto node_it = wait_queue_.insert(wait_queue_.end(), waiter);

    for (;;) {
        switch (waiter->state) {
            case WaiterState::SlotGranted: {
                if (lifecycle_.load(std::memory_order_acquire) == ControllerLifecycle::ShuttingDown ||
                    isCanceledNow(cancel_flag, cancel_pred)) {
                    if (active_total_ > 0) --active_total_;
                    if (isLowPriority(priority) && active_low_priority_ > 0) {
                        --active_low_priority_;
                    }
                    dispatchWaitersLocked();
                    return {};
                }
                return TrafficPermit(this, priority, std::chrono::steady_clock::now());
            }
            case WaiterState::CanceledByTag: {
                wait_queue_.erase(node_it);
                return {};
            }
            case WaiterState::Queued:
                break;
        }

        if (lifecycle_.load(std::memory_order_acquire) == ControllerLifecycle::ShuttingDown ||
            isCanceledNow(cancel_flag, cancel_pred)) {
            wait_queue_.erase(node_it);
            return {};
        }

        if (quality_.load(std::memory_order_acquire) == NetworkQuality::Offline &&
            offline_policy == OfflinePolicy::FailFastOffline) {
            wait_queue_.erase(node_it);
            return {};
        }

        if (cancel_pred || cancel_flag) {
            cv_.wait_for(lock, std::chrono::milliseconds(15));
        } else {
            cv_.wait(lock);
        }
    }
}

bool NativeTrafficController::waitForOnline(
    const std::atomic<bool>* cancel_flag,
    const CancelPredicate& cancel_pred) {
    if (lifecycle_.load(std::memory_order_acquire) == ControllerLifecycle::ShuttingDown ||
        isCanceledNow(cancel_flag, cancel_pred)) {
        return false;
    }

    if (refreshRouteState() == RouteStatus::Online) {
        return true;
    }

    std::unique_lock<std::mutex> lock(mu_);
    while (quality_.load(std::memory_order_acquire) == NetworkQuality::Offline) {
        if (lifecycle_.load(std::memory_order_acquire) == ControllerLifecycle::ShuttingDown ||
            isCanceledNow(cancel_flag, cancel_pred)) {
            return false;
        }
        cv_.wait_for(lock, std::chrono::milliseconds(20));
        lock.unlock();
        const RouteStatus status = refreshRouteState();
        lock.lock();
        if (status == RouteStatus::Online) {
            return !isCanceledNow(cancel_flag, cancel_pred);
        }
    }
    return !isCanceledNow(cancel_flag, cancel_pred);
}

void NativeTrafficController::cancelByTagPrefix(std::string_view tag_prefix) noexcept {
    if (tag_prefix.empty()) return;
    {
        std::lock_guard<std::mutex> lock(mu_);
        for (auto& w : wait_queue_) {
            if (w->state == WaiterState::Queued &&
                !w->tag.empty() &&
                w->tag.size() >= tag_prefix.size() &&
                std::memcmp(w->tag.data(), tag_prefix.data(), tag_prefix.size()) == 0) {
                w->state = WaiterState::CanceledByTag;
            }
        }
    }
    cv_.notify_all();
}

void NativeTrafficController::notifyAllWaiters() noexcept {
    cv_.notify_all();
}

void NativeTrafficController::reportTransferOutcome(
    int64_t rtt_ms,
    TransferOutcome outcome) noexcept {
    switch (outcome) {
        case TransferOutcome::TransportFailure:
        case TransferOutcome::TimedOut: {
            const bool route_alive = NativeHttpClient::hasActiveNetworkRoute();
            std::lock_guard<std::mutex> lock(mu_);
            if (!route_alive) {
                applyRouteStatusLocked(RouteStatus::Offline);
                return;
            }
            if (outcome == TransferOutcome::TimedOut) {
                const uint32_t timeouts =
                    consecutive_timeouts_.fetch_add(1, std::memory_order_acq_rel) + 1;
                if (timeouts >= 1 && quality_.load(std::memory_order_acquire) == NetworkQuality::Fast) {
                    quality_.store(NetworkQuality::Slow, std::memory_order_release);
                    NTC_LOGW("Network quality degraded to Slow due to transfer timeout");
                }
            }
            return;
        }
        case TransferOutcome::Success:
            break;
    }

    consecutive_timeouts_.store(0, std::memory_order_release);
    if (rtt_ms > 0) {
        const int64_t prev_rtt = rolling_rtt_ms_.load(std::memory_order_relaxed);
        const int64_t updated_rtt = (prev_rtt * 7 + rtt_ms * 3) / 10;
        rolling_rtt_ms_.store(updated_rtt, std::memory_order_release);
    }

    std::lock_guard<std::mutex> lock(mu_);
    const int64_t current_rtt = rolling_rtt_ms_.load(std::memory_order_acquire);
    const NetworkQuality target_quality =
        (current_rtt > kSlowNetworkRttThresholdMs) ? NetworkQuality::Slow : NetworkQuality::Fast;
    const NetworkQuality prev_quality = quality_.exchange(target_quality, std::memory_order_acq_rel);
    if (prev_quality != target_quality) {
        NTC_LOGI("Network quality transitioned -> %s (rolling_rtt=%lld ms)",
                 target_quality == NetworkQuality::Fast ? "Fast" : "Slow",
                 static_cast<long long>(current_rtt));
        dispatchWaitersLocked();
    }
}

RouteStatus NativeTrafficController::refreshRouteState() noexcept {
    const RouteStatus status = NativeHttpClient::hasActiveNetworkRoute()
        ? RouteStatus::Online
        : RouteStatus::Offline;
    const NetworkQuality current = quality_.load(std::memory_order_acquire);
    if (status == RouteStatus::Online && current == NetworkQuality::Offline) {
        std::lock_guard<std::mutex> lock(mu_);
        applyRouteStatusLocked(RouteStatus::Online);
    } else if (status == RouteStatus::Offline && current != NetworkQuality::Offline) {
        std::lock_guard<std::mutex> lock(mu_);
        applyRouteStatusLocked(RouteStatus::Offline);
    }
    return status;
}

void NativeTrafficController::releaseSlot(
    RequestPriority priority,
    std::chrono::steady_clock::time_point acquired_at,
    PermitLifecycleState prior_state) noexcept {
    if (prior_state == PermitLifecycleState::GrantedActive) {
        const auto elapsed_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::steady_clock::now() - acquired_at).count();
        const TransferOutcome fallback_outcome = NativeHttpClient::hasActiveNetworkRoute()
            ? TransferOutcome::Success
            : TransferOutcome::TransportFailure;
        reportTransferOutcome(std::max<int64_t>(1, elapsed_ms), fallback_outcome);
    }

    std::lock_guard<std::mutex> lock(mu_);
    if (active_total_ > 0) {
        --active_total_;
    }
    if (isLowPriority(priority) && active_low_priority_ > 0) {
        --active_low_priority_;
    }
    dispatchWaitersLocked();
}

bool NativeTrafficController::canGrantSlotLocked(RequestPriority priority) const noexcept {
    const NetworkQuality q = quality_.load(std::memory_order_acquire);
    if (q == NetworkQuality::Offline) {
        return false;
    }

    const size_t max_total =
        (q == NetworkQuality::Slow) ? kSlowMaxConcurrency : kFastMaxConcurrency;
    if (active_total_ >= max_total) {
        return false;
    }

    if (isLowPriority(priority)) {
        const size_t max_low =
            (q == NetworkQuality::Slow) ? kSlowMaxLowPriorityConcurrency : kFastMaxLowPriorityConcurrency;
        if (active_low_priority_ >= max_low) {
            return false;
        }
    }

    return true;
}

void NativeTrafficController::applyRouteStatusLocked(RouteStatus status) noexcept {
    const NetworkQuality prev = quality_.load(std::memory_order_acquire);
    switch (status) {
        case RouteStatus::Offline: {
            if (prev != NetworkQuality::Offline) {
                quality_.store(NetworkQuality::Offline, std::memory_order_release);
                NTC_LOGW("Kernel network route lost -> Offline (holding %zu queued requests)",
                         wait_queue_.size());
                cv_.notify_all();
            }
            return;
        }
        case RouteStatus::Online: {
            if (prev == NetworkQuality::Offline) {
                const int64_t rtt = rolling_rtt_ms_.load(std::memory_order_acquire);
                const NetworkQuality restored =
                    (rtt > kSlowNetworkRttThresholdMs) ? NetworkQuality::Slow : NetworkQuality::Fast;
                quality_.store(restored, std::memory_order_release);
                NTC_LOGI("Kernel network route restored -> %s (auto-draining %zu queued requests in P0->P3 order)",
                         restored == NetworkQuality::Fast ? "Fast" : "Slow",
                         wait_queue_.size());
                dispatchWaitersLocked();
                cv_.notify_all();
            }
            return;
        }
    }
}

void NativeTrafficController::dispatchWaitersLocked() noexcept {
    if (quality_.load(std::memory_order_acquire) == NetworkQuality::Offline ||
        wait_queue_.empty()) {
        return;
    }

    bool granted_any = false;
    while (!wait_queue_.empty()) {
        auto best_it = wait_queue_.end();
        for (auto it = wait_queue_.begin(); it != wait_queue_.end(); ++it) {
            const auto& candidate = *it;
            if (candidate->state != WaiterState::Queued) {
                continue;
            }
            if (!canGrantSlotLocked(candidate->priority)) {
                continue;
            }
            if (best_it == wait_queue_.end() ||
                static_cast<uint8_t>(candidate->priority) < static_cast<uint8_t>((*best_it)->priority) ||
                (candidate->priority == (*best_it)->priority &&
                 candidate->sequence < (*best_it)->sequence)) {
                best_it = it;
            }
        }

        if (best_it == wait_queue_.end()) {
            break;
        }

        auto chosen = *best_it;
        wait_queue_.erase(best_it);
        chosen->state = WaiterState::SlotGranted;
        ++active_total_;
        if (isLowPriority(chosen->priority)) {
            ++active_low_priority_;
        }
        granted_any = true;
    }

    if (granted_any) {
        cv_.notify_all();
    }
}

void NativeTrafficController::routeMonitorLoop() noexcept {
    int nl_fd = ::socket(AF_NETLINK, SOCK_RAW | SOCK_CLOEXEC | SOCK_NONBLOCK, NETLINK_ROUTE);
    if (nl_fd >= 0) {
        struct sockaddr_nl sa{};
        sa.nl_family = AF_NETLINK;
        sa.nl_groups = RTMGRP_LINK | RTMGRP_IPV4_ROUTE | RTMGRP_IPV6_ROUTE |
                       RTMGRP_IPV4_IFADDR | RTMGRP_IPV6_IFADDR;
        if (::bind(nl_fd, reinterpret_cast<struct sockaddr*>(&sa), sizeof(sa)) != 0) {
            ::close(nl_fd);
            nl_fd = -1;
        }
    }

    uint8_t drain_buf[4096];

    while (lifecycle_.load(std::memory_order_acquire) == ControllerLifecycle::Running) {
        struct pollfd fds[2]{};
        nfds_t nfds = 0;

        if (wake_pipe_[0] >= 0) {
            fds[nfds].fd = wake_pipe_[0];
            fds[nfds].events = POLLIN;
            ++nfds;
        }
        if (nl_fd >= 0) {
            fds[nfds].fd = nl_fd;
            fds[nfds].events = POLLIN;
            ++nfds;
        }

        const int timeout_ms =
            (quality_.load(std::memory_order_acquire) == NetworkQuality::Offline) ? 250 : 1500;

        if (nfds > 0) {
            const int rc = ::poll(fds, nfds, timeout_ms);
            if (rc > 0) {
                for (nfds_t i = 0; i < nfds; ++i) {
                    if ((fds[i].revents & POLLIN) != 0) {
                        while (::read(fds[i].fd, drain_buf, sizeof(drain_buf)) > 0) {
                        }
                    }
                }
            }
        } else {
            std::this_thread::sleep_for(std::chrono::milliseconds(timeout_ms));
        }

        if (lifecycle_.load(std::memory_order_acquire) == ControllerLifecycle::ShuttingDown) {
            break;
        }

        refreshRouteState();
    }

    if (nl_fd >= 0) {
        ::close(nl_fd);
    }
}

} // namespace spotify::network
