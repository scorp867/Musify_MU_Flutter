import 'package:flutter/foundation.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_state.dart';

/// Single source of truth for classifying whether a track or playback context
/// represents an authentic, public Spotify song eligible for Spotify backend
/// network requests (ScrollSita, Color Lyrics, Kodiak Extended Metadata, and
/// Spotify Connect `PutState`).
///
/// Explicitly excludes:
/// - All Private Vault tracks (local sandbox, local reference, and Spotify-sourced
///   vault tracks, whether masked or unmasked).
/// - All local device files (`spotify:local:`, `file://`, absolute paths, `content://`,
///   `is_local=true`, or non-empty `local_file_path`).
/// - Non-song Spotify entities (ads, episodes, clips, delimiters, metadata markers).
@immutable
abstract final class SpotifyTrackEligibilityPolicy {
  static const String spotifyTrackPrefix = 'spotify:track:';
  static const String spotifyArtistPrefix = 'spotify:artist:';
  static const String vaultProvider = 'musify_vault';
  static const String vaultUidPrefix = 'vault_';
  static const String vaultUriPrefix = 'vault:';
  static const String vaultInternalContextMarker = 'spotify:internal:vault-';
  static const String localInternalContextMarker =
      'spotify:internal:local-files';
  static const String vaultNomediaPathMarker = 'vault_media/.nomedia';

  static final RegExp _validSpotifyIdPattern = RegExp(r'^[A-Za-z0-9_-]+$');

  /// Returns true if [track] belongs to the Private Vault (even if its backing
  /// source is a Spotify track URI).
  static bool isVaultTrack(ContextTrack track) {
    if (track.provider == vaultProvider) {
      return true;
    }
    if (track.uid.startsWith(vaultUidPrefix) ||
        track.uri.startsWith(vaultUriPrefix) ||
        track.uri.startsWith('musify:vault:')) {
      return true;
    }
    final metadata = track.metadata;
    if (metadata['is_vault_track'] == 'true' ||
        metadata['musify_vault_masked'] == 'true' ||
        metadata.containsKey('vault_track_id') ||
        metadata.containsKey('vault_playlist_id') ||
        metadata.containsKey('vault_source_type')) {
      return true;
    }
    if (metadata[ContextTrackMetadata.keyLocalFilePath] case final path?) {
      if (path.contains(vaultNomediaPathMarker)) {
        return true;
      }
    }
    return false;
  }

  /// Returns true if [track] represents a local device audio file.
  static bool isLocalTrack(ContextTrack track) {
    final uri = track.uri;
    if (uri.startsWith('spotify:local:') ||
        uri.startsWith('file://') ||
        uri.startsWith('content://') ||
        uri.startsWith('/')) {
      return true;
    }
    final metadata = track.metadata;
    if (metadata[ContextTrackMetadata.keyIsLocal] case final rawLocal?) {
      final normalized = rawLocal.toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
    }
    if (metadata[ContextTrackMetadata.keyLocalFilePath] case final path?
        when path.isNotEmpty) {
      return true;
    }
    return false;
  }

  /// Returns true if [playerState] is playing from a Private Vault context.
  static bool isVaultContext(PlayerState? playerState) {
    if (playerState == null) {
      return false;
    }
    if (playerState.contextUri.contains(vaultInternalContextMarker) ||
        playerState.contextUri.startsWith(vaultUriPrefix) ||
        playerState.contextUri.startsWith('musify:vault:') ||
        playerState.contextUrl.contains(vaultInternalContextMarker)) {
      return true;
    }
    final ctxMeta = playerState.contextMetadata;
    if (ctxMeta['is_vault_context'] == 'true' ||
        ctxMeta.containsKey('vault_track_id') ||
        ctxMeta.containsKey('vault_playlist_id')) {
      return true;
    }
    final origin = playerState.playOrigin;
    if (origin.featureIdentifier == 'vault_track' ||
        origin.featureIdentifier == 'vault_playlist' ||
        origin.viewUri.contains(vaultInternalContextMarker)) {
      return true;
    }
    return false;
  }

