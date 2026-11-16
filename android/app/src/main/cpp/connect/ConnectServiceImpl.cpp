// 1:1 Replicated Spotify Esperanto ConnectService Native Adapter
// Sources:
// - `liborbit-jni-spotify.so`: `spotify::connect::esperanto::proto::ConnectService`
//   dispatcher @ `0xe3e3dc`, vtable @ `0x18f48b0` (handlers `0xe397c0..0xe3b0e6`)
// - Decompiled Java: `p199p/s77.java`, `p199p/C2086nd.java`, `p199p/c8k.java`, `p199p/n8d.java`

#include "ConnectServiceImpl.h"

#include <algorithm>
#include <cctype>
#include <unordered_set>
#include <utility>

namespace spotify::connectstate::esperanto {
namespace {

std::string device_type_to_wire_string(DeviceType type) {
    switch (type) {
        case DeviceType::UNKNOWN: return "UNKNOWN";
        case DeviceType::COMPUTER: return "COMPUTER";
        case DeviceType::TABLET: return "TABLET";
        case DeviceType::SMARTPHONE: return "SMARTPHONE";
        case DeviceType::SPEAKER: return "SPEAKER";
        case DeviceType::TV: return "TV";
        case DeviceType::AVR: return "AVR";
        case DeviceType::STB: return "STB";
        case DeviceType::AUDIO_DONGLE: return "AUDIO_DONGLE";
        case DeviceType::GAME_CONSOLE: return "GAME_CONSOLE";
        case DeviceType::CAST_VIDEO: return "CAST_VIDEO";
        case DeviceType::CAST_AUDIO: return "CAST_AUDIO";
        case DeviceType::AUTOMOBILE: return "AUTOMOBILE";
        case DeviceType::SMARTWATCH: return "SMARTWATCH";
        case DeviceType::CHROMEBOOK: return "CHROMEBOOK";
        case DeviceType::UNKNOWN_SPOTIFY: return "UNKNOWN_SPOTIFY";
        case DeviceType::CAR_THING: return "CAR_THING";
        case DeviceType::OBSERVER: return "OBSERVER";
        case DeviceType::HOME_THING: return "HOME_THING";
    }
    return "UNKNOWN";
}

bool contains_case_insensitive(std::string_view haystack, std::string_view needle) {
    if (needle.empty() || haystack.size() < needle.size()) {
        return false;
    }
    for (size_t i = 0; i <= haystack.size() - needle.size(); ++i) {
        bool match = true;
        for (size_t j = 0; j < needle.size(); ++j) {
            const auto a = static_cast<unsigned char>(std::tolower(static_cast<unsigned char>(haystack[i + j])));
            const auto b = static_cast<unsigned char>(std::tolower(static_cast<unsigned char>(needle[j])));
            if (a != b) {
                match = false;
                break;
            }
        }
        if (match) return true;
    }
    return false;
}

bool is_amazon_device(const DeviceInfo& info) {
    return contains_case_insensitive(info.brand, "amazon") ||
           contains_case_insensitive(info.model, "echo") ||
           contains_case_insensitive(info.model, "alexa");
}

OutputPeripheralConnectionType map_output_connection_type(AudioOutputDeviceType type) {
    switch (type) {
        case AudioOutputDeviceType::UNKNOWN_AUDIO_OUTPUT_DEVICE_TYPE:
            return OutputPeripheralConnectionType::UNKNOWN;
        case AudioOutputDeviceType::BUILT_IN_SPEAKER:
            return OutputPeripheralConnectionType::BUILT_IN_SPEAKER;
        case AudioOutputDeviceType::LINE_OUT:
            return OutputPeripheralConnectionType::WIRED;
        case AudioOutputDeviceType::BLUETOOTH:
            return OutputPeripheralConnectionType::BLUETOOTH;
        case AudioOutputDeviceType::AIRPLAY:
            return OutputPeripheralConnectionType::AIRPLAY;
        case AudioOutputDeviceType::AUTOMOTIVE:
        case AudioOutputDeviceType::CAR_PROJECTED:
            return OutputPeripheralConnectionType::CAR_PROJECTED;
    }
    return OutputPeripheralConnectionType::UNKNOWN;
}

AudioOutputDeviceType map_wire_connection_type(OutputPeripheralConnectionType type) {
    switch (type) {
        case OutputPeripheralConnectionType::UNKNOWN:
            return AudioOutputDeviceType::UNKNOWN_AUDIO_OUTPUT_DEVICE_TYPE;
        case OutputPeripheralConnectionType::WIRED:
            return AudioOutputDeviceType::LINE_OUT;
        case OutputPeripheralConnectionType::CAR_PROJECTED:
            return AudioOutputDeviceType::CAR_PROJECTED;
        case OutputPeripheralConnectionType::BLUETOOTH:
            return AudioOutputDeviceType::BLUETOOTH;
        case OutputPeripheralConnectionType::AIRPLAY:
            return AudioOutputDeviceType::AIRPLAY;
        case OutputPeripheralConnectionType::BUILT_IN_SPEAKER:
            return AudioOutputDeviceType::BUILT_IN_SPEAKER;
    }
    return AudioOutputDeviceType::UNKNOWN_AUDIO_OUTPUT_DEVICE_TYPE;
}

OutputPeripheralCategory map_output_category(AudioOutputCategory cat) {
    switch (cat) {
        case AudioOutputCategory::AUDIO_OUTPUT_CATEGORY_UNKNOWN:
            return OutputPeripheralCategory::UNKNOWN;
        case AudioOutputCategory::AUDIO_OUTPUT_CATEGORY_HEADPHONES:
            return OutputPeripheralCategory::HEADPHONES;
        case AudioOutputCategory::AUDIO_OUTPUT_CATEGORY_CAR:
            return OutputPeripheralCategory::CAR;
        case AudioOutputCategory::AUDIO_OUTPUT_CATEGORY_SPEAKER:
            return OutputPeripheralCategory::SPEAKER;
        case AudioOutputCategory::AUDIO_OUTPUT_CATEGORY_WEARABLE:
            return OutputPeripheralCategory::WEARABLE;
        case AudioOutputCategory::AUDIO_OUTPUT_CATEGORY_GLASSES:
            return OutputPeripheralCategory::GLASSES;
        case AudioOutputCategory::AUDIO_OUTPUT_CATEGORY_APP:
            return OutputPeripheralCategory::APP;
    }
    return OutputPeripheralCategory::UNKNOWN;
}

AudioOutputCategory map_wire_category(OutputPeripheralCategory cat) {
    switch (cat) {
        case OutputPeripheralCategory::UNKNOWN:
            return AudioOutputCategory::AUDIO_OUTPUT_CATEGORY_UNKNOWN;
        case OutputPeripheralCategory::CAR:
            return AudioOutputCategory::AUDIO_OUTPUT_CATEGORY_CAR;
        case OutputPeripheralCategory::HEADPHONES:
            return AudioOutputCategory::AUDIO_OUTPUT_CATEGORY_HEADPHONES;
        case OutputPeripheralCategory::SPEAKER:
            return AudioOutputCategory::AUDIO_OUTPUT_CATEGORY_SPEAKER;
        case OutputPeripheralCategory::WEARABLE:
            return AudioOutputCategory::AUDIO_OUTPUT_CATEGORY_WEARABLE;
        case OutputPeripheralCategory::GLASSES:
            return AudioOutputCategory::AUDIO_OUTPUT_CATEGORY_GLASSES;
        case OutputPeripheralCategory::APP:
            return AudioOutputCategory::AUDIO_OUTPUT_CATEGORY_APP;
    }
    return AudioOutputCategory::AUDIO_OUTPUT_CATEGORY_UNKNOWN;
}

GroupError map_add_group_error(const AckHttpResult& res) {
    if (res.http_status == 404) return GroupError::GROUP_DEVICE_NOT_FOUND;
    if (res.http_status == 408 || res.http_status == 504) return GroupError::TIMEOUT_GROUP_ERROR;
    if (res.http_status == 409 || res.http_status == 429 || res.http_status == 503) {
        return GroupError::BUSY;
    }
    if (res.http_status == 422) return GroupError::MAX_NUMBER_OF_DEVICES_REACHED;
    if (res.http_status == 501) return GroupError::NOT_IMPLEMENTED;
    return GroupError::INTERNAL_GROUP_ERROR;
}

RemoveGroupError map_remove_group_error(const AckHttpResult& res) {
    if (res.http_status == 404) return RemoveGroupError::REMOVE_GROUP_DEVICE_NOT_FOUND;
    if (res.http_status == 408 || res.http_status == 504) {
        return RemoveGroupError::TIMEOUT_REMOVE_ERROR;
    }
    if (res.http_status == 409 || res.http_status == 429 || res.http_status == 503) {
        return RemoveGroupError::REMOVE_BUSY;
    }
    if (res.http_status == 501) return RemoveGroupError::REMOVE_NOT_IMPLEMENTED;
    return RemoveGroupError::INTERNAL_REMOVE_ERROR;
}

DeleteGroupError map_delete_group_error(const AckHttpResult& res) {
    if (res.http_status == 404) return DeleteGroupError::DELETE_TARGET_NOT_FOUND;
    if (res.http_status == 408 || res.http_status == 504) {
        return DeleteGroupError::TIMEOUT_DELETE_ERROR;
    }
    if (res.http_status == 409 || res.http_status == 429 || res.http_status == 503) {
        return DeleteGroupError::DELETE_BUSY;
    }
    if (res.http_status == 501) return DeleteGroupError::DELETE_NOT_IMPLEMENTED;
    return DeleteGroupError::INTERNAL_DELETE_ERROR;
}

}  // namespace

ConnectServiceImpl::ConnectServiceImpl(ConnectSubsystem& subsystem)
    : subsystem_(subsystem) {}

EsperantoCallResult ConnectServiceImpl::dispatch(
    std::string_view method,
    const uint8_t* payload,
    size_t len) {
    if (method == "State") return handle_state(payload, len);
    if (method == "Transfer") return handle_transfer(payload, len);
    if (method == "SendCommand") return handle_send_command(payload, len);
    if (method == "Pull") return handle_pull(payload, len);
    if (method == "Rename") return handle_rename(payload, len);
    if (method == "Logout") return handle_logout(payload, len);
    if (method == "NotifyAudioRouteChanged") {
        return handle_notify_audio_route_changed(payload, len);
    }
    if (method == "SetPreferredIncarnation") {
        return handle_set_preferred_incarnation(payload, len);
    }
    if (method == "CreateStaticGroup") return handle_create_static_group(payload, len);
    if (method == "RenameGroup") return handle_rename_group(payload, len);
    if (method == "AddDeviceToGroup") return handle_add_device_to_group(payload, len);
    if (method == "RemoveDeviceFromGroup") {
        return handle_remove_device_from_group(payload, len);
    }
    if (method == "DeleteGroup") return handle_delete_group(payload, len);
    if (method == "ClusterUpdateAfterBackendConnection") {
        return handle_cluster_update_after_backend_connection(payload, len);
    }
    if (method == "InstallSpotify") return handle_install_spotify(payload, len);
    if (method == "PerformDiscovery") return handle_perform_discovery(payload, len);
    if (method == "RefreshCluster") return handle_refresh_cluster(payload, len);
    if (method == "WakeSleepingClusterDevices") {
        return handle_wake_sleeping_cluster_devices(payload, len);
    }
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kUnknownMethod,
        .payload = {},
    };
}

