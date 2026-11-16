// ============================================================================
// 1:1 Replicated Spotify Connect State Protobuf Wire Encoders & Decoders
// Sources:
// - `liborbit-jni-spotify_memdump.so` offsets:
//   - 0x3fa5c4 (`connect.proto`)
//   - 0x3fdc98 (`connect-service.proto`)
//   - 0x3fe008 (`devices.proto`)
//   - 0x3fe6e8 (`player.proto`)
//   - 0x36de24 (`connect_group.proto`)
//   - 0x36a536 (`dodos_messages.proto`)
// - ARM64 ELF `liborbit-jni-spotify.so` FileDescriptorProto offsets:
//   - 0x631e5c (`connect.proto`), 0x635530 (`connect-service.proto`),
//     0x6358a0 (`devices.proto`), 0x635f80 (`player.proto`),
//     0x5a56c0 (`connect_group.proto`), 0x5a1dd0 (`dodos_messages.proto`)
// - Embedded proto messages (`connect.proto` @ ELF 0x631e5c / memdump 0x3fa5c4):
//   `spotify.connectstate.PutStateRequest`, `spotify.connectstate.Cluster`,
//   `spotify.connectstate.ClusterUpdate`
// ============================================================================

#pragma once

#include "../ProtobufWireHelper.h"

#include <cstdint>
#include <cstring>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

namespace spotify::connectstate {

enum class PutStateReason : uint32_t {
    UNKNOWN_PUT_STATE_REASON = 0,
    SPIRC_HELLO = 1,
    SPIRC_NOTIFY = 2,
    NEW_DEVICE = 3,
    PLAYER_STATE_CHANGED = 4,
    VOLUME_CHANGED = 5,
    PICKER_OPENED = 6,
    BECAME_INACTIVE = 7,
    ALIAS_CHANGED = 8,
    NEW_CONNECTION = 9,
    PULL_PLAYBACK = 10,
    AUDIO_DRIVER_INFO_CHANGED = 11,
    PUT_STATE_RATE_LIMITED = 12,
    BACKEND_METADATA_APPLIED = 13,
    LOCAL_DEVICES_CHANGED = 14,
    GROUP_STATE_CHANGED = 15,
    PRIVATE_SESSION_CHANGED = 16,
};

enum class MemberType : uint32_t {
    SPIRC_V2 = 0,
    SPIRC_V3 = 1,
    CONNECT_STATE = 2,
    CONNECT_STATE_EXTENDED = 5,
    ACTIVE_DEVICE_TRACKER = 6,
    PLAY_TOKEN = 7,
};

enum class DeviceType : uint32_t {
    UNKNOWN = 0,
    COMPUTER = 1,
    TABLET = 2,
    SMARTPHONE = 3,
    SPEAKER = 4,
    TV = 5,
    AVR = 6,
    STB = 7,
    AUDIO_DONGLE = 8,
    GAME_CONSOLE = 9,
    CAST_VIDEO = 10,
    CAST_AUDIO = 11,
    AUTOMOBILE = 12,
    SMARTWATCH = 13,
    CHROMEBOOK = 14,
    UNKNOWN_SPOTIFY = 100,
    CAR_THING = 101,
    OBSERVER = 102,
    HOME_THING = 103,
};

enum class AudioOutputDeviceType : uint32_t {
    UNKNOWN_AUDIO_OUTPUT_DEVICE_TYPE = 0,
    BUILT_IN_SPEAKER = 1,
    LINE_OUT = 2,
    BLUETOOTH = 3,
    AIRPLAY = 4,
    AUTOMOTIVE = 5,
    CAR_PROJECTED = 6,
};

enum class AudioOutputCategory : uint32_t {
    AUDIO_OUTPUT_CATEGORY_UNKNOWN = 0,
    AUDIO_OUTPUT_CATEGORY_CAR = 1,
    AUDIO_OUTPUT_CATEGORY_HEADPHONES = 2,
    AUDIO_OUTPUT_CATEGORY_SPEAKER = 3,
    AUDIO_OUTPUT_CATEGORY_WEARABLE = 4,
    AUDIO_OUTPUT_CATEGORY_GLASSES = 5,
    AUDIO_OUTPUT_CATEGORY_APP = 6,
};

enum class DodoDeviceType : uint32_t {
    UNKNOWN_DODO_DEVICE_TYPE = 0,
    DODO1 = 1,
    DODO2 = 2,
};

enum class AudioQuality : uint32_t {
    AUDIO_QUALITY_DEFAULT = 0,
    AUDIO_QUALITY_LOW = 1,
    AUDIO_QUALITY_NORMAL = 2,
    AUDIO_QUALITY_HIGH = 3,
    AUDIO_QUALITY_VERY_HIGH = 4,
    AUDIO_QUALITY_HIFI = 5,
    AUDIO_QUALITY_HIFI_24 = 6,
};

enum class ClusterUpdateReason : uint32_t {
    UNKNOWN_CLUSTER_UPDATE_REASON = 0,
    DEVICES_DISAPPEARED = 1,
    DEVICE_STATE_CHANGED = 2,
    NEW_DEVICE_APPEARED = 3,
    DEVICE_VOLUME_CHANGED = 4,
    DEVICE_ALIAS_CHANGED = 5,
    DEVICE_NEW_CONNECTION = 6,
};

enum class FileOrigin : uint32_t {
    FILE_ORIGIN_UNKNOWN = 0,
    FILE_ORIGIN_INTERNAL = 1,
    FILE_ORIGIN_EXTERNAL = 2,
    FILE_ORIGIN_LOCAL = 3,
    FILE_ORIGIN_GENERATED = 4,
};

enum class BitrateLevel : uint32_t {
    BITRATE_LEVEL_UNKNOWN = 0,
    BITRATE_LEVEL_LOW = 1,
    BITRATE_LEVEL_NORMAL = 2,
    BITRATE_LEVEL_HIGH = 3,
    BITRATE_LEVEL_VERY_HIGH = 4,
    BITRATE_LEVEL_HIFI = 5,
    BITRATE_LEVEL_HIFI24 = 6,
    BITRATE_LEVEL_PETREL = 7,
};

enum class BitrateStrategy : uint32_t {
    BITRATE_STRATEGY_UNKNOWN = 0,
    BITRATE_STRATEGY_BEST_MATCHING = 1,
    BITRATE_STRATEGY_BACKEND_ADVISED = 2,
    BITRATE_STRATEGY_OFFLINED_FILE = 3,
    BITRATE_STRATEGY_CACHED_FILE = 4,
    BITRATE_STRATEGY_LOCAL_FILE = 5,
};

enum class HiFiStatus : uint32_t {
    HIFI_STATUS_NONE = 0,
    HIFI_STATUS_OFF = 1,
    HIFI_STATUS_ON = 2,
};

enum class AddDeviceToGroupError : uint32_t {
    UNKNOWN_ERROR = 0,
    TIMEOUT = 1,
    DEVICE_NOT_GROUPABLE = 3,
    MAX_NUMBER_OF_DEVICES_REACHED = 4,
    NOT_IMPLEMENTED = 6,
    NOT_SUPPORTED = 7,
    INTEGRATION_ERROR = 8,
    SDK_ERROR = 9,
    CONNECT_ERROR = 10,
    GROUP_NOT_FOUND = 11,
    INVALID_GROUP = 12,
    BUSY = 13,
};

enum class RemoveDeviceFromGroupError : uint32_t {
    UNKNOWN_ERROR = 0,
    TIMEOUT = 1,
    DEVICE_NOT_REMOVABLE = 3,
    NOT_IMPLEMENTED = 5,
    NOT_SUPPORTED = 6,
    INTEGRATION_ERROR = 7,
    SDK_ERROR = 8,
    CONNECT_ERROR = 9,
    GROUP_NOT_FOUND = 10,
    INVALID_GROUP = 11,
    BUSY = 12,
};

enum class DeleteGroupError : uint32_t {
    UNKNOWN_ERROR = 0,
    TIMEOUT = 1,
    NOT_IMPLEMENTED = 4,
    NOT_SUPPORTED = 5,
    INTEGRATION_ERROR = 6,
    SDK_ERROR = 7,
    CONNECT_ERROR = 8,
    GROUP_NOT_FOUND = 9,
    INVALID_GROUP = 10,
    BUSY = 11,
};

enum class ResyncGroupDataError : uint32_t {
    UNKNOWN_ERROR = 0,
    TIMEOUT = 1,
    NOT_IMPLEMENTED = 2,
    SDK_ERROR = 3,
    CONNECT_ERROR = 4,
};

struct CapabilitySupportDetails {
    bool fully_supported{false};
    bool user_eligible{false};
    bool device_supported{false};
};

struct Capabilities {
    bool can_be_player{true};
    bool restrict_to_local{false};
    bool gaia_eq_connect_id{true};
    bool supports_logout{true};
    bool is_observable{true};
    int32_t volume_steps{64};
    std::vector<std::string> supported_types{"audio/episode", "audio/track"};
    bool command_acks{true};
    bool supports_rename{false};
    bool hidden{false};
    bool disable_volume{false};
    bool connect_disabled{false};
    bool supports_playlist_v2{true};
    bool is_controllable{true};
    bool supports_external_episodes{true};
    bool supports_set_backend_metadata{true};
    bool supports_transfer_command{true};
    bool supports_command_request{true};
    bool is_voice_enabled{false};
    bool needs_full_player_state{false};
    bool supports_gzip_pushes{true};
    bool supports_set_options_command{true};
    std::optional<CapabilitySupportDetails> supports_hifi;
    std::string connect_capabilities;
    bool supports_rooms{false};
    bool supports_dj{true};
    AudioQuality supported_audio_quality{AudioQuality::AUDIO_QUALITY_VERY_HIGH};
    bool supports_smart_shuffle_mode{true};
    bool supports_remote_sleep_timer{true};
    bool supports_ping_request{true};
    bool supports_playlist_mixing{true};
    bool supports_remote_audio_quality_control{true};
    bool supports_zephyr{true};
    bool supports_gapless{true};
    bool supports_crossfade{true};
};

struct AudioOutputDeviceInfo {
    AudioOutputDeviceType audio_output_device_type{AudioOutputDeviceType::UNKNOWN_AUDIO_OUTPUT_DEVICE_TYPE};
    std::string device_name;
    std::string brand;
    std::string model;
    AudioOutputCategory category{AudioOutputCategory::AUDIO_OUTPUT_CATEGORY_UNKNOWN};
};

struct DeviceAlias {
    uint32_t id{0};
    std::string display_name;
    bool is_group{false};
    std::string group_instance;
};

struct DeviceInfo {
    bool can_play{true};
    uint32_t volume{65535};
    std::string name;
    Capabilities capabilities;
    std::string device_software_version{"1.2.87.215"};
    DeviceType device_type{DeviceType::SMARTPHONE};
    std::string spirc_version{"3.2.0"};
    std::string device_id;
    bool is_private_session{false};
    bool is_social_connect{false};
    std::string client_id;
    std::string brand{"Musify"};
    std::string model{"Musify Mobile"};
    std::unordered_map<std::string, std::string> metadata_map;
    std::string product_id{"musify-client"};
    std::string deduplication_id;
    uint32_t selected_alias_id{0};
    std::unordered_map<uint32_t, DeviceAlias> device_aliases;
    bool is_offline{false};
    std::string public_ip;
    std::string license{"premium"};
    AudioOutputDeviceInfo audio_output_device_info;
    bool is_group{false};
    bool is_dynamic_device{false};
    std::vector<std::string> disallow_playback_reasons;
    std::vector<std::string> disallow_transfer_reasons;
    bool is_locally_discovered{false};
    std::string group_instance;
    bool is_public{true};
    bool is_wol_capable{false};
};

struct WakeOnLanInfo {
    std::vector<uint8_t> mac_address;
    uint32_t port{0};
    uint32_t retries{0};
    uint32_t delay_ms{0};
    bool broadcast_on_all_interfaces{false};
};

struct LocalDevice {
    std::string device_id;
    std::string device_name;
    DeviceType device_type{DeviceType::UNKNOWN};
    std::string client_id;
    std::string product_id;
    std::string brand;
    std::string model;
    std::string local_ip;
    uint32_t alias_id{0};
    std::vector<std::string> supported_media_types;
    bool supports_dj{false};
    bool supports_on_demand{false};
    bool is_voice_enabled{false};
    std::string license;
    std::optional<CapabilitySupportDetails> supports_hifi;
    std::vector<std::string> disallow_reasons;
    std::string connect_capabilities;
    bool supports_external_episodes{false};
    std::optional<WakeOnLanInfo> wol_info;
};

struct DodoDeviceInfo {
    struct PlayerStateSummary {
        bool is_playing{false};
        bool is_paused{false};
        bool disallow_pausing{false};
        bool disallow_resuming{false};
        bool disallow_skipping_prev{false};
        bool disallow_skipping_next{false};
    };

