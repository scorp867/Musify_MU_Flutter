// ============================================================================
// 1:1 Replicated Spotify Esperanto Player Restrictions Engine
// Emits `spotify.player.esperanto.proto.Restrictions` wire bytes.
// Sources:
// - `liborbit-jni-spotify.so` (arm64):
//   - `EsRestrictions` embedded descriptors @ `0x175be00`, `0x1765f00`
//   - `EsContextPlayerState` encoder @ `0x11281d0` -> `0x1128938` / `0x13c65ac`
//   - Restrictions builder @ `0xf85e5c` (init @ `0x108a968`, `0x10ab890`):
//     - `"not_paused"` (`0x361c57`) @ `0xf84ebc`, `0x11afdf8`
//     - `"not_supported_by_content_type"` (`0x38158d`) @ `0xf852c4`, `0x13bc7ec`
//     - `"already_set"` (`0x344594`) @ `0xf856f8`, `0x10ad28c`, `0x10ad324`
// - Decompiled Java / Esperanto Proto:
//   - `com/spotify/player/esperanto/proto/EsRestrictions$Restrictions.java:23-55`
//   - `com/spotify/player/esperanto/proto/EsRestrictions$ModeRestrictions.java`
//   - `com/spotify/player/esperanto/proto/EsRestrictions$RestrictionReasons.java`
//   - `p199p/f111.java` (`m43130a`: `EsRestrictions` -> `Restrictions`)
// ============================================================================

#pragma once

#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

#include "../ProtobufWireHelper.h"

namespace spotify::player {

/// 1:1 replica of `spotify.player.esperanto.proto.Restrictions` / RestrictionsSetupImpl
class RestrictionsEngine {
public:
    RestrictionsEngine() = default;
    ~RestrictionsEngine() = default;

