#pragma once

// ============================================================================
// Single source of truth for Spotify playback network & Connect eligibility.
// Mirrors Dart `SpotifyTrackEligibilityPolicy`:
// - Vault songs (local sandbox, local reference, OR Spotify-sourced vault
//   tracks, masked or unmasked) MUST NEVER trigger Spotify metadata decoration
//   or Connect `PutState` requests.
// - Local songs (`spotify:local:`, `file://`, `/`, `content://`, `is_local`,
//   or non-empty `local_file_path`) MUST NEVER trigger Spotify metadata
//   decoration or Connect `PutState` requests.
// - Only authentic, non-vault, non-local Spotify songs (`spotify:track:<id>`)
//   are eligible to publish playback state via Connect `PutState`.
// ============================================================================

#include <cctype>
#include <string>
#include <string_view>
#include <unordered_map>

#include "../ContextViewEntry.h"
#include "ContextPlayerImpl.h"

namespace spotify::player {

class SpotifyPlaybackPolicy final {
public:
    SpotifyPlaybackPolicy() = delete;

    static constexpr std::string_view kSpotifyTrackPrefix = "spotify:track:";
    static constexpr std::string_view kSpotifyEpisodePrefix = "spotify:episode:";
    static constexpr std::string_view kVaultProvider = "musify_vault";
    static constexpr std::string_view kVaultUidPrefix = "vault_";
    static constexpr std::string_view kVaultUriPrefix = "vault:";
    static constexpr std::string_view kMusifyVaultUriPrefix = "musify:vault:";
    static constexpr std::string_view kVaultInternalContextMarker = "spotify:internal:vault-";
    static constexpr std::string_view kLocalInternalContextMarker = "spotify:internal:local-files";
    static constexpr std::string_view kVaultNomediaPathMarker = "vault_media/.nomedia";

    [[nodiscard]] static bool starts_with(std::string_view value, std::string_view prefix) noexcept {
        return value.size() >= prefix.size() && value.compare(0, prefix.size(), prefix) == 0;
    }

    [[nodiscard]] static bool contains(std::string_view value, std::string_view needle) noexcept {
        return value.find(needle) != std::string_view::npos;
    }

    [[nodiscard]] static bool is_valid_spotify_id(std::string_view id) noexcept {
        if (id.empty()) {
            return false;
        }
        for (const char ch : id) {
            const unsigned char uch = static_cast<unsigned char>(ch);
            const bool allowed = std::isalnum(uch) != 0 || ch == '_' || ch == '-';
            if (!allowed) {
                return false;
            }
        }
        return true;
    }

    [[nodiscard]] static bool is_vault_masked_entry(const context_view::Entry& entry) noexcept {
        const auto it = entry.metadata.find("musify_vault_masked");
        return it != entry.metadata.end() && it->second == "true";
    }

    [[nodiscard]] static bool is_vault_entry(const context_view::Entry& entry) noexcept {
        if (entry.provider == kVaultProvider) {
            return true;
        }
        if (starts_with(entry.uid, kVaultUidPrefix) ||
            starts_with(entry.uri, kVaultUriPrefix) ||
            starts_with(entry.uri, kMusifyVaultUriPrefix)) {
            return true;
        }
        if (const auto it = entry.metadata.find("is_vault_track");
            it != entry.metadata.end() && it->second == "true") {
            return true;
        }
        if (is_vault_masked_entry(entry)) {
            return true;
        }
        if (entry.metadata.find("vault_track_id") != entry.metadata.end() ||
            entry.metadata.find("vault_playlist_id") != entry.metadata.end() ||
            entry.metadata.find("vault_source_type") != entry.metadata.end()) {
            return true;
        }
        if (const auto it = entry.metadata.find("local_file_path");
            it != entry.metadata.end() && contains(it->second, kVaultNomediaPathMarker)) {
            return true;
        }
        return false;
    }

    [[nodiscard]] static bool is_local_entry(const context_view::Entry& entry) noexcept {
        if (starts_with(entry.uri, "spotify:local:") ||
            starts_with(entry.uri, "file://") ||
            starts_with(entry.uri, "content://") ||
            (!entry.uri.empty() && entry.uri[0] == '/')) {
            return true;
        }
        if (const auto it = entry.metadata.find("is_local");
            it != entry.metadata.end() &&
            (it->second == "true" || it->second == "True" || it->second == "1")) {
            return true;
        }
        if (const auto it = entry.metadata.find("local_file_path");
            it != entry.metadata.end() && !it->second.empty()) {
            return true;
        }
        return false;
    }

