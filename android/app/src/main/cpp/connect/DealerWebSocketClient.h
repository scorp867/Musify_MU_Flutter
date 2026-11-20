// ============================================================================
// Replicated Spotify Dealer WebSocket Client (Slim Orchestrator)
// Sources (`liborbit-jni-spotify.so` arm64):
// - Connect-State 12 dealer topics @ 0xdb4d9c..0xdb50c0:
//   hm://connect-state/v1/{cluster,connect/volume,connect/logout,
//     connect/set_backend_metadata,group/add-device,group/remove-device,
//     group/delete,group/resync,player/command,ping,
//     connect/proxy_transfer,connect/proxy_wake}
// - Connect-Group 2 dealer topics:
//   hm://connect-group/v1/group-data-event (0x39aac6 @ 0xd9f810),
//   hm://connect-group/v1/group-device-volume-event (0x34e81a @ 0xd9f85c)
// - dealerPingTime = 30000ms (0x7530)
// - WebSocket auth error refresh @ 0xb99358 ("websocket: received authentication error, refreshing token")
// - WebSocket connectivity & foreground wakeup @ 0xb98884, 0xb9893c (`ConnectConnectivityListener` @ 0xdb9af4)
// - Upgrade headers: `es_websocket_connect_request.proto` @ 0x5a6068 -> `p199p/l25.java`, `p199p/C1637b6.java`
// ============================================================================

#ifndef MUSIFY_CONNECT_DEALER_WEB_SOCKET_CLIENT_H_
#define MUSIFY_CONNECT_DEALER_WEB_SOCKET_CLIENT_H_

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstddef>
#include <cstdint>
#include <deque>
#include <functional>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <thread>
#include <vector>

#include "../network/AuthSessionStore.h"
#include "ConnectStateProtos.h"
#include "dealer/DealerMessageParser.h"
#include "dealer/WakeOnLanSender.h"
#include "dealer/WsCodec.h"

namespace spotify::connectstate {

enum class DealerConnectionState : uint8_t {
    kDisconnected = 0,
    kConnecting = 1,
    kConnected = 2,
    kReconnecting = 3,
};

struct DealerCallbacks {
    std::function<void(DealerConnectionState)> on_connection_state_changed;
    std::function<void(const std::string& connection_id)> on_connection_id;
    std::function<void(const ClusterUpdate&)> on_cluster_update;
    std::function<bool(const DealerPlayerCommand&)> on_player_command;
    std::function<void(const SetVolumeCommand&)> on_set_volume;
    std::function<void(const LogoutCommand&)> on_logout;
    std::function<void(const SetBackendMetadataCommand&)> on_set_backend_metadata;
    std::function<void(const ProxyTransferCommand&)> on_proxy_transfer;
    std::function<void(const ProxyWakeCommand&)> on_proxy_wake;
    std::function<void(const AddDeviceToGroupCommand&)> on_add_device_to_group;
    std::function<void(const RemoveDeviceFromGroupCommand&)> on_remove_device_from_group;
    std::function<void(const DeleteGroupCommand&)> on_delete_group;
    std::function<void(const ResyncGroupDataCommand&)> on_resync_group_data;
    std::function<void(const GroupDataEvent&)> on_group_data_event;
    std::function<void(const GroupDeviceVolumeEvent&)> on_group_device_volume_event;
    std::function<void(std::string_view event_type, std::string_view detail)> on_diagnostic_event;
};

class DealerWebSocketClient {
public:
    static constexpr const char* kDefaultDealerWsUrl = "wss://dealer.g2.spotify.com:443/";
    static constexpr const char* kTopicCluster = DealerMessageParser::kTopicCluster;
    static constexpr const char* kTopicVolume = DealerMessageParser::kTopicVolume;
    static constexpr const char* kTopicLogout = DealerMessageParser::kTopicLogout;
    static constexpr const char* kTopicBackendMetadata =
        DealerMessageParser::kTopicBackendMetadata;
    static constexpr const char* kTopicPlayerCommand = DealerMessageParser::kTopicPlayerCommand;
    static constexpr const char* kTopicProxyTransfer = DealerMessageParser::kTopicProxyTransfer;
    static constexpr const char* kTopicProxyWake = DealerMessageParser::kTopicProxyWake;
    static constexpr const char* kTopicGroupAddDevice = DealerMessageParser::kTopicGroupAddDevice;
    static constexpr const char* kTopicGroupRemoveDevice =
        DealerMessageParser::kTopicGroupRemoveDevice;
    static constexpr const char* kTopicGroupDelete = DealerMessageParser::kTopicGroupDelete;
    static constexpr const char* kTopicGroupResync = DealerMessageParser::kTopicGroupResync;
    static constexpr const char* kTopicPing = DealerMessageParser::kTopicPing;
    static constexpr const char* kTopicGroupDataEvent = DealerMessageParser::kTopicGroupDataEvent;
    static constexpr const char* kTopicGroupDeviceVolumeEvent =
        DealerMessageParser::kTopicGroupDeviceVolumeEvent;
    static constexpr const char* kPusherConnectionsPrefix =
        DealerMessageParser::kPusherConnectionsPrefix;