    /// Evaluates all 30+ playback restriction rules and serializes
    /// the Restrictions protobuf message into wire-format bytes.
    [[nodiscard]] std::vector<uint8_t> evaluate(
            bool is_playing,
            bool is_paused,
            bool has_prev,
            bool has_next,
            bool is_shuffling,
            bool is_repeating_context,
            bool is_repeating_track,
            bool has_queue,
            bool supports_playback_speed = false,
            bool has_active_sleep_timer = false) const {
        std::vector<uint8_t> buf;

        // Field 1: disallow_pausing_reasons
        if (!is_playing || is_paused) {
            std::vector<std::string> reasons = custom_disallow_pausing_.empty()
                ? std::vector<std::string>{is_paused ? "already_paused" : "not_playing"}
                : custom_disallow_pausing_;
            encode_reasons_field(buf, 1, reasons);
        } else if (!custom_disallow_pausing_.empty()) {
            encode_reasons_field(buf, 1, custom_disallow_pausing_);
        }

        // Field 2: disallow_resuming_reasons
        // liborbit @ 0xf84ebc / 0x11afdf8: reason is "not_paused" (0x361c57).
        if (is_playing && !is_paused) {
            std::vector<std::string> reasons = custom_disallow_resuming_.empty()
                ? std::vector<std::string>{"not_paused"}
                : custom_disallow_resuming_;
            encode_reasons_field(buf, 2, reasons);
        } else if (!custom_disallow_resuming_.empty()) {
            encode_reasons_field(buf, 2, custom_disallow_resuming_);
        }

        // Field 3: disallow_seeking_reasons
        if (!is_playing && !is_paused) {
            std::vector<std::string> reasons = custom_disallow_seeking_.empty()
                ? std::vector<std::string>{"not_playing"}
                : custom_disallow_seeking_;
            encode_reasons_field(buf, 3, reasons);
        } else if (!custom_disallow_seeking_.empty()) {
            encode_reasons_field(buf, 3, custom_disallow_seeking_);
        }

        // Field 4: disallow_peeking_prev_reasons
        if (!has_prev && !is_repeating_context) {
            std::vector<std::string> reasons = custom_disallow_peeking_prev_.empty()
                ? std::vector<std::string>{"no_prev_track"}
                : custom_disallow_peeking_prev_;
            encode_reasons_field(buf, 4, reasons);
        } else if (!custom_disallow_peeking_prev_.empty()) {
            encode_reasons_field(buf, 4, custom_disallow_peeking_prev_);
        }

        // Field 5: disallow_peeking_next_reasons
        if (!has_next && !is_repeating_context && !has_queue) {
            std::vector<std::string> reasons = custom_disallow_peeking_next_.empty()
                ? std::vector<std::string>{"no_next_track"}
                : custom_disallow_peeking_next_;
            encode_reasons_field(buf, 5, reasons);
        } else if (!custom_disallow_peeking_next_.empty()) {
            encode_reasons_field(buf, 5, custom_disallow_peeking_next_);
        }

        // Field 6: disallow_skipping_prev_reasons
        if (!has_prev && !is_repeating_context) {
            std::vector<std::string> reasons = custom_disallow_skipping_prev_.empty()
                ? std::vector<std::string>{"no_prev_track"}
                : custom_disallow_skipping_prev_;
            encode_reasons_field(buf, 6, reasons);
        } else if (!custom_disallow_skipping_prev_.empty()) {
            encode_reasons_field(buf, 6, custom_disallow_skipping_prev_);
        }

        // Field 7: disallow_skipping_next_reasons
        if (!has_next && !is_repeating_context && !has_queue) {
            std::vector<std::string> reasons = custom_disallow_skipping_next_.empty()
                ? std::vector<std::string>{"no_next_track"}
                : custom_disallow_skipping_next_;
            encode_reasons_field(buf, 7, reasons);
        } else if (!custom_disallow_skipping_next_.empty()) {
            encode_reasons_field(buf, 7, custom_disallow_skipping_next_);
        }

        // Field 8: disallow_toggling_repeat_context_reasons
        if (is_repeating_context && !custom_disallow_toggling_repeat_context_.empty()) {
            encode_reasons_field(buf, 8, custom_disallow_toggling_repeat_context_);
        } else if (!custom_disallow_toggling_repeat_context_.empty()) {
            encode_reasons_field(buf, 8, custom_disallow_toggling_repeat_context_);
        }

        // Field 9: disallow_toggling_repeat_track_reasons
        // Spotify: "is_not_repeatable" when content doesn't support repeat-track
        if (is_repeating_track && !custom_disallow_toggling_repeat_track_.empty()) {
            encode_reasons_field(buf, 9, custom_disallow_toggling_repeat_track_);
        } else if (!custom_disallow_toggling_repeat_track_.empty()) {
            encode_reasons_field(buf, 9, custom_disallow_toggling_repeat_track_);
        }

        // Field 10: disallow_toggling_shuffle_reasons
        // Spotify: "endless_context" when context doesn't support shuffle toggling
        if (is_shuffling && !custom_disallow_toggling_shuffle_.empty()) {
            encode_reasons_field(buf, 10, custom_disallow_toggling_shuffle_);
        } else if (!custom_disallow_toggling_shuffle_.empty()) {
            encode_reasons_field(buf, 10, custom_disallow_toggling_shuffle_);
        }

        // Field 11: disallow_set_queue_reasons
        if (!custom_disallow_set_queue_.empty()) {
            encode_reasons_field(buf, 11, custom_disallow_set_queue_);
        }

        // Field 12: disallow_interrupting_playback_reasons
        if (!custom_disallow_interrupting_playback_.empty()) {
            encode_reasons_field(buf, 12, custom_disallow_interrupting_playback_);
        }

        // Field 13: disallow_transferring_playback_reasons
        if (!custom_disallow_transferring_playback_.empty()) {
            encode_reasons_field(buf, 13, custom_disallow_transferring_playback_);
        }

        // Field 14: disallow_remote_control_reasons
        if (!custom_disallow_remote_control_.empty()) {
            encode_reasons_field(buf, 14, custom_disallow_remote_control_);
        }

        // Field 15: disallow_inserting_into_next_tracks_reasons
        if (!custom_disallow_inserting_into_next_tracks_.empty()) {
            encode_reasons_field(buf, 15, custom_disallow_inserting_into_next_tracks_);
        }

        // Field 16: disallow_inserting_into_context_tracks_reasons
        if (!custom_disallow_inserting_into_context_tracks_.empty()) {
            encode_reasons_field(buf, 16, custom_disallow_inserting_into_context_tracks_);
        }

        // Field 17: disallow_reordering_in_next_tracks_reasons
        if (!custom_disallow_reordering_in_next_tracks_.empty()) {
            encode_reasons_field(buf, 17, custom_disallow_reordering_in_next_tracks_);
        }

        // Field 18: disallow_reordering_in_context_tracks_reasons
        if (!custom_disallow_reordering_in_context_tracks_.empty()) {
            encode_reasons_field(buf, 18, custom_disallow_reordering_in_context_tracks_);
        }

        // Field 19: disallow_removing_from_next_tracks_reasons
        if (!custom_disallow_removing_from_next_tracks_.empty()) {
            encode_reasons_field(buf, 19, custom_disallow_removing_from_next_tracks_);
        }

        // Field 20: disallow_removing_from_context_tracks_reasons
        if (!custom_disallow_removing_from_context_tracks_.empty()) {
            encode_reasons_field(buf, 20, custom_disallow_removing_from_context_tracks_);
        }

        // Field 21: disallow_updating_context_reasons
        if (!custom_disallow_updating_context_.empty()) {
            encode_reasons_field(buf, 21, custom_disallow_updating_context_);
        }

        // Field 22: disallow_add_to_queue_reasons
        if (!custom_disallow_add_to_queue_.empty()) {
            encode_reasons_field(buf, 22, custom_disallow_add_to_queue_);
        }

        // Field 23: disallow_setting_playback_speed_reasons
        // liborbit @ 0xf852c4 / 0x13bc7ec: "not_supported_by_content_type" (0x38158d) on music tracks.
        if (!custom_disallow_setting_playback_speed_.empty()) {
            encode_reasons_field(buf, 23, custom_disallow_setting_playback_speed_);
        } else if ((is_playing || is_paused) && !supports_playback_speed) {
            encode_reasons_field(buf, 23, {"not_supported_by_content_type"});
        }

        // Field 25: disallow_setting_modes (map<string, ModeRestrictions>)
        // EsRestrictions$Restrictions.java: tag 25 (tag 24 is unused in EsRestrictions).
        encode_mode_restrictions_map(buf, 25, disallow_setting_modes_);

        // Field 26: disallow_signals (map<string, RestrictionReasons>)
        encode_signal_restrictions_map(buf, 26, disallow_signals_);

        // Field 27: disallow_play_as_next_in_queue_reasons (repeated string)
        if (!custom_disallow_play_as_next_in_queue_.empty()) {
            encode_reasons_field(buf, 27, custom_disallow_play_as_next_in_queue_);
        }

        // Field 28: disallow_sleep_timer_clear_reasons (EsRestrictions tag 28 -> connectstate tag 31)
        // liborbit @ 0xf856f8 / 0x10ad28c: "already_set" (0x344594) when no sleep timer is active.
        if (!custom_disallow_sleep_timer_clear_.empty()) {
            encode_reasons_field(buf, 28, custom_disallow_sleep_timer_clear_);
        } else if ((is_playing || is_paused) && !has_active_sleep_timer) {
            encode_reasons_field(buf, 28, {"already_set"});
        }

        return buf;
    }

