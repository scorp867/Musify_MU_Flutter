#pragma once

#include "NativeHttpClient.h"

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <list>
#include <memory>
#include <mutex>
#include <string>
#include <string_view>
#include <thread>

namespace spotify::network {

/// 4-Tier Real-Time Audio Priority Model for all C++ network operations.
/// Lower numeric value = higher scheduling priority.
enum class RequestPriority : uint8_t {
    /// Active 64 KiB audio stream blocks (HttpRangeStreamCache) and active Ogg head files (HeadFileManager).
    P0_PlaybackCritical = 0,
    /// Widevine DRM license/provisioning (WidevineLicenseClient) and active track StorageResolveClient.
    P1_PlaybackSetup = 1,
    /// Active/selected track metadata resolution (TrackInfoProvider interactive lookup).
    P2_InteractiveMetadata = 2,
    /// Background lookahead queue batch metadata resolution and passive pre-warming.
    P3_BackgroundBatch = 3,
};

/// Behavior when a network request is enqueued while the device has no active internet route.
enum class OfflinePolicy : uint8_t {
    /// Hold the request in the priority queue without hammering libcurl/DNS, and automatically
    /// dispatch in strict P0 -> P3 order the instant connectivity returns (or wake in <1ms if canceled).
    WaitForOnline = 0,
    /// Reject immediately if the device is currently offline.
    FailFastOffline = 1,
};

/// High-level execution intent for content delivery and stream acquisition.
enum class AcquisitionIntent : uint8_t {
    /// Active user playback / seek: high priority + WaitForOnline when uncached.
    InteractivePlayback = 0,
    /// Background pre-warm for upcoming queue item: P3_BackgroundBatch + FailFastOffline.
    BackgroundPrefetch = 1,
};

/// Real-time adaptive network quality state derived from kernel routing + rolling HTTP RTT.
enum class NetworkQuality : uint8_t {
    /// Online with healthy latency (EMA RTT <= 1500 ms). Max concurrency = 6 (up to 3 P2/P3).
    Fast = 0,
    /// Online with degraded latency (EMA RTT > 1500 ms or recent timeout).
    /// Max concurrency = 4; P2/P3 throttled to 1 slot; 3 fast-lane slots reserved for P0/P1.
    Slow = 1,
    /// No active IPv4/IPv6 kernel route. Zero libcurl dispatches; WaitForOnline requests parked.
    Offline = 2,
};

/// Outcome of an HTTP transfer reported back to a TrafficPermit for RTT & quality state updates.
enum class TransferOutcome : uint8_t {
    Success = 0,
    TransportFailure = 1,
    TimedOut = 2,
};

/// Explicit lifecycle state machine of a TrafficPermit RAII lease.
enum class PermitLifecycleState : uint8_t {
    Unacquired = 0,
    GrantedActive = 1,
    CompletedWithTelemetry = 2,
    ReleasedSlot = 3,
};

/// Kernel route status observed by the AF_NETLINK route monitor.
enum class RouteStatus : uint8_t {
    Offline = 0,
    Online = 1,
};

class NativeTrafficController;

/// Move-only RAII execution lease granted by NativeTrafficController.
/// Automatically releases its concurrency slot and records round-trip telemetry on destruction.
class TrafficPermit {
public:
    TrafficPermit() noexcept = default;

    TrafficPermit(
        NativeTrafficController* controller,
        RequestPriority priority,
        std::chrono::steady_clock::time_point acquired_at) noexcept
        : controller_(controller),
          priority_(priority),
          acquired_at_(acquired_at),
          state_(controller != nullptr ? PermitLifecycleState::GrantedActive
                                       : PermitLifecycleState::Unacquired) {}

    ~TrafficPermit() noexcept {
        release();
    }

    TrafficPermit(const TrafficPermit&) = delete;
    TrafficPermit& operator=(const TrafficPermit&) = delete;

    TrafficPermit(TrafficPermit&& other) noexcept
        : controller_(other.controller_),
          priority_(other.priority_),
          acquired_at_(other.acquired_at_),
          state_(other.state_) {
        other.controller_ = nullptr;
        other.state_ = PermitLifecycleState::ReleasedSlot;
    }

    TrafficPermit& operator=(TrafficPermit&& other) noexcept {
        if (this != &other) {
            release();
            controller_ = other.controller_;
            priority_ = other.priority_;
            acquired_at_ = other.acquired_at_;
            state_ = other.state_;
            other.controller_ = nullptr;
            other.state_ = PermitLifecycleState::ReleasedSlot;
        }
        return *this;
    }

    [[nodiscard]] explicit operator bool() const noexcept {
        return isGranted();
    }

    [[nodiscard]] bool isGranted() const noexcept {
        return state_ == PermitLifecycleState::GrantedActive ||
               state_ == PermitLifecycleState::CompletedWithTelemetry;
    }

    [[nodiscard]] PermitLifecycleState state() const noexcept {
        return state_;
    }

    /// Explicitly records the HTTP transfer outcome for adaptive RTT / Slow-network detection
    /// and releases the concurrency slot immediately.
    void complete(TransferOutcome outcome) noexcept;