    [[nodiscard]] static bool is_vault_context(
        std::string_view context_uri,
        std::string_view context_url,
        const std::unordered_map<std::string, std::string>& context_metadata,
        const PlayOriginData& play_origin) noexcept {
        if (contains(context_uri, kVaultInternalContextMarker) ||
            starts_with(context_uri, kVaultUriPrefix) ||
            starts_with(context_uri, kMusifyVaultUriPrefix) ||
            contains(context_url, kVaultInternalContextMarker)) {
            return true;
        }
        if (const auto it = context_metadata.find("is_vault_context");
            it != context_metadata.end() && it->second == "true") {
            return true;
        }
        if (context_metadata.find("vault_track_id") != context_metadata.end() ||
            context_metadata.find("vault_playlist_id") != context_metadata.end()) {
            return true;
        }
        if (play_origin.feature_identifier == "vault_track" ||
            play_origin.feature_identifier == "vault_playlist" ||
            contains(play_origin.view_uri, kVaultInternalContextMarker)) {
            return true;
        }
        return false;
    }

    [[nodiscard]] static bool is_local_context(
        std::string_view context_uri,
        std::string_view context_url,
        const PlayOriginData& play_origin) noexcept {
        if (contains(context_uri, kLocalInternalContextMarker) ||
            starts_with(context_uri, "spotify:local:") ||
            starts_with(context_uri, "file://") ||
            (!context_uri.empty() && context_uri[0] == '/') ||
            contains(context_url, kLocalInternalContextMarker)) {
            return true;
        }
        if (play_origin.feature_identifier == "local_files" ||
            contains(play_origin.view_uri, kLocalInternalContextMarker)) {
            return true;
        }
        return false;
    }

    [[nodiscard]] static bool is_spotify_song_entry(const context_view::Entry& entry) noexcept {
        if (entry.is_delimiter() || entry.is_placeholder() || entry.uri.empty()) {
            return false;
        }
        if (is_vault_entry(entry) || is_local_entry(entry)) {
            return false;
        }
        if (!starts_with(entry.uri, kSpotifyTrackPrefix)) {
            return false;
        }
        const std::string_view id = std::string_view(entry.uri).substr(kSpotifyTrackPrefix.size());
        return is_valid_spotify_id(id);
    }

    [[nodiscard]] static bool is_decoratable_spotify_entry(const context_view::Entry& entry) noexcept {
        if (entry.is_delimiter() || entry.is_placeholder() || entry.uri.empty()) {
            return false;
        }
        if (is_vault_entry(entry) || is_local_entry(entry)) {
            return false;
        }
        if (starts_with(entry.uri, kSpotifyTrackPrefix)) {
            const std::string_view id =
                std::string_view(entry.uri).substr(kSpotifyTrackPrefix.size());
            return is_valid_spotify_id(id);
        }
        if (starts_with(entry.uri, kSpotifyEpisodePrefix)) {
            const std::string_view id =
                std::string_view(entry.uri).substr(kSpotifyEpisodePrefix.size());
            return is_valid_spotify_id(id);
        }
        return false;
    }

    [[nodiscard]] static bool is_private_or_local_snapshot(
        const ContextPlayerImpl::ConnectPlayerSnapshot& snapshot) noexcept {
        if (is_vault_context(
                snapshot.context_uri,
                snapshot.context_url,
                snapshot.context_metadata,
                snapshot.play_origin) ||
            is_local_context(
                snapshot.context_uri,
                snapshot.context_url,
                snapshot.play_origin)) {
            return true;
        }
        if (snapshot.current_track.has_value()) {
            return is_vault_entry(*snapshot.current_track) ||
                   is_local_entry(*snapshot.current_track);
        }
        return false;
    }

    [[nodiscard]] static bool is_connect_eligible_snapshot(
        const ContextPlayerImpl::ConnectPlayerSnapshot& snapshot) noexcept {
        if (is_private_or_local_snapshot(snapshot)) {
            return false;
        }
        if (!snapshot.current_track.has_value()) {
            return false;
        }
        return is_spotify_song_entry(*snapshot.current_track);
    }
};

}  // namespace spotify::player