    // Policy setters matching Spotify restrictions configuration
    void set_custom_disallow_pausing(std::vector<std::string> reasons) {
        custom_disallow_pausing_ = std::move(reasons);
    }
    void set_custom_disallow_resuming(std::vector<std::string> reasons) {
        custom_disallow_resuming_ = std::move(reasons);
    }
    void set_custom_disallow_seeking(std::vector<std::string> reasons) {
        custom_disallow_seeking_ = std::move(reasons);
    }
    void set_custom_disallow_skipping_prev(std::vector<std::string> reasons) {
        custom_disallow_skipping_prev_ = std::move(reasons);
    }
    void set_custom_disallow_skipping_next(std::vector<std::string> reasons) {
        custom_disallow_skipping_next_ = std::move(reasons);
    }
    void set_custom_disallow_toggling_repeat_context(std::vector<std::string> reasons) {
        custom_disallow_toggling_repeat_context_ = std::move(reasons);
    }
    void set_custom_disallow_toggling_repeat_track(std::vector<std::string> reasons) {
        custom_disallow_toggling_repeat_track_ = std::move(reasons);
    }
    void set_custom_disallow_toggling_shuffle(std::vector<std::string> reasons) {
        custom_disallow_toggling_shuffle_ = std::move(reasons);
    }
    void set_custom_disallow_add_to_queue(std::vector<std::string> reasons) {
        custom_disallow_add_to_queue_ = std::move(reasons);
    }
    void set_custom_disallow_play_as_next_in_queue(std::vector<std::string> reasons) {
        custom_disallow_play_as_next_in_queue_ = std::move(reasons);
    }

    [[nodiscard]] const std::vector<std::string>& get_custom_disallow_skipping_next() const noexcept {
        return custom_disallow_skipping_next_;
    }
    [[nodiscard]] const std::vector<std::string>& get_custom_disallow_skipping_prev() const noexcept {
        return custom_disallow_skipping_prev_;
    }

