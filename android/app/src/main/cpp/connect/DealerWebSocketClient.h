// Replicated from liborbit-jni-spotify.so (Dealer WebSocket client & Connect-State dispatcher):
// - Binary symbols / offsets:
//   - Connect-State 12 dealer topics @ 0xdb4d9c..0xdb50c0 (liborbit-jni-spotify.so):
//     hm://connect-state/v1/cluster (0x37818e -> 0xdb7870),
//     hm://connect-state/v1/connect/volume (0x3475c7 -> 0xdb7b3c),
//     hm://connect-state/v1/connect/logout (0x33fdab -> 0xdb7e88),
//     hm://connect-state/v1/connect/set_backend_metadata (0x390dbd -> 0xdb7f88),
//     hm://connect-state/v1/group/add-device (0x360f80 -> 0xdb8394),
//     hm://connect-state/v1/group/remove-device (0x36def9 -> 0xdb85ec),
//     hm://connect-state/v1/group/delete (0x394683 -> 0xdb8844),
//     hm://connect-state/v1/group/resync (0x37be33 -> 0xdb8a98),
//     hm://connect-state/v1/player/command (0x374ed7 -> 0xdb8ccc),
//     hm://connect-state/v1/ping (0x39e37a -> 0xdb93cc -> {"success": true }),
//     hm://connect-state/v1/connect/proxy_transfer (0x35a05a -> 0xdb9424),
//     hm://connect-state/v1/connect/proxy_wake (0x33fdd0 -> 0xdb9828)
//   - dealerPingTime = 30000ms (0x7530)
//   - Spotify-Connection-Id / X-Spotify-Connection-Id header extraction (0x3af6a4, 0x39c1c3)
//   - Base64 + zlib "compressed" player command envelope & gzip protobuf decompression (0xdba108)
//   - WakeOnLanInfo validation (mac.size() == 6, port < 65536) & 102-byte UDP magic packet
//   - WebSocketConnectRequestUrlAccessToken proto string @ 0x16e9168
// - Java counterparts:
//   - com/spotify/connectivity/AuthenticatedScopeConfiguration.java (dealerPingTime)
//   - com/comscore/util/log/LogLevel.java (NONE = 30000)
//   - com/spotify/connectivity/NativeAuthenticatedScope.java
//   - com/spotify/connectivity/websocket/esperanto/proto/EsWebsocketConnectRequest$WebSocketConnectRequest.java
//   - p199p/l25.java, p199p/C1637b6.java

#ifndef MUSIFY_CONNECT_DEALER_WEB_SOCKET_CLIENT_H_
#define MUSIFY_CONNECT_DEALER_WEB_SOCKET_CLIENT_H_

#include <array>
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstddef>
#include <cstdint>
#include <deque>
#include <functional>
#include <map>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <thread>
#include <vector>

#include "../network/AuthSessionStore.h"
#include "ConnectStateProtos.h"

namespace spotify::connectstate {

namespace json {

struct JsonValue {
    enum class Type : uint8_t {
        kNull = 0,
        kBool = 1,
        kNumber = 2,
        kString = 3,
        kArray = 4,
        kObject = 5,
    };

    using Array = std::vector<JsonValue>;
    using Object = std::map<std::string, JsonValue, std::less<>>;

    Type type{Type::kNull};
    bool bool_value{false};
    double number_value{0.0};
    int64_t int_value{0};
    bool is_integer{false};
    std::string string_value;
    Array array_value;
    Object object_value;

    [[nodiscard]] bool is_null() const { return type == Type::kNull; }
    [[nodiscard]] bool is_bool() const { return type == Type::kBool; }
    [[nodiscard]] bool is_number() const { return type == Type::kNumber; }
    [[nodiscard]] bool is_string() const { return type == Type::kString; }
    [[nodiscard]] bool is_array() const { return type == Type::kArray; }
    [[nodiscard]] bool is_object() const { return type == Type::kObject; }