    std::string cs_id;
    DodoDeviceType dodo_device_type{DodoDeviceType::UNKNOWN_DODO_DEVICE_TYPE};
    PlayerStateSummary player_state_summary;
    uint64_t started_playing_at_timestamp{0};
};

struct SingleDodo {
    std::string dodo_id;
    std::string cs_id;
    bool is_primary{false};
    bool is_being_observed{false};
};

struct ContextIndex {
    uint32_t page{0};
    uint32_t track{0};
};

struct PlaybackQuality {
    BitrateLevel bitrate_level{BitrateLevel::BITRATE_LEVEL_UNKNOWN};
    BitrateStrategy strategy{BitrateStrategy::BITRATE_STRATEGY_UNKNOWN};
    BitrateLevel target_bitrate_level{BitrateLevel::BITRATE_LEVEL_UNKNOWN};
    bool target_bitrate_available{false};
    HiFiStatus hifi_status{HiFiStatus::HIFI_STATUS_NONE};
    BitrateLevel highest_available_quality{BitrateLevel::BITRATE_LEVEL_UNKNOWN};
    FileOrigin file_origin{FileOrigin::FILE_ORIGIN_UNKNOWN};
};

struct RestrictionReasons {
    std::vector<std::string> reasons;
};

struct ModeRestrictions {
    std::unordered_map<std::string, RestrictionReasons> values;
};

struct Restrictions {
    std::vector<std::string> disallow_pausing_reasons;
    std::vector<std::string> disallow_resuming_reasons;
    std::vector<std::string> disallow_seeking_reasons;
    std::vector<std::string> disallow_peeking_prev_reasons;
    std::vector<std::string> disallow_peeking_next_reasons;
    std::vector<std::string> disallow_skipping_prev_reasons;
    std::vector<std::string> disallow_skipping_next_reasons;
    std::vector<std::string> disallow_toggling_repeat_context_reasons;
    std::vector<std::string> disallow_toggling_repeat_track_reasons;
    std::vector<std::string> disallow_toggling_shuffle_reasons;
    std::vector<std::string> disallow_set_queue_reasons;
    std::vector<std::string> disallow_interrupting_playback_reasons;
    std::vector<std::string> disallow_transferring_playback_reasons;
    std::vector<std::string> disallow_remote_control_reasons;
    std::vector<std::string> disallow_inserting_into_next_tracks_reasons;
    std::vector<std::string> disallow_inserting_into_context_tracks_reasons;
    std::vector<std::string> disallow_reordering_in_next_tracks_reasons;
    std::vector<std::string> disallow_reordering_in_context_tracks_reasons;
    std::vector<std::string> disallow_removing_from_next_tracks_reasons;
    std::vector<std::string> disallow_removing_from_context_tracks_reasons;
    std::vector<std::string> disallow_updating_context_reasons;
    std::vector<std::string> disallow_playing_reasons;
    std::vector<std::string> disallow_stopping_reasons;
    std::vector<std::string> disallow_add_to_queue_reasons;
    std::vector<std::string> disallow_setting_playback_speed_reasons;
    std::unordered_map<std::string, ModeRestrictions> disallow_setting_modes;
    std::unordered_map<std::string, RestrictionReasons> disallow_signals;
    std::vector<std::string> disallow_play_as_next_in_queue_reasons;
    std::vector<std::string> disallow_sleep_timer_clear_reasons;
    std::vector<std::string> disallow_sleep_timer_duration_reasons;
    std::vector<std::string> disallow_sleep_timer_end_of_track_reasons;
    std::vector<std::string> disallow_add_to_queue_track_reasons;
    std::vector<std::string> disallow_tap_to_play_track_in_next_tracks_reasons;
    std::vector<std::string> disallow_reordering_track_in_next_tracks_reasons;
    std::vector<std::string> disallow_reordering_episode_in_next_tracks_reasons;
    std::vector<std::string> disallow_reordering_enqueued_track_in_next_tracks_reasons;
    std::vector<std::string> disallow_reordering_enqueued_episode_in_next_tracks_reasons;
    std::vector<std::string> disallow_viewing_queue_reasons;
    std::vector<std::string> disallow_viewing_ordered_tracks_in_next_tracks_reasons;

    [[nodiscard]] bool empty() const noexcept {
        return disallow_pausing_reasons.empty() &&
               disallow_resuming_reasons.empty() &&
               disallow_seeking_reasons.empty() &&
               disallow_peeking_prev_reasons.empty() &&
               disallow_peeking_next_reasons.empty() &&
               disallow_skipping_prev_reasons.empty() &&
               disallow_skipping_next_reasons.empty() &&
               disallow_toggling_repeat_context_reasons.empty() &&
               disallow_toggling_repeat_track_reasons.empty() &&
               disallow_toggling_shuffle_reasons.empty() &&
               disallow_set_queue_reasons.empty() &&
               disallow_interrupting_playback_reasons.empty() &&
               disallow_transferring_playback_reasons.empty() &&
               disallow_remote_control_reasons.empty() &&
               disallow_inserting_into_next_tracks_reasons.empty() &&
               disallow_inserting_into_context_tracks_reasons.empty() &&
               disallow_reordering_in_next_tracks_reasons.empty() &&
               disallow_reordering_in_context_tracks_reasons.empty() &&
               disallow_removing_from_next_tracks_reasons.empty() &&
               disallow_removing_from_context_tracks_reasons.empty() &&
               disallow_updating_context_reasons.empty() &&
               disallow_playing_reasons.empty() &&
               disallow_stopping_reasons.empty() &&
               disallow_add_to_queue_reasons.empty() &&
               disallow_setting_playback_speed_reasons.empty() &&
               disallow_setting_modes.empty() &&
               disallow_signals.empty() &&
               disallow_play_as_next_in_queue_reasons.empty() &&
               disallow_sleep_timer_clear_reasons.empty() &&
               disallow_sleep_timer_duration_reasons.empty() &&
               disallow_sleep_timer_end_of_track_reasons.empty() &&
               disallow_add_to_queue_track_reasons.empty() &&
               disallow_tap_to_play_track_in_next_tracks_reasons.empty() &&
               disallow_reordering_track_in_next_tracks_reasons.empty() &&
               disallow_reordering_episode_in_next_tracks_reasons.empty() &&
               disallow_reordering_enqueued_track_in_next_tracks_reasons.empty() &&
               disallow_reordering_enqueued_episode_in_next_tracks_reasons.empty() &&
               disallow_viewing_queue_reasons.empty() &&
               disallow_viewing_ordered_tracks_in_next_tracks_reasons.empty();
    }
};

struct PlayOrigin {
    std::string feature_identifier;
    std::string feature_version;
    std::string view_uri;
    std::string external_referrer;
    std::string referrer_identifier;
    std::string device_identifier;
    std::vector<std::string> feature_classes;
    std::string restriction_identifier;

