#pragma once

#include <cstdint>
#include <cstring>
#include <string>
#include <unordered_map>
#include <vector>

#include "../ContextViewEntry.h"
#include "../ProtobufWireHelper.h"

namespace spotify::player {

/// 1:1 replica of Spotify PlayOrigin model (com.spotify.player.model.PlayOrigin)
struct PlayOriginData {
    std::string feature_identifier;
    std::string feature_version;
    std::string view_uri;
    std::string external_referrer;
    std::string referrer_identifier;
    std::string device_identifier;
    std::vector<std::string> feature_classes;
    std::string restriction_identifier;
};

/// Parameter block for serializing ContextPlayerState
struct PlayerStateData {
    int64_t timestamp{0};
    std::string context_uri;
    std::string context_url;
    std::vector<uint8_t> restrictions;
    PlayOriginData play_origin;
    int32_t page_index{0};
    int32_t track_index{0};
    const context_view::Entry* track{nullptr};
    int64_t duration_ms{0};
    bool is_playing{false};
    bool is_paused{false};
    double playback_speed{1.0};
    int64_t position_as_of_timestamp{0};
    bool shuffling_context{false};
    bool repeating_context{false};
    bool repeating_track{false};
    bool is_buffering{false};
    std::vector<uint8_t> suppressions;
    std::unordered_map<std::string, std::string> context_metadata;
    std::unordered_map<std::string, std::string> page_metadata;
    std::string session_id;
    std::vector<std::string> signals;
    std::string session_command_id;
    int64_t queue_revision{0};
};

/// 1:1 replica of Spotify Esperanto StateEmitter
/// Serializes ContextPlayerState and Queue protobuf binary messages
class StateEmitter {
public:
    /// Encodes an OptionalInt64 wrapper message:
    /// message OptionalInt64 { int64 value = 1; }
    [[nodiscard]] static std::vector<uint8_t> encode_optional_int64(int64_t value) {
        std::vector<uint8_t> buf;
        encode_varint(buf, (1 << 3) | 0);
        encode_varint(buf, static_cast<uint64_t>(value));
        return buf;
    }

    /// Encodes an OptionalDouble wrapper message:
    /// message OptionalDouble { double value = 1; }
    [[nodiscard]] static std::vector<uint8_t> encode_optional_double(double value) {
        std::vector<uint8_t> buf;
        encode_varint(buf, (1 << 3) | 1); // 64-bit fixed
        uint64_t raw = 0;
        std::memcpy(&raw, &value, sizeof(double));
        for (int i = 0; i < 8; ++i) {
            buf.push_back(static_cast<uint8_t>((raw >> (i * 8)) & 0xFF));
        }
        return buf;
    }

    /// Encodes an OptionalBoolean wrapper message:
    /// message OptionalBoolean { bool value = 1; }
    [[nodiscard]] static std::vector<uint8_t> encode_optional_boolean(bool value) {
        std::vector<uint8_t> buf;
        encode_varint(buf, (1 << 3) | 0);
        encode_varint(buf, value ? 1 : 0);
        return buf;
    }

    /// Encodes ContextPlayerOptions submessage matching EsContextPlayerOptions$ContextPlayerOptions.java:
    /// field 1: shuffling_context (bool)
    /// field 2: repeating_context (bool)
    /// field 3: repeating_track (bool)
    [[nodiscard]] static std::vector<uint8_t> encode_context_player_options(
            bool shuffling,
            bool repeating_context,
            bool repeating_track) {
        std::vector<uint8_t> buf;
        encode_varint(buf, (1 << 3) | 0);
        encode_varint(buf, shuffling ? 1 : 0);
        encode_varint(buf, (2 << 3) | 0);
        encode_varint(buf, repeating_context ? 1 : 0);
        encode_varint(buf, (3 << 3) | 0);
        encode_varint(buf, repeating_track ? 1 : 0);
        return buf;
    }

    /// Encodes ProvidedTrack submessage by delegating to ProtobufWireHelper
    [[nodiscard]] static std::vector<uint8_t> encode_provided_track(const context_view::Entry& entry) {
        return ::spotify::player::encode_provided_track(entry);
    }

    /// Encodes PlayOrigin submessage matching EsPlayOrigin$PlayOrigin.java:
    /// field 1: feature_identifier (string)
    /// field 2: feature_version (string)
    /// field 3: view_uri (string)
    /// field 4: external_referrer (string)
    /// field 5: referrer_identifier (string)
    /// field 6: device_identifier (string)
    /// field 7: feature_classes (repeated string)
    /// field 8: restriction_identifier (string)
    [[nodiscard]] static std::vector<uint8_t> encode_play_origin(const PlayOriginData& po) {
        std::vector<uint8_t> buf;
        if (!po.feature_identifier.empty()) {
            encode_string_field(buf, 1, po.feature_identifier);
        }
        if (!po.feature_version.empty()) {
            encode_string_field(buf, 2, po.feature_version);
        }
        if (!po.view_uri.empty()) {
            encode_string_field(buf, 3, po.view_uri);
        }
        if (!po.external_referrer.empty()) {
            encode_string_field(buf, 4, po.external_referrer);
        }
        if (!po.referrer_identifier.empty()) {
            encode_string_field(buf, 5, po.referrer_identifier);
        }
        if (!po.device_identifier.empty()) {
            encode_string_field(buf, 6, po.device_identifier);
        }
        for (const auto& fc : po.feature_classes) {
            encode_string_field(buf, 7, fc);
        }
        if (!po.restriction_identifier.empty()) {
            encode_string_field(buf, 8, po.restriction_identifier);
        }
        return buf;
    }

