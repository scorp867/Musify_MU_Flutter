// 1:1 Replicated Spotify Esperanto Wire Codecs (ConnectService, ConnectVolumeService, DodoService)
// Sources:
// - `liborbit-jni-spotify.so` `.rodata` FileDescriptorProto offsets:
//   `5714450` (`dodos_messages.proto`), `5715106` (`volume_messages.proto`),
//   `5957570` (`connect_messages.proto`), `5968226` (`common_messages.proto`)
// - `liborbit-jni-spotify_memdump.so` offsets `0x3a79bc`, `0x36a7bc`, `0x3a5024`, `0x36a536`, `0x36de24`
// - Decompiled Java: `p199p/s77.java`, `p199p/n8d.java`, `p199p/a0f1.java`, `p199p/lw51.java`, `p199p/C2086nd.java`

#ifndef MUSIFY_CONNECT_CONNECT_ESPERANTO_PROTOS_H_
#define MUSIFY_CONNECT_CONNECT_ESPERANTO_PROTOS_H_

#include <cstddef>
#include <cstdint>
#include <cstring>
#include <map>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "../ProtobufWireHelper.h"
#include "ConnectStateProtos.h"

namespace spotify::connectstate::esperanto {

// ---------------------------------------------------------------------------
// Wire Primitives (delegated strictly to ProtobufWireHelper)
// ---------------------------------------------------------------------------

inline void write_tag(std::vector<uint8_t>& out, uint32_t field, uint32_t wire_type) {
    spotify::player::encode_varint(
        out, (static_cast<uint64_t>(field) << 3U) | (wire_type & 0x07U));
}

inline void write_uint64(std::vector<uint8_t>& out, uint32_t field, uint64_t value) {
    write_tag(out, field, 0);
    spotify::player::encode_varint(out, value);
}

inline void write_uint32(std::vector<uint8_t>& out, uint32_t field, uint32_t value) {
    write_uint64(out, field, static_cast<uint64_t>(value));
}

inline void write_int64(std::vector<uint8_t>& out, uint32_t field, int64_t value) {
    write_uint64(out, field, static_cast<uint64_t>(value));
}

inline void write_int32(std::vector<uint8_t>& out, uint32_t field, int32_t value) {
    write_uint64(out, field, static_cast<uint64_t>(static_cast<int64_t>(value)));
}

inline void write_bool(std::vector<uint8_t>& out, uint32_t field, bool value) {
    write_uint64(out, field, value ? 1ULL : 0ULL);
}

inline void write_string(std::vector<uint8_t>& out, uint32_t field, const std::string& value) {
    write_tag(out, field, 2);
    spotify::player::encode_varint(out, static_cast<uint64_t>(value.size()));
    out.insert(out.end(), value.begin(), value.end());
}

inline bool read_length_delimited(
    const uint8_t*& p,
    const uint8_t* end,
    const uint8_t*& slice_ptr,
    size_t& slice_len) {
    uint64_t len = 0;
    if (!spotify::player::decode_varint(p, end, len)) {
        return false;
    }
    if (!spotify::player::has_bytes(p, end, len)) {
        return false;
    }
    slice_ptr = p;
    slice_len = static_cast<size_t>(len);
    p += slice_len;
    return true;
}

inline bool read_string(const uint8_t*& p, const uint8_t* end, std::string& out) {
    const uint8_t* slice = nullptr;
    size_t len = 0;
    if (!read_length_delimited(p, end, slice, len)) {
        return false;
    }
    out.assign(reinterpret_cast<const char*>(slice), len);
    return true;
}

inline bool read_bool(const uint8_t*& p, const uint8_t* end, bool& out) {
    uint64_t raw = 0;
    if (!spotify::player::decode_varint(p, end, raw)) {
        return false;
    }
    out = (raw != 0);
    return true;
}

inline bool read_uint32(const uint8_t*& p, const uint8_t* end, uint32_t& out) {
    uint64_t raw = 0;
    if (!spotify::player::decode_varint(p, end, raw)) {
        return false;
    }
    out = static_cast<uint32_t>(raw);
    return true;
}

inline bool read_int32(const uint8_t*& p, const uint8_t* end, int32_t& out) {
    uint64_t raw = 0;
    if (!spotify::player::decode_varint(p, end, raw)) {
        return false;
    }
    uint32_t bits = static_cast<uint32_t>(raw);
    std::memcpy(&out, &bits, sizeof(out));
    return true;
}

inline bool read_int64(const uint8_t*& p, const uint8_t* end, int64_t& out) {
    uint64_t raw = 0;
    if (!spotify::player::decode_varint(p, end, raw)) {
        return false;
    }
    std::memcpy(&out, &raw, sizeof(out));
    return true;
}

inline bool decode_empty_message(const uint8_t* data, size_t size) {
    if (data == nullptr) return size == 0;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(p, end, tag)) return false;
        if ((tag >> 3U) == 0U) return false;
        const uint32_t wire = static_cast<uint32_t>(tag & 0x07U);
        if (!spotify::player::skip_field(p, end, wire)) return false;
    }
    return true;
}

// ---------------------------------------------------------------------------
// common_messages.proto
// ---------------------------------------------------------------------------

enum class Status : uint32_t {
    OK = 0,
    NOT_FOUND = 1,
    INVALID_ARGUMENTS = 2,
    BACKEND_FAILURE = 3,
    UNIMPLEMENTED = 4,
};

struct LoggingParams {
    std::optional<int64_t> command_initiated_time;
    std::optional<int64_t> command_received_time;
    std::vector<std::string> page_instance_ids;
    std::vector<std::string> interaction_ids;
    std::optional<std::string> command_id;
    std::optional<std::string> feature_identifier;
};

struct StatusResponse {
    Status status{Status::OK};
};

