// ============================================================================
// Replicated from liborbit-jni-spotify.so (ConnectSubsystem bidirectional
// engine orchestrator + IRemotePlaybackDelegate bridge):
// - Binary symbols / offsets (`liborbit-jni-spotify.so` arm64):
//   - DealerWebSocketClient (0xdb4d9c..0xdb50c0),
//   - ConnectStateClientImpl (0xdc1b80..0xdc6310),
//   - PutStateBackoff (0xdc5e8c..0xdc6310),
//   - VolumeThrottler (0xdca2d4..0xdca6fc),
//   - ConnectDevicesImpl (0xdac4e0..0xdbddaa),
//   - TransferManager (0xdf16e8..0xdf4cf8),
//   - GroupDataEnricher (0xd9f810..0xda1818),
//   - StateRestoreController (`LoadLastTransferBlob` @ 0xdb4758, 5000ms @ 0xdb9e10),
//   - LocalDeviceReporter (0xdc3b90..0xdc42bc, 0xdcf304..0xdd232c, 0xdedec0..0xdeffff),
//   - ConnectStateImpl::onClusterChanged (0xdb6740..0xdb7060, stale check 0xdb6984..0xdb69f4 -> 0xdf0074),
//   - ConnectProxyPlayer (0x162da80: becomeInactive @ 0xdaaa2c, updateRemotePlayerState @ 0xdaaab4),
//   - ConnectManager::sendPutState (0xdb2088..0xdb26f8), PutState race guard (0xdb2e84..0xdb3154),
//   - ConnectManager::onClusterUpdate (0xdb3260..0xdb329c), adjustTimestamps (0xdb28c0..0xdb2968),
//   - `player.arch = "3"` Dual-Chain Architecture (0x10873e8):
//     - Object A / Chain 1 (0x108a878) -> Connect `[ConnectState + 0x378]` (0xd94764),
//       base `toPlayerState` (0x10d77c0..0x10d8f80), `restrictions` (0xf85e5c),
//       `playback_quality` (0x10d7f00..0x10d8078),
//     - Object B / Chain 2 (0x108ad38, ExtendedMetadataDecorator 0x10da59c -> 0x10dc214) -> Esperanto (0x11281d0),
//   - `ListPlayerConfig` full-load clip limits (0x127f4b0: prev=20, 0x127f4c8: next=80 -> 0x108a0c8 -> ListState 0x10abac4),
//   - `spirc_version = "3.2.6"` (0xd92cb8), `metadata_map` (`debug_level`/`device_address_mask` @ 0xdb81d4..0xdb81fc),
//   - enable_player_state_stripping (0xdb232c..0xdb24dc, 0x3e0778, 0x341adf, 0x449e08, 0x449e20, 0x1582d50),
//   - encodeProvidedTrack (0xdc6bc0..0xdc6c94), ListPlayer delimiter metadata (0xe61068..0xe61560),
//   - ConnectApiImpl outbound remote command forward (0xda66f0..0xda96ac).
// - Esperanto service contracts:
//   - ConnectService (.so @ 0x3a20cd), ConnectVolumeService (.so @ 0x343b80),
//     DodoService (.so @ 0x36a9f8)
// - Java / Esperanto counterparts:
//   - com/spotify/core/corefullimpl/NativeFullAuthenticatedScopeImpl.java
//   - p199p/s77.java, p199p/c8k.java, p199p/C2086nd.java, p199p/a0f1.java, p199p/lw51.java
// ============================================================================

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
#include <string_view>
#include <thread>
#include <unordered_map>
#include <utility>
#include <vector>

#include "../network/AuthSessionStore.h"
#include "../network/NativeHttpClient.h"
#include "../player/ContextPlayerImpl.h"
#include "../player/RemotePlaybackDelegate.h"
#include "ConnectDevicesImpl.h"
#include "ConnectStateClientImpl.h"
#include "ConnectStateProtos.h"
#include "DealerWebSocketClient.h"
#include "GroupDataEnricher.h"
#include "LocalDeviceReporter.h"
#include "StateRestoreController.h"
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