    void clear_custom_overrides() noexcept {
        custom_disallow_pausing_.clear();
        custom_disallow_resuming_.clear();
        custom_disallow_seeking_.clear();
        custom_disallow_peeking_prev_.clear();
        custom_disallow_peeking_next_.clear();
        custom_disallow_skipping_prev_.clear();
        custom_disallow_skipping_next_.clear();
        custom_disallow_toggling_repeat_context_.clear();
        custom_disallow_toggling_repeat_track_.clear();
        custom_disallow_toggling_shuffle_.clear();
        custom_disallow_set_queue_.clear();
        custom_disallow_interrupting_playback_.clear();
        custom_disallow_transferring_playback_.clear();
        custom_disallow_remote_control_.clear();
        custom_disallow_inserting_into_next_tracks_.clear();
        custom_disallow_inserting_into_context_tracks_.clear();
        custom_disallow_reordering_in_next_tracks_.clear();
        custom_disallow_reordering_in_context_tracks_.clear();
        custom_disallow_removing_from_next_tracks_.clear();
        custom_disallow_removing_from_context_tracks_.clear();
        custom_disallow_updating_context_.clear();
        custom_disallow_add_to_queue_.clear();
        custom_disallow_setting_playback_speed_.clear();
        disallow_setting_modes_.clear();
        disallow_signals_.clear();
        custom_disallow_play_as_next_in_queue_.clear();
        custom_disallow_sleep_timer_clear_.clear();
    }

private:
    // 1:1 with EsRestrictions$Restrictions.java: all disallow_*_reasons fields are
    // direct `repeated string` (wire type 2 per element), NOT nested submessages.
    static void encode_reasons_field(
            std::vector<uint8_t>& buf,
            uint32_t field_num,
            const std::vector<std::string>& reasons) {
        for (const auto& r : reasons) {
            encode_string_field(buf, field_num, r);
        }
    }

    static std::vector<uint8_t> encode_restriction_reasons(
            const std::vector<std::string>& reasons) {
        std::vector<uint8_t> sub;
        for (const auto& r : reasons) {
            encode_string_field(sub, 1, r);
        }
        return sub;
    }

    static void encode_mode_restrictions_map(
            std::vector<uint8_t>& buf,
            uint32_t field_num,
            const std::unordered_map<
                std::string,
                std::unordered_map<std::string, std::vector<std::string>>>& modes) {
        for (const auto& [mode_key, mode_values] : modes) {
            std::vector<uint8_t> mode_msg;
            for (const auto& [val_key, reasons] : mode_values) {
                std::vector<uint8_t> val_entry;
                encode_string_field(val_entry, 1, val_key);
                encode_submessage_field(val_entry, 2, encode_restriction_reasons(reasons));
                encode_submessage_field(mode_msg, 1, val_entry);
            }
            std::vector<uint8_t> entry;
            encode_string_field(entry, 1, mode_key);
            encode_submessage_field(entry, 2, mode_msg);
            encode_submessage_field(buf, field_num, entry);
        }
    }

    static void encode_signal_restrictions_map(
            std::vector<uint8_t>& buf,
            uint32_t field_num,
            const std::unordered_map<std::string, std::vector<std::string>>& signals) {
        for (const auto& [signal_key, reasons] : signals) {
            std::vector<uint8_t> entry;
            encode_string_field(entry, 1, signal_key);
            encode_submessage_field(entry, 2, encode_restriction_reasons(reasons));
            encode_submessage_field(buf, field_num, entry);
        }
    }

    std::vector<std::string> custom_disallow_pausing_;
    std::vector<std::string> custom_disallow_resuming_;
    std::vector<std::string> custom_disallow_seeking_;
    std::vector<std::string> custom_disallow_peeking_prev_;
    std::vector<std::string> custom_disallow_peeking_next_;
    std::vector<std::string> custom_disallow_skipping_prev_;
    std::vector<std::string> custom_disallow_skipping_next_;
    std::vector<std::string> custom_disallow_toggling_repeat_context_;
    std::vector<std::string> custom_disallow_toggling_repeat_track_;
    std::vector<std::string> custom_disallow_toggling_shuffle_;
    std::vector<std::string> custom_disallow_set_queue_;
    std::vector<std::string> custom_disallow_interrupting_playback_;
    std::vector<std::string> custom_disallow_transferring_playback_;
    std::vector<std::string> custom_disallow_remote_control_;
    std::vector<std::string> custom_disallow_inserting_into_next_tracks_;
    std::vector<std::string> custom_disallow_inserting_into_context_tracks_;
    std::vector<std::string> custom_disallow_reordering_in_next_tracks_;
    std::vector<std::string> custom_disallow_reordering_in_context_tracks_;
    std::vector<std::string> custom_disallow_removing_from_next_tracks_;
    std::vector<std::string> custom_disallow_removing_from_context_tracks_;
    std::vector<std::string> custom_disallow_updating_context_;
    std::vector<std::string> custom_disallow_add_to_queue_;
    std::vector<std::string> custom_disallow_setting_playback_speed_;
    std::unordered_map<std::string, std::unordered_map<std::string, std::vector<std::string>>>
        disallow_setting_modes_;
    std::unordered_map<std::string, std::vector<std::string>> disallow_signals_;
    std::vector<std::string> custom_disallow_play_as_next_in_queue_;
    std::vector<std::string> custom_disallow_sleep_timer_clear_;
};

} // namespace spotify::player