StateDevice ConnectServiceImpl::map_device(
    const DeviceInfo& info,
    bool is_self,
    const Cluster& cluster,
    const std::string& preferred_incarnation,
    std::optional<uint32_t> preferred_login_type) const {
    StateDevice d;
    d.is_self = is_self;
    d.local_identifier = info.device_id;
    d.deduplication_id = info.deduplication_id;
    d.connect_state_identifier = info.device_id;
    d.name = info.name;
    d.type = device_type_to_wire_string(info.device_type);
    d.is_disabled = info.capabilities.connect_disabled;
    d.is_active = !cluster.active_device_id.empty() &&
                  cluster.active_device_id == info.device_id;
    d.is_being_activated = subsystem_.is_being_activated(info.device_id);
    d.is_zeroconf = info.is_locally_discovered;
    d.is_webapp = (info.device_type == DeviceType::OBSERVER);
    d.is_local = is_self || info.is_locally_discovered;
    d.is_group = info.is_group;
    d.is_offline = info.is_offline;
    d.is_social_connect = info.is_social_connect;
    d.state = d.is_offline ? "unavailable" : "logged_in";
    d.volume = info.volume;

    if (info.capabilities.supports_hifi.has_value()) {
        d.hifi = StateHifi{
            .fully_supported = info.capabilities.supports_hifi->fully_supported,
            .user_eligible = info.capabilities.supports_hifi->user_eligible,
            .device_supported = info.capabilities.supports_hifi->device_supported,
        };
    }

    d.license = info.license;
    d.supports_on_demand = info.can_play;
    d.supports_volume = !info.capabilities.disable_volume;
    d.supports_logout = info.capabilities.supports_logout;
    d.supports_rename = info.capabilities.supports_rename;
    d.is_voice_enabled = info.capabilities.is_voice_enabled;
    d.supported_media_types = info.capabilities.supported_types;
    d.brand_display_name = info.brand;
    d.model_display_name = info.model;
    if (info.capabilities.volume_steps > 0) {
        d.volume_steps = static_cast<uint32_t>(info.capabilities.volume_steps);
    }
    if (!info.capabilities.connect_capabilities.empty()) {
        d.capabilities = info.capabilities.connect_capabilities;
    }

    if (!info.device_id.empty()) {
        StateIncarnation inc;
        const bool is_preferred = (preferred_incarnation == info.device_id);
        inc.login_type =
            (is_preferred && preferred_login_type.has_value() &&
             *preferred_login_type == static_cast<uint32_t>(LoginType::CAST))
                ? LoginType::CAST
                : LoginType::CONNECT;
        inc.identifier = info.device_id;
        inc.preferred = is_preferred;
        inc.preferred_reason = is_preferred
                                   ? ProtocolChoiceReason::PROTOCOL_CHOICE_REASON_USER_SELECTED
                                   : ProtocolChoiceReason::PROTOCOL_CHOICE_REASON_DEFAULT;
        inc.connect_state_identifier = info.device_id;
        d.incarnations.push_back(std::move(inc));
    }

    if (info.selected_alias_id != 0) {
        d.alias_id = info.selected_alias_id;
    }
    d.supports_dj = info.capabilities.supports_dj;
    d.library_version = info.device_software_version;

    const AudioOutputDeviceInfo& ao = info.audio_output_device_info;
    if (ao.audio_output_device_type !=
            AudioOutputDeviceType::UNKNOWN_AUDIO_OUTPUT_DEVICE_TYPE ||
        !ao.device_name.empty() || !ao.brand.empty() || !ao.model.empty() ||
        ao.category != AudioOutputCategory::AUDIO_OUTPUT_CATEGORY_UNKNOWN) {
        OutputPeripheral op;
        if (!ao.device_name.empty()) op.name = ao.device_name;
        if (!ao.brand.empty()) op.brand = ao.brand;
        if (!ao.model.empty()) op.model = ao.model;
        op.category = map_output_category(ao.category);
        op.connection_type = map_output_connection_type(ao.audio_output_device_type);
        d.output_peripheral = std::move(op);
    }

    d.local_ip = info.public_ip;
    d.supports_remote_sleep_timer = info.capabilities.supports_remote_sleep_timer;
    d.supports_playlist_mixing = info.capabilities.supports_playlist_mixing;

    if (info.is_group || !info.device_aliases.empty()) {
        GroupData gd;
        gd.capabilities = GroupCapabilities{.max_devices = 5};
        for (const auto& [alias_id, alias] : info.device_aliases) {
            (void)alias_id;
            GroupDevice dev;
            GroupDeviceIdentifiers ids;
            ids.group_device_identifier =
                alias.group_instance.empty() ? info.device_id : alias.group_instance;
            ids.connect_state_identifier = info.device_id;
            dev.identifiers = std::move(ids);
            dev.name = alias.display_name;
            dev.type = d.type;
            dev.model_display_name = info.model;
            dev.capabilities = GroupDeviceCapabilities{
                .removable = true,
                .removal_dissolves_group = false,
            };
            dev.grouping_status = alias.is_group
                                      ? GroupingStatus::GROUPED
                                      : GroupingStatus::GROUPABLE;
            dev.volume = GroupDeviceVolume{
                .volume = info.volume,
                .volume_steps = info.capabilities.volume_steps,
            };
            gd.devices.push_back(std::move(dev));
        }
        d.group_data = std::move(gd);
    }

    d.is_public = info.is_public;
    d.supports_remote_audio_quality_control =
        info.capabilities.supports_remote_audio_quality_control;
    d.is_authenticated_with_current_user = true;
    d.supports_zephyr = info.capabilities.supports_zephyr;
    d.supports_gapless = info.capabilities.supports_gapless;
    d.supports_crossfade = info.capabilities.supports_crossfade;
    return d;
}