class ConnectSubsystem final
    : public player::ContextPlayerImpl::PlayerStateListener,
      public player::IRemotePlaybackDelegate {
public:
    static constexpr uint32_t kMaxVolumeSteps = 65535;
    static constexpr uint32_t kDefaultVolumeStep = 4096;
    static constexpr int kStopInactiveTimeoutMs = 1500;
    static constexpr size_t kPutStateMaxPrevTracks = 20;      // liborbit ListPlayerConfig 0x127f4b0 (0x14)
    static constexpr size_t kPutStateMaxNextTracks = 80;      // liborbit ListPlayerConfig 0x127f4c8 (0x50)
    static constexpr size_t kPutStateStrippedTrackCount = 2;  // liborbit 0xdb2434..0xdb2480

    static constexpr int32_t kStartOk = 0;
    static constexpr int32_t kStartInvalidArgs = -1;
    static constexpr int32_t kStartDecodeError = -2;
    static constexpr int32_t kStartMissingIdentity = -3;

    using StateListener = std::function<void()>;
    using VolumeListener = std::function<void(const ConnectVolumeSnapshot&)>;
    using LocalVolumeListener = std::function<void(uint32_t volume, LocalVolumeReason reason)>;
    using DiagnosticCallback = std::function<void(const std::string& json_payload)>;

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
        std::string dealer_base_url = DealerWebSocketClient::kDefaultDealerWsUrl,
        LocalDeviceReporter::ZeroconfGetFn zeroconf_get_fn = {});

    ~ConnectSubsystem() override;

    ConnectSubsystem(const ConnectSubsystem&) = delete;
    ConnectSubsystem& operator=(const ConnectSubsystem&) = delete;

    // Fail-fast start entry points:
    //   0  = started (or already running)
    //  -1  = null/empty device_info_bytes or invalid length
    //  -2  = DeviceInfo protobuf decode failure
    //  -3  = missing mandatory device_id, name, or client_id
    int32_t start(const uint8_t* device_info_bytes, int32_t len);
    int32_t start(const std::vector<uint8_t>& device_info_bytes);
    int32_t start(const DeviceInfo& initial_device);

    // Idempotent teardown: sends bounded (1.5s) PUT /devices/{id}/inactive if local active,
    // stops Dealer/LocalDeviceReporter/StateRestoreController/GroupDataEnricher/TransferManager,
    // clears connection_id, and clears remote mirrored playback state.
    void stop();
    [[nodiscard]] bool is_running() const;

    // Wave 3 FFI lifecycle, connectivity, discovery, volume & diagnostics hooks (#47 sec 2).
    int32_t set_endpoints(std::string_view spclient_base_url, std::string_view dealer_ws_url);
    int32_t reconnect(int32_t reason_code);
    void set_network_available(bool is_available);
    int32_t update_nsd_services(std::string_view services_json_utf8);
    int32_t set_local_volume(
        uint32_t volume_0_to_65535,
        int32_t volume_steps,
        int32_t reason_code);
    int32_t set_local_volume(
        uint32_t volume_0_to_65535,
        int32_t volume_steps,
        LocalVolumeReason reason);
    void set_diagnostic_callback(DiagnosticCallback callback);

    // ContextPlayerImpl::PlayerStateListener override (invoked outside player mutex).
    void on_player_state_changed(
        const player::ContextPlayerImpl::ConnectPlayerSnapshot& snapshot,
        bool track_changed) override;

    // player::IRemotePlaybackDelegate overrides (#47 sec 3).
    [[nodiscard]] bool is_remote_active() const override;
    [[nodiscard]] std::string active_remote_device_id() const override;
    bool forward_player_command(
        const std::string& endpoint,
        const std::string& payload_json,
        const std::string& intent_id = {}) override;

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

    [[nodiscard]] GroupDataEnricher& group_enricher() noexcept { return group_enricher_; }
    [[nodiscard]] const GroupDataEnricher& group_enricher() const noexcept {
        return group_enricher_;
    }

    [[nodiscard]] StateRestoreController& state_restore_controller() noexcept {
        return state_restore_;
    }
    [[nodiscard]] const StateRestoreController& state_restore_controller() const noexcept {
        return state_restore_;
    }

    [[nodiscard]] LocalDeviceReporter& local_device_reporter() noexcept {
        return local_device_reporter_;
    }
    [[nodiscard]] const LocalDeviceReporter& local_device_reporter() const noexcept {
        return local_device_reporter_;
    }

    // Converts a local ContextPlayerImpl snapshot into a Connect wire PlayerState.
    [[nodiscard]] static PlayerState build_connect_player_state(
        const player::ContextPlayerImpl::ConnectPlayerSnapshot& snapshot,
        bool strip_player_state = false,
        int64_t clock_skew_ms = 0);

    // Converts a remote Cluster into a MirroredRemotePlaybackState for ContextPlayerImpl.
    [[nodiscard]] static MirroredRemotePlaybackState build_mirrored_remote_state(
        const Cluster& cluster,
        std::optional<int64_t> fallback_clock_skew_ms = std::nullopt);