inline std::vector<uint8_t> encode_logging_params(const LoggingParams& msg) {
    std::vector<uint8_t> out;
    if (msg.command_initiated_time.has_value()) {
        write_int64(out, 1, *msg.command_initiated_time);
    }
    if (msg.command_received_time.has_value()) {
        write_int64(out, 2, *msg.command_received_time);
    }
    for (const auto& id : msg.page_instance_ids) {
        write_string(out, 3, id);
    }
    for (const auto& id : msg.interaction_ids) {
        write_string(out, 4, id);
    }
    if (msg.command_id.has_value()) {
        write_string(out, 5, *msg.command_id);
    }
    if (msg.feature_identifier.has_value()) {
        write_string(out, 6, *msg.feature_identifier);
    }
    return out;
}

inline bool decode_logging_params(const uint8_t* data, size_t size, LoggingParams& out) {
    if (data == nullptr && size > 0) {
        return false;
    }
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(p, end, tag)) {
            return false;
        }
        const uint32_t field = static_cast<uint32_t>(tag >> 3U);
        const uint32_t wire = static_cast<uint32_t>(tag & 0x07U);
        if (field == 1 && wire == 0) {
            int64_t val = 0;
            if (!read_int64(p, end, val)) return false;
            out.command_initiated_time = val;
        } else if (field == 2 && wire == 0) {
            int64_t val = 0;
            if (!read_int64(p, end, val)) return false;
            out.command_received_time = val;
        } else if (field == 3 && wire == 2) {
            std::string val;
            if (!read_string(p, end, val)) return false;
            out.page_instance_ids.push_back(std::move(val));
        } else if (field == 4 && wire == 2) {
            std::string val;
            if (!read_string(p, end, val)) return false;
            out.interaction_ids.push_back(std::move(val));
        } else if (field == 5 && wire == 2) {
            std::string val;
            if (!read_string(p, end, val)) return false;
            out.command_id = std::move(val);
        } else if (field == 6 && wire == 2) {
            std::string val;
            if (!read_string(p, end, val)) return false;
            out.feature_identifier = std::move(val);
        } else {
            if (!spotify::player::skip_field(p, end, wire)) return false;
        }
    }
    return true;
}

inline std::vector<uint8_t> encode_status_response(Status status) {
    std::vector<uint8_t> out;
    if (status != Status::OK) {
        write_uint32(out, 1, static_cast<uint32_t>(status));
    }
    return out;
}

inline std::vector<uint8_t> encode_status_response(const StatusResponse& msg) {
    return encode_status_response(msg.status);
}

inline bool decode_status_response(const uint8_t* data, size_t size, StatusResponse& out) {
    if (data == nullptr && size > 0) {
        return false;
    }
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(p, end, tag)) return false;
        const uint32_t field = static_cast<uint32_t>(tag >> 3U);
        const uint32_t wire = static_cast<uint32_t>(tag & 0x07U);
        if (field == 1 && wire == 0) {
            uint32_t val = 0;
            if (!read_uint32(p, end, val)) return false;
            out.status = static_cast<Status>(val);
        } else {
            if (!spotify::player::skip_field(p, end, wire)) return false;
        }
    }
    return true;
}

// ---------------------------------------------------------------------------
// spotify.connect.group (group.proto)
// ---------------------------------------------------------------------------

enum class GroupingStatus : uint32_t {
    UNKNOWN_GROUPING_STATUS = 0,
    GROUPED = 1,
    GROUPABLE = 2,
    GROUPING = 3,
};

struct GroupCapabilities {
    uint32_t max_devices{0};
};

struct GroupDeviceCapabilities {
    bool removable{false};
    bool removal_dissolves_group{false};
};

struct GroupDeviceIdentifiers {
    std::string group_device_identifier;
    std::optional<std::string> local_identifier;
    std::optional<std::string> deduplication_id;
    std::optional<std::string> connect_state_identifier;
};

struct GroupDeviceVolume {
    uint32_t volume{0};
    int32_t volume_steps{0};
};

struct GroupDevice {
    std::optional<GroupDeviceIdentifiers> identifiers;
    std::string name;
    std::string type;
    std::string model_display_name;
    std::optional<GroupDeviceCapabilities> capabilities;
    GroupingStatus grouping_status{GroupingStatus::UNKNOWN_GROUPING_STATUS};
    std::optional<GroupDeviceVolume> volume;
};

struct GroupData {
    std::vector<GroupDevice> devices;
    std::optional<GroupCapabilities> capabilities;
};

inline std::vector<uint8_t> encode_group_capabilities(const GroupCapabilities& msg) {
    std::vector<uint8_t> out;
    if (msg.max_devices != 0) {
        write_uint32(out, 1, msg.max_devices);
    }
    return out;
}

inline std::vector<uint8_t> encode_group_device_capabilities(
    const GroupDeviceCapabilities& msg) {
    std::vector<uint8_t> out;
    if (msg.removable) write_bool(out, 1, true);
    if (msg.removal_dissolves_group) write_bool(out, 2, true);
    return out;
}

inline std::vector<uint8_t> encode_group_device_identifiers(
    const GroupDeviceIdentifiers& msg) {
    std::vector<uint8_t> out;
    if (!msg.group_device_identifier.empty()) {
        write_string(out, 1, msg.group_device_identifier);
    }
    if (msg.local_identifier.has_value()) {
        write_string(out, 2, *msg.local_identifier);
    }
    if (msg.deduplication_id.has_value()) {
        write_string(out, 3, *msg.deduplication_id);
    }
    if (msg.connect_state_identifier.has_value()) {
        write_string(out, 4, *msg.connect_state_identifier);
    }
    return out;
}

inline std::vector<uint8_t> encode_group_device_volume(const GroupDeviceVolume& msg) {
    std::vector<uint8_t> out;
    if (msg.volume != 0) write_uint32(out, 1, msg.volume);
    if (msg.volume_steps != 0) write_int32(out, 2, msg.volume_steps);
    return out;
}