    [[nodiscard]] const JsonValue* find(std::string_view key) const;
    [[nodiscard]] std::optional<std::string> get_string(std::string_view key) const;
    [[nodiscard]] std::optional<int64_t> get_int64(std::string_view key) const;
    [[nodiscard]] std::optional<uint32_t> get_uint32(std::string_view key) const;
    [[nodiscard]] std::optional<double> get_double(std::string_view key) const;
    [[nodiscard]] std::optional<bool> get_bool(std::string_view key) const;
};

[[nodiscard]] std::optional<JsonValue> parse_json(std::string_view text);
[[nodiscard]] std::string json_escape(std::string_view text);
[[nodiscard]] std::string serialize_json(const JsonValue& value);

}  // namespace json

// Shared base64 / zlib / gzip helpers (used by DealerWebSocketClient & ConnectStateClientImpl).
[[nodiscard]] std::optional<std::vector<uint8_t>> base64_decode(std::string_view input);
[[nodiscard]] std::string base64_encode(const uint8_t* data, size_t len);
[[nodiscard]] std::optional<std::vector<uint8_t>> zlib_decompress(
    const uint8_t* data,
    size_t len,
    size_t max_output_bytes = 16U * 1024U * 1024U);
[[nodiscard]] std::optional<std::vector<uint8_t>> gzip_compress(
    const uint8_t* data,
    size_t len);

// RFC 6455 §4.1 / §5.1-5.8 WebSocket framing, SHA-1 accept verification, and HTTP/1.1 upgrade.
inline constexpr size_t kMaxInboundWebSocketBytes = 16U * 1024U * 1024U;
inline constexpr size_t kMaxWsUpgradeHeaderBytes = 65536U;

enum class Rfc6455Opcode : uint8_t {
    kContinuation = 0x0U,
    kText = 0x1U,
    kBinary = 0x2U,
    kClose = 0x8U,
    kPing = 0x9U,
    kPong = 0xAU,
};

struct Rfc6455Frame {
    Rfc6455Opcode opcode{Rfc6455Opcode::kText};
    std::string payload;
};

enum class Rfc6455ParseResult : uint8_t {
    kNeedMoreData = 0,
    kFrameReady = 1,
    kProtocolError = 2,
};

enum class HttpUpgradeParseResult : uint8_t {
    kNeedMoreData = 0,
    kOk = 1,
    kProtocolError = 2,
};

class Rfc6455FrameParser {
public:
    static constexpr size_t kMaxMessageBytes = kMaxInboundWebSocketBytes;

    void reset();
    void feed(const uint8_t* data, size_t len);
    [[nodiscard]] Rfc6455ParseResult next_frame(Rfc6455Frame& out_frame);
    [[nodiscard]] size_t buffered_bytes() const noexcept;

private:
    enum class Phase : uint8_t {
        kReadBaseHeader = 0,
        kReadExtendedLen16 = 1,
        kReadExtendedLen64 = 2,
        kReadPayload = 3,
    };

    [[nodiscard]] size_t available() const noexcept { return rx_buf_.size() - rx_offset_; }
    void compact_if_needed();
    [[nodiscard]] Rfc6455ParseResult validate_and_prepare_payload();

    std::vector<uint8_t> rx_buf_;
    size_t rx_offset_{0};

    Phase phase_{Phase::kReadBaseHeader};
    bool protocol_error_{false};
    bool current_fin_{false};
    uint8_t current_opcode_{0};
    bool current_is_control_{false};
    uint64_t current_payload_len_{0};
    size_t current_frame_received_{0};

    // Control frame payload buffer (<= 125 bytes), isolated from fragmented data messages.
    std::string control_payload_;