    /// Releases the concurrency slot if still held.
    void release() noexcept;

private:
    NativeTrafficController* controller_{nullptr};
    RequestPriority priority_{RequestPriority::P3_BackgroundBatch};
    std::chrono::steady_clock::time_point acquired_at_{};
    PermitLifecycleState state_{PermitLifecycleState::Unacquired};
};

/// Centralized C++ network traffic controller, priority queue, and Linux kernel route monitor.
class NativeTrafficController {
public:
    static constexpr int64_t kSlowNetworkRttThresholdMs = 1500;
    static constexpr size_t kFastMaxConcurrency = 6;
    static constexpr size_t kFastMaxLowPriorityConcurrency = 3;
    static constexpr size_t kSlowMaxConcurrency = 4;
    static constexpr size_t kSlowMaxLowPriorityConcurrency = 1;

    [[nodiscard]] static NativeTrafficController& instance();

    NativeTrafficController();
    ~NativeTrafficController();

    NativeTrafficController(const NativeTrafficController&) = delete;
    NativeTrafficController& operator=(const NativeTrafficController&) = delete;

    /// Acquires an execution permit for a network request according to its priority and offline policy.
    /// Blocks in priority order until a concurrency slot is available (and until the device is online
    /// when `offline_policy == OfflinePolicy::WaitForOnline`), or returns an empty `TrafficPermit`
    /// immediately if canceled or if `offline_policy == OfflinePolicy::FailFastOffline` while offline.
    [[nodiscard]] TrafficPermit acquirePermit(
        RequestPriority priority,
        OfflinePolicy offline_policy = OfflinePolicy::WaitForOnline,
        std::string tag = {},
        const std::atomic<bool>* cancel_flag = nullptr,
        const CancelPredicate& cancel_pred = nullptr);

    /// Parks the caller thread until the device has an active internet route, or returns false
    /// immediately if `cancel_flag` / `cancel_pred` fires.
    [[nodiscard]] bool waitForOnline(
        const std::atomic<bool>* cancel_flag = nullptr,
        const CancelPredicate& cancel_pred = nullptr);

    /// Cancels all queued waiters whose tag starts with `tag_prefix` and wakes all waiting threads.
    void cancelByTagPrefix(std::string_view tag_prefix) noexcept;

    /// Wakes all threads currently waiting in `acquirePermit()` or `waitForOnline()` so they
    /// re-evaluate their cancellation predicates immediately.
    void notifyAllWaiters() noexcept;

    /// Records a completed HTTP transfer's round-trip time and outcome to adapt concurrency limits.
    void reportTransferOutcome(int64_t rtt_ms, TransferOutcome outcome) noexcept;

    /// Forces an immediate kernel route re-probe and wakes queued WaitForOnline requests if online.
    RouteStatus refreshRouteState() noexcept;

    [[nodiscard]] NetworkQuality networkQuality() const noexcept {
        return quality_.load(std::memory_order_acquire);
    }

    [[nodiscard]] bool isOnline() const noexcept {
        return quality_.load(std::memory_order_acquire) != NetworkQuality::Offline;
    }

    [[nodiscard]] int64_t rollingRttMs() const noexcept {
        return rolling_rtt_ms_.load(std::memory_order_acquire);
    }

private:
    friend class TrafficPermit;

    enum class WaiterState : uint8_t {
        Queued = 0,
        SlotGranted = 1,
        CanceledByTag = 2,
    };

    enum class ControllerLifecycle : uint8_t {
        Running = 0,
        ShuttingDown = 1,
    };

    struct Waiter {
        uint64_t sequence{0};
        RequestPriority priority{RequestPriority::P3_BackgroundBatch};
        OfflinePolicy offline_policy{OfflinePolicy::WaitForOnline};
        std::string tag;
        WaiterState state{WaiterState::Queued};
    };

    void releaseSlot(
        RequestPriority priority,
        std::chrono::steady_clock::time_point acquired_at,
        PermitLifecycleState prior_state) noexcept;

    void routeMonitorLoop() noexcept;
    void applyRouteStatusLocked(RouteStatus status) noexcept;
    void dispatchWaitersLocked() noexcept;
    [[nodiscard]] bool canGrantSlotLocked(RequestPriority priority) const noexcept;

    mutable std::mutex mu_;
    std::condition_variable cv_;
    std::list<std::shared_ptr<Waiter>> wait_queue_;
    uint64_t next_sequence_{1};

    size_t active_total_{0};
    size_t active_low_priority_{0}; // P2 + P3 active count

    std::atomic<NetworkQuality> quality_{NetworkQuality::Fast};
    std::atomic<int64_t> rolling_rtt_ms_{180};
    std::atomic<uint32_t> consecutive_timeouts_{0};

    std::atomic<ControllerLifecycle> lifecycle_{ControllerLifecycle::Running};
    int wake_pipe_[2]{-1, -1};
    std::thread monitor_thread_;
};

} // namespace spotify::network