    /// Encodes ContextIndex submessage matching EsContextPlayerState$ContextIndex.java:
    /// field 1: page (uint64 varint)
    /// field 2: track (uint64 varint)
    [[nodiscard]] static std::vector<uint8_t> encode_context_index(int32_t page, int32_t track) {
        std::vector<uint8_t> buf;
        encode_varint(buf, (1 << 3) | 0);
        encode_varint(buf, static_cast<uint64_t>(page >= 0 ? page : 0));
        encode_varint(buf, (2 << 3) | 0);
        encode_varint(buf, static_cast<uint64_t>(track >= 0 ? track : 0));
        return buf;
    }

    /// Encodes map<string, string> metadata into a protobuf stream
    static void encode_context_metadata(
            std::vector<uint8_t>& buf,
            uint32_t field_num,
            const std::unordered_map<std::string, std::string>& metadata) {
        for (const auto& [k, v] : metadata) {
            std::vector<uint8_t> map_entry;
            encode_string_field(map_entry, 1, k);
            encode_string_field(map_entry, 2, v);
            encode_submessage_field(buf, field_num, map_entry);
        }
    }

    /// Overload returning standalone serialized map submessage
    [[nodiscard]] static std::vector<uint8_t> encode_context_metadata(
            const std::unordered_map<std::string, std::string>& metadata) {
        std::vector<uint8_t> buf;
        encode_context_metadata(buf, 22, metadata);
        return buf;
    }

    /// Builds the full ContextPlayerState protobuf wire bytes
    /// Field numbers verified 1:1 against Spotify EsContextPlayerState$ContextPlayerState.java
    [[nodiscard]] static std::vector<uint8_t> encode_player_state(const PlayerStateData& data) {
        std::vector<uint8_t> buf;

        // Field 1: timestamp (int64)
        if (data.timestamp != 0) {
            encode_varint(buf, (1 << 3) | 0);
            encode_varint(buf, static_cast<uint64_t>(data.timestamp));
        }

        // Field 2: context_uri (string)
        if (!data.context_uri.empty()) {
            encode_string_field(buf, 2, data.context_uri);
        }

        // Field 3: context_url (string)
        if (!data.context_url.empty()) {
            encode_string_field(buf, 3, data.context_url);
        }

        // Field 4: context_restrictions (submessage)
        if (!data.restrictions.empty()) {
            encode_submessage_field(buf, 4, data.restrictions);
        }

        // Field 5: play_origin (PlayOrigin submessage) - PLAY_ORIGIN_FIELD_NUMBER = 5
        if (!data.play_origin.feature_identifier.empty() || !data.play_origin.view_uri.empty()) {
            auto po_bytes = encode_play_origin(data.play_origin);
            if (!po_bytes.empty()) {
                encode_submessage_field(buf, 5, po_bytes);
            }
        }

        // Field 6: index (ContextIndex submessage) - INDEX_FIELD_NUMBER = 6
        if (data.track_index >= 0) {
            auto idx_bytes = encode_context_index(data.page_index, data.track_index);
            encode_submessage_field(buf, 6, idx_bytes);
        }

        // Field 7: track (ProvidedTrack submessage) - TRACK_FIELD_NUMBER = 7
        if (data.track != nullptr) {
            auto track_bytes = encode_provided_track(*data.track);
            encode_submessage_field(buf, 7, track_bytes);
        }

        // Field 10: playback_speed (OptionalDouble submessage) - PLAYBACK_SPEED_FIELD_NUMBER = 10
        if (data.playback_speed != 0.0) {
            auto speed_bytes = encode_optional_double(data.playback_speed);
            encode_submessage_field(buf, 10, speed_bytes);
        }

        // Field 11: position_as_of_timestamp (OptionalInt64 submessage) - POSITION_AS_OF_TIMESTAMP_FIELD_NUMBER = 11
        if (data.position_as_of_timestamp >= 0) {
            auto pos_bytes = encode_optional_int64(data.position_as_of_timestamp);
            encode_submessage_field(buf, 11, pos_bytes);
        }

        // Field 12: duration (OptionalInt64 submessage) - DURATION_FIELD_NUMBER = 12
        if (data.duration_ms >= 0) {
            auto dur_bytes = encode_optional_int64(data.duration_ms);
            encode_submessage_field(buf, 12, dur_bytes);
        }

        // Field 13: is_playing (bool) - IS_PLAYING_FIELD_NUMBER = 13
        encode_varint(buf, (13 << 3) | 0);
        encode_varint(buf, data.is_playing ? 1 : 0);

        // Field 14: is_paused (bool) - IS_PAUSED_FIELD_NUMBER = 14
        encode_varint(buf, (14 << 3) | 0);
        encode_varint(buf, data.is_paused ? 1 : 0);

        // Field 15: is_buffering (bool) - IS_BUFFERING_FIELD_NUMBER = 15
        encode_varint(buf, (15 << 3) | 0);
        encode_varint(buf, data.is_buffering ? 1 : 0);

        // Field 17: options (ContextPlayerOptions submessage) - OPTIONS_FIELD_NUMBER = 17
        {
            auto opt_bytes = encode_context_player_options(
                data.shuffling_context,
                data.repeating_context,
                data.repeating_track);
            encode_submessage_field(buf, 17, opt_bytes);
        }

        // Field 18: restrictions (submessage) - RESTRICTIONS_FIELD_NUMBER = 18
        if (!data.restrictions.empty()) {
            encode_submessage_field(buf, 18, data.restrictions);
        }

        // Field 19: suppressions (submessage) - SUPPRESSIONS_FIELD_NUMBER = 19
        if (!data.suppressions.empty()) {
            encode_submessage_field(buf, 19, data.suppressions);
        }

        // Field 22: context_metadata (map<string,string>) - CONTEXT_METADATA_FIELD_NUMBER = 22
        encode_context_metadata(buf, 22, data.context_metadata);

        // Field 23: page_metadata (map<string,string>) - PAGE_METADATA_FIELD_NUMBER = 23
        encode_context_metadata(buf, 23, data.page_metadata);

        // Field 24: session_id (string) - SESSION_ID_FIELD_NUMBER = 24
        if (!data.session_id.empty()) {
            encode_string_field(buf, 24, data.session_id);
        }

        // Field 25: queue_revision (uint64) - QUEUE_REVISION_FIELD_NUMBER = 25
        if (data.queue_revision != 0) {
            encode_varint(buf, (25 << 3) | 0);
            encode_varint(buf, static_cast<uint64_t>(data.queue_revision));
        }

        // Field 27: signals (repeated bytes) - SIGNALS_FIELD_NUMBER = 27
        for (const auto& sig : data.signals) {
            encode_string_field(buf, 27, sig);
        }

        // Field 28: session_command_id (string) - SESSION_COMMAND_ID_FIELD_NUMBER = 28
        if (!data.session_command_id.empty()) {
            encode_string_field(buf, 28, data.session_command_id);
        }

        return buf;
    }

