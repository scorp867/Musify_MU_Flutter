// Replicated from liborbit-jni-spotify.so (ConnectSubsystem bidirectional engine orchestrator):
// - Binary symbols / offsets (`liborbit-jni-spotify.so`):
//   - Internal C++ wiring connecting DealerWebSocketClient (0xdb4d9c..0xdb50c0),
//     ConnectStateClientImpl (0xdc1b80..0xdc6310), PutStateBackoff (0xdc5e8c..0xdc6310),
//     VolumeThrottler (0xdca2d4..0xdca6fc), ConnectDevicesImpl (0xdac4e0..0xdbddaa),
//     TransferManager (0xdf16e8..0xdf4cf8), and ContextPlayerImpl local playback state.
// - Esperanto service contracts (`liborbit-jni-spotify.so` / `liborbit-jni-spotify_memdump.so`):
//   - ConnectService (.so @ 0x3a20cd), ConnectVolumeService (.so @ 0x343b80,
//     LocalVolumeResponse @ .so 0x5a24d5 / memdump 0x36ac39),
//     DodoService (.so @ 0x36a9f8, dodos_messages.proto @ .so 0x5a1dd0 / memdump 0x36a536)
// - Java / Esperanto counterparts:
//   - com/spotify/core/corefullimpl/NativeFullAuthenticatedScopeImpl.java
//   - p199p/s77.java, p199p/c8k.java, p199p/C2086nd.java, p199p/a0f1.java, p199p/lw51.java

#ifndef MUSIFY_CONNECT_CONNECT_SUBSYSTEM_H_
#define MUSIFY_CONNECT_CONNECT_SUBSYSTEM_H_

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <deque>
#include <functional>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>

#include "../network/AuthSessionStore.h"
#include "../network/NativeHttpClient.h"
#include "../player/ContextPlayerImpl.h"
#include "ConnectDevicesImpl.h"
#include "ConnectStateClientImpl.h"
#include "ConnectStateProtos.h"
#include "DealerWebSocketClient.h"
#include "TransferManager.h"

namespace spotify::connectstate {

enum class LocalVolumeReason : uint32_t {
    kUser = 0,
    kSystem = 1,
};

struct ConnectVolumeSnapshot {
    uint32_t volume{0};
    std::string active_device_connect_state_identifier;
    std::unordered_map<std::string, uint32_t> group_device_volumes;
    uint32_t local_volume{65535};
    std::string local_reason;
};

class ConnectSubsystem final : public player::ContextPlayerImpl::PlayerStateListener {
public:
    static constexpr uint32_t kMaxVolumeSteps = 65535;
    static constexpr uint32_t kDefaultVolumeStep = 4096;

    using StateListener = std::function<void()>;
    using VolumeListener = std::function<void(const ConnectVolumeSnapshot&)>;
    using LocalVolumeListener = std::function<void(uint32_t volume, LocalVolumeReason reason)>;

    ConnectSubsystem(
        player::ContextPlayerImpl& player,
        network::AuthSessionStore& auth_store,
        network::NativeHttpClient& http_client,
        std::string spclient_base_url = ConnectStateClientImpl::kDefaultSpclientBaseUrl,
        std::string dealer_base_url = DealerWebSocketClient::kDefaultDealerWsUrl);

    // Injectable HTTP transport constructor for deterministic end-to-end native testing.
    ConnectSubsystem(
        player::ContextPlayerImpl& player,
        network::AuthSessionStore& auth_store,
        ConnectStateClientImpl::TransportFn transport_fn,
        std::string spclient_base_url = ConnectStateClientImpl::kDefaultSpclientBaseUrl,
        std::string dealer_base_url = DealerWebSocketClient::kDefaultDealerWsUrl);

    ~ConnectSubsystem() override;

    ConnectSubsystem(const ConnectSubsystem&) = delete;
    ConnectSubsystem& operator=(const ConnectSubsystem&) = delete;