    [[nodiscard]] bool empty() const noexcept {
        return feature_identifier.empty() &&
               feature_version.empty() &&
               view_uri.empty() &&
               external_referrer.empty() &&
               referrer_identifier.empty() &&
               device_identifier.empty() &&
               feature_classes.empty() &&
               restriction_identifier.empty();
    }
};

struct Suppressions {
    std::vector<std::string> providers;
};

struct AdBreakContext {
    uint64_t max_seconds_remaining{0};
    uint64_t position_in_current_ad_break{0};
    uint64_t total_ads_in_break_estimate{0};
};

struct SleepTimer {
    enum class Kind : uint8_t {
        Unset = 0,
        None = 1,
        Timestamp = 2,
        EndOfTrack = 3,
    };
    Kind kind{Kind::Unset};
    int64_t timestamp{0};
};

struct ProvidedTrack {
    std::string uri;
    std::string uid;
    std::unordered_map<std::string, std::string> metadata;
    std::vector<std::string> removed;
    std::vector<std::string> blocked;
    std::string provider{"context"};
    std::optional<Restrictions> restrictions;
    std::string album_uri;
    std::vector<std::string> disallow_reasons;
    std::string artist_uri;
};

struct ContextPlayerOptions {
    bool shuffling_context{false};
    bool repeating_context{false};
    bool repeating_track{false};
    float playback_speed{1.0f};
    std::unordered_map<std::string, std::string> modes;
};

struct PlayerState {
    int64_t timestamp{0};
    std::string context_uri;
    std::string context_url;
    std::optional<Restrictions> context_restrictions;
    std::optional<PlayOrigin> play_origin;
    std::optional<ContextIndex> index;
    ProvidedTrack track;
    std::string playback_id;
    double playback_speed{1.0};
    int64_t position_as_of_timestamp{0};
    int64_t duration{0};
    bool is_playing{false};
    bool is_paused{false};
    bool is_buffering{false};
    bool is_system_initiated{false};
    ContextPlayerOptions options;
    std::optional<Restrictions> restrictions;
    std::optional<Suppressions> suppressions;
    std::vector<ProvidedTrack> prev_tracks;
    std::vector<ProvidedTrack> next_tracks;
    std::unordered_map<std::string, std::string> context_metadata;
    std::unordered_map<std::string, std::string> page_metadata;
    std::string session_id;
    std::string queue_revision{"1"};
    int64_t position{0};
    std::optional<PlaybackQuality> playback_quality;
    std::vector<std::string> signals;
    std::string session_command_id;
    std::optional<AdBreakContext> ad_break_context;
    std::optional<SleepTimer> sleep_timer;
};

struct Device {
    DeviceInfo device_info;
    PlayerState player_state;
    bool has_player_state{false};
    std::string platform{"Android"};
    std::vector<uint8_t> transfer_data;
};

struct PutStateRequest {
    std::string callback_url;
    Device device;
    MemberType member_type{MemberType::CONNECT_STATE};
    bool is_active{false};
    PutStateReason put_state_reason{PutStateReason::NEW_DEVICE};
    uint32_t message_id{1};
    std::string last_command_sent_by_device_id;
    uint32_t last_command_message_id{0};
    uint64_t started_playing_at{0};
    uint64_t has_been_playing_for_ms{0};
    uint64_t client_side_timestamp{0};
    bool only_write_player_state{false};
};

struct PutStateRequestWrapper {
    std::string device_id;
    std::string connection_id;
    bool ignore_response{false};
    PutStateRequest put_state_request;
    bool wake_devices{false};
};

struct SetDeviceInactiveRequest {
    std::string device_id;
    bool notify_others{false};
    uint64_t client_side_timestamp{0};
};

struct SetDoDoRequest {
    std::string dodo1;
    std::string dodo2;
};

struct UpdateLocalDevicesRequest {
    std::string reporting_device_id;
    std::vector<LocalDevice> local_devices;
};

struct ConnectCommand {
    std::string command;
    std::string target_device_id;
};

struct Cluster {
    int64_t changed_timestamp_ms{0};
    std::string active_device_id;
    PlayerState player_state;
    std::unordered_map<std::string, DeviceInfo> devices;
    std::vector<uint8_t> transfer_data;
    uint64_t transfer_data_timestamp{0};
    bool need_full_player_state{false};
    int64_t server_timestamp_ms{0};
    bool needs_state_updates{false};
    uint64_t started_playing_at_timestamp{0};
    std::vector<DodoDeviceInfo> dodo_devices;
    bool needs_local_devices{false};
};

struct ClusterUpdate {
    Cluster cluster;
    ClusterUpdateReason update_reason{ClusterUpdateReason::UNKNOWN_CLUSTER_UPDATE_REASON};
    std::string ack_id;
    std::vector<std::string> devices_that_changed;
};

// Dealer Command Protos (`connect.proto` ELF 0x631e5c)
struct ConnectCommandOptions {
    int32_t message_id{0};
    uint32_t target_alias_id{0};
};

struct ConnectLoggingParams {
    std::vector<std::string> interaction_ids;
    std::vector<std::string> page_instance_ids;
};

struct LogoutCommand {
    ConnectCommandOptions command_options;
};

struct SetVolumeCommand {
    int32_t volume{0};
    ConnectCommandOptions command_options;
    ConnectLoggingParams logging_params;
    std::string connection_type;
    std::string sent_by_device_id;
    std::string group_device_identifier;
    std::string group_instance;
};

struct RenameCommand {
    std::string rename_to;
    ConnectCommandOptions command_options;
};

struct ProxyTransferCommand {
    std::string player_command_json;
    ConnectCommandOptions command_options;
    std::string target_device_id;
    ConnectLoggingParams logging_params;
    std::string command_id;
    std::optional<WakeOnLanInfo> wol_info;
};

struct ProxyWakeCommand {
    std::string target_device_id;
    std::optional<WakeOnLanInfo> wol_info;
    ConnectLoggingParams logging_params;
    std::string command_id;
};

struct SetBackendMetadataCommand {
    std::unordered_map<std::string, std::string> metadata;
};

struct AddDeviceToGroupCommand {
    std::string group_device_identifier;
    ConnectCommandOptions command_options;
    ConnectLoggingParams logging_params;
    std::string group_instance;
    std::string command_id;
};

struct AddDeviceToGroupCommandResponse {
    bool success{false};
    AddDeviceToGroupError error{AddDeviceToGroupError::UNKNOWN_ERROR};
};

struct RemoveDeviceFromGroupCommand {
    std::string group_device_identifier;
    ConnectCommandOptions command_options;
    ConnectLoggingParams logging_params;
    std::string group_instance;
    std::string command_id;
};

struct RemoveDeviceFromGroupCommandResponse {
    bool success{false};
    RemoveDeviceFromGroupError error{RemoveDeviceFromGroupError::UNKNOWN_ERROR};
};

struct DeleteGroupCommand {
    ConnectCommandOptions command_options;
    ConnectLoggingParams logging_params;
    std::string group_instance;
    std::string command_id;
};

struct DeleteGroupCommandResponse {
    bool success{false};
    DeleteGroupError error{DeleteGroupError::UNKNOWN_ERROR};
};

struct ResyncGroupDataCommand {
};

struct ResyncGroupDataCommandResponse {
    bool success{false};
    ResyncGroupDataError error{ResyncGroupDataError::UNKNOWN_ERROR};
};

// ============================================================================
// Wire Format Helpers
// ============================================================================

inline void encode_uint64_field(std::vector<uint8_t>& buf, uint32_t field_num, uint64_t val) {
    if (val == 0) return;
    spotify::player::encode_varint(buf, (field_num << 3) | 0);
    spotify::player::encode_varint(buf, val);
}

inline void encode_int64_field(std::vector<uint8_t>& buf, uint32_t field_num, int64_t val) {
    if (val == 0) return;
    spotify::player::encode_varint(buf, (field_num << 3) | 0);
    spotify::player::encode_varint(buf, static_cast<uint64_t>(val));
}

inline void encode_bool_field(std::vector<uint8_t>& buf, uint32_t field_num, bool val) {
    if (!val) return;
    spotify::player::encode_varint(buf, (field_num << 3) | 0);
    spotify::player::encode_varint(buf, 1);
}

inline void encode_double_field(std::vector<uint8_t>& buf, uint32_t field_num, double val) {
    if (val == 0.0) return;
    spotify::player::encode_varint(buf, (field_num << 3) | 1);
    uint64_t raw = 0;
    std::memcpy(&raw, &val, sizeof(double));
    for (size_t i = 0; i < 8; ++i) {
        buf.push_back(static_cast<uint8_t>((raw >> (i * 8)) & 0xFF));
    }
}

inline void encode_float_field(std::vector<uint8_t>& buf, uint32_t field_num, float val) {
    if (val == 0.0f) return;
    spotify::player::encode_varint(buf, (field_num << 3) | 5);
    uint32_t raw = 0;
    std::memcpy(&raw, &val, sizeof(float));
    for (size_t i = 0; i < 4; ++i) {
        buf.push_back(static_cast<uint8_t>((raw >> (i * 8)) & 0xFF));
    }
}

inline void encode_bytes_field(std::vector<uint8_t>& buf, uint32_t field_num, const std::vector<uint8_t>& data) {
    if (data.empty()) return;
    spotify::player::encode_varint(buf, (field_num << 3) | 2);
    spotify::player::encode_varint(buf, data.size());
    buf.insert(buf.end(), data.begin(), data.end());
}

inline void encode_string_map_entry(std::vector<uint8_t>& buf, uint32_t field_num, const std::string& key, const std::string& value) {
    std::vector<uint8_t> entry;
    spotify::player::encode_string_field(entry, 1, key);
    spotify::player::encode_string_field(entry, 2, value);
    spotify::player::encode_submessage_field(buf, field_num, entry);
}

inline bool decode_string_field_checked(
    const uint8_t*& ptr,
    const uint8_t* end,
    uint32_t wire_type,
    std::string& out) {
    if (wire_type != 2) {
        return spotify::player::skip_field(ptr, end, wire_type);
    }
    uint64_t len = 0;
    if (!spotify::player::decode_varint(ptr, end, len)) return false;
    if (!spotify::player::has_bytes(ptr, end, len)) return false;
    const size_t n = static_cast<size_t>(len);
    out.assign(reinterpret_cast<const char*>(ptr), n);
    ptr += n;
    return true;
}

inline bool decode_bytes_field_checked(
    const uint8_t*& ptr,
    const uint8_t* end,
    uint32_t wire_type,
    std::vector<uint8_t>& out) {
    if (wire_type != 2) {
        return spotify::player::skip_field(ptr, end, wire_type);
    }
    uint64_t len = 0;
    if (!spotify::player::decode_varint(ptr, end, len)) return false;
    if (!spotify::player::has_bytes(ptr, end, len)) return false;
    const size_t n = static_cast<size_t>(len);
    out.assign(ptr, ptr + n);
    ptr += n;
    return true;
}

inline bool decode_repeated_string_checked(
    const uint8_t*& ptr,
    const uint8_t* end,
    uint32_t wire_type,
    std::vector<std::string>& out) {
    if (wire_type != 2) {
        return spotify::player::skip_field(ptr, end, wire_type);
    }
    uint64_t len = 0;
    if (!spotify::player::decode_varint(ptr, end, len)) return false;
    if (!spotify::player::has_bytes(ptr, end, len)) return false;
    const size_t n = static_cast<size_t>(len);
    out.emplace_back(reinterpret_cast<const char*>(ptr), n);
    ptr += n;
    return true;
}

inline bool decode_varint_checked(
    const uint8_t*& ptr,
    const uint8_t* end,
    uint32_t wire_type,
    uint64_t& val,
    bool& decoded) {
    if (wire_type != 0) {
        decoded = false;
        return spotify::player::skip_field(ptr, end, wire_type);
    }
    decoded = true;
    return spotify::player::decode_varint(ptr, end, val);
}

inline bool decode_string_map_entry(
    const uint8_t*& ptr,
    const uint8_t* end,
    uint32_t wire_type,
    std::unordered_map<std::string, std::string>& out) {
    if (wire_type != 2) {
        return spotify::player::skip_field(ptr, end, wire_type);
    }
    uint64_t len = 0;
    if (!spotify::player::decode_varint(ptr, end, len)) return false;
    if (!spotify::player::has_bytes(ptr, end, len)) return false;
    const uint8_t* m_end = ptr + static_cast<size_t>(len);
    std::string k;
    std::string v;
    while (ptr < m_end) {
        uint64_t m_tag = 0;
        if (!spotify::player::decode_varint(ptr, m_end, m_tag)) return false;
        const uint32_t m_field = static_cast<uint32_t>(m_tag >> 3);
        const uint32_t m_wire = static_cast<uint32_t>(m_tag & 0x07);
        if (m_field == 1 && m_wire == 2) {
            uint64_t k_len = 0;
            if (!spotify::player::decode_varint(ptr, m_end, k_len)) return false;
            if (!spotify::player::has_bytes(ptr, m_end, k_len)) return false;
            const size_t kn = static_cast<size_t>(k_len);
            k.assign(reinterpret_cast<const char*>(ptr), kn);
            ptr += kn;
        } else if (m_field == 2 && m_wire == 2) {
            uint64_t v_len = 0;
            if (!spotify::player::decode_varint(ptr, m_end, v_len)) return false;
            if (!spotify::player::has_bytes(ptr, m_end, v_len)) return false;
            const size_t vn = static_cast<size_t>(v_len);
            v.assign(reinterpret_cast<const char*>(ptr), vn);
            ptr += vn;
        } else {
            if (!spotify::player::skip_field(ptr, m_end, m_wire)) return false;
        }
    }
    if (!k.empty()) {
        out[std::move(k)] = std::move(v);
    }
    return true;
}

// ============================================================================
// Encoders
// ============================================================================

inline std::vector<uint8_t> encode_capability_support_details(const CapabilitySupportDetails& details) {
    std::vector<uint8_t> buf;
    encode_bool_field(buf, 1, details.fully_supported);
    encode_bool_field(buf, 2, details.user_eligible);
    encode_bool_field(buf, 3, details.device_supported);
    return buf;
}

inline std::vector<uint8_t> encode_capabilities(const Capabilities& caps) {
    std::vector<uint8_t> buf;
    encode_bool_field(buf, 2, caps.can_be_player);
    encode_bool_field(buf, 3, caps.restrict_to_local);
    encode_bool_field(buf, 5, caps.gaia_eq_connect_id);
    encode_bool_field(buf, 6, caps.supports_logout);
    encode_bool_field(buf, 7, caps.is_observable);
    encode_int64_field(buf, 8, caps.volume_steps);
    for (const auto& t : caps.supported_types) {
        spotify::player::encode_string_field(buf, 9, t);
    }
    encode_bool_field(buf, 10, caps.command_acks);
    encode_bool_field(buf, 11, caps.supports_rename);
    encode_bool_field(buf, 12, caps.hidden);
    encode_bool_field(buf, 13, caps.disable_volume);
    encode_bool_field(buf, 14, caps.connect_disabled);
    encode_bool_field(buf, 15, caps.supports_playlist_v2);
    encode_bool_field(buf, 16, caps.is_controllable);
    encode_bool_field(buf, 17, caps.supports_external_episodes);
    encode_bool_field(buf, 18, caps.supports_set_backend_metadata);
    encode_bool_field(buf, 19, caps.supports_transfer_command);
    encode_bool_field(buf, 20, caps.supports_command_request);
    encode_bool_field(buf, 21, caps.is_voice_enabled);
    encode_bool_field(buf, 22, caps.needs_full_player_state);
    encode_bool_field(buf, 23, caps.supports_gzip_pushes);
    encode_bool_field(buf, 25, caps.supports_set_options_command);
    if (caps.supports_hifi.has_value()) {
        spotify::player::encode_submessage_field(
            buf, 26, encode_capability_support_details(*caps.supports_hifi));
    }
    spotify::player::encode_string_field(buf, 27, caps.connect_capabilities);
    encode_bool_field(buf, 28, caps.supports_rooms);
    encode_bool_field(buf, 29, caps.supports_dj);
    encode_uint64_field(buf, 30, static_cast<uint64_t>(caps.supported_audio_quality));
    encode_bool_field(buf, 33, caps.supports_smart_shuffle_mode);
    encode_bool_field(buf, 34, caps.supports_remote_sleep_timer);
    encode_bool_field(buf, 35, caps.supports_ping_request);
    encode_bool_field(buf, 36, caps.supports_playlist_mixing);
    encode_bool_field(buf, 37, caps.supports_remote_audio_quality_control);
    encode_bool_field(buf, 38, caps.supports_zephyr);
    encode_bool_field(buf, 39, caps.supports_gapless);
    encode_bool_field(buf, 40, caps.supports_crossfade);
    return buf;
}

inline std::vector<uint8_t> encode_audio_output_device_info(const AudioOutputDeviceInfo& info) {
    std::vector<uint8_t> buf;
    encode_uint64_field(buf, 1, static_cast<uint64_t>(info.audio_output_device_type));
    spotify::player::encode_string_field(buf, 2, info.device_name);
    spotify::player::encode_string_field(buf, 3, info.brand);
    spotify::player::encode_string_field(buf, 4, info.model);
    encode_uint64_field(buf, 5, static_cast<uint64_t>(info.category));
    return buf;
}

inline std::vector<uint8_t> encode_device_alias(const DeviceAlias& alias) {
    std::vector<uint8_t> buf;
    encode_uint64_field(buf, 1, alias.id);
    spotify::player::encode_string_field(buf, 2, alias.display_name);
    encode_bool_field(buf, 3, alias.is_group);
    spotify::player::encode_string_field(buf, 5, alias.group_instance);
    return buf;
}

inline std::vector<uint8_t> encode_device_info(const DeviceInfo& info) {
    std::vector<uint8_t> buf;
    encode_bool_field(buf, 1, info.can_play);
    encode_uint64_field(buf, 2, info.volume);
    spotify::player::encode_string_field(buf, 3, info.name);
    spotify::player::encode_submessage_field(buf, 4, encode_capabilities(info.capabilities));
    spotify::player::encode_string_field(buf, 6, info.device_software_version);
    encode_uint64_field(buf, 7, static_cast<uint64_t>(info.device_type));
    spotify::player::encode_string_field(buf, 9, info.spirc_version);
    spotify::player::encode_string_field(buf, 10, info.device_id);
    encode_bool_field(buf, 11, info.is_private_session);
    encode_bool_field(buf, 12, info.is_social_connect);
    spotify::player::encode_string_field(buf, 13, info.client_id);
    spotify::player::encode_string_field(buf, 14, info.brand);
    spotify::player::encode_string_field(buf, 15, info.model);
    for (const auto& [k, v] : info.metadata_map) {
        encode_string_map_entry(buf, 16, k, v);
    }
    spotify::player::encode_string_field(buf, 17, info.product_id);
    spotify::player::encode_string_field(buf, 18, info.deduplication_id);
    encode_uint64_field(buf, 19, info.selected_alias_id);
    for (const auto& [alias_key, alias_val] : info.device_aliases) {
        std::vector<uint8_t> entry;
        encode_uint64_field(entry, 1, alias_key);
        spotify::player::encode_submessage_field(entry, 2, encode_device_alias(alias_val));
        spotify::player::encode_submessage_field(buf, 20, entry);
    }
    encode_bool_field(buf, 21, info.is_offline);
    spotify::player::encode_string_field(buf, 22, info.public_ip);
    spotify::player::encode_string_field(buf, 23, info.license);
    spotify::player::encode_submessage_field(buf, 24, encode_audio_output_device_info(info.audio_output_device_info));
    encode_bool_field(buf, 25, info.is_group);
    encode_bool_field(buf, 26, info.is_dynamic_device);
    for (const auto& r : info.disallow_playback_reasons) {
        spotify::player::encode_string_field(buf, 27, r);
    }
    for (const auto& r : info.disallow_transfer_reasons) {
        spotify::player::encode_string_field(buf, 28, r);
    }
    encode_bool_field(buf, 29, info.is_locally_discovered);
    spotify::player::encode_string_field(buf, 31, info.group_instance);
    encode_bool_field(buf, 32, info.is_public);
    encode_bool_field(buf, 34, info.is_wol_capable);
    return buf;
}

inline std::vector<uint8_t> encode_wol_info(const WakeOnLanInfo& wol) {
    std::vector<uint8_t> buf;
    encode_bytes_field(buf, 1, wol.mac_address);
    encode_uint64_field(buf, 2, wol.port);
    encode_uint64_field(buf, 3, wol.retries);
    encode_uint64_field(buf, 4, wol.delay_ms);
    encode_bool_field(buf, 5, wol.broadcast_on_all_interfaces);
    return buf;
}

inline std::vector<uint8_t> encode_local_device(const LocalDevice& dev) {
    std::vector<uint8_t> buf;
    spotify::player::encode_string_field(buf, 1, dev.device_id);
    spotify::player::encode_string_field(buf, 2, dev.device_name);
    encode_uint64_field(buf, 3, static_cast<uint64_t>(dev.device_type));
    spotify::player::encode_string_field(buf, 4, dev.client_id);
    spotify::player::encode_string_field(buf, 5, dev.product_id);
    spotify::player::encode_string_field(buf, 6, dev.brand);
    spotify::player::encode_string_field(buf, 7, dev.model);
    spotify::player::encode_string_field(buf, 8, dev.local_ip);
    encode_uint64_field(buf, 9, dev.alias_id);
    for (const auto& m : dev.supported_media_types) {
        spotify::player::encode_string_field(buf, 11, m);
    }
    encode_bool_field(buf, 12, dev.supports_dj);
    encode_bool_field(buf, 13, dev.supports_on_demand);
    encode_bool_field(buf, 14, dev.is_voice_enabled);
    spotify::player::encode_string_field(buf, 15, dev.license);
    if (dev.supports_hifi.has_value()) {
        spotify::player::encode_submessage_field(
            buf, 16, encode_capability_support_details(*dev.supports_hifi));
    }
    for (const auto& r : dev.disallow_reasons) {
        spotify::player::encode_string_field(buf, 17, r);
    }
    spotify::player::encode_string_field(buf, 18, dev.connect_capabilities);
    encode_bool_field(buf, 19, dev.supports_external_episodes);
    if (dev.wol_info.has_value()) {
        spotify::player::encode_submessage_field(buf, 20, encode_wol_info(*dev.wol_info));
    }
    return buf;
}

inline std::vector<uint8_t> encode_dodo_device_info(const DodoDeviceInfo& dodo) {
    std::vector<uint8_t> buf;
    spotify::player::encode_string_field(buf, 1, dodo.cs_id);
    encode_uint64_field(buf, 2, static_cast<uint64_t>(dodo.dodo_device_type));
    {
        std::vector<uint8_t> summary;
        encode_bool_field(summary, 1, dodo.player_state_summary.is_playing);
        encode_bool_field(summary, 2, dodo.player_state_summary.is_paused);
        encode_bool_field(summary, 3, dodo.player_state_summary.disallow_pausing);
        encode_bool_field(summary, 4, dodo.player_state_summary.disallow_resuming);
        encode_bool_field(summary, 5, dodo.player_state_summary.disallow_skipping_prev);
        encode_bool_field(summary, 6, dodo.player_state_summary.disallow_skipping_next);
        spotify::player::encode_submessage_field(buf, 3, summary);
    }
    encode_uint64_field(buf, 4, dodo.started_playing_at_timestamp);
    return buf;
}

inline std::vector<uint8_t> encode_restriction_reasons(const RestrictionReasons& rr) {
    std::vector<uint8_t> buf;
    for (const auto& r : rr.reasons) {
        spotify::player::encode_string_field(buf, 1, r);
    }
    return buf;
}

inline std::vector<uint8_t> encode_mode_restrictions(const ModeRestrictions& mr) {
    std::vector<uint8_t> buf;
    for (const auto& [k, v] : mr.values) {
        std::vector<uint8_t> entry;
        spotify::player::encode_string_field(entry, 1, k);
        spotify::player::encode_submessage_field(entry, 2, encode_restriction_reasons(v));
        spotify::player::encode_submessage_field(buf, 1, entry);
    }
    return buf;
}

inline std::vector<uint8_t> encode_restrictions(const Restrictions& r) {
    std::vector<uint8_t> buf;
    auto emit_rep = [&buf](uint32_t fn, const std::vector<std::string>& vals) {
        for (const auto& v : vals) {
            spotify::player::encode_string_field(buf, fn, v);
        }
    };
    emit_rep(1, r.disallow_pausing_reasons);
    emit_rep(2, r.disallow_resuming_reasons);
    emit_rep(3, r.disallow_seeking_reasons);
    emit_rep(4, r.disallow_peeking_prev_reasons);
    emit_rep(5, r.disallow_peeking_next_reasons);
    emit_rep(6, r.disallow_skipping_prev_reasons);
    emit_rep(7, r.disallow_skipping_next_reasons);
    emit_rep(8, r.disallow_toggling_repeat_context_reasons);
    emit_rep(9, r.disallow_toggling_repeat_track_reasons);
    emit_rep(10, r.disallow_toggling_shuffle_reasons);
    emit_rep(11, r.disallow_set_queue_reasons);
    emit_rep(12, r.disallow_interrupting_playback_reasons);
    emit_rep(13, r.disallow_transferring_playback_reasons);
    emit_rep(14, r.disallow_remote_control_reasons);
    emit_rep(15, r.disallow_inserting_into_next_tracks_reasons);
    emit_rep(16, r.disallow_inserting_into_context_tracks_reasons);
    emit_rep(17, r.disallow_reordering_in_next_tracks_reasons);
    emit_rep(18, r.disallow_reordering_in_context_tracks_reasons);
    emit_rep(19, r.disallow_removing_from_next_tracks_reasons);
    emit_rep(20, r.disallow_removing_from_context_tracks_reasons);
    emit_rep(21, r.disallow_updating_context_reasons);
    emit_rep(22, r.disallow_playing_reasons);
    emit_rep(23, r.disallow_stopping_reasons);
    emit_rep(24, r.disallow_add_to_queue_reasons);
    emit_rep(25, r.disallow_setting_playback_speed_reasons);
    for (const auto& [k, v] : r.disallow_setting_modes) {
        std::vector<uint8_t> entry;
        spotify::player::encode_string_field(entry, 1, k);
        spotify::player::encode_submessage_field(entry, 2, encode_mode_restrictions(v));
        spotify::player::encode_submessage_field(buf, 28, entry);
    }
    for (const auto& [k, v] : r.disallow_signals) {
        std::vector<uint8_t> entry;
        spotify::player::encode_string_field(entry, 1, k);
        spotify::player::encode_submessage_field(entry, 2, encode_restriction_reasons(v));
        spotify::player::encode_submessage_field(buf, 29, entry);
    }
    emit_rep(30, r.disallow_play_as_next_in_queue_reasons);
    emit_rep(31, r.disallow_sleep_timer_clear_reasons);
    emit_rep(32, r.disallow_sleep_timer_duration_reasons);
    emit_rep(33, r.disallow_sleep_timer_end_of_track_reasons);
    emit_rep(34, r.disallow_add_to_queue_track_reasons);
    emit_rep(35, r.disallow_tap_to_play_track_in_next_tracks_reasons);
    emit_rep(36, r.disallow_reordering_track_in_next_tracks_reasons);
    emit_rep(37, r.disallow_reordering_episode_in_next_tracks_reasons);
    emit_rep(38, r.disallow_reordering_enqueued_track_in_next_tracks_reasons);
    emit_rep(39, r.disallow_reordering_enqueued_episode_in_next_tracks_reasons);
    emit_rep(40, r.disallow_viewing_queue_reasons);
    emit_rep(41, r.disallow_viewing_ordered_tracks_in_next_tracks_reasons);
    return buf;
}

inline std::vector<uint8_t> encode_play_origin(const PlayOrigin& po) {
    std::vector<uint8_t> buf;
    spotify::player::encode_string_field(buf, 1, po.feature_identifier);
    spotify::player::encode_string_field(buf, 2, po.feature_version);
    spotify::player::encode_string_field(buf, 3, po.view_uri);
    spotify::player::encode_string_field(buf, 4, po.external_referrer);
    spotify::player::encode_string_field(buf, 5, po.referrer_identifier);
    spotify::player::encode_string_field(buf, 6, po.device_identifier);
    for (const auto& fc : po.feature_classes) {
        spotify::player::encode_string_field(buf, 7, fc);
    }
    spotify::player::encode_string_field(buf, 8, po.restriction_identifier);
    return buf;
}

inline std::vector<uint8_t> encode_context_index(const ContextIndex& idx) {
    std::vector<uint8_t> buf;
    encode_uint64_field(buf, 1, idx.page);
    encode_uint64_field(buf, 2, idx.track);
    return buf;
}

inline std::vector<uint8_t> encode_suppressions(const Suppressions& sup) {
    std::vector<uint8_t> buf;
    for (const auto& p : sup.providers) {
        spotify::player::encode_string_field(buf, 1, p);
    }
    return buf;
}

inline std::vector<uint8_t> encode_playback_quality(const PlaybackQuality& pq) {
    std::vector<uint8_t> buf;
    encode_uint64_field(buf, 1, static_cast<uint64_t>(pq.bitrate_level));
    encode_uint64_field(buf, 2, static_cast<uint64_t>(pq.strategy));
    encode_uint64_field(buf, 3, static_cast<uint64_t>(pq.target_bitrate_level));
    encode_bool_field(buf, 4, pq.target_bitrate_available);
    encode_uint64_field(buf, 5, static_cast<uint64_t>(pq.hifi_status));
    encode_uint64_field(buf, 6, static_cast<uint64_t>(pq.highest_available_quality));
    encode_uint64_field(buf, 7, static_cast<uint64_t>(pq.file_origin));
    return buf;
}

inline std::vector<uint8_t> encode_ad_break_context(const AdBreakContext& abc) {
    std::vector<uint8_t> buf;
    encode_uint64_field(buf, 1, abc.max_seconds_remaining);
    encode_uint64_field(buf, 2, abc.position_in_current_ad_break);
    encode_uint64_field(buf, 3, abc.total_ads_in_break_estimate);
    return buf;
}

inline std::vector<uint8_t> encode_sleep_timer(const SleepTimer& st) {
    std::vector<uint8_t> buf;
    if (st.kind == SleepTimer::Kind::None) {
        spotify::player::encode_submessage_field(buf, 1, {});
    } else if (st.kind == SleepTimer::Kind::Timestamp) {
        std::vector<uint8_t> sub;
        encode_int64_field(sub, 1, st.timestamp);
        spotify::player::encode_submessage_field(buf, 2, sub);
    } else if (st.kind == SleepTimer::Kind::EndOfTrack) {
        spotify::player::encode_submessage_field(buf, 3, {});
    }
    return buf;
}

inline std::vector<uint8_t> encode_provided_track(const ProvidedTrack& track) {
    std::vector<uint8_t> buf;
    spotify::player::encode_string_field(buf, 1, track.uri);
    spotify::player::encode_string_field(buf, 2, track.uid);
    for (const auto& [k, v] : track.metadata) {
        encode_string_map_entry(buf, 3, k, v);
    }
    for (const auto& rem : track.removed) {
        spotify::player::encode_string_field(buf, 4, rem);
    }
    for (const auto& blk : track.blocked) {
        spotify::player::encode_string_field(buf, 5, blk);
    }
    spotify::player::encode_string_field(buf, 6, track.provider);
    if (track.restrictions.has_value()) {
        spotify::player::encode_submessage_field(buf, 7, encode_restrictions(*track.restrictions));
    }
    spotify::player::encode_string_field(buf, 8, track.album_uri);
    for (const auto& dis : track.disallow_reasons) {
        spotify::player::encode_string_field(buf, 9, dis);
    }
    spotify::player::encode_string_field(buf, 10, track.artist_uri);
    return buf;
}

inline std::vector<uint8_t> encode_context_player_options(const ContextPlayerOptions& opts) {
    std::vector<uint8_t> buf;
    encode_bool_field(buf, 1, opts.shuffling_context);
    encode_bool_field(buf, 2, opts.repeating_context);
    encode_bool_field(buf, 3, opts.repeating_track);
    encode_float_field(buf, 4, opts.playback_speed);
    for (const auto& [k, v] : opts.modes) {
        encode_string_map_entry(buf, 5, k, v);
    }
    return buf;
}

inline std::vector<uint8_t> encode_player_state(const PlayerState& ps) {
    std::vector<uint8_t> buf;
    encode_int64_field(buf, 1, ps.timestamp);
    spotify::player::encode_string_field(buf, 2, ps.context_uri);
    spotify::player::encode_string_field(buf, 3, ps.context_url);
    if (ps.context_restrictions.has_value()) {
        spotify::player::encode_submessage_field(buf, 4, encode_restrictions(*ps.context_restrictions));
    }
    if (ps.play_origin.has_value()) {
        spotify::player::encode_submessage_field(buf, 5, encode_play_origin(*ps.play_origin));
    }
    if (ps.index.has_value()) {
        spotify::player::encode_submessage_field(buf, 6, encode_context_index(*ps.index));
    }
    if (!ps.track.uri.empty()) {
        spotify::player::encode_submessage_field(buf, 7, encode_provided_track(ps.track));
    }
    spotify::player::encode_string_field(buf, 8, ps.playback_id);
    encode_double_field(buf, 9, ps.playback_speed);
    encode_int64_field(buf, 10, ps.position_as_of_timestamp);
    encode_int64_field(buf, 11, ps.duration);
    encode_bool_field(buf, 12, ps.is_playing);
    encode_bool_field(buf, 13, ps.is_paused);
    encode_bool_field(buf, 14, ps.is_buffering);
    encode_bool_field(buf, 15, ps.is_system_initiated);
    spotify::player::encode_submessage_field(buf, 16, encode_context_player_options(ps.options));
    if (ps.restrictions.has_value()) {
        spotify::player::encode_submessage_field(buf, 17, encode_restrictions(*ps.restrictions));
    }
    if (ps.suppressions.has_value()) {
        spotify::player::encode_submessage_field(buf, 18, encode_suppressions(*ps.suppressions));
    }
    for (const auto& pt : ps.prev_tracks) {
        spotify::player::encode_submessage_field(buf, 19, encode_provided_track(pt));
    }
    for (const auto& nt : ps.next_tracks) {
        spotify::player::encode_submessage_field(buf, 20, encode_provided_track(nt));
    }
    for (const auto& [k, v] : ps.context_metadata) {
        encode_string_map_entry(buf, 21, k, v);
    }
    for (const auto& [k, v] : ps.page_metadata) {
        encode_string_map_entry(buf, 22, k, v);
    }
    spotify::player::encode_string_field(buf, 23, ps.session_id);
    spotify::player::encode_string_field(buf, 24, ps.queue_revision);
    encode_int64_field(buf, 25, ps.position);
    if (ps.playback_quality.has_value()) {
        spotify::player::encode_submessage_field(buf, 32, encode_playback_quality(*ps.playback_quality));
    }
    for (const auto& sig : ps.signals) {
        spotify::player::encode_string_field(buf, 33, sig);
    }
    spotify::player::encode_string_field(buf, 35, ps.session_command_id);
    if (ps.ad_break_context.has_value()) {
        spotify::player::encode_submessage_field(buf, 37, encode_ad_break_context(*ps.ad_break_context));
    }
    if (ps.sleep_timer.has_value() && ps.sleep_timer->kind != SleepTimer::Kind::Unset) {
        spotify::player::encode_submessage_field(buf, 38, encode_sleep_timer(*ps.sleep_timer));
    }
    return buf;
}

[[nodiscard]] inline bool is_player_state_populated(const PlayerState& ps) noexcept {
    return ps.timestamp != 0 ||
           !ps.context_uri.empty() ||
           !ps.track.uri.empty() ||
           !ps.playback_id.empty() ||
           !ps.session_id.empty() ||
           ps.is_playing ||
           ps.is_paused ||
           ps.is_buffering;
}

inline std::vector<uint8_t> encode_device(const Device& dev) {
    std::vector<uint8_t> buf;
    spotify::player::encode_submessage_field(buf, 1, encode_device_info(dev.device_info));
    if (dev.has_player_state || is_player_state_populated(dev.player_state)) {
        spotify::player::encode_submessage_field(buf, 2, encode_player_state(dev.player_state));
    }
    if (!dev.platform.empty()) {
        std::vector<uint8_t> p_buf;
        spotify::player::encode_string_field(p_buf, 1, dev.platform);
        spotify::player::encode_submessage_field(buf, 3, p_buf);
    }
    encode_bytes_field(buf, 4, dev.transfer_data);
    return buf;
}

inline std::vector<uint8_t> encode_put_state_request(const PutStateRequest& req) {
    std::vector<uint8_t> buf;
    spotify::player::encode_string_field(buf, 1, req.callback_url);
    spotify::player::encode_submessage_field(buf, 2, encode_device(req.device));
    encode_uint64_field(buf, 3, static_cast<uint64_t>(req.member_type));
    encode_bool_field(buf, 4, req.is_active);
    encode_uint64_field(buf, 5, static_cast<uint64_t>(req.put_state_reason));
    encode_uint64_field(buf, 6, req.message_id);
    spotify::player::encode_string_field(buf, 7, req.last_command_sent_by_device_id);
    encode_uint64_field(buf, 8, req.last_command_message_id);
    encode_uint64_field(buf, 9, req.started_playing_at);
    // Tag 10 is unused in Spotify's connect.proto (`liborbit` memdump 0x3fa5c4)
    encode_uint64_field(buf, 11, req.has_been_playing_for_ms);
    encode_uint64_field(buf, 12, req.client_side_timestamp);
    encode_bool_field(buf, 13, req.only_write_player_state);
    return buf;
}

inline std::vector<uint8_t> encode_put_state_request_wrapper(const PutStateRequestWrapper& wrapper) {
    std::vector<uint8_t> buf;
    spotify::player::encode_string_field(buf, 1, wrapper.device_id);
    spotify::player::encode_string_field(buf, 2, wrapper.connection_id);
    encode_bool_field(buf, 3, wrapper.ignore_response);
    spotify::player::encode_submessage_field(buf, 4, encode_put_state_request(wrapper.put_state_request));
    encode_bool_field(buf, 5, wrapper.wake_devices);
    return buf;
}

inline std::vector<uint8_t> encode_set_device_inactive_request(const SetDeviceInactiveRequest& req) {
    std::vector<uint8_t> buf;
    spotify::player::encode_string_field(buf, 1, req.device_id);
    encode_bool_field(buf, 2, req.notify_others);
    encode_uint64_field(buf, 3, req.client_side_timestamp);
    return buf;
}

inline std::vector<uint8_t> encode_set_dodo_request(const SetDoDoRequest& req) {
    std::vector<uint8_t> buf;
    spotify::player::encode_string_field(buf, 1, req.dodo1);
    spotify::player::encode_string_field(buf, 2, req.dodo2);
    return buf;
}

inline std::vector<uint8_t> encode_update_local_devices_request(const UpdateLocalDevicesRequest& req) {
    std::vector<uint8_t> buf;
    spotify::player::encode_string_field(buf, 1, req.reporting_device_id);
    for (const auto& ld : req.local_devices) {
        spotify::player::encode_submessage_field(buf, 2, encode_local_device(ld));
    }
    return buf;
}

inline std::vector<uint8_t> encode_cluster(const Cluster& cluster) {
    std::vector<uint8_t> buf;
    encode_int64_field(buf, 1, cluster.changed_timestamp_ms);
    spotify::player::encode_string_field(buf, 2, cluster.active_device_id);
    if (is_player_state_populated(cluster.player_state)) {
        spotify::player::encode_submessage_field(buf, 3, encode_player_state(cluster.player_state));
    }
    for (const auto& [id, dev] : cluster.devices) {
        std::vector<uint8_t> entry;
        spotify::player::encode_string_field(entry, 1, id);
        spotify::player::encode_submessage_field(entry, 2, encode_device_info(dev));
        spotify::player::encode_submessage_field(buf, 4, entry);
    }
    encode_bytes_field(buf, 5, cluster.transfer_data);
    encode_uint64_field(buf, 6, cluster.transfer_data_timestamp);
    encode_bool_field(buf, 8, cluster.need_full_player_state);
    encode_int64_field(buf, 9, cluster.server_timestamp_ms);
    encode_bool_field(buf, 10, cluster.needs_state_updates);
    encode_uint64_field(buf, 11, cluster.started_playing_at_timestamp);
    for (const auto& dodo : cluster.dodo_devices) {
        spotify::player::encode_submessage_field(buf, 12, encode_dodo_device_info(dodo));
    }
    encode_bool_field(buf, 13, cluster.needs_local_devices);
    return buf;
}

inline std::vector<uint8_t> encode_cluster_update(const ClusterUpdate& update) {
    std::vector<uint8_t> buf;
    spotify::player::encode_submessage_field(buf, 1, encode_cluster(update.cluster));
    encode_uint64_field(buf, 2, static_cast<uint64_t>(update.update_reason));
    spotify::player::encode_string_field(buf, 3, update.ack_id);
    for (const auto& d : update.devices_that_changed) {
        spotify::player::encode_string_field(buf, 4, d);
    }
    return buf;
}

inline std::vector<uint8_t> encode_connect_command_options(const ConnectCommandOptions& opts) {
    std::vector<uint8_t> buf;
    encode_int64_field(buf, 1, opts.message_id);
    encode_uint64_field(buf, 3, opts.target_alias_id);
    return buf;
}

inline std::vector<uint8_t> encode_connect_logging_params(const ConnectLoggingParams& lp) {
    std::vector<uint8_t> buf;
    for (const auto& id : lp.interaction_ids) {
        spotify::player::encode_string_field(buf, 1, id);
    }
    for (const auto& pid : lp.page_instance_ids) {
        spotify::player::encode_string_field(buf, 2, pid);
    }
    return buf;
}

inline std::vector<uint8_t> encode_set_volume_command(const SetVolumeCommand& cmd) {
    std::vector<uint8_t> buf;
    encode_int64_field(buf, 1, cmd.volume);
    spotify::player::encode_submessage_field(buf, 2, encode_connect_command_options(cmd.command_options));
    spotify::player::encode_submessage_field(buf, 3, encode_connect_logging_params(cmd.logging_params));
    spotify::player::encode_string_field(buf, 4, cmd.connection_type);
    spotify::player::encode_string_field(buf, 5, cmd.sent_by_device_id);
    spotify::player::encode_string_field(buf, 6, cmd.group_device_identifier);
    spotify::player::encode_string_field(buf, 7, cmd.group_instance);
    return buf;
}

inline std::vector<uint8_t> encode_logout_command(const LogoutCommand& cmd) {
    std::vector<uint8_t> buf;
    spotify::player::encode_submessage_field(buf, 1, encode_connect_command_options(cmd.command_options));
    return buf;
}

inline std::vector<uint8_t> encode_rename_command(const RenameCommand& cmd) {
    std::vector<uint8_t> buf;
    spotify::player::encode_string_field(buf, 1, cmd.rename_to);
    spotify::player::encode_submessage_field(buf, 2, encode_connect_command_options(cmd.command_options));
    return buf;
}

inline std::vector<uint8_t> encode_add_device_to_group_command(const AddDeviceToGroupCommand& cmd) {
    std::vector<uint8_t> buf;
    spotify::player::encode_string_field(buf, 1, cmd.group_device_identifier);
    spotify::player::encode_submessage_field(buf, 2, encode_connect_command_options(cmd.command_options));
    spotify::player::encode_submessage_field(buf, 3, encode_connect_logging_params(cmd.logging_params));
    spotify::player::encode_string_field(buf, 4, cmd.group_instance);
    spotify::player::encode_string_field(buf, 5, cmd.command_id);
    return buf;
}

inline std::vector<uint8_t> encode_remove_device_from_group_command(const RemoveDeviceFromGroupCommand& cmd) {
    std::vector<uint8_t> buf;
    spotify::player::encode_string_field(buf, 1, cmd.group_device_identifier);
    spotify::player::encode_submessage_field(buf, 2, encode_connect_command_options(cmd.command_options));
    spotify::player::encode_submessage_field(buf, 3, encode_connect_logging_params(cmd.logging_params));
    spotify::player::encode_string_field(buf, 4, cmd.group_instance);
    spotify::player::encode_string_field(buf, 5, cmd.command_id);
    return buf;
}

inline std::vector<uint8_t> encode_delete_group_command(const DeleteGroupCommand& cmd) {
    std::vector<uint8_t> buf;
    spotify::player::encode_submessage_field(buf, 1, encode_connect_command_options(cmd.command_options));
    spotify::player::encode_submessage_field(buf, 2, encode_connect_logging_params(cmd.logging_params));
    spotify::player::encode_string_field(buf, 3, cmd.group_instance);
    spotify::player::encode_string_field(buf, 4, cmd.command_id);
    return buf;
}

// ============================================================================
// Decoders (Every switch case validates wire_type before parsing)
// ============================================================================

inline bool decode_capability_support_details(const uint8_t* ptr, size_t size, CapabilitySupportDetails& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        uint64_t val = 0;
        bool ok = false;
        switch (field_num) {
            case 1:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.fully_supported = (val != 0);
                break;
            case 2:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.user_eligible = (val != 0);
                break;
            case 3:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.device_supported = (val != 0);
                break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_capabilities(const uint8_t* ptr, size_t size, Capabilities& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        uint64_t val = 0;
        bool ok = false;

        switch (field_num) {
            case 2:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.can_be_player = (val != 0);
                break;
            case 3:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.restrict_to_local = (val != 0);
                break;
            case 5:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.gaia_eq_connect_id = (val != 0);
                break;
            case 6:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supports_logout = (val != 0);
                break;
            case 7:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.is_observable = (val != 0);
                break;
            case 8:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.volume_steps = static_cast<int32_t>(val);
                break;
            case 9:
                if (!decode_repeated_string_checked(ptr, end, wire_type, out.supported_types)) return false;
                break;
            case 10:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.command_acks = (val != 0);
                break;
            case 11:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supports_rename = (val != 0);
                break;
            case 12:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.hidden = (val != 0);
                break;
            case 13:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.disable_volume = (val != 0);
                break;
            case 14:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.connect_disabled = (val != 0);
                break;
            case 15:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supports_playlist_v2 = (val != 0);
                break;
            case 16:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.is_controllable = (val != 0);
                break;
            case 17:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supports_external_episodes = (val != 0);
                break;
            case 18:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supports_set_backend_metadata = (val != 0);
                break;
            case 19:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supports_transfer_command = (val != 0);
                break;
            case 20:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supports_command_request = (val != 0);
                break;
            case 21:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.is_voice_enabled = (val != 0);
                break;
            case 22:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.needs_full_player_state = (val != 0);
                break;
            case 23:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supports_gzip_pushes = (val != 0);
                break;
            case 25:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supports_set_options_command = (val != 0);
                break;
            case 26: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                CapabilitySupportDetails details;
                if (!decode_capability_support_details(ptr, static_cast<size_t>(len), details)) return false;
                out.supports_hifi = details;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 27:
                if (!decode_string_field_checked(ptr, end, wire_type, out.connect_capabilities)) return false;
                break;
            case 28:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supports_rooms = (val != 0);
                break;
            case 29:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supports_dj = (val != 0);
                break;
            case 30:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supported_audio_quality = static_cast<AudioQuality>(val);
                break;
            case 33:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supports_smart_shuffle_mode = (val != 0);
                break;
            case 34:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supports_remote_sleep_timer = (val != 0);
                break;
            case 35:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supports_ping_request = (val != 0);
                break;
            case 36:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supports_playlist_mixing = (val != 0);
                break;
            case 37:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supports_remote_audio_quality_control = (val != 0);
                break;
            case 38:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supports_zephyr = (val != 0);
                break;
            case 39:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supports_gapless = (val != 0);
                break;
            case 40:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.supports_crossfade = (val != 0);
                break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_audio_output_device_info(const uint8_t* ptr, size_t size, AudioOutputDeviceInfo& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        uint64_t val = 0;
        bool ok = false;

        switch (field_num) {
            case 1:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.audio_output_device_type = static_cast<AudioOutputDeviceType>(val);
                break;
            case 2:
                if (!decode_string_field_checked(ptr, end, wire_type, out.device_name)) return false;
                break;
            case 3:
                if (!decode_string_field_checked(ptr, end, wire_type, out.brand)) return false;
                break;
            case 4:
                if (!decode_string_field_checked(ptr, end, wire_type, out.model)) return false;
                break;
            case 5:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.category = static_cast<AudioOutputCategory>(val);
                break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_device_alias(const uint8_t* ptr, size_t size, DeviceAlias& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        uint64_t val = 0;
        bool ok = false;

        switch (field_num) {
            case 1:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.id = static_cast<uint32_t>(val);
                break;
            case 2:
                if (!decode_string_field_checked(ptr, end, wire_type, out.display_name)) return false;
                break;
            case 3:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.is_group = (val != 0);
                break;
            case 5:
                if (!decode_string_field_checked(ptr, end, wire_type, out.group_instance)) return false;
                break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_device_info(const uint8_t* ptr, size_t size, DeviceInfo& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        uint64_t val = 0;
        bool ok = false;

        switch (field_num) {
            case 1:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.can_play = (val != 0);
                break;
            case 2:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.volume = static_cast<uint32_t>(val);
                break;
            case 3:
                if (!decode_string_field_checked(ptr, end, wire_type, out.name)) return false;
                break;
            case 4: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_capabilities(ptr, static_cast<size_t>(len), out.capabilities)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 6:
                if (!decode_string_field_checked(ptr, end, wire_type, out.device_software_version)) return false;
                break;
            case 7:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.device_type = static_cast<DeviceType>(val);
                break;
            case 9:
                if (!decode_string_field_checked(ptr, end, wire_type, out.spirc_version)) return false;
                break;
            case 10:
                if (!decode_string_field_checked(ptr, end, wire_type, out.device_id)) return false;
                break;
            case 11:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.is_private_session = (val != 0);
                break;
            case 12:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.is_social_connect = (val != 0);
                break;
            case 13:
                if (!decode_string_field_checked(ptr, end, wire_type, out.client_id)) return false;
                break;
            case 14:
                if (!decode_string_field_checked(ptr, end, wire_type, out.brand)) return false;
                break;
            case 15:
                if (!decode_string_field_checked(ptr, end, wire_type, out.model)) return false;
                break;
            case 16:
                if (!decode_string_map_entry(ptr, end, wire_type, out.metadata_map)) return false;
                break;
            case 17:
                if (!decode_string_field_checked(ptr, end, wire_type, out.product_id)) return false;
                break;
            case 18:
                if (!decode_string_field_checked(ptr, end, wire_type, out.deduplication_id)) return false;
                break;
            case 19:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.selected_alias_id = static_cast<uint32_t>(val);
                break;
            case 20: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                const uint8_t* m_end = ptr + static_cast<size_t>(len);
                uint32_t alias_key = 0;
                bool has_key = false;
                DeviceAlias alias_val;
                while (ptr < m_end) {
                    uint64_t m_tag = 0;
                    if (!spotify::player::decode_varint(ptr, m_end, m_tag)) return false;
                    const uint32_t m_field = static_cast<uint32_t>(m_tag >> 3);
                    const uint32_t m_wire = static_cast<uint32_t>(m_tag & 0x07);
                    if (m_field == 1 && m_wire == 0) {
                        uint64_t kv = 0;
                        if (!spotify::player::decode_varint(ptr, m_end, kv)) return false;
                        alias_key = static_cast<uint32_t>(kv);
                        has_key = true;
                    } else if (m_field == 2 && m_wire == 2) {
                        uint64_t v_len = 0;
                        if (!spotify::player::decode_varint(ptr, m_end, v_len) || !spotify::player::has_bytes(ptr, m_end, v_len)) return false;
                        if (!decode_device_alias(ptr, v_len, alias_val)) return false;
                        ptr += static_cast<size_t>(v_len);
                    } else {
                        if (!spotify::player::skip_field(ptr, m_end, m_wire)) return false;
                    }
                }
                if (has_key || alias_val.id != 0) {
                    if (!has_key) alias_key = alias_val.id;
                    if (alias_val.id == 0) alias_val.id = alias_key;
                    out.device_aliases[alias_key] = std::move(alias_val);
                }
                break;
            }
            case 21:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.is_offline = (val != 0);
                break;
            case 22:
                if (!decode_string_field_checked(ptr, end, wire_type, out.public_ip)) return false;
                break;
            case 23:
                if (!decode_string_field_checked(ptr, end, wire_type, out.license)) return false;
                break;
            case 24: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_audio_output_device_info(ptr, static_cast<size_t>(len), out.audio_output_device_info)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 25:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.is_group = (val != 0);
                break;
            case 26:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.is_dynamic_device = (val != 0);
                break;
            case 27:
                if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_playback_reasons)) return false;
                break;
            case 28:
                if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_transfer_reasons)) return false;
                break;
            case 29:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.is_locally_discovered = (val != 0);
                break;
            case 31:
                if (!decode_string_field_checked(ptr, end, wire_type, out.group_instance)) return false;
                break;
            case 32:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.is_public = (val != 0);
                break;
            case 34:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.is_wol_capable = (val != 0);
                break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_wol_info(const uint8_t* ptr, size_t size, WakeOnLanInfo& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        uint64_t val = 0;
        bool ok = false;

        switch (field_num) {
            case 1:
                if (!decode_bytes_field_checked(ptr, end, wire_type, out.mac_address)) return false;
                break;
            case 2:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.port = static_cast<uint32_t>(val);
                break;
            case 3:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.retries = static_cast<uint32_t>(val);
                break;
            case 4:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.delay_ms = static_cast<uint32_t>(val);
                break;
            case 5:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.broadcast_on_all_interfaces = (val != 0);
                break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_dodo_device_info(const uint8_t* ptr, size_t size, DodoDeviceInfo& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        uint64_t val = 0;
        bool ok = false;

        switch (field_num) {
            case 1:
                if (!decode_string_field_checked(ptr, end, wire_type, out.cs_id)) return false;
                break;
            case 2:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.dodo_device_type = static_cast<DodoDeviceType>(val);
                break;
            case 3: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                const uint8_t* s_end = ptr + static_cast<size_t>(len);
                while (ptr < s_end) {
                    uint64_t s_tag = 0;
                    if (!spotify::player::decode_varint(ptr, s_end, s_tag)) return false;
                    const uint32_t sf = static_cast<uint32_t>(s_tag >> 3);
                    const uint32_t sw = static_cast<uint32_t>(s_tag & 0x07);
                    uint64_t sv = 0;
                    bool sok = false;
                    switch (sf) {
                        case 1:
                            if (!decode_varint_checked(ptr, s_end, sw, sv, sok)) return false;
                            if (sok) out.player_state_summary.is_playing = (sv != 0);
                            break;
                        case 2:
                            if (!decode_varint_checked(ptr, s_end, sw, sv, sok)) return false;
                            if (sok) out.player_state_summary.is_paused = (sv != 0);
                            break;
                        case 3:
                            if (!decode_varint_checked(ptr, s_end, sw, sv, sok)) return false;
                            if (sok) out.player_state_summary.disallow_pausing = (sv != 0);
                            break;
                        case 4:
                            if (!decode_varint_checked(ptr, s_end, sw, sv, sok)) return false;
                            if (sok) out.player_state_summary.disallow_resuming = (sv != 0);
                            break;
                        case 5:
                            if (!decode_varint_checked(ptr, s_end, sw, sv, sok)) return false;
                            if (sok) out.player_state_summary.disallow_skipping_prev = (sv != 0);
                            break;
                        case 6:
                            if (!decode_varint_checked(ptr, s_end, sw, sv, sok)) return false;
                            if (sok) out.player_state_summary.disallow_skipping_next = (sv != 0);
                            break;
                        default:
                            if (!spotify::player::skip_field(ptr, s_end, sw)) return false;
                            break;
                    }
                }
                break;
            }
            case 4:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.started_playing_at_timestamp = val;
                break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_restriction_reasons(const uint8_t* ptr, size_t size, RestrictionReasons& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        if (field_num == 1) {
            if (!decode_repeated_string_checked(ptr, end, wire_type, out.reasons)) return false;
        } else {
            if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
        }
    }
    return true;
}

inline bool decode_mode_restrictions(const uint8_t* ptr, size_t size, ModeRestrictions& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        if (field_num == 1 && wire_type == 2) {
            uint64_t len = 0;
            if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
            const uint8_t* m_end = ptr + static_cast<size_t>(len);
            std::string k;
            RestrictionReasons rr;
            while (ptr < m_end) {
                uint64_t mt = 0;
                if (!spotify::player::decode_varint(ptr, m_end, mt)) return false;
                const uint32_t mf = static_cast<uint32_t>(mt >> 3);
                const uint32_t mw = static_cast<uint32_t>(mt & 0x07);
                if (mf == 1 && mw == 2) {
                    if (!decode_string_field_checked(ptr, m_end, mw, k)) return false;
                } else if (mf == 2 && mw == 2) {
                    uint64_t vlen = 0;
                    if (!spotify::player::decode_varint(ptr, m_end, vlen) || !spotify::player::has_bytes(ptr, m_end, vlen)) return false;
                    if (!decode_restriction_reasons(ptr, vlen, rr)) return false;
                    ptr += static_cast<size_t>(vlen);
                } else {
                    if (!spotify::player::skip_field(ptr, m_end, mw)) return false;
                }
            }
            if (!k.empty()) out.values[std::move(k)] = std::move(rr);
        } else {
            if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
        }
    }
    return true;
}

inline bool decode_restrictions(const uint8_t* ptr, size_t size, Restrictions& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);

        switch (field_num) {
            case 1: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_pausing_reasons)) return false; break;
            case 2: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_resuming_reasons)) return false; break;
            case 3: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_seeking_reasons)) return false; break;
            case 4: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_peeking_prev_reasons)) return false; break;
            case 5: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_peeking_next_reasons)) return false; break;
            case 6: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_skipping_prev_reasons)) return false; break;
            case 7: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_skipping_next_reasons)) return false; break;
            case 8: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_toggling_repeat_context_reasons)) return false; break;
            case 9: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_toggling_repeat_track_reasons)) return false; break;
            case 10: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_toggling_shuffle_reasons)) return false; break;
            case 11: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_set_queue_reasons)) return false; break;
            case 12: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_interrupting_playback_reasons)) return false; break;
            case 13: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_transferring_playback_reasons)) return false; break;
            case 14: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_remote_control_reasons)) return false; break;
            case 15: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_inserting_into_next_tracks_reasons)) return false; break;
            case 16: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_inserting_into_context_tracks_reasons)) return false; break;
            case 17: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_reordering_in_next_tracks_reasons)) return false; break;
            case 18: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_reordering_in_context_tracks_reasons)) return false; break;
            case 19: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_removing_from_next_tracks_reasons)) return false; break;
            case 20: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_removing_from_context_tracks_reasons)) return false; break;
            case 21: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_updating_context_reasons)) return false; break;
            case 22: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_playing_reasons)) return false; break;
            case 23: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_stopping_reasons)) return false; break;
            case 24: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_add_to_queue_reasons)) return false; break;
            case 25: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_setting_playback_speed_reasons)) return false; break;
            case 28: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                const uint8_t* m_end = ptr + static_cast<size_t>(len);
                std::string k;
                ModeRestrictions mr;
                while (ptr < m_end) {
                    uint64_t mt = 0;
                    if (!spotify::player::decode_varint(ptr, m_end, mt)) return false;
                    const uint32_t mf = static_cast<uint32_t>(mt >> 3);
                    const uint32_t mw = static_cast<uint32_t>(mt & 0x07);
                    if (mf == 1 && mw == 2) {
                        if (!decode_string_field_checked(ptr, m_end, mw, k)) return false;
                    } else if (mf == 2 && mw == 2) {
                        uint64_t vlen = 0;
                        if (!spotify::player::decode_varint(ptr, m_end, vlen) || !spotify::player::has_bytes(ptr, m_end, vlen)) return false;
                        if (!decode_mode_restrictions(ptr, vlen, mr)) return false;
                        ptr += static_cast<size_t>(vlen);
                    } else {
                        if (!spotify::player::skip_field(ptr, m_end, mw)) return false;
                    }
                }
                if (!k.empty()) out.disallow_setting_modes[std::move(k)] = std::move(mr);
                break;
            }
            case 29: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                const uint8_t* m_end = ptr + static_cast<size_t>(len);
                std::string k;
                RestrictionReasons rr;
                while (ptr < m_end) {
                    uint64_t mt = 0;
                    if (!spotify::player::decode_varint(ptr, m_end, mt)) return false;
                    const uint32_t mf = static_cast<uint32_t>(mt >> 3);
                    const uint32_t mw = static_cast<uint32_t>(mt & 0x07);
                    if (mf == 1 && mw == 2) {
                        if (!decode_string_field_checked(ptr, m_end, mw, k)) return false;
                    } else if (mf == 2 && mw == 2) {
                        uint64_t vlen = 0;
                        if (!spotify::player::decode_varint(ptr, m_end, vlen) || !spotify::player::has_bytes(ptr, m_end, vlen)) return false;
                        if (!decode_restriction_reasons(ptr, vlen, rr)) return false;
                        ptr += static_cast<size_t>(vlen);
                    } else {
                        if (!spotify::player::skip_field(ptr, m_end, mw)) return false;
                    }
                }
                if (!k.empty()) out.disallow_signals[std::move(k)] = std::move(rr);
                break;
            }
            case 30: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_play_as_next_in_queue_reasons)) return false; break;
            case 31: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_sleep_timer_clear_reasons)) return false; break;
            case 32: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_sleep_timer_duration_reasons)) return false; break;
            case 33: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_sleep_timer_end_of_track_reasons)) return false; break;
            case 34: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_add_to_queue_track_reasons)) return false; break;
            case 35: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_tap_to_play_track_in_next_tracks_reasons)) return false; break;
            case 36: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_reordering_track_in_next_tracks_reasons)) return false; break;
            case 37: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_reordering_episode_in_next_tracks_reasons)) return false; break;
            case 38: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_reordering_enqueued_track_in_next_tracks_reasons)) return false; break;
            case 39: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_reordering_enqueued_episode_in_next_tracks_reasons)) return false; break;
            case 40: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_viewing_queue_reasons)) return false; break;
            case 41: if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_viewing_ordered_tracks_in_next_tracks_reasons)) return false; break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_play_origin(const uint8_t* ptr, size_t size, PlayOrigin& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        switch (field_num) {
            case 1: if (!decode_string_field_checked(ptr, end, wire_type, out.feature_identifier)) return false; break;
            case 2: if (!decode_string_field_checked(ptr, end, wire_type, out.feature_version)) return false; break;
            case 3: if (!decode_string_field_checked(ptr, end, wire_type, out.view_uri)) return false; break;
            case 4: if (!decode_string_field_checked(ptr, end, wire_type, out.external_referrer)) return false; break;
            case 5: if (!decode_string_field_checked(ptr, end, wire_type, out.referrer_identifier)) return false; break;
            case 6: if (!decode_string_field_checked(ptr, end, wire_type, out.device_identifier)) return false; break;
            case 7: if (!decode_repeated_string_checked(ptr, end, wire_type, out.feature_classes)) return false; break;
            case 8: if (!decode_string_field_checked(ptr, end, wire_type, out.restriction_identifier)) return false; break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_context_index(const uint8_t* ptr, size_t size, ContextIndex& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        uint64_t val = 0;
        bool ok = false;
        switch (field_num) {
            case 1:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.page = static_cast<uint32_t>(val);
                break;
            case 2:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.track = static_cast<uint32_t>(val);
                break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_suppressions(const uint8_t* ptr, size_t size, Suppressions& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        if (field_num == 1) {
            if (!decode_repeated_string_checked(ptr, end, wire_type, out.providers)) return false;
        } else {
            if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
        }
    }
    return true;
}

inline bool decode_playback_quality(const uint8_t* ptr, size_t size, PlaybackQuality& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        uint64_t val = 0;
        bool ok = false;
        switch (field_num) {
            case 1:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.bitrate_level = static_cast<BitrateLevel>(val);
                break;
            case 2:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.strategy = static_cast<BitrateStrategy>(val);
                break;
            case 3:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.target_bitrate_level = static_cast<BitrateLevel>(val);
                break;
            case 4:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.target_bitrate_available = (val != 0);
                break;
            case 5:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.hifi_status = static_cast<HiFiStatus>(val);
                break;
            case 6:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.highest_available_quality = static_cast<BitrateLevel>(val);
                break;
            case 7:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.file_origin = static_cast<FileOrigin>(val);
                break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_ad_break_context(const uint8_t* ptr, size_t size, AdBreakContext& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        uint64_t val = 0;
        bool ok = false;
        switch (field_num) {
            case 1:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.max_seconds_remaining = val;
                break;
            case 2:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.position_in_current_ad_break = val;
                break;
            case 3:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.total_ads_in_break_estimate = val;
                break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_sleep_timer(const uint8_t* ptr, size_t size, SleepTimer& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        if (wire_type != 2) {
            if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
            continue;
        }
        uint64_t len = 0;
        if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
        if (field_num == 1) {
            out.kind = SleepTimer::Kind::None;
            ptr += static_cast<size_t>(len);
        } else if (field_num == 2) {
            out.kind = SleepTimer::Kind::Timestamp;
            const uint8_t* t_end = ptr + static_cast<size_t>(len);
            while (ptr < t_end) {
                uint64_t tt = 0;
                if (!spotify::player::decode_varint(ptr, t_end, tt)) return false;
                const uint32_t tf = static_cast<uint32_t>(tt >> 3);
                const uint32_t tw = static_cast<uint32_t>(tt & 0x07);
                uint64_t tv = 0;
                bool ok = false;
                if (tf == 1) {
                    if (!decode_varint_checked(ptr, t_end, tw, tv, ok)) return false;
                    if (ok) out.timestamp = static_cast<int64_t>(tv);
                } else {
                    if (!spotify::player::skip_field(ptr, t_end, tw)) return false;
                }
            }
        } else if (field_num == 3) {
            out.kind = SleepTimer::Kind::EndOfTrack;
            ptr += static_cast<size_t>(len);
        } else {
            ptr += static_cast<size_t>(len);
        }
    }
    return true;
}

inline bool decode_provided_track(const uint8_t* ptr, size_t size, ProvidedTrack& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);

        switch (field_num) {
            case 1:
                if (!decode_string_field_checked(ptr, end, wire_type, out.uri)) return false;
                break;
            case 2:
                if (!decode_string_field_checked(ptr, end, wire_type, out.uid)) return false;
                break;
            case 3:
                if (!decode_string_map_entry(ptr, end, wire_type, out.metadata)) return false;
                break;
            case 4:
                if (!decode_repeated_string_checked(ptr, end, wire_type, out.removed)) return false;
                break;
            case 5:
                if (!decode_repeated_string_checked(ptr, end, wire_type, out.blocked)) return false;
                break;
            case 6:
                if (!decode_string_field_checked(ptr, end, wire_type, out.provider)) return false;
                break;
            case 7: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                Restrictions r;
                if (!decode_restrictions(ptr, static_cast<size_t>(len), r)) return false;
                out.restrictions = std::move(r);
                ptr += static_cast<size_t>(len);
                break;
            }
            case 8:
                if (!decode_string_field_checked(ptr, end, wire_type, out.album_uri)) return false;
                break;
            case 9:
                if (!decode_repeated_string_checked(ptr, end, wire_type, out.disallow_reasons)) return false;
                break;
            case 10:
                if (!decode_string_field_checked(ptr, end, wire_type, out.artist_uri)) return false;
                break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_context_player_options(const uint8_t* ptr, size_t size, ContextPlayerOptions& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t o_tag = 0;
        if (!spotify::player::decode_varint(ptr, end, o_tag)) return false;
        const uint32_t o_field = static_cast<uint32_t>(o_tag >> 3);
        const uint32_t o_wire = static_cast<uint32_t>(o_tag & 0x07);
        uint64_t v = 0;
        bool ok = false;

        switch (o_field) {
            case 1:
                if (!decode_varint_checked(ptr, end, o_wire, v, ok)) return false;
                if (ok) out.shuffling_context = (v != 0);
                break;
            case 2:
                if (!decode_varint_checked(ptr, end, o_wire, v, ok)) return false;
                if (ok) out.repeating_context = (v != 0);
                break;
            case 3:
                if (!decode_varint_checked(ptr, end, o_wire, v, ok)) return false;
                if (ok) out.repeating_track = (v != 0);
                break;
            case 4:
                if (o_wire == 5) {
                    if (!spotify::player::has_bytes(ptr, end, 4)) return false;
                    uint32_t raw = 0;
                    for (size_t i = 0; i < 4; ++i) {
                        raw |= (static_cast<uint32_t>(*ptr++) << (i * 8));
                    }
                    std::memcpy(&out.playback_speed, &raw, sizeof(float));
                } else {
                    if (!spotify::player::skip_field(ptr, end, o_wire)) return false;
                }
                break;
            case 5:
                if (!decode_string_map_entry(ptr, end, o_wire, out.modes)) return false;
                break;
            default:
                if (!spotify::player::skip_field(ptr, end, o_wire)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_player_state(const uint8_t* ptr, size_t size, PlayerState& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        uint64_t val = 0;
        bool ok = false;

        switch (field_num) {
            case 1:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.timestamp = static_cast<int64_t>(val);
                break;
            case 2:
                if (!decode_string_field_checked(ptr, end, wire_type, out.context_uri)) return false;
                break;
            case 3:
                if (!decode_string_field_checked(ptr, end, wire_type, out.context_url)) return false;
                break;
            case 4: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                Restrictions r;
                if (!decode_restrictions(ptr, static_cast<size_t>(len), r)) return false;
                out.context_restrictions = std::move(r);
                ptr += static_cast<size_t>(len);
                break;
            }
            case 5: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                PlayOrigin po;
                if (!decode_play_origin(ptr, static_cast<size_t>(len), po)) return false;
                out.play_origin = std::move(po);
                ptr += static_cast<size_t>(len);
                break;
            }
            case 6: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                ContextIndex idx;
                if (!decode_context_index(ptr, static_cast<size_t>(len), idx)) return false;
                out.index = idx;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 7: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_provided_track(ptr, static_cast<size_t>(len), out.track)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 8:
                if (!decode_string_field_checked(ptr, end, wire_type, out.playback_id)) return false;
                break;
            case 9:
                if (wire_type == 1) {
                    if (!spotify::player::has_bytes(ptr, end, 8)) return false;
                    uint64_t raw = 0;
                    for (size_t i = 0; i < 8; ++i) {
                        raw |= (static_cast<uint64_t>(*ptr++) << (i * 8));
                    }
                    std::memcpy(&out.playback_speed, &raw, sizeof(double));
                } else if (wire_type == 5) {
                    if (!spotify::player::has_bytes(ptr, end, 4)) return false;
                    float f_val = 0.0f;
                    uint32_t raw = 0;
                    for (size_t i = 0; i < 4; ++i) {
                        raw |= (static_cast<uint32_t>(*ptr++) << (i * 8));
                    }
                    std::memcpy(&f_val, &raw, sizeof(float));
                    out.playback_speed = static_cast<double>(f_val);
                } else {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                }
                break;
            case 10:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.position_as_of_timestamp = static_cast<int64_t>(val);
                break;
            case 11:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.duration = static_cast<int64_t>(val);
                break;
            case 12:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.is_playing = (val != 0);
                break;
            case 13:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.is_paused = (val != 0);
                break;
            case 14:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.is_buffering = (val != 0);
                break;
            case 15:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.is_system_initiated = (val != 0);
                break;
            case 16: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_context_player_options(ptr, static_cast<size_t>(len), out.options)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 17: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                Restrictions r;
                if (!decode_restrictions(ptr, static_cast<size_t>(len), r)) return false;
                out.restrictions = std::move(r);
                ptr += static_cast<size_t>(len);
                break;
            }
            case 18: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                Suppressions sup;
                if (!decode_suppressions(ptr, static_cast<size_t>(len), sup)) return false;
                out.suppressions = std::move(sup);
                ptr += static_cast<size_t>(len);
                break;
            }
            case 19: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                ProvidedTrack pt;
                if (!decode_provided_track(ptr, static_cast<size_t>(len), pt)) return false;
                out.prev_tracks.push_back(std::move(pt));
                ptr += static_cast<size_t>(len);
                break;
            }
            case 20: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                ProvidedTrack nt;
                if (!decode_provided_track(ptr, static_cast<size_t>(len), nt)) return false;
                out.next_tracks.push_back(std::move(nt));
                ptr += static_cast<size_t>(len);
                break;
            }
            case 21:
                if (!decode_string_map_entry(ptr, end, wire_type, out.context_metadata)) return false;
                break;
            case 22:
                if (!decode_string_map_entry(ptr, end, wire_type, out.page_metadata)) return false;
                break;
            case 23:
                if (!decode_string_field_checked(ptr, end, wire_type, out.session_id)) return false;
                break;
            case 24:
                if (!decode_string_field_checked(ptr, end, wire_type, out.queue_revision)) return false;
                break;
            case 25:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.position = static_cast<int64_t>(val);
                break;
            case 32: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                PlaybackQuality pq;
                if (!decode_playback_quality(ptr, static_cast<size_t>(len), pq)) return false;
                out.playback_quality = pq;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 33:
                if (!decode_repeated_string_checked(ptr, end, wire_type, out.signals)) return false;
                break;
            case 35:
                if (!decode_string_field_checked(ptr, end, wire_type, out.session_command_id)) return false;
                break;
            case 37: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                AdBreakContext abc;
                if (!decode_ad_break_context(ptr, static_cast<size_t>(len), abc)) return false;
                out.ad_break_context = abc;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 38: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                SleepTimer st;
                if (!decode_sleep_timer(ptr, static_cast<size_t>(len), st)) return false;
                out.sleep_timer = st;
                ptr += static_cast<size_t>(len);
                break;
            }
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_device(const uint8_t* ptr, size_t size, Device& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);

        switch (field_num) {
            case 1: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_device_info(ptr, static_cast<size_t>(len), out.device_info)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 2: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_player_state(ptr, static_cast<size_t>(len), out.player_state)) return false;
                out.has_player_state = true;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 3: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                const uint8_t* p_end = ptr + static_cast<size_t>(len);
                while (ptr < p_end) {
                    uint64_t pt = 0;
                    if (!spotify::player::decode_varint(ptr, p_end, pt)) return false;
                    const uint32_t pf = static_cast<uint32_t>(pt >> 3);
                    const uint32_t pw = static_cast<uint32_t>(pt & 0x07);
                    if (pf == 1) {
                        if (!decode_string_field_checked(ptr, p_end, pw, out.platform)) return false;
                    } else {
                        if (!spotify::player::skip_field(ptr, p_end, pw)) return false;
                    }
                }
                break;
            }
            case 4:
                if (!decode_bytes_field_checked(ptr, end, wire_type, out.transfer_data)) return false;
                break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_put_state_request(const uint8_t* ptr, size_t size, PutStateRequest& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        uint64_t val = 0;
        bool ok = false;

        switch (field_num) {
            case 1:
                if (!decode_string_field_checked(ptr, end, wire_type, out.callback_url)) return false;
                break;
            case 2: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_device(ptr, static_cast<size_t>(len), out.device)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 3:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.member_type = static_cast<MemberType>(val);
                break;
            case 4:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.is_active = (val != 0);
                break;
            case 5:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.put_state_reason = static_cast<PutStateReason>(val);
                break;
            case 6:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.message_id = static_cast<uint32_t>(val);
                break;
            case 7:
                if (!decode_string_field_checked(ptr, end, wire_type, out.last_command_sent_by_device_id)) return false;
                break;
            case 8:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.last_command_message_id = static_cast<uint32_t>(val);
                break;
            case 9:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.started_playing_at = val;
                break;
            case 11:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.has_been_playing_for_ms = val;
                break;
            case 12:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.client_side_timestamp = val;
                break;
            case 13:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.only_write_player_state = (val != 0);
                break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_put_state_request_wrapper(const uint8_t* ptr, size_t size, PutStateRequestWrapper& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        uint64_t val = 0;
        bool ok = false;

        switch (field_num) {
            case 1:
                if (!decode_string_field_checked(ptr, end, wire_type, out.device_id)) return false;
                break;
            case 2:
                if (!decode_string_field_checked(ptr, end, wire_type, out.connection_id)) return false;
                break;
            case 3:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.ignore_response = (val != 0);
                break;
            case 4: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_put_state_request(ptr, static_cast<size_t>(len), out.put_state_request)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 5:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.wake_devices = (val != 0);
                break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_cluster(const uint8_t* ptr, size_t size, Cluster& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        uint64_t val = 0;
        bool ok = false;

        switch (field_num) {
            case 1:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.changed_timestamp_ms = static_cast<int64_t>(val);
                break;
            case 2:
                if (!decode_string_field_checked(ptr, end, wire_type, out.active_device_id)) return false;
                break;
            case 3: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_player_state(ptr, static_cast<size_t>(len), out.player_state)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 4: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                const uint8_t* map_end = ptr + static_cast<size_t>(len);
                std::string dev_id;
                DeviceInfo dev_info;
                while (ptr < map_end) {
                    uint64_t m_tag = 0;
                    if (!spotify::player::decode_varint(ptr, map_end, m_tag)) return false;
                    const uint32_t m_field = static_cast<uint32_t>(m_tag >> 3);
                    const uint32_t m_wire = static_cast<uint32_t>(m_tag & 0x07);
                    if (m_field == 1 && m_wire == 2) {
                        uint64_t k_len = 0;
                        if (!spotify::player::decode_varint(ptr, map_end, k_len) || !spotify::player::has_bytes(ptr, map_end, k_len)) return false;
                        dev_id.assign(reinterpret_cast<const char*>(ptr), static_cast<size_t>(k_len));
                        ptr += static_cast<size_t>(k_len);
                    } else if (m_field == 2 && m_wire == 2) {
                        uint64_t v_len = 0;
                        if (!spotify::player::decode_varint(ptr, map_end, v_len) || !spotify::player::has_bytes(ptr, map_end, v_len)) return false;
                        if (!decode_device_info(ptr, v_len, dev_info)) return false;
                        ptr += static_cast<size_t>(v_len);
                    } else {
                        if (!spotify::player::skip_field(ptr, map_end, m_wire)) return false;
                    }
                }
                if (!dev_id.empty()) {
                    if (dev_info.device_id.empty()) dev_info.device_id = dev_id;
                    out.devices[std::move(dev_id)] = std::move(dev_info);
                }
                break;
            }
            case 5:
                if (!decode_bytes_field_checked(ptr, end, wire_type, out.transfer_data)) return false;
                break;
            case 6:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.transfer_data_timestamp = val;
                break;
            case 8:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.need_full_player_state = (val != 0);
                break;
            case 9:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.server_timestamp_ms = static_cast<int64_t>(val);
                break;
            case 10:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.needs_state_updates = (val != 0);
                break;
            case 11:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.started_playing_at_timestamp = val;
                break;
            case 12: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                DodoDeviceInfo dodo;
                if (!decode_dodo_device_info(ptr, static_cast<size_t>(len), dodo)) return false;
                out.dodo_devices.push_back(std::move(dodo));
                ptr += static_cast<size_t>(len);
                break;
            }
            case 13:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.needs_local_devices = (val != 0);
                break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_cluster_update(const uint8_t* ptr, size_t size, ClusterUpdate& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        uint64_t val = 0;
        bool ok = false;

        switch (field_num) {
            case 1: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_cluster(ptr, static_cast<size_t>(len), out.cluster)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 2:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.update_reason = static_cast<ClusterUpdateReason>(val);
                break;
            case 3:
                if (!decode_string_field_checked(ptr, end, wire_type, out.ack_id)) return false;
                break;
            case 4:
                if (!decode_repeated_string_checked(ptr, end, wire_type, out.devices_that_changed)) return false;
                break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

// ============================================================================
// Dealer Command Decoders (`connect.proto` ELF 0x631e5c)
// ============================================================================

inline bool decode_connect_command_options(const uint8_t* ptr, size_t size, ConnectCommandOptions& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        uint64_t val = 0;
        bool ok = false;
        switch (field_num) {
            case 1:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.message_id = static_cast<int32_t>(val);
                break;
            case 3:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.target_alias_id = static_cast<uint32_t>(val);
                break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_connect_logging_params(const uint8_t* ptr, size_t size, ConnectLoggingParams& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        switch (field_num) {
            case 1: if (!decode_repeated_string_checked(ptr, end, wire_type, out.interaction_ids)) return false; break;
            case 2: if (!decode_repeated_string_checked(ptr, end, wire_type, out.page_instance_ids)) return false; break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_logout_command(const uint8_t* ptr, size_t size, LogoutCommand& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        if (field_num == 1 && wire_type == 2) {
            uint64_t len = 0;
            if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
            if (!decode_connect_command_options(ptr, static_cast<size_t>(len), out.command_options)) return false;
            ptr += static_cast<size_t>(len);
        } else {
            if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
        }
    }
    return true;
}

inline bool decode_set_volume_command(const uint8_t* ptr, size_t size, SetVolumeCommand& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        uint64_t val = 0;
        bool ok = false;
        switch (field_num) {
            case 1:
                if (!decode_varint_checked(ptr, end, wire_type, val, ok)) return false;
                if (ok) out.volume = static_cast<int32_t>(val);
                break;
            case 2: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_connect_command_options(ptr, static_cast<size_t>(len), out.command_options)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 3: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_connect_logging_params(ptr, static_cast<size_t>(len), out.logging_params)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 4: if (!decode_string_field_checked(ptr, end, wire_type, out.connection_type)) return false; break;
            case 5: if (!decode_string_field_checked(ptr, end, wire_type, out.sent_by_device_id)) return false; break;
            case 6: if (!decode_string_field_checked(ptr, end, wire_type, out.group_device_identifier)) return false; break;
            case 7: if (!decode_string_field_checked(ptr, end, wire_type, out.group_instance)) return false; break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_rename_command(const uint8_t* ptr, size_t size, RenameCommand& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        switch (field_num) {
            case 1:
                if (!decode_string_field_checked(ptr, end, wire_type, out.rename_to)) return false;
                break;
            case 2: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_connect_command_options(ptr, static_cast<size_t>(len), out.command_options)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_set_backend_metadata_command(const uint8_t* ptr, size_t size, SetBackendMetadataCommand& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        if (field_num == 1) {
            if (!decode_string_map_entry(ptr, end, wire_type, out.metadata)) return false;
        } else {
            if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
        }
    }
    return true;
}

inline bool decode_proxy_transfer_command(const uint8_t* ptr, size_t size, ProxyTransferCommand& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        switch (field_num) {
            case 1: if (!decode_string_field_checked(ptr, end, wire_type, out.player_command_json)) return false; break;
            case 2: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_connect_command_options(ptr, static_cast<size_t>(len), out.command_options)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 3: if (!decode_string_field_checked(ptr, end, wire_type, out.target_device_id)) return false; break;
            case 4: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_connect_logging_params(ptr, static_cast<size_t>(len), out.logging_params)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 5: if (!decode_string_field_checked(ptr, end, wire_type, out.command_id)) return false; break;
            case 6: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                WakeOnLanInfo wol;
                if (!decode_wol_info(ptr, static_cast<size_t>(len), wol)) return false;
                out.wol_info = std::move(wol);
                ptr += static_cast<size_t>(len);
                break;
            }
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_proxy_wake_command(const uint8_t* ptr, size_t size, ProxyWakeCommand& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        switch (field_num) {
            case 1: if (!decode_string_field_checked(ptr, end, wire_type, out.target_device_id)) return false; break;
            case 2: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                WakeOnLanInfo wol;
                if (!decode_wol_info(ptr, static_cast<size_t>(len), wol)) return false;
                out.wol_info = std::move(wol);
                ptr += static_cast<size_t>(len);
                break;
            }
            case 3: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_connect_logging_params(ptr, static_cast<size_t>(len), out.logging_params)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 4: if (!decode_string_field_checked(ptr, end, wire_type, out.command_id)) return false; break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_add_device_to_group_command(const uint8_t* ptr, size_t size, AddDeviceToGroupCommand& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        switch (field_num) {
            case 1: if (!decode_string_field_checked(ptr, end, wire_type, out.group_device_identifier)) return false; break;
            case 2: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_connect_command_options(ptr, static_cast<size_t>(len), out.command_options)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 3: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_connect_logging_params(ptr, static_cast<size_t>(len), out.logging_params)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 4: if (!decode_string_field_checked(ptr, end, wire_type, out.group_instance)) return false; break;
            case 5: if (!decode_string_field_checked(ptr, end, wire_type, out.command_id)) return false; break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_remove_device_from_group_command(const uint8_t* ptr, size_t size, RemoveDeviceFromGroupCommand& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        switch (field_num) {
            case 1: if (!decode_string_field_checked(ptr, end, wire_type, out.group_device_identifier)) return false; break;
            case 2: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_connect_command_options(ptr, static_cast<size_t>(len), out.command_options)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 3: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_connect_logging_params(ptr, static_cast<size_t>(len), out.logging_params)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 4: if (!decode_string_field_checked(ptr, end, wire_type, out.group_instance)) return false; break;
            case 5: if (!decode_string_field_checked(ptr, end, wire_type, out.command_id)) return false; break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_delete_group_command(const uint8_t* ptr, size_t size, DeleteGroupCommand& out) {
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t field_num = static_cast<uint32_t>(tag >> 3);
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        switch (field_num) {
            case 1: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_connect_command_options(ptr, static_cast<size_t>(len), out.command_options)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 2: {
                if (wire_type != 2) {
                    if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                    break;
                }
                uint64_t len = 0;
                if (!spotify::player::decode_varint(ptr, end, len) || !spotify::player::has_bytes(ptr, end, len)) return false;
                if (!decode_connect_logging_params(ptr, static_cast<size_t>(len), out.logging_params)) return false;
                ptr += static_cast<size_t>(len);
                break;
            }
            case 3: if (!decode_string_field_checked(ptr, end, wire_type, out.group_instance)) return false; break;
            case 4: if (!decode_string_field_checked(ptr, end, wire_type, out.command_id)) return false; break;
            default:
                if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
                break;
        }
    }
    return true;
}

inline bool decode_resync_group_data_command(const uint8_t* ptr, size_t size, ResyncGroupDataCommand& out) {
    (void)out;
    if (ptr == nullptr) return size == 0;
    const uint8_t* end = ptr + size;
    while (ptr < end) {
        uint64_t tag = 0;
        if (!spotify::player::decode_varint(ptr, end, tag)) return false;
        const uint32_t wire_type = static_cast<uint32_t>(tag & 0x07);
        if (!spotify::player::skip_field(ptr, end, wire_type)) return false;
    }
    return true;
}

} // namespace spotify::connectstate