StateResponse ConnectServiceImpl::build_state_response(const StateRequest& request) const {
    const DeviceInfo local = subsystem_.devices().local_device_info();
    const Cluster cluster = subsystem_.devices().current_cluster();
    const std::string preferred = subsystem_.devices().preferred_incarnation();
    const std::optional<uint32_t> preferred_type = subsystem_.preferred_login_type();

    StateResponse resp;
    resp.is_running = subsystem_.is_running();
    resp.is_connected = subsystem_.devices().is_backend_connected();
    resp.local_name = local.name;
    resp.is_active = !cluster.active_device_id.empty();
    resp.is_active_on_same_device =
        (!local.device_id.empty() && cluster.active_device_id == local.device_id) ||
        subsystem_.is_local_active();
    resp.is_synced_with_backend =
        subsystem_.has_received_cluster_update_after_backend_connection();
    resp.should_use_local_playback =
        !resp.is_active || resp.is_active_on_same_device;

    std::unordered_set<std::string> seen_ids;
    auto maybe_append_device = [&](const DeviceInfo& info, bool is_self) {
        if (info.device_id.empty()) {
            return;
        }
        if (is_self && !request.include_local_device) {
            return;
        }
        if (!is_self && request.exclude_non_local_devices &&
            !info.is_locally_discovered) {
            return;
        }
        bool treat_offline = info.is_offline;
        if (treat_offline) {
            if (request.show_offline_amazon_devices_as_online &&
                is_amazon_device(info)) {
                treat_offline = false;
            } else if (!request.show_offline_devices_in_core) {
                return;
            }
        }
        if (!seen_ids.insert(info.device_id).second) {
            return;
        }
        StateDevice mapped = map_device(
            info, is_self, cluster, preferred, preferred_type);
        if (!treat_offline && info.is_offline) {
            mapped.is_offline = false;
            mapped.state = "logged_in";
        }
        resp.devices.push_back(std::move(mapped));
    };

    if (!local.device_id.empty()) {
        const auto cluster_local_it = cluster.devices.find(local.device_id);
        if (cluster_local_it != cluster.devices.end()) {
            DeviceInfo merged = cluster_local_it->second;
            merged.audio_output_device_info = local.audio_output_device_info;
            merged.volume = local.volume;
            maybe_append_device(merged, true);
        } else {
            maybe_append_device(local, true);
        }
    }

    std::vector<std::string> sorted_ids;
    sorted_ids.reserve(cluster.devices.size());
    for (const auto& [id, dev] : cluster.devices) {
        (void)dev;
        if (id != local.device_id) {
            sorted_ids.push_back(id);
        }
    }
    std::sort(sorted_ids.begin(), sorted_ids.end());
    for (const auto& id : sorted_ids) {
        const auto it = cluster.devices.find(id);
        if (it != cluster.devices.end()) {
            maybe_append_device(it->second, false);
        }
    }

    return resp;
}