    /// Convenience overload accepting individual parameters
    [[nodiscard]] static std::vector<uint8_t> encode_player_state(
            int64_t timestamp,
            const std::string& context_uri,
            const std::string& context_url,
            const std::vector<uint8_t>& restrictions,
            const context_view::Entry* track,
            int64_t duration_ms,
            bool is_playing,
            bool is_paused,
            double playback_speed,
            int64_t position_as_of_timestamp,
            bool shuffling_context,
            bool repeating_context,
            bool repeating_track,
            bool is_buffering,
            const std::unordered_map<std::string, std::string>& context_metadata,
            const std::unordered_map<std::string, std::string>& page_metadata,
            const std::string& session_id,
            const std::vector<std::string>& signals = {},
            const std::string& session_command_id = "",
            const PlayOriginData& play_origin = {},
            int32_t page_index = 0,
            int32_t track_index = 0) {
        PlayerStateData data;
        data.timestamp = timestamp;
        data.context_uri = context_uri;
        data.context_url = context_url;
        data.restrictions = restrictions;
        data.track = track;
        data.duration_ms = duration_ms;
        data.is_playing = is_playing;
        data.is_paused = is_paused;
        data.playback_speed = playback_speed;
        data.position_as_of_timestamp = position_as_of_timestamp;
        data.shuffling_context = shuffling_context;
        data.repeating_context = repeating_context;
        data.repeating_track = repeating_track;
        data.is_buffering = is_buffering;
        data.context_metadata = context_metadata;
        data.page_metadata = page_metadata;
        data.session_id = session_id;
        data.signals = signals;
        data.session_command_id = session_command_id;
        data.play_origin = play_origin;
        data.page_index = page_index;
        data.track_index = track_index;
        return encode_player_state(data);
    }

    /// Encodes the Queue protobuf binary delegating to ProtobufWireHelper
    [[nodiscard]] static std::vector<uint8_t> encode_queue(
            const context_view::Entry* current_track,
            const std::vector<context_view::Entry>& next_tracks,
            const std::vector<context_view::Entry>& prev_tracks,
            int64_t queue_revision = 0) {
        return ::spotify::player::encode_queue(current_track, next_tracks, prev_tracks, queue_revision);
    }
};

} // namespace spotify::player