    void start(const DeviceInfo& initial_device);
    void stop();
    [[nodiscard]] bool is_running() const;

    // ContextPlayerImpl::PlayerStateListener override (invoked outside player mutex).
    void on_player_state_changed(
        const player::ContextPlayerImpl::ConnectPlayerSnapshot& snapshot,
        bool track_changed) override;

    // Listener registration forwarded cleanly to ConnectDevicesImpl.
    uint64_t add_cluster_listener(ConnectDevicesImpl::ClusterListener listener);
    void remove_cluster_listener(uint64_t listener_id);

    uint64_t add_dodo_listener(ConnectDevicesImpl::DodoListener listener);
    void remove_dodo_listener(uint64_t listener_id);

    void set_local_volume_callback(std::function<void(uint32_t volume)> callback);
    void set_logout_callback(std::function<void()> callback);

    uint64_t add_state_listener(StateListener listener);
    void remove_state_listener(uint64_t listener_id);

    uint64_t add_volume_listener(VolumeListener listener);
    void remove_volume_listener(uint64_t listener_id);

    uint64_t add_local_volume_listener(LocalVolumeListener listener);
    void remove_local_volume_listener(uint64_t listener_id);

    // ConnectService M1 -> M2 surface.
    TransferOutcome transfer(
        const std::string& target_device_id,
        const TransferOptionsParams& options = {},
        const std::vector<std::string>& interaction_ids = {},
        bool dodo = false);

    TransferOutcome pull(const TransferOptionsParams& options = {});

    AckHttpResult send_player_command(
        const std::string& target_device_id,
        const std::string& command_json,
        const std::string& intent_id = {});

    AckHttpResult rename(
        const std::string& target_device_id,
        const std::string& new_name);

    SimpleHttpResult logout(const std::string& target_device_id = {});

    PutStateResult notify_audio_route_changed(
        const std::vector<AudioOutputDeviceInfo>& outputs);

    void set_preferred_incarnation(
        const std::string& device_id,
        std::optional<uint32_t> preferred_login_type = std::nullopt);
    [[nodiscard]] std::optional<uint32_t> preferred_login_type() const;

    AckHttpResult add_device_to_group(
        const std::string& target_device_id,
        const std::string& group_device_id);

    AckHttpResult remove_device_from_group(
        const std::string& target_device_id,
        const std::string& group_device_id);

    AckHttpResult delete_group(const std::string& group_device_id);

    [[nodiscard]] bool is_local_active() const;
    [[nodiscard]] bool is_being_activated(std::string_view device_id) const;

    [[nodiscard]] bool has_received_cluster_update_after_backend_connection() const;
    bool perform_discovery();
    PutStateResult refresh_cluster();
    SimpleHttpResult wake_sleeping_cluster_devices();

    // ConnectVolumeService M1 -> M2 surface.
    AckHttpResult volume_set(
        uint32_t volume,
        const std::string& group_device_id = {});
    AckHttpResult volume_up(
        uint32_t step = kDefaultVolumeStep,
        const std::string& group_device_id = {});
    AckHttpResult volume_down(
        uint32_t step = kDefaultVolumeStep,
        const std::string& group_device_id = {});
    [[nodiscard]] ConnectVolumeSnapshot current_volume_snapshot() const;

    // DodoService M1 -> M2 surface.
    [[nodiscard]] std::vector<SingleDodo> list_dodos() const;
    ClusterHttpResult switch_to_dodo(const std::string& cs_id);
    ClusterHttpResult create_new_dodo(const std::string& name = {});
    ClusterHttpResult end_dodo();

    // Subsystem component accessors.
    [[nodiscard]] ConnectDevicesImpl& devices() noexcept { return devices_; }
    [[nodiscard]] const ConnectDevicesImpl& devices() const noexcept { return devices_; }

