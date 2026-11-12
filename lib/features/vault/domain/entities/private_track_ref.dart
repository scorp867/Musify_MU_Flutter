import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Origin and storage strategy of a track referenced inside a private playlist.
enum TrackSourceTypeEnum {
  /// Public Spotify streaming track reference (preserves canonical Spotify track URI and metadata).
  spotify(id: 'SPOTIFY', displayName: 'Spotify Stream'),

  /// Reference to a local file residing on public device storage (file remains public).
  localReference(id: 'LOCAL_REFERENCE', displayName: 'Local Device File (Reference)'),

  /// App-internal local audio file isolated inside `<app_storage>/vault_media/.nomedia/`.
  localSandbox(id: 'LOCAL_SANDBOX', displayName: 'Local Sandbox (.nomedia)');

  /// Canonical serialization identifier.
  final String id;

  /// Human-readable display label.
  final String displayName;

  const TrackSourceTypeEnum({
    required this.id,
    required this.displayName,
  });

  /// Serializes the source type to its unique identifier string.
  String toJson() => id;

  /// Deserializes a string identifier into a [TrackSourceTypeEnum] instance.
  ///
  /// Throws [FormatException] if [id] does not match any valid enum variant.
  static TrackSourceTypeEnum fromId(String id) {
    for (final source in TrackSourceTypeEnum.values) {
      if (source.id == id || source.name == id) {
        return source;
      }
    }
    throw FormatException(
      'Invalid TrackSourceTypeEnum identifier: "$id". '
      'Valid options are: ${TrackSourceTypeEnum.values.map((v) => v.id).join(', ')}.',
    );
  }

  /// Alias for [fromId] supporting JSON decoding pipelines.
  static TrackSourceTypeEnum fromJson(String json) => fromId(json);
}

/// Deeply immutable entity representing a track entry contained within a private playlist.
///
/// Strictly enforces the Zero Loose Booleans mandate: source type is modeled via [TrackSourceTypeEnum]
/// rather than `bool isLocal` or `bool isSpotify`.
@immutable
class PrivateTrackRef extends Equatable {
  /// Unique identifier of this private track reference.
  final String id;

  /// Identifier of the parent [PrivatePlaylist] containing this track.
  final String playlistId;

  /// Canonical playback URI (e.g. `spotify:track:<id>` or `file://...`).
  final String trackUri;

  /// Track title.
  final String title;

  /// Track artist name.
  final String artistName;

  /// Album title.
  final String albumTitle;

  /// Track playback duration in milliseconds.
  final int durationMs;

  /// Source classification (Spotify stream, local reference, or isolated local sandbox file).
  final TrackSourceTypeEnum sourceType;

  /// Relative path within the vault media sandbox directory (`vault_media/.nomedia/<track_id>.mp3`).
  /// Mandatory when [sourceType] is [TrackSourceTypeEnum.localSandbox]; must be null for Spotify tracks
  /// and local reference tracks.
  final String? localRelativePath;

  /// Zero-based position index within the playlist track sequence.
  final int sortOrder;

  /// Epoch timestamp in milliseconds when this track was added to the private playlist.
  final int addedAtEpochMs;

  /// Optional artwork URI (`https://...`, `spotify:localfileimage:...`, or `file://...`).
  final String? artworkUri;

  /// Constructs a validated [PrivateTrackRef] instance.
  ///
  /// Throws [FormatException] if any required string field is empty, [durationMs] is negative,
  /// [sortOrder] is negative, [addedAtEpochMs] is non-positive, [localRelativePath] is missing for
  /// a local sandbox track, or [localRelativePath] is specified for a Spotify or local reference track.
  PrivateTrackRef({
    required this.id,
    required this.playlistId,
    required this.trackUri,
    required this.title,
    required this.artistName,
    required this.albumTitle,
    required this.durationMs,
    required this.sourceType,
    this.localRelativePath,
    required this.sortOrder,
    required this.addedAtEpochMs,
    this.artworkUri,
  }) {
    if (id.trim().isEmpty) {
      throw const FormatException('PrivateTrackRef id must not be empty.');
    }
    if (playlistId.trim().isEmpty) {
      throw const FormatException('PrivateTrackRef playlistId must not be empty.');
    }
    if (trackUri.trim().isEmpty) {
      throw const FormatException('PrivateTrackRef trackUri must not be empty.');
    }
    if (title.trim().isEmpty) {
      throw const FormatException('PrivateTrackRef title must not be empty.');
    }
    if (artistName.trim().isEmpty) {
      throw const FormatException('PrivateTrackRef artistName must not be empty.');
    }
    if (albumTitle.trim().isEmpty) {
      throw const FormatException('PrivateTrackRef albumTitle must not be empty.');
    }
    if (durationMs < 0) {
      throw FormatException(
        'PrivateTrackRef durationMs must be non-negative: $durationMs',
      );
    }
    if (sortOrder < 0) {
      throw FormatException(
        'PrivateTrackRef sortOrder must be non-negative: $sortOrder',
      );
    }
    if (addedAtEpochMs <= 0) {
      throw FormatException(
        'PrivateTrackRef addedAtEpochMs must be positive: $addedAtEpochMs',
      );
    }

    switch (sourceType) {
      case TrackSourceTypeEnum.localSandbox:
        final path = localRelativePath;
        if (path == null || path.trim().isEmpty) {
          throw const FormatException(
            'PrivateTrackRef localRelativePath must not be null or empty when sourceType is localSandbox.',
          );
        }
      case TrackSourceTypeEnum.spotify:
      case TrackSourceTypeEnum.localReference:
        if (localRelativePath != null) {
          throw const FormatException(
            'PrivateTrackRef localRelativePath must be null when sourceType is spotify or localReference.',
          );
        }
    }

    if (artworkUri case final art? when art.trim().isEmpty) {
      throw const FormatException(
        'PrivateTrackRef artworkUri must not be empty when provided.',
      );
    }
  }

  /// Creates a copy of this track reference with updated fields.
  PrivateTrackRef copyWith({
    String? id,
    String? playlistId,
    String? trackUri,
    String? title,
    String? artistName,
    String? albumTitle,
    int? durationMs,
    TrackSourceTypeEnum? sourceType,
    String? localRelativePath,
    int? sortOrder,
    int? addedAtEpochMs,
    String? artworkUri,
    bool clearArtworkUri = false,
  }) {
    return PrivateTrackRef(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      trackUri: trackUri ?? this.trackUri,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      albumTitle: albumTitle ?? this.albumTitle,
      durationMs: durationMs ?? this.durationMs,
      sourceType: sourceType ?? this.sourceType,
      localRelativePath: localRelativePath ?? this.localRelativePath,
      sortOrder: sortOrder ?? this.sortOrder,
      addedAtEpochMs: addedAtEpochMs ?? this.addedAtEpochMs,
      artworkUri: clearArtworkUri ? null : (artworkUri ?? this.artworkUri),
    );
  }

  @override
  List<Object?> get props => [
        id,
        playlistId,
        trackUri,
        title,
        artistName,
        albumTitle,
        durationMs,
        sourceType,
        localRelativePath,
        sortOrder,
        addedAtEpochMs,
        artworkUri,
      ];
}
