// ============================================================================
// Frozen Cross-Subsystem Remote Playback Delegate & Mirrored State Contract
// Bridges `spotify::connectstate::ConnectSubsystem` and
// `spotify::player::ContextPlayerImpl` with ZERO dependency on `connect/`.
//
// Sources (`liborbit-jni-spotify.so` arm64):
// - ConnectStateImpl::onClusterChanged @ 0xdb6740..0xdb7060 (`core.load_cluster`)
// - ConnectApiImpl @ 0xda66f0..0xda96ac (`&not_playing_locally` @ 0xdaa0bc)
// - LocalPlaybackIntentContextPlayer @ 0x1090200..0x10924a8
// ============================================================================

#pragma once

#include "../ContextViewEntry.h"
#include "StateEmitter.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

namespace spotify::player {

using MirroredRemoteTrack = context_view::Entry;
using MirroredPlayOrigin = PlayOriginData;

/// Neutral POD holding a remote Spotify Connect cluster's active `PlayerState`,
/// translated into `spotify::player` domain primitives so `ContextPlayerImpl`
/// can emit mirrored `ContextPlayerState` and `Queue` protobuf payloads to Dart
/// without any circular header dependency on `connect/`.
struct MirroredRemotePlaybackState {
    std::string active_device_id;
    int64_t timestamp_ms{0};
    std::string context_uri;
    std::string context_url;
    std::string playback_id;
    std::string session_id;
    std::string session_command_id;
    uint64_t queue_revision{0};
    std::string raw_queue_revision;

    int64_t position_as_of_timestamp_ms{0};
    int64_t duration_ms{0};
    double playback_speed{1.0};
    int32_t page_index{0};
    int32_t track_index{0};

    bool is_playing{false};
    bool is_paused{false};
    bool is_buffering{false};
    bool shuffling{false};
    bool repeating_context{false};
    bool repeating_track{false};

    std::optional<context_view::Entry> current_track;
    std::vector<context_view::Entry> prev_tracks;
    std::vector<context_view::Entry> next_tracks;

    std::vector<uint8_t> restrictions_bytes;
    std::vector<uint8_t> suppressions_bytes;
    std::unordered_map<std::string, std::string> context_metadata;
    std::unordered_map<std::string, std::string> page_metadata;
    PlayOriginData play_origin;
    std::vector<std::string> signals;
    std::unordered_map<std::string, std::string> modes;

    [[nodiscard]] bool has_active_session() const noexcept {
        return !active_device_id.empty() &&
               (!context_uri.empty() ||
                !context_url.empty() ||
                current_track.has_value() ||
                is_playing ||
                is_paused ||
                is_buffering);
    }

    /// Extrapolates the playback position at `now_epoch_ms` when actively playing.
    [[nodiscard]] int64_t extrapolated_position_ms(int64_t now_epoch_ms) const noexcept {
        int64_t base_pos = std::max<int64_t>(0, position_as_of_timestamp_ms);
        if (is_playing && !is_paused && !is_buffering &&
            playback_speed > 0.0 && timestamp_ms > 0 && now_epoch_ms > timestamp_ms) {
            const double delta =
                static_cast<double>(now_epoch_ms - timestamp_ms) * playback_speed;
            base_pos += static_cast<int64_t>(std::llround(delta));
        }
        if (duration_ms > 0 && base_pos > duration_ms) {
            base_pos = duration_ms;
        }
        return base_pos;
    }
};

/// Pure abstract interface implemented by `ConnectSubsystem` and injected into
/// `ContextPlayerImpl::set_remote_playback_delegate(IRemotePlaybackDelegate*)`.
/// When `is_remote_active()` is true and a local command's `CommandOptions`
/// does not set `only_for_local_device = true`, `ContextPlayerImpl` forwards
/// the command to the active remote Connect device via `forward_player_command`.
class IRemotePlaybackDelegate {
public:
    virtual ~IRemotePlaybackDelegate() = default;

    /// Returns true when a remote Spotify Connect device is currently the active
    /// cluster playback target (and local audio playback is not active).
    [[nodiscard]] virtual bool is_remote_active() const = 0;

    /// Returns the Connect `device_id` of the currently active remote device,
    /// or an empty string when local playback or no device is active.
    [[nodiscard]] virtual std::string active_remote_device_id() const = 0;

    /// Forwards a player command to the active remote device via
    /// `POST connect-state/v1/player/command/from/{local_id}/to/{active_remote_id}`.
    /// - `endpoint`: e.g. `"play"`, `"prepare_play"`, `"pause"`, `"resume"`,
    ///   `"seek_to"`, `"skip_next"`, `"skip_prev"`, `"set_options"`,
    ///   `"set_shuffling_context"`, `"set_repeating_context"`,
    ///   `"set_repeating_track"`, `"add_to_queue"`, `"set_queue"`,
    ///   `"play_as_next_in_queue"`, `"update_context"`, `"signal"`,
    ///   `"set_sleep_timer"`.
    /// - `payload_json`: Complete Connect player command JSON object (or inner fields).
    /// - `intent_id`: Optional interaction / command correlation ID.
    virtual bool forward_player_command(
        const std::string& endpoint,
        const std::string& payload_json,
        const std::string& intent_id = {}) = 0;
};

}  // namespace spotify::player

namespace spotify::connectstate {
using ::spotify::player::IRemotePlaybackDelegate;
using ::spotify::player::MirroredPlayOrigin;
using ::spotify::player::MirroredRemotePlaybackState;
using ::spotify::player::MirroredRemoteTrack;
}  // namespace spotify::connectstate