inline std::vector<uint8_t> encode_group_device(const GroupDevice& msg) {
    std::vector<uint8_t> out;
    if (msg.identifiers.has_value()) {
        spotify::player::encode_submessage_field(
            out, 1, encode_group_device_identifiers(*msg.identifiers));
    }
    if (!msg.name.empty()) write_string(out, 2, msg.name);
    if (!msg.type.empty()) write_string(out, 3, msg.type);
    if (!msg.model_display_name.empty()) write_string(out, 4, msg.model_display_name);
    if (msg.capabilities.has_value()) {
        spotify::player::encode_submessage_field(
            out, 5, encode_group_device_capabilities(*msg.capabilities));
    }
    if (msg.grouping_status != GroupingStatus::UNKNOWN_GROUPING_STATUS) {
        write_uint32(out, 6, static_cast<uint32_t>(msg.grouping_status));
    }
    if (msg.volume.has_value()) {
        spotify::player::encode_submessage_field(
            out, 7, encode_group_device_volume(*msg.volume));
    }
    return out;
}

inline std::vector<uint8_t> encode_group_data(const GroupData& msg) {
    std::vector<uint8_t> out;
    for (const auto& d : msg.devices) {
        spotify::player::encode_submessage_field(out, 1, encode_group_device(d));
    }
    if (msg.capabilities.has_value()) {
        spotify::player::encode_submessage_field(
            out, 2, encode_group_capabilities(*msg.capabilities));
    }
    return out;
}

// ---------------------------------------------------------------------------
// connect_messages.proto
// ---------------------------------------------------------------------------

enum class LoginType : uint32_t {
    CONNECT = 0,
    CAST = 1,
};

enum class ProtocolChoiceReason : uint32_t {
    PROTOCOL_CHOICE_REASON_DEFAULT = 0,
    PROTOCOL_CHOICE_REASON_USER_SELECTED = 1,
    PROTOCOL_CHOICE_REASON_STREAM_EXPANSION = 2,
    PROTOCOL_CHOICE_REASON_ANDROID_TV = 3,
    PROTOCOL_CHOICE_REASON_TAP_DEVICE = 4,
};

enum class OutputPeripheralCategory : uint32_t {
    UNKNOWN = 0,
    CAR = 1,
    HEADPHONES = 2,
    SPEAKER = 3,
    WEARABLE = 4,
    GLASSES = 5,
    APP = 6,
};

enum class OutputPeripheralConnectionType : uint32_t {
    UNKNOWN = 0,
    WIRED = 1,
    CAR_PROJECTED = 2,
    BLUETOOTH = 3,
    AIRPLAY = 4,
    BUILT_IN_SPEAKER = 5,
};

enum class GroupError : uint32_t {
    UNKNOWN_GROUP_ERROR = 0,
    TIMEOUT_GROUP_ERROR = 1,
    INTERNAL_GROUP_ERROR = 2,
    GROUP_DEVICE_NOT_FOUND = 3,
    MAX_NUMBER_OF_DEVICES_REACHED = 4,
    TARGET_NOT_FOUND = 5,
    NOT_IMPLEMENTED = 6,
    BUSY = 13,
};

enum class RemoveGroupError : uint32_t {
    UNKNOWN_REMOVE_ERROR = 0,
    TIMEOUT_REMOVE_ERROR = 1,
    INTERNAL_REMOVE_ERROR = 2,
    REMOVE_GROUP_DEVICE_NOT_FOUND = 3,
    REMOVE_TARGET_NOT_FOUND = 4,
    REMOVE_NOT_IMPLEMENTED = 5,
    REMOVE_BUSY = 12,
};

enum class DeleteGroupError : uint32_t {
    UNKNOWN_DELETE_ERROR = 0,
    TIMEOUT_DELETE_ERROR = 1,
    INTERNAL_DELETE_ERROR = 2,
    DELETE_TARGET_NOT_FOUND = 3,
    DELETE_NOT_IMPLEMENTED = 4,
    DELETE_BUSY = 11,
};

enum class InstallSpotifyState : uint32_t {
    CONNECTING = 0,
    PAIRING = 1,
    SUBSCRIBING = 2,
    LAUNCHING_APP_STORE = 3,
    WAITING_FOR_APP_TO_BE_INSTALLED = 4,
    LAUNCHING_THE_APP = 5,
    SUCCESS = 6,
    UNKNOWN_ERROR = 100,
    DEVICE_NOT_FOUND = 101,
    DEVICE_NOT_SUPPORTED = 102,
    TIMEOUT = 103,
    CANCELLED = 104,
};

struct OutputPeripheral {
    std::optional<std::string> name;
    std::optional<std::string> brand;
    std::optional<std::string> model;
    std::optional<OutputPeripheralCategory> category;
    std::optional<OutputPeripheralConnectionType> connection_type;
};

struct StateRequest {
    bool show_offline_devices_in_core{false};
    bool show_offline_amazon_devices_as_online{false};
    bool include_local_device{false};
    bool exclude_non_local_devices{false};
    bool include_user_match_unauthenticated_devices{false};
};

struct StateHifi {
    bool fully_supported{false};
    bool user_eligible{false};
    bool device_supported{false};
};

struct StateIncarnation {
    LoginType login_type{LoginType::CONNECT};
    std::string identifier;
    bool preferred{false};
    ProtocolChoiceReason preferred_reason{ProtocolChoiceReason::PROTOCOL_CHOICE_REASON_DEFAULT};
    std::string connect_state_identifier;
};