EsperantoCallResult ConnectServiceImpl::handle_state(
    const uint8_t* payload,
    size_t len) const {
    StateRequest req;
    if (!decode_state_request(payload, len, req)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = {},
        };
    }
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_state_response(build_state_response(req)),
    };
}

EsperantoCallResult ConnectServiceImpl::handle_transfer(
    const uint8_t* payload,
    size_t len) {
    TransferRequest req;
    if (!decode_transfer_request(payload, len, req)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = encode_status_response(Status::INVALID_ARGUMENTS),
        };
    }
    if (req.connect_device_identifier.empty() || !is_valid_command_id(req.logging_params)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kOk,
            .payload = encode_status_response(Status::INVALID_ARGUMENTS),
        };
    }

    TransferOptionsParams opts;
    std::vector<std::string> interaction_ids;
    if (req.logging_params.has_value()) {
        interaction_ids = req.logging_params->interaction_ids;
    }
    const bool dodo = req.dodo.value_or(false);
    const TransferOutcome outcome = subsystem_.transfer(
        req.connect_device_identifier, opts, interaction_ids, dodo);
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_status_response(
            outcome.ok ? Status::OK : Status::BACKEND_FAILURE),
    };
}

EsperantoCallResult ConnectServiceImpl::handle_send_command(
    const uint8_t* payload,
    size_t len) {
    SendCommandRequest req;
    if (!decode_send_command_request(payload, len, req)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = {},
        };
    }
    if (req.connect_device_identifier.empty() ||
        req.command_json.empty() ||
        !is_valid_command_id(req.logging_params)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kInvalidArguments,
            .payload = encode_send_command_response(
                SendCommandResponse{.context_player_error = -1}),
        };
    }
    std::string intent_id;
    if (req.logging_params.has_value() && req.logging_params->command_id.has_value()) {
        intent_id = *req.logging_params->command_id;
    }
    const AckHttpResult res = subsystem_.send_player_command(
        req.connect_device_identifier, req.command_json, intent_id);
    const int32_t err = res.ok ? 0 : (res.http_status > 0 ? res.http_status : -1);
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_send_command_response(
            SendCommandResponse{.context_player_error = err}),
    };
}