    // Fragmented data message reassembly state (TEXT / BINARY).
    bool has_active_data_msg_{false};
    uint8_t active_data_opcode_{0};
    size_t active_data_bytes_{0};
    std::string data_msg_buffer_;
};

[[nodiscard]] std::array<uint8_t, 20> sha1_digest(std::string_view input);
[[nodiscard]] std::string compute_websocket_accept(std::string_view sec_websocket_key);
[[nodiscard]] HttpUpgradeParseResult parse_websocket_upgrade_response(
    std::string_view buffer,
    std::string_view expected_accept,
    size_t& out_header_bytes);
[[nodiscard]] bool encode_rfc6455_client_frame(
    Rfc6455Opcode opcode,
    const uint8_t* payload,
    size_t payload_len,
    std::vector<uint8_t>& out_bytes);

enum class DealerConnectionState : uint8_t {
    kDisconnected = 0,
    kConnecting = 1,
    kConnected = 2,
    kReconnecting = 3,
};

struct DealerEnvelope {
    std::string type;          // "message", "request", "pong", "ping", "reply"
    std::string uri;           // message uri
    std::string message_ident; // request message_ident
    std::string key;           // request reply key
    std::string method;        // optional HTTP-like method
    std::map<std::string, std::string, std::less<>> headers;
    std::vector<std::string> payload_strings;
    std::optional<json::JsonValue> payload_json;
};

struct DealerPlayerCommand {
    std::string message_ident;
    std::string key;
    uint32_t message_id{0};
    std::string sent_by_device_id;
    std::string endpoint;
    std::string command_json;
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
};

class DealerWebSocketClient {
public:
    static constexpr const char* kDefaultDealerWsUrl = "wss://dealer.g2.spotify.com:443/";
    static constexpr const char* kTopicCluster = "hm://connect-state/v1/cluster";
    static constexpr const char* kTopicVolume = "hm://connect-state/v1/connect/volume";
    static constexpr const char* kTopicLogout = "hm://connect-state/v1/connect/logout";
    static constexpr const char* kTopicBackendMetadata =
        "hm://connect-state/v1/connect/set_backend_metadata";
    static constexpr const char* kTopicPlayerCommand = "hm://connect-state/v1/player/command";
    static constexpr const char* kTopicProxyTransfer =
        "hm://connect-state/v1/connect/proxy_transfer";
    static constexpr const char* kTopicProxyWake =
        "hm://connect-state/v1/connect/proxy_wake";
    static constexpr const char* kTopicGroupAddDevice = "hm://connect-state/v1/group/add-device";
    static constexpr const char* kTopicGroupRemoveDevice =
        "hm://connect-state/v1/group/remove-device";
    static constexpr const char* kTopicGroupDelete = "hm://connect-state/v1/group/delete";
    static constexpr const char* kTopicGroupResync = "hm://connect-state/v1/group/resync";
    static constexpr const char* kTopicPing = "hm://connect-state/v1/ping";
    static constexpr const char* kPusherConnectionsPrefix = "hm://pusher/v1/connections/";

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
    void start();
    void stop();
    void reconnect_now();

    [[nodiscard]] DealerConnectionState connection_state() const;
    [[nodiscard]] std::string connection_id() const;
    [[nodiscard]] bool is_running() const;
    [[nodiscard]] bool is_on_worker_thread() const noexcept;

    // Queues a text frame on the active WebSocket connection (thread-safe).
    bool send_text(std::string text);
    bool send_reply(std::string_view key, bool success);

    // Parses and dispatches an inbound Dealer JSON text frame (exposed for unit tests and
    // used directly by the WebSocket receive loop).
    bool handle_incoming_text_message(std::string_view text);

    // Pure helpers exposed for deterministic validation & unit testing.
    [[nodiscard]] static std::optional<DealerEnvelope> parse_dealer_envelope(std::string_view text);
    [[nodiscard]] static std::optional<DealerPlayerCommand> parse_player_command_envelope(
        const DealerEnvelope& envelope);
    [[nodiscard]] static std::optional<std::vector<uint8_t>> decode_protobuf_payload(
        const DealerEnvelope& envelope);
    [[nodiscard]] static std::string build_connection_url(
        std::string_view base_url,
        std::string_view access_token);

    // Wake-on-LAN validation (mac.size() == 6, port < 65536) and 102-byte magic packet builder.
    [[nodiscard]] static bool validate_wol_info(const WakeOnLanInfo& info);
    [[nodiscard]] static std::optional<std::vector<uint8_t>> build_wol_magic_packet(
        const WakeOnLanInfo& info);
    static bool send_wol_magic_packet(const WakeOnLanInfo& info);

private:
    void worker_loop();
    void set_state(DealerConnectionState state);
    bool process_inbound_text_frame(std::string_view text, bool* out_received_pong = nullptr);
    void dispatch_dealer_envelope(const DealerEnvelope& envelope);
    void open_wakeup_fd();
    void wake_io_loop();
    void close_wakeup_fd();

    network::AuthSessionStore& auth_store_;
    std::string dealer_base_url_;

    mutable std::mutex lifecycle_mutex_;
    mutable std::mutex callbacks_mutex_;
    DealerCallbacks callbacks_;

    mutable std::mutex state_mutex_;
    std::condition_variable state_cv_;
    DealerConnectionState state_{DealerConnectionState::kDisconnected};
    std::string connection_id_;
    bool running_{false};
    bool stop_requested_{false};
    bool reconnect_requested_{false};

    mutable std::mutex outbound_mutex_;
    std::deque<std::string> outbound_queue_;

    mutable std::mutex wakeup_mutex_;
    std::atomic<int> wakeup_fd_{-1};
    std::atomic<std::thread::id> worker_thread_id_{};
    std::thread worker_thread_;
};

}  // namespace spotify::connectstate

#endif  // MUSIFY_CONNECT_DEALER_WEB_SOCKET_CLIENT_H_