struct StateDevice {
    bool is_self{false};
    std::string local_identifier;
    std::string deduplication_id;
    std::string connect_state_identifier;
    std::string name;
    std::string type;
    std::string state;
    bool is_disabled{false};
    bool is_active{false};
    bool is_being_activated{false};
    bool is_zeroconf{false};
    bool is_webapp{false};
    bool is_local{false};
    bool is_group{false};
    bool is_offline{false};
    bool is_social_connect{false};
    uint64_t creation_time_ms{0};
    uint32_t volume{0};
    std::optional<StateHifi> hifi;
    std::string license;
    bool supports_on_demand{false};
    bool supports_volume{false};
    bool supports_logout{false};
    bool supports_rename{false};
    bool supports_alarm{false};
    bool is_voice_enabled{false};
    bool is_newly_discovered{false};
    std::vector<std::string> supported_media_types;
    std::string brand_display_name;
    std::string model_display_name;
    std::optional<uint32_t> volume_steps;
    std::optional<std::string> capabilities;
    std::vector<StateIncarnation> incarnations;
    std::optional<uint32_t> alias_id;
    std::optional<bool> supports_dj;
    std::string library_version;
    std::optional<OutputPeripheral> output_peripheral;
    std::string local_ip;
    uint32_t discovery_method{0};
    bool supports_remote_sleep_timer{false};
    bool supports_playlist_mixing{false};
    std::optional<GroupData> group_data;
    bool is_public{false};
    bool supports_remote_audio_quality_control{false};
    std::optional<bool> is_authenticated_with_current_user;
    bool supports_zephyr{false};
    bool supports_gapless{false};
    bool supports_crossfade{false};
};

struct StateResponse {
    bool is_running{false};
    bool is_connected{false};
    std::string local_name;
    bool should_use_local_playback{false};
    std::vector<StateDevice> devices;
    bool is_active{false};
    bool is_active_on_same_device{false};
    bool is_synced_with_backend{false};
};

struct TransferRequest {
    std::optional<LoggingParams> logging_params;
    std::string connect_device_identifier;
    std::optional<bool> dodo;
};

struct PullRequest {
    std::optional<LoggingParams> logging_params;
};

struct LogoutRequest {
    std::string connect_device_identifier;
};

struct NotifyAudioRouteChangedRequest {
    std::optional<std::string> audio_output_device_name;
    std::optional<OutputPeripheralConnectionType> audio_output_device_connection_type;
    std::optional<std::string> audio_output_device_brand;
    std::optional<std::string> audio_output_device_model;
    std::optional<OutputPeripheralCategory> audio_output_device_category;
};

struct SetPreferredIncarnationRequest {
    std::string device_id;
    std::optional<LoginType> preferred_login_type;
    std::optional<LoggingParams> logging_params;
};

struct SendCommandRequest {
    std::optional<LoggingParams> logging_params;
    std::string connect_device_identifier;
    std::string command_json;
};

struct SendCommandResponse {
    int32_t context_player_error{0};
};

struct RenameRequest {
    std::string device_id;
    std::string new_name;
};

struct AddDeviceToGroupRequest {
    std::string connect_device_identifier;
    std::string group_device_identifier;
    std::optional<LoggingParams> logging_params;
};

struct AddDeviceToGroupResponse {
    bool success{false};
    std::optional<GroupError> error;
};

struct RemoveDeviceFromGroupRequest {
    std::string connect_device_identifier;
    std::string group_device_identifier;
    std::optional<LoggingParams> logging_params;
};

struct RemoveDeviceFromGroupResponse {
    bool success{false};
    std::optional<RemoveGroupError> error;
};

struct DeleteGroupRequest {
    std::string connect_device_identifier;
    std::optional<LoggingParams> logging_params;
};

struct DeleteGroupResponse {
    bool success{false};
    std::optional<DeleteGroupError> error;
};

struct ClusterUpdateAfterBackendConnectionResponse {
    bool has_received_cluster_update_after_backend_connection{false};
};

struct InstallSpotifyRequest {
    std::string connect_device_identifier;
    std::optional<uint32_t> port;
    std::optional<LoggingParams> logging_params;
};

struct InstallSpotifyStatusUpdate {
    InstallSpotifyState current_state{InstallSpotifyState::CONNECTING};
};

inline std::vector<uint8_t> encode_output_peripheral(const OutputPeripheral& msg) {
    std::vector<uint8_t> out;
    if (msg.name.has_value()) write_string(out, 1, *msg.name);
    if (msg.brand.has_value()) write_string(out, 2, *msg.brand);
    if (msg.model.has_value()) write_string(out, 3, *msg.model);
    if (msg.category.has_value()) {
        write_uint32(out, 4, static_cast<uint32_t>(*msg.category));
    }
    if (msg.connection_type.has_value()) {
        write_uint32(out, 5, static_cast<uint32_t>(*msg.connection_type));
    }
    return out;
}

inline std::vector<uint8_t> encode_state_hifi(const StateHifi& msg) {
    std::vector<uint8_t> out;
    if (msg.fully_supported) write_bool(out, 1, true);
    if (msg.user_eligible) write_bool(out, 2, true);
    if (msg.device_supported) write_bool(out, 3, true);
    return out;
}

inline std::vector<uint8_t> encode_state_incarnation(const StateIncarnation& msg) {
    std::vector<uint8_t> out;
    if (msg.login_type != LoginType::CONNECT) {
        write_uint32(out, 1, static_cast<uint32_t>(msg.login_type));
    }
    if (!msg.identifier.empty()) write_string(out, 2, msg.identifier);
    if (msg.preferred) write_bool(out, 3, true);
    if (msg.preferred_reason != ProtocolChoiceReason::PROTOCOL_CHOICE_REASON_DEFAULT) {
        write_uint32(out, 4, static_cast<uint32_t>(msg.preferred_reason));
    }
    if (!msg.connect_state_identifier.empty()) {
        write_string(out, 5, msg.connect_state_identifier);
    }
    return out;
}