EsperantoCallResult ConnectServiceImpl::handle_pull(
    const uint8_t* payload,
    size_t len) {
    PullRequest req;
    if (!decode_pull_request(payload, len, req)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = encode_status_response(Status::INVALID_ARGUMENTS),
        };
    }
    if (!is_valid_command_id(req.logging_params)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kOk,
            .payload = encode_status_response(Status::INVALID_ARGUMENTS),
        };
    }
    const TransferOutcome outcome = subsystem_.pull();
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_status_response(
            outcome.ok ? Status::OK : Status::BACKEND_FAILURE),
    };
}

EsperantoCallResult ConnectServiceImpl::handle_rename(
    const uint8_t* payload,
    size_t len) {
    RenameRequest req;
    if (!decode_rename_request(payload, len, req)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = encode_status_response(Status::INVALID_ARGUMENTS),
        };
    }
    if (req.device_id.empty() || req.new_name.empty()) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kOk,
            .payload = encode_status_response(Status::INVALID_ARGUMENTS),
        };
    }
    const AckHttpResult res = subsystem_.rename(req.device_id, req.new_name);
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_status_response(
            res.ok ? Status::OK : Status::BACKEND_FAILURE),
    };
}

EsperantoCallResult ConnectServiceImpl::handle_logout(
    const uint8_t* payload,
    size_t len) {
    LogoutRequest req;
    if (!decode_logout_request(payload, len, req)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = encode_status_response(Status::INVALID_ARGUMENTS),
        };
    }
    const SimpleHttpResult res = subsystem_.logout(req.connect_device_identifier);
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_status_response(
            res.ok ? Status::OK : Status::BACKEND_FAILURE),
    };
}