    // Exact dealerPingTime = 30000ms (0x7530) from liborbit-jni-spotify.so.
    static constexpr int64_t kDealerPingIntervalMs = 30000;
    static constexpr int64_t kDealerPongTimeoutMs = 15000;
    static constexpr int64_t kInitialReconnectDelayMs = 1000;
    static constexpr int64_t kMaxReconnectDelayMs = 30000;

    explicit DealerWebSocketClient(
        network::AuthSessionStore& auth_store,
        std::string dealer_base_url = kDefaultDealerWsUrl);

    ~DealerWebSocketClient();

    DealerWebSocketClient(const DealerWebSocketClient&) = delete;
    DealerWebSocketClient& operator=(const DealerWebSocketClient&) = delete;

    void set_callbacks(DealerCallbacks callbacks);
    void set_dealer_base_url(std::string dealer_base_url);
    [[nodiscard]] std::string dealer_base_url() const;

    void set_network_available(bool is_available);
    [[nodiscard]] bool is_network_available() const;

    void start();
    void stop();
    void force_reconnect(int32_t reason_code);
    void reconnect_now();

    [[nodiscard]] DealerConnectionState connection_state() const;
    [[nodiscard]] std::string connection_id() const;
    [[nodiscard]] bool is_running() const;
    [[nodiscard]] bool is_on_worker_thread() const noexcept;

    // Queues a text frame on the active WebSocket connection (thread-safe).
    bool send_text(std::string text);
    bool send_reply(std::string_view key, bool success);

    // Parses and dispatches an inbound Dealer JSON text frame.
    bool handle_incoming_text_message(std::string_view text);

    // Pure helpers delegating to connect/dealer/* (kept for testability & API continuity).
    [[nodiscard]] static std::optional<DealerEnvelope> parse_dealer_envelope(std::string_view text);
    [[nodiscard]] static std::optional<DealerPlayerCommand> parse_player_command_envelope(
        const DealerEnvelope& envelope);
    [[nodiscard]] static std::optional<std::vector<uint8_t>> decode_protobuf_payload(
        const DealerEnvelope& envelope);
    [[nodiscard]] static std::string build_connection_url(
        std::string_view base_url,
        std::string_view access_token);
    [[nodiscard]] static std::string build_profile_ws_url(
        std::string_view base_url,
        std::string_view access_token,
        const network::ClientHeaderProfile& profile);
    [[nodiscard]] static std::string build_upgrade_request(
        std::string_view request_target,
        std::string_view host_header,
        std::string_view sec_websocket_key,
        std::string_view access_token,
        const network::ClientHeaderProfile& profile);

    [[nodiscard]] static bool validate_wol_info(const WakeOnLanInfo& info);
    [[nodiscard]] static std::optional<std::vector<uint8_t>> build_wol_magic_packet(
        const WakeOnLanInfo& info);
    static bool send_wol_magic_packet(const WakeOnLanInfo& info);

private:
    void worker_loop();
    void on_auth_session_updated(const network::AuthCredentials& creds);
    void set_state(DealerConnectionState state);
    void emit_diagnostic(std::string_view event_type, std::string_view detail);
    bool process_inbound_text_frame(std::string_view text, bool* out_received_pong = nullptr);
    void dispatch_dealer_envelope(const DealerEnvelope& envelope);
    void open_wakeup_fd();
    void wake_io_loop();
    void close_wakeup_fd();

    network::AuthSessionStore& auth_store_;

    mutable std::mutex lifecycle_mutex_;
    mutable std::mutex callbacks_mutex_;
    DealerCallbacks callbacks_;

    mutable std::mutex state_mutex_;
    std::condition_variable state_cv_;
    std::string dealer_base_url_;
    DealerConnectionState state_{DealerConnectionState::kDisconnected};
    std::string connection_id_;
    bool network_available_{true};
    bool running_{false};
    bool stop_requested_{false};
    bool reconnect_requested_{false};
    bool reset_backoff_requested_{false};
    uint64_t last_auth_generation_{0};
    std::string last_access_token_;

    uint64_t auth_listener_id_{0};

    mutable std::mutex outbound_mutex_;
    std::deque<std::string> outbound_queue_;

    mutable std::mutex wakeup_mutex_;
    std::atomic<int> wakeup_fd_{-1};
    std::atomic<std::thread::id> worker_thread_id_{};
    std::thread worker_thread_;
};

}  // namespace spotify::connectstate

#endif  // MUSIFY_CONNECT_DEALER_WEB_SOCKET_CLIENT_H_