inline std::vector<uint8_t> encode_state_device(const StateDevice& d) {
    std::vector<uint8_t> out;
    if (d.is_self) write_bool(out, 1, true);
    if (!d.local_identifier.empty()) write_string(out, 2, d.local_identifier);
    if (!d.deduplication_id.empty()) write_string(out, 3, d.deduplication_id);
    if (!d.connect_state_identifier.empty()) {
        write_string(out, 4, d.connect_state_identifier);
    }
    if (!d.name.empty()) write_string(out, 5, d.name);
    if (!d.type.empty()) write_string(out, 6, d.type);
    if (!d.state.empty()) write_string(out, 7, d.state);
    if (d.is_disabled) write_bool(out, 8, true);
    if (d.is_active) write_bool(out, 9, true);
    if (d.is_being_activated) write_bool(out, 10, true);
    if (d.is_zeroconf) write_bool(out, 11, true);
    if (d.is_webapp) write_bool(out, 12, true);
    // Tag 13 reserved.
    if (d.is_local) write_bool(out, 14, true);
    if (d.is_group) write_bool(out, 15, true);
    if (d.is_offline) write_bool(out, 16, true);
    if (d.is_social_connect) write_bool(out, 17, true);
    if (d.creation_time_ms != 0) write_uint64(out, 18, d.creation_time_ms);
    if (d.volume != 0) write_uint32(out, 19, d.volume);
    if (d.hifi.has_value()) {
        spotify::player::encode_submessage_field(out, 20, encode_state_hifi(*d.hifi));
    }
    if (!d.license.empty()) write_string(out, 21, d.license);
    if (d.supports_on_demand) write_bool(out, 22, true);
    if (d.supports_volume) write_bool(out, 23, true);
    if (d.supports_logout) write_bool(out, 24, true);
    if (d.supports_rename) write_bool(out, 25, true);
    if (d.supports_alarm) write_bool(out, 26, true);
    if (d.is_voice_enabled) write_bool(out, 27, true);
    if (d.is_newly_discovered) write_bool(out, 28, true);
    for (const auto& mt : d.supported_media_types) {
        write_string(out, 29, mt);
    }
    if (!d.brand_display_name.empty()) write_string(out, 30, d.brand_display_name);
    if (!d.model_display_name.empty()) write_string(out, 31, d.model_display_name);
    if (d.volume_steps.has_value()) write_uint32(out, 32, *d.volume_steps);
    if (d.capabilities.has_value()) write_string(out, 33, *d.capabilities);
    for (const auto& inc : d.incarnations) {
        spotify::player::encode_submessage_field(out, 34, encode_state_incarnation(inc));
    }
    if (d.alias_id.has_value()) write_uint32(out, 35, *d.alias_id);
    if (d.supports_dj.has_value()) write_bool(out, 36, *d.supports_dj);
    if (!d.library_version.empty()) write_string(out, 37, d.library_version);
    if (d.output_peripheral.has_value()) {
        spotify::player::encode_submessage_field(
            out, 38, encode_output_peripheral(*d.output_peripheral));
    }
    if (!d.local_ip.empty()) write_string(out, 39, d.local_ip);
    if (d.discovery_method != 0) write_uint32(out, 40, d.discovery_method);
    if (d.supports_remote_sleep_timer) write_bool(out, 41, true);
    if (d.supports_playlist_mixing) write_bool(out, 42, true);
    if (d.group_data.has_value()) {
        spotify::player::encode_submessage_field(out, 43, encode_group_data(*d.group_data));
    }
    if (d.is_public) write_bool(out, 44, true);
    if (d.supports_remote_audio_quality_control) write_bool(out, 45, true);
    if (d.is_authenticated_with_current_user.has_value()) {
        write_bool(out, 46, *d.is_authenticated_with_current_user);
    }
    if (d.supports_zephyr) write_bool(out, 47, true);
    if (d.supports_gapless) write_bool(out, 48, true);
    if (d.supports_crossfade) write_bool(out, 49, true);
    return out;
}

inline std::vector<uint8_t> encode_state_response(const StateResponse& msg) {
    std::vector<uint8_t> out;
    if (msg.is_running) write_bool(out, 1, true);
    if (msg.is_connected) write_bool(out, 2, true);
    if (!msg.local_name.empty()) write_string(out, 3, msg.local_name);
    if (msg.should_use_local_playback) write_bool(out, 4, true);
    for (const auto& d : msg.devices) {
        spotify::player::encode_submessage_field(out, 5, encode_state_device(d));
    }
    if (msg.is_active) write_bool(out, 6, true);
    if (msg.is_active_on_same_device) write_bool(out, 7, true);
    if (msg.is_synced_with_backend) write_bool(out, 8, true);
    return out;
}

inline bool decode_state_request(const uint8_t* data, size_t size, StateRequest& out) {
    if (data == nullptr && size > 0) return false;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(p, end, tag)) return false;
        const uint32_t field = static_cast<uint32_t>(tag >> 3U);
        const uint32_t wire = static_cast<uint32_t>(tag & 0x07U);
        if (field == 1 && wire == 0) {
            if (!read_bool(p, end, out.show_offline_devices_in_core)) return false;
        } else if (field == 2 && wire == 0) {
            if (!read_bool(p, end, out.show_offline_amazon_devices_as_online)) return false;
        } else if (field == 3 && wire == 0) {
            if (!read_bool(p, end, out.include_local_device)) return false;
        } else if (field == 4 && wire == 0) {
            if (!read_bool(p, end, out.exclude_non_local_devices)) return false;
        } else if (field == 5 && wire == 0) {
            if (!read_bool(p, end, out.include_user_match_unauthenticated_devices)) return false;
        } else {
            if (!spotify::player::skip_field(p, end, wire)) return false;
        }
    }
    return true;
}

inline bool decode_transfer_request(const uint8_t* data, size_t size, TransferRequest& out) {
    if (data == nullptr && size > 0) return false;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(p, end, tag)) return false;
        const uint32_t field = static_cast<uint32_t>(tag >> 3U);
        const uint32_t wire = static_cast<uint32_t>(tag & 0x07U);
        if (field == 1 && wire == 2) {
            const uint8_t* slice = nullptr;
            size_t len = 0;
            if (!read_length_delimited(p, end, slice, len)) return false;
            LoggingParams lp;
            if (!decode_logging_params(slice, len, lp)) return false;
            out.logging_params = std::move(lp);
        } else if (field == 2 && wire == 2) {
            if (!read_string(p, end, out.connect_device_identifier)) return false;
        } else if (field == 3 && wire == 0) {
            bool val = false;
            if (!read_bool(p, end, val)) return false;
            out.dodo = val;
        } else {
            if (!spotify::player::skip_field(p, end, wire)) return false;
        }
    }
    return true;
}

