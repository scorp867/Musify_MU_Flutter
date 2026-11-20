// ============================================================================
// Replicated Spotify Connect StateRestoreController (`LoadLastTransferBlob`)
// Sources (`liborbit-jni-spotify.so` arm64):
// - Cluster.transfer_data & transfer_data_timestamp caching @ 0xdb1e78, 0xdf0ba8
// - `LoadLastTransferBlob` recovery path @ 0xdb4758, 0xdb9ef8
// - 5000ms disconnect recovery timer @ 0xdb9e10
// ============================================================================

#ifndef MUSIFY_CONNECT_STATE_RESTORE_CONTROLLER_H_
#define MUSIFY_CONNECT_STATE_RESTORE_CONTROLLER_H_

#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <functional>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <vector>

#include "ConnectStateProtos.h"

namespace spotify::connectstate {

struct CachedTransferBlob {
    std::vector<uint8_t> transfer_data;
    uint64_t transfer_data_timestamp{0};
    std::string active_device_id;
    int64_t cluster_changed_timestamp_ms{0};
};

class StateRestoreController {
public:
    static constexpr int64_t kDefaultRecoveryDelayMs = 5000;

    using Clock = std::function<std::chrono::steady_clock::time_point()>;
    using RestoreCallback = std::function<void(const CachedTransferBlob&)>;

    explicit StateRestoreController(
        int64_t recovery_delay_ms = kDefaultRecoveryDelayMs,
        Clock clock = {});

    ~StateRestoreController();

    StateRestoreController(const StateRestoreController&) = delete;
    StateRestoreController& operator=(const StateRestoreController&) = delete;

    void start();
    void stop();
    void reset();

    void set_restore_callback(RestoreCallback callback);

    // Caches the latest non-empty `Cluster.transfer_data` blob and timestamp.
    void on_cluster_update(const Cluster& cluster);

    // Arms the 5000ms recovery timer if the local device was active and a cached
    // transfer blob is available (`liborbit` @ 0xdb9e10).
    void on_dealer_disconnected(bool local_was_active);

    // Cancels any pending recovery timer when Dealer reconnects or playback moves on.
    void on_dealer_reconnected();
    void cancel_pending_recovery();

    [[nodiscard]] std::optional<CachedTransferBlob> cached_transfer_blob() const;
    [[nodiscard]] bool is_recovery_armed() const;

private:
    void worker_loop();
    [[nodiscard]] std::chrono::steady_clock::time_point now() const;

    int64_t recovery_delay_ms_{kDefaultRecoveryDelayMs};
    Clock clock_;

    mutable std::mutex mutex_;
    std::condition_variable cv_;
    RestoreCallback restore_callback_;
    std::optional<CachedTransferBlob> cached_blob_;

    bool worker_running_{false};
    bool stop_requested_{false};
    bool recovery_armed_{false};
    uint64_t recovery_generation_{0};
    std::chrono::steady_clock::time_point recovery_deadline_{};
    std::thread worker_thread_;
};

}  // namespace spotify::connectstate

#endif  // MUSIFY_CONNECT_STATE_RESTORE_CONTROLLER_H_