EsperantoCallResult ConnectServiceImpl::handle_notify_audio_route_changed(
    const uint8_t* payload,
    size_t len) {
    NotifyAudioRouteChangedRequest req;
    if (!decode_notify_audio_route_changed_request(payload, len, req)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = {},
        };
    }

    AudioOutputDeviceInfo info;
    if (req.audio_output_device_name.has_value()) {
        info.device_name = *req.audio_output_device_name;
    }
    if (req.audio_output_device_connection_type.has_value()) {
        info.audio_output_device_type =
            map_wire_connection_type(*req.audio_output_device_connection_type);
    }
    if (req.audio_output_device_brand.has_value()) {
        info.brand = *req.audio_output_device_brand;
    }
    if (req.audio_output_device_model.has_value()) {
        info.model = *req.audio_output_device_model;
    }
    if (req.audio_output_device_category.has_value()) {
        info.category = map_wire_category(*req.audio_output_device_category);
    }

    (void)subsystem_.notify_audio_route_changed({info});
    // Per liborbit @ 0xe3a7f8 and s77.java:1114, NotifyAudioRouteChanged returns google.protobuf.Empty.
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = {},
    };
}

EsperantoCallResult ConnectServiceImpl::handle_set_preferred_incarnation(
    const uint8_t* payload,
    size_t len) {
    SetPreferredIncarnationRequest req;
    if (!decode_set_preferred_incarnation_request(payload, len, req)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = encode_status_response(Status::INVALID_ARGUMENTS),
        };
    }
    if (req.device_id.empty()) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kOk,
            .payload = encode_status_response(Status::INVALID_ARGUMENTS),
        };
    }
    std::optional<uint32_t> login_type;
    if (req.preferred_login_type.has_value()) {
        login_type = static_cast<uint32_t>(*req.preferred_login_type);
    }
    subsystem_.set_preferred_incarnation(req.device_id, login_type);
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_status_response(Status::OK),
    };
}

