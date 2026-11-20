// ============================================================================
// Modular Dealer JSON & Message Envelope Parser
// Replicated from `liborbit-jni-spotify.so` (arm64):
// - Connect-State 12 dealer topics @ 0xdb4d9c..0xdb50c0
// - Connect-Group 2 dealer topics:
//   - `hm://connect-group/v1/group-data-event` (0x39aac6 @ 0xd9f810)
//   - `hm://connect-group/v1/group-device-volume-event` (0x34e81a @ 0xd9f85c)
// - `target_alias_id` extraction (0x3476f4 @ 0xdb8ff0)
// - `Spotify-Connection-Id` / `X-Spotify-Connection-Id` extraction (0x3af6a4, 0x39c1c3)
// - Base64 + zlib "compressed" command envelope & gzip protobuf decompression (0xdba108)
// ============================================================================

#ifndef MUSIFY_CONNECT_DEALER_DEALER_MESSAGE_PARSER_H_
#define MUSIFY_CONNECT_DEALER_DEALER_MESSAGE_PARSER_H_

#include <cstdint>
#include <functional>
#include <map>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "../ConnectStateProtos.h"

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

    [[nodiscard]] bool is_null() const noexcept { return type == Type::kNull; }
    [[nodiscard]] bool is_bool() const noexcept { return type == Type::kBool; }
    [[nodiscard]] bool is_number() const noexcept { return type == Type::kNumber; }
    [[nodiscard]] bool is_string() const noexcept { return type == Type::kString; }
    [[nodiscard]] bool is_array() const noexcept { return type == Type::kArray; }
    [[nodiscard]] bool is_object() const noexcept { return type == Type::kObject; }

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

struct DealerEnvelope {
    std::string type;           // "message", "request", "pong", "ping", "reply"
    std::string uri;            // message uri
    std::string message_ident;  // request message_ident
    std::string key;            // request reply key
    std::string method;         // optional HTTP-like method
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
    uint32_t target_alias_id{0};
    bool has_target_alias_id{false};
};

class DealerMessageParser {
public:
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
    static constexpr const char* kTopicGroupDataEvent = "hm://connect-group/v1/group-data-event";
    static constexpr const char* kTopicGroupDeviceVolumeEvent =
        "hm://connect-group/v1/group-device-volume-event";
    static constexpr const char* kPusherConnectionsPrefix = "hm://pusher/v1/connections/";

    [[nodiscard]] static std::optional<DealerEnvelope> parse_dealer_envelope(
        std::string_view text);

    [[nodiscard]] static std::optional<DealerPlayerCommand> parse_player_command_envelope(
        const DealerEnvelope& envelope);

    [[nodiscard]] static std::optional<std::vector<uint8_t>> decode_protobuf_payload(
        const DealerEnvelope& envelope);

    [[nodiscard]] static std::optional<std::string> extract_connection_id(
        const DealerEnvelope& envelope);

    [[nodiscard]] static bool decode_group_data_event_payload(
        const DealerEnvelope& envelope,
        GroupDataEvent& out_event);

    [[nodiscard]] static bool decode_group_device_volume_event_payload(
        const DealerEnvelope& envelope,
        GroupDeviceVolumeEvent& out_event);
};

}  // namespace spotify::connectstate

#endif  // MUSIFY_CONNECT_DEALER_DEALER_MESSAGE_PARSER_H_