    [[nodiscard]] ConnectStateClientImpl& client() noexcept { return client_; }
    [[nodiscard]] const ConnectStateClientImpl& client() const noexcept { return client_; }

    [[nodiscard]] TransferManager& transfer_manager() noexcept { return transfer_manager_; }
    [[nodiscard]] const TransferManager& transfer_manager() const noexcept {
        return transfer_manager_;
    }

    [[nodiscard]] VolumeThrottler& volume_throttler() noexcept {
        return client_.volume_throttler();
    }
    [[nodiscard]] const VolumeThrottler& volume_throttler() const noexcept {
        return client_.volume_throttler();
    }

    [[nodiscard]] DealerWebSocketClient& dealer() noexcept { return dealer_; }
    [[nodiscard]] const DealerWebSocketClient& dealer() const noexcept { return dealer_; }

    // Converts a local ContextPlayerImpl snapshot into a Connect wire PlayerState.
    [[nodiscard]] static PlayerState build_connect_player_state(
        const player::ContextPlayerImpl::ConnectPlayerSnapshot& snapshot);

private:
    struct QueuedPutStateTask {
        PutStateReason reason{PutStateReason::UNKNOWN_PUT_STATE_REASON};
        bool only_write_player_state{false};
        bool wake_devices{false};
        std::optional<player::ContextPlayerImpl::ConnectPlayerSnapshot> snapshot;
    };

    void setup_dealer_callbacks();
    void enqueue_put_state(QueuedPutStateTask task);
    PutStateResult execute_put_state_task(const QueuedPutStateTask& task);
    void put_state_worker_loop();
    PutStateRequest assemble_put_state_request(const QueuedPutStateTask& task);

    void handle_remote_volume_command(const SetVolumeCommand& cmd);
    void handle_remote_logout_command(const LogoutCommand& cmd);
    void handle_remote_backend_metadata_command(const SetBackendMetadataCommand& cmd);
    void handle_cluster_changed(const Cluster& cluster);
    void schedule_stop_from_logout();
    void join_pending_logout_stop_thread();
    void notify_state_listeners();
    void notify_volume_listeners();
    void notify_local_volume_listeners(uint32_t volume, LocalVolumeReason reason);

    player::ContextPlayerImpl& player_;
    ConnectStateClientImpl client_;
    ConnectDevicesImpl devices_;
    TransferManager transfer_manager_;
    DealerWebSocketClient dealer_;

    mutable std::mutex lifecycle_mutex_;
    bool needs_teardown_{false};
    mutable std::mutex logout_thread_mutex_;
    std::thread logout_stop_thread_;

    mutable std::mutex state_mutex_;
    bool running_{false};
    bool local_active_{false};
    std::string last_cluster_active_device_id_;
    uint64_t transfer_cluster_listener_id_{0};
    uint32_t put_state_message_seq_{1};
    uint64_t started_playing_at_ms_{0};
    bool was_playing_{false};
    std::string local_volume_reason_{"initial"};
    std::unordered_map<std::string, uint32_t> group_device_volumes_;
    std::optional<uint32_t> preferred_incarnation_login_type_;

    mutable std::mutex cb_mutex_;
    std::function<void(uint32_t)> local_volume_callback_;
    std::function<void()> logout_callback_;
    uint64_t next_listener_id_{1};
    std::vector<std::pair<uint64_t, StateListener>> state_listeners_;
    std::vector<std::pair<uint64_t, VolumeListener>> volume_listeners_;
    std::vector<std::pair<uint64_t, LocalVolumeListener>> local_volume_listeners_;

    mutable std::mutex queue_mutex_;
    std::condition_variable queue_cv_;
    std::deque<QueuedPutStateTask> put_state_queue_;
    bool worker_stop_requested_{false};
    std::thread put_state_worker_;
};

}  // namespace spotify::connectstate

#endif  // MUSIFY_CONNECT_CONNECT_SUBSYSTEM_H_