EsperantoCallResult ConnectServiceImpl::handle_create_static_group(
    const uint8_t* payload,
    size_t len) const {
    if (!decode_empty_message(payload, len)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = {},
        };
    }
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = {},
    };
}

EsperantoCallResult ConnectServiceImpl::handle_rename_group(
    const uint8_t* payload,
    size_t len) const {
    if (!decode_empty_message(payload, len)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = {},
        };
    }
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = {},
    };
}

EsperantoCallResult ConnectServiceImpl::handle_add_device_to_group(
    const uint8_t* payload,
    size_t len) {
    AddDeviceToGroupRequest req;
    if (!decode_add_device_to_group_request(payload, len, req)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = encode_add_device_to_group_response(
                AddDeviceToGroupResponse{.success = false, .error = GroupError::INTERNAL_GROUP_ERROR}),
        };
    }
    if (req.connect_device_identifier.empty() || req.group_device_identifier.empty()) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kOk,
            .payload = encode_add_device_to_group_response(
                AddDeviceToGroupResponse{.success = false, .error = GroupError::GROUP_DEVICE_NOT_FOUND}),
        };
    }
    const AckHttpResult res = subsystem_.add_device_to_group(
        req.connect_device_identifier, req.group_device_identifier);
    AddDeviceToGroupResponse out;
    out.success = res.ok;
    if (!res.ok) {
        out.error = map_add_group_error(res);
    }
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_add_device_to_group_response(out),
    };
}