  /// Returns true if [playerState] is playing from a local files context.
  static bool isLocalContext(PlayerState? playerState) {
    if (playerState == null) {
      return false;
    }
    if (playerState.contextUri.contains(localInternalContextMarker) ||
        playerState.contextUri.startsWith('spotify:local:') ||
        playerState.contextUri.startsWith('file://') ||
        playerState.contextUri.startsWith('/') ||
        playerState.contextUrl.contains(localInternalContextMarker)) {
      return true;
    }
    final origin = playerState.playOrigin;
    if (origin.featureIdentifier == 'local_files' ||
        origin.viewUri.contains(localInternalContextMarker)) {
      return true;
    }
    return false;
  }

  /// Returns true if [candidate] is a syntactically valid Spotify track ID.
  static bool isValidSpotifyId(String candidate) {
    return candidate.isNotEmpty && _validSpotifyIdPattern.hasMatch(candidate);
  }

  /// Extracts a canonical Spotify track ID (without `spotify:track:`) from a
  /// raw ID or URI string, or returns `null` if it is empty, malformed, local,
  /// vault, or a non-track Spotify URI.
  static String? extractCanonicalSpotifyTrackId(String? trackIdOrUri) {
    if (trackIdOrUri == null) {
      return null;
    }
    final trimmed = trackIdOrUri.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.startsWith(spotifyTrackPrefix)) {
      final id = trimmed.substring(spotifyTrackPrefix.length);
      return isValidSpotifyId(id) ? id : null;
    }
    if (trimmed.contains(':') || trimmed.startsWith('/')) {
      return null;
    }
    return isValidSpotifyId(trimmed) ? trimmed : null;
  }

  /// Resolves a canonical `spotify:track:<id>` URI from [trackIdOrUri], or
  /// returns `null` if ineligible.
  static String? resolveCanonicalSpotifyTrackUri(String? trackIdOrUri) {
    final id = extractCanonicalSpotifyTrackId(trackIdOrUri);
    if (id == null) {
      return null;
    }
    return '$spotifyTrackPrefix$id';
  }

  /// Resolves a canonical `spotify:artist:<id>` URI, or returns `null` if empty
  /// or not a valid Spotify artist URI.
  static String? resolveCanonicalSpotifyArtistUri(String? artistUri) {
    if (artistUri == null) {
      return null;
    }
    final trimmed = artistUri.trim();
    if (!trimmed.startsWith(spotifyArtistPrefix)) {
      return null;
    }
    final id = trimmed.substring(spotifyArtistPrefix.length);
    return isValidSpotifyId(id) ? trimmed : null;
  }

  /// Extracts the eligible Spotify track ID for [track] within optional
  /// [playerState], returning `null` for vault songs, local songs, ads,
  /// episodes, and all other non-Spotify-song entries.
  static String? extractEligibleSpotifyTrackId(
    ContextTrack? track, {
    PlayerState? playerState,
  }) {
    if (track == null) {
      return null;
    }
    if (isVaultContext(playerState) || isLocalContext(playerState)) {
      return null;
    }
    if (isVaultTrack(track) || isLocalTrack(track)) {
      return null;
    }
    final uri = track.uri.trim();
    if (!uri.startsWith(spotifyTrackPrefix)) {
      return null;
    }
    final id = uri.substring(spotifyTrackPrefix.length);
    return isValidSpotifyId(id) ? id : null;
  }

  /// Returns true iff [track] (and optional [playerState]) represents an
  /// authentic Spotify song eligible for Spotify network requests.
  static bool isEligibleSpotifySong(
    ContextTrack? track, {
    PlayerState? playerState,
  }) {
    return extractEligibleSpotifyTrackId(track, playerState: playerState) !=
        null;
  }
}