private:
    enum class WorkerTaskKind : uint8_t {
        kPutState = 0,
        kSetDeviceInactive = 1,
        kProxyTransfer = 2,
    };

    struct QueuedPutStateTask {
        WorkerTaskKind kind{WorkerTaskKind::kPutState};
        PutStateReason reason{PutStateReason::UNKNOWN_PUT_STATE_REASON};
        bool only_write_player_state{false};
        bool wake_devices{false};
        std::optional<player::ContextPlayerImpl::ConnectPlayerSnapshot> snapshot;
        std::string proxy_transfer_target_device_id;
    };

    void setup_dealer_callbacks();
    void enqueue_put_state(QueuedPutStateTask task);
    void purge_pending_local_player_state_tasks();
    PutStateResult execute_put_state_task(const QueuedPutStateTask& task);
    void put_state_worker_loop();
    PutStateRequest assemble_put_state_request(const QueuedPutStateTask& task);

    void handle_remote_volume_command(const SetVolumeCommand& cmd);
    void handle_remote_logout_command(const LogoutCommand& cmd);
    void handle_remote_backend_metadata_command(const SetBackendMetadataCommand& cmd);
    void handle_cluster_changed(const Cluster& cluster);
    void handle_restore_transfer_blob(const CachedTransferBlob& blob);
    void schedule_stop_from_logout();
    void join_pending_logout_stop_thread();
    void notify_state_listeners();
    void notify_volume_listeners();
    void notify_local_volume_listeners(uint32_t volume, LocalVolumeReason reason);
    void emit_diagnostic(std::string_view source, std::string_view event, std::string_view detail);

    player::ContextPlayerImpl& player_;
    ConnectStateClientImpl client_;
    ConnectDevicesImpl devices_;
    TransferManager transfer_manager_;
    GroupDataEnricher group_enricher_;
    StateRestoreController state_restore_;
    LocalDeviceReporter local_device_reporter_;
    DealerWebSocketClient dealer_;

    mutable std::mutex lifecycle_mutex_;
    bool needs_teardown_{false};
    mutable std::mutex logout_thread_mutex_;
    std::thread logout_stop_thread_;

    mutable std::mutex state_mutex_;
    bool running_{false};
    bool local_active_{false};
    std::string last_cluster_active_device_id_;
    int64_t clock_skew_ms_{0};
    bool last_needs_state_updates_{false};
    bool last_need_full_player_state_{true};
    uint64_t transfer_cluster_listener_id_{0};
    uint64_t started_playing_at_ms_{0};
    bool was_playing_{false};
    std::string local_volume_reason_{"initial"};
    std::unordered_map<std::string, uint32_t> group_device_volumes_;
    std::optional<uint32_t> preferred_incarnation_login_type_;

    mutable std::mutex cb_mutex_;
    std::function<void(uint32_t)> local_volume_callback_;
    std::function<void()> logout_callback_;
    DiagnosticCallback diagnostic_callback_;
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