EsperantoCallResult ConnectServiceImpl::handle_remove_device_from_group(
    const uint8_t* payload,
    size_t len) {
    RemoveDeviceFromGroupRequest req;
    if (!decode_remove_device_from_group_request(payload, len, req)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = encode_remove_device_from_group_response(
                RemoveDeviceFromGroupResponse{
                    .success = false,
                    .error = RemoveGroupError::INTERNAL_REMOVE_ERROR}),
        };
    }
    if (req.connect_device_identifier.empty() || req.group_device_identifier.empty()) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kOk,
            .payload = encode_remove_device_from_group_response(
                RemoveDeviceFromGroupResponse{
                    .success = false,
                    .error = RemoveGroupError::REMOVE_GROUP_DEVICE_NOT_FOUND}),
        };
    }
    const AckHttpResult res = subsystem_.remove_device_from_group(
        req.connect_device_identifier, req.group_device_identifier);
    RemoveDeviceFromGroupResponse out;
    out.success = res.ok;
    if (!res.ok) {
        out.error = map_remove_group_error(res);
    }
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_remove_device_from_group_response(out),
    };
}

EsperantoCallResult ConnectServiceImpl::handle_delete_group(
    const uint8_t* payload,
    size_t len) {
    DeleteGroupRequest req;
    if (!decode_delete_group_request(payload, len, req)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = encode_delete_group_response(
                DeleteGroupResponse{
                    .success = false,
                    .error = DeleteGroupError::INTERNAL_DELETE_ERROR}),
        };
    }
    if (req.connect_device_identifier.empty()) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kOk,
            .payload = encode_delete_group_response(
                DeleteGroupResponse{
                    .success = false,
                    .error = DeleteGroupError::DELETE_TARGET_NOT_FOUND}),
        };
    }
    const AckHttpResult res = subsystem_.delete_group(req.connect_device_identifier);
    DeleteGroupResponse out;
    out.success = res.ok;
    if (!res.ok) {
        out.error = map_delete_group_error(res);
    }
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_delete_group_response(out),
    };
}

EsperantoCallResult ConnectServiceImpl::handle_cluster_update_after_backend_connection(
    const uint8_t* payload,
    size_t len) const {
    if (!decode_empty_message(payload, len)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = {},
        };
    }
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_cluster_update_after_backend_connection_response(
            subsystem_.has_received_cluster_update_after_backend_connection()),
    };
}

EsperantoCallResult ConnectServiceImpl::handle_install_spotify(
    const uint8_t* payload,
    size_t len) const {
    InstallSpotifyRequest req;
    if (!decode_install_spotify_request(payload, len, req)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = {},
        };
    }
    const InstallSpotifyState state = req.connect_device_identifier.empty()
                                          ? InstallSpotifyState::DEVICE_NOT_FOUND
                                          : InstallSpotifyState::DEVICE_NOT_SUPPORTED;
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = encode_install_spotify_status_update(state),
    };
}

EsperantoCallResult ConnectServiceImpl::handle_perform_discovery(
    const uint8_t* payload,
    size_t len) {
    if (!decode_empty_message(payload, len)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = {},
        };
    }
    (void)subsystem_.perform_discovery();
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = {},
    };
}

EsperantoCallResult ConnectServiceImpl::handle_refresh_cluster(
    const uint8_t* payload,
    size_t len) {
    if (!decode_empty_message(payload, len)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = {},
        };
    }
    (void)subsystem_.refresh_cluster();
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = {},
    };
}

EsperantoCallResult ConnectServiceImpl::handle_wake_sleeping_cluster_devices(
    const uint8_t* payload,
    size_t len) {
    if (!decode_empty_message(payload, len)) {
        return EsperantoCallResult{
            .status = EsperantoCallStatus::kDecodeError,
            .payload = {},
        };
    }
    (void)subsystem_.wake_sleeping_cluster_devices();
    return EsperantoCallResult{
        .status = EsperantoCallStatus::kOk,
        .payload = {},
    };
}

}  // namespace spotify::connectstate::esperanto