inline bool decode_pull_request(const uint8_t* data, size_t size, PullRequest& out) {
    if (data == nullptr && size > 0) return false;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(p, end, tag)) return false;
        const uint32_t field = static_cast<uint32_t>(tag >> 3U);
        const uint32_t wire = static_cast<uint32_t>(tag & 0x07U);
        if (field == 1 && wire == 2) {
            const uint8_t* slice = nullptr;
            size_t len = 0;
            if (!read_length_delimited(p, end, slice, len)) return false;
            LoggingParams lp;
            if (!decode_logging_params(slice, len, lp)) return false;
            out.logging_params = std::move(lp);
        } else {
            if (!spotify::player::skip_field(p, end, wire)) return false;
        }
    }
    return true;
}

inline bool decode_logout_request(const uint8_t* data, size_t size, LogoutRequest& out) {
    if (data == nullptr && size > 0) return false;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(p, end, tag)) return false;
        const uint32_t field = static_cast<uint32_t>(tag >> 3U);
        const uint32_t wire = static_cast<uint32_t>(tag & 0x07U);
        if (field == 1 && wire == 2) {
            if (!read_string(p, end, out.connect_device_identifier)) return false;
        } else {
            if (!spotify::player::skip_field(p, end, wire)) return false;
        }
    }
    return true;
}

inline bool decode_notify_audio_route_changed_request(
    const uint8_t* data,
    size_t size,
    NotifyAudioRouteChangedRequest& out) {
    if (data == nullptr && size > 0) return false;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(p, end, tag)) return false;
        const uint32_t field = static_cast<uint32_t>(tag >> 3U);
        const uint32_t wire = static_cast<uint32_t>(tag & 0x07U);
        if (field == 1 && wire == 2) {
            std::string s;
            if (!read_string(p, end, s)) return false;
            out.audio_output_device_name = std::move(s);
        } else if (field == 2 && wire == 0) {
            uint32_t v = 0;
            if (!read_uint32(p, end, v)) return false;
            out.audio_output_device_connection_type =
                static_cast<OutputPeripheralConnectionType>(v);
        } else if (field == 3 && wire == 2) {
            std::string s;
            if (!read_string(p, end, s)) return false;
            out.audio_output_device_brand = std::move(s);
        } else if (field == 4 && wire == 2) {
            std::string s;
            if (!read_string(p, end, s)) return false;
            out.audio_output_device_model = std::move(s);
        } else if (field == 5 && wire == 0) {
            uint32_t v = 0;
            if (!read_uint32(p, end, v)) return false;
            out.audio_output_device_category = static_cast<OutputPeripheralCategory>(v);
        } else {
            if (!spotify::player::skip_field(p, end, wire)) return false;
        }
    }
    return true;
}

inline bool decode_set_preferred_incarnation_request(
    const uint8_t* data,
    size_t size,
    SetPreferredIncarnationRequest& out) {
    if (data == nullptr && size > 0) return false;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(p, end, tag)) return false;
        const uint32_t field = static_cast<uint32_t>(tag >> 3U);
        const uint32_t wire = static_cast<uint32_t>(tag & 0x07U);
        if (field == 1 && wire == 2) {
            if (!read_string(p, end, out.device_id)) return false;
        } else if (field == 2 && wire == 0) {
            uint32_t v = 0;
            if (!read_uint32(p, end, v)) return false;
            out.preferred_login_type = static_cast<LoginType>(v);
        } else if (field == 3 && wire == 2) {
            const uint8_t* slice = nullptr;
            size_t len = 0;
            if (!read_length_delimited(p, end, slice, len)) return false;
            LoggingParams lp;
            if (!decode_logging_params(slice, len, lp)) return false;
            out.logging_params = std::move(lp);
        } else {
            if (!spotify::player::skip_field(p, end, wire)) return false;
        }
    }
    return true;
}

inline bool decode_send_command_request(
    const uint8_t* data,
    size_t size,
    SendCommandRequest& out) {
    if (data == nullptr && size > 0) return false;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(p, end, tag)) return false;
        const uint32_t field = static_cast<uint32_t>(tag >> 3U);
        const uint32_t wire = static_cast<uint32_t>(tag & 0x07U);
        if (field == 1 && wire == 2) {
            const uint8_t* slice = nullptr;
            size_t len = 0;
            if (!read_length_delimited(p, end, slice, len)) return false;
            LoggingParams lp;
            if (!decode_logging_params(slice, len, lp)) return false;
            out.logging_params = std::move(lp);
        } else if (field == 2 && wire == 2) {
            if (!read_string(p, end, out.connect_device_identifier)) return false;
        } else if (field == 3 && wire == 2) {
            if (!read_string(p, end, out.command_json)) return false;
        } else {
            if (!spotify::player::skip_field(p, end, wire)) return false;
        }
    }
    return true;
}

inline std::vector<uint8_t> encode_send_command_response(const SendCommandResponse& msg) {
    std::vector<uint8_t> out;
    if (msg.context_player_error != 0) {
        write_int32(out, 1, msg.context_player_error);
    }
    return out;
}

inline bool decode_rename_request(const uint8_t* data, size_t size, RenameRequest& out) {
    if (data == nullptr && size > 0) return false;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(p, end, tag)) return false;
        const uint32_t field = static_cast<uint32_t>(tag >> 3U);
        const uint32_t wire = static_cast<uint32_t>(tag & 0x07U);
        if (field == 1 && wire == 2) {
            if (!read_string(p, end, out.device_id)) return false;
        } else if (field == 2 && wire == 2) {
            if (!read_string(p, end, out.new_name)) return false;
        } else {
            if (!spotify::player::skip_field(p, end, wire)) return false;
        }
    }
    return true;
}

inline bool decode_add_device_to_group_request(
    const uint8_t* data,
    size_t size,
    AddDeviceToGroupRequest& out) {
    if (data == nullptr && size > 0) return false;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(p, end, tag)) return false;
        const uint32_t field = static_cast<uint32_t>(tag >> 3U);
        const uint32_t wire = static_cast<uint32_t>(tag & 0x07U);
        if (field == 1 && wire == 2) {
            if (!read_string(p, end, out.connect_device_identifier)) return false;
        } else if (field == 2 && wire == 2) {
            if (!read_string(p, end, out.group_device_identifier)) return false;
        } else if (field == 3 && wire == 2) {
            const uint8_t* slice = nullptr;
            size_t len = 0;
            if (!read_length_delimited(p, end, slice, len)) return false;
            LoggingParams lp;
            if (!decode_logging_params(slice, len, lp)) return false;
            out.logging_params = std::move(lp);
        } else {
            if (!spotify::player::skip_field(p, end, wire)) return false;
        }
    }
    return true;
}

inline std::vector<uint8_t> encode_add_device_to_group_response(
    const AddDeviceToGroupResponse& msg) {
    std::vector<uint8_t> out;
    if (msg.success) write_bool(out, 1, true);
    if (msg.error.has_value()) write_uint32(out, 2, static_cast<uint32_t>(*msg.error));
    return out;
}

inline bool decode_remove_device_from_group_request(
    const uint8_t* data,
    size_t size,
    RemoveDeviceFromGroupRequest& out) {
    if (data == nullptr && size > 0) return false;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(p, end, tag)) return false;
        const uint32_t field = static_cast<uint32_t>(tag >> 3U);
        const uint32_t wire = static_cast<uint32_t>(tag & 0x07U);
        if (field == 1 && wire == 2) {
            if (!read_string(p, end, out.connect_device_identifier)) return false;
        } else if (field == 2 && wire == 2) {
            if (!read_string(p, end, out.group_device_identifier)) return false;
        } else if (field == 3 && wire == 2) {
            const uint8_t* slice = nullptr;
            size_t len = 0;
            if (!read_length_delimited(p, end, slice, len)) return false;
            LoggingParams lp;
            if (!decode_logging_params(slice, len, lp)) return false;
            out.logging_params = std::move(lp);
        } else {
            if (!spotify::player::skip_field(p, end, wire)) return false;
        }
    }
    return true;
}

inline std::vector<uint8_t> encode_remove_device_from_group_response(
    const RemoveDeviceFromGroupResponse& msg) {
    std::vector<uint8_t> out;
    if (msg.success) write_bool(out, 1, true);
    if (msg.error.has_value()) write_uint32(out, 2, static_cast<uint32_t>(*msg.error));
    return out;
}

inline bool decode_delete_group_request(
    const uint8_t* data,
    size_t size,
    DeleteGroupRequest& out) {
    if (data == nullptr && size > 0) return false;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(p, end, tag)) return false;
        const uint32_t field = static_cast<uint32_t>(tag >> 3U);
        const uint32_t wire = static_cast<uint32_t>(tag & 0x07U);
        if (field == 1 && wire == 2) {
            if (!read_string(p, end, out.connect_device_identifier)) return false;
        } else if (field == 2 && wire == 2) {
            const uint8_t* slice = nullptr;
            size_t len = 0;
            if (!read_length_delimited(p, end, slice, len)) return false;
            LoggingParams lp;
            if (!decode_logging_params(slice, len, lp)) return false;
            out.logging_params = std::move(lp);
        } else {
            if (!spotify::player::skip_field(p, end, wire)) return false;
        }
    }
    return true;
}

inline std::vector<uint8_t> encode_delete_group_response(const DeleteGroupResponse& msg) {
    std::vector<uint8_t> out;
    if (msg.success) write_bool(out, 1, true);
    if (msg.error.has_value()) write_uint32(out, 2, static_cast<uint32_t>(*msg.error));
    return out;
}

inline std::vector<uint8_t> encode_cluster_update_after_backend_connection_response(
    bool has_received) {
    std::vector<uint8_t> out;
    if (has_received) write_bool(out, 1, true);
    return out;
}

inline bool decode_install_spotify_request(
    const uint8_t* data,
    size_t size,
    InstallSpotifyRequest& out) {
    if (data == nullptr && size > 0) return false;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(p, end, tag)) return false;
        const uint32_t field = static_cast<uint32_t>(tag >> 3U);
        const uint32_t wire = static_cast<uint32_t>(tag & 0x07U);
        if (field == 1 && wire == 2) {
            if (!read_string(p, end, out.connect_device_identifier)) return false;
        } else if (field == 2 && wire == 0) {
            uint32_t v = 0;
            if (!read_uint32(p, end, v)) return false;
            out.port = v;
        } else if (field == 3 && wire == 2) {
            const uint8_t* slice = nullptr;
            size_t len = 0;
            if (!read_length_delimited(p, end, slice, len)) return false;
            LoggingParams lp;
            if (!decode_logging_params(slice, len, lp)) return false;
            out.logging_params = std::move(lp);
        } else {
            if (!spotify::player::skip_field(p, end, wire)) return false;
        }
    }
    return true;
}

inline std::vector<uint8_t> encode_install_spotify_status_update(InstallSpotifyState state) {
    std::vector<uint8_t> out;
    if (state != InstallSpotifyState::CONNECTING) {
        write_uint32(out, 1, static_cast<uint32_t>(state));
    }
    return out;
}

// ---------------------------------------------------------------------------
// volume_messages.proto
// ---------------------------------------------------------------------------

struct VolumeResponse {
    std::optional<int32_t> volume;
    Status status{Status::OK};
    std::optional<std::string> active_device_connect_state_identifier;
    std::map<std::string, uint32_t> group_device_volumes;
};

struct VolumeSetRequest {
    int32_t volume{0};
    std::optional<LoggingParams> logging_params;
    std::optional<std::string> group_device_identifier;
};

struct VolumeStepRequest {
    std::optional<LoggingParams> logging_params;
    std::optional<std::string> group_device_identifier;
};

enum class LocalVolumeReason : uint32_t {
    USER = 0,
    SYSTEM = 1,
};

struct LocalVolumeResponse {
    int32_t volume{0};
    LocalVolumeReason reason{LocalVolumeReason::USER};
};

inline std::vector<uint8_t> encode_volume_response(const VolumeResponse& msg) {
    std::vector<uint8_t> out;
    if (msg.volume.has_value()) {
        write_int32(out, 1, *msg.volume);
    }
    if (msg.status != Status::OK) {
        write_uint32(out, 2, static_cast<uint32_t>(msg.status));
    }
    if (msg.active_device_connect_state_identifier.has_value()) {
        write_string(out, 3, *msg.active_device_connect_state_identifier);
    }
    for (const auto& [k, v] : msg.group_device_volumes) {
        std::vector<uint8_t> entry;
        if (!k.empty()) write_string(entry, 1, k);
        if (v != 0) write_uint32(entry, 2, v);
        spotify::player::encode_submessage_field(out, 4, entry);
    }
    return out;
}

inline bool decode_volume_set_request(
    const uint8_t* data,
    size_t size,
    VolumeSetRequest& out) {
    if (data == nullptr && size > 0) return false;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(p, end, tag)) return false;
        const uint32_t field = static_cast<uint32_t>(tag >> 3U);
        const uint32_t wire = static_cast<uint32_t>(tag & 0x07U);
        if (field == 1 && wire == 0) {
            if (!read_int32(p, end, out.volume)) return false;
        } else if (field == 2 && wire == 2) {
            const uint8_t* slice = nullptr;
            size_t len = 0;
            if (!read_length_delimited(p, end, slice, len)) return false;
            LoggingParams lp;
            if (!decode_logging_params(slice, len, lp)) return false;
            out.logging_params = std::move(lp);
        } else if (field == 3 && wire == 2) {
            std::string val;
            if (!read_string(p, end, val)) return false;
            out.group_device_identifier = std::move(val);
        } else {
            if (!spotify::player::skip_field(p, end, wire)) return false;
        }
    }
    return true;
}

inline bool decode_volume_step_request(
    const uint8_t* data,
    size_t size,
    VolumeStepRequest& out) {
    if (data == nullptr && size > 0) return false;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(p, end, tag)) return false;
        const uint32_t field = static_cast<uint32_t>(tag >> 3U);
        const uint32_t wire = static_cast<uint32_t>(tag & 0x07U);
        if (field == 1 && wire == 2) {
            const uint8_t* slice = nullptr;
            size_t len = 0;
            if (!read_length_delimited(p, end, slice, len)) return false;
            LoggingParams lp;
            if (!decode_logging_params(slice, len, lp)) return false;
            out.logging_params = std::move(lp);
        } else if (field == 2 && wire == 2) {
            std::string val;
            if (!read_string(p, end, val)) return false;
            out.group_device_identifier = std::move(val);
        } else {
            if (!spotify::player::skip_field(p, end, wire)) return false;
        }
    }
    return true;
}

inline std::vector<uint8_t> encode_local_volume_response(const LocalVolumeResponse& msg) {
    std::vector<uint8_t> out;
    if (msg.volume != 0) write_int32(out, 1, msg.volume);
    if (msg.reason != LocalVolumeReason::USER) {
        write_uint32(out, 2, static_cast<uint32_t>(msg.reason));
    }
    return out;
}

// ---------------------------------------------------------------------------
// dodos_messages.proto
// ---------------------------------------------------------------------------

struct SwitchToDodoRequest {
    std::string cs_id;
};

inline std::vector<uint8_t> encode_single_dodo(const spotify::connectstate::SingleDodo& d) {
    std::vector<uint8_t> out;
    if (!d.dodo_id.empty()) write_string(out, 1, d.dodo_id);
    if (!d.cs_id.empty()) write_string(out, 2, d.cs_id);
    if (d.is_primary) write_bool(out, 3, true);
    if (d.is_being_observed) write_bool(out, 4, true);
    return out;
}

inline std::vector<uint8_t> encode_dodo_sub_response(
    const std::vector<spotify::connectstate::SingleDodo>& dodos) {
    std::vector<uint8_t> out;
    for (const auto& d : dodos) {
        spotify::player::encode_submessage_field(out, 1, encode_single_dodo(d));
    }
    return out;
}

inline bool decode_switch_to_dodo_request(
    const uint8_t* data,
    size_t size,
    SwitchToDodoRequest& out) {
    if (data == nullptr && size > 0) return false;
    const uint8_t* p = data;
    const uint8_t* end = data + size;
    while (p < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(p, end, tag)) return false;
        const uint32_t field = static_cast<uint32_t>(tag >> 3U);
        const uint32_t wire = static_cast<uint32_t>(tag & 0x07U);
        if (field == 1 && wire == 2) {
            if (!read_string(p, end, out.cs_id)) return false;
        } else {
            if (!spotify::player::skip_field(p, end, wire)) return false;
        }
    }
    return true;
}

// Shared validation: empty command_id or 32 hex chars (liborbit 0xe3b718).
inline bool is_valid_command_id(const std::optional<LoggingParams>& lp) {
    if (!lp.has_value() || !lp->command_id.has_value() || lp->command_id->empty()) {
        return true;
    }
    const std::string& cid = *lp->command_id;
    if (cid.size() != 32U) {
        return false;
    }
    for (unsigned char c : cid) {
        const bool hex =
            (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
        if (!hex) {
            return false;
        }
    }
    return true;
}

}  // namespace spotify::connectstate::esperanto

#endif  // MUSIFY_CONNECT_CONNECT_ESPERANTO_PROTOS_H_
