import '../../domain/models/context_track.dart';

extension ContextTrackExtensions on ContextTrack {
  /// Compounded unique key identifying a track instance in the queue (from Spotify ybb1.W).
  /// Format: uid + uri + provider + iteration
  String get queueKey =>
      '$uid$uri$provider${metadata[ContextTrackMetadata.keyIteration] ?? ''}';

  /// Title resolved from metadata (from Spotify ybb1.X).
  String get title => metadata[ContextTrackMetadata.keyTitle] ?? '';

  /// Artist name resolved from metadata.
  String get artist => metadata[ContextTrackMetadata.keyArtistName] ?? '';

  /// Album title resolved from metadata.
  String get album => metadata[ContextTrackMetadata.keyAlbumTitle] ?? '';

  /// Artwork URL resolved from metadata (prioritizes large, xlarge, small).
  String? get imageUrl =>
      metadata[ContextTrackMetadata.keyImageLargeUrl] ??
      metadata[ContextTrackMetadata.keyImageXlargeUrl] ??
      metadata[ContextTrackMetadata.keyImageSmallUrl];

  /// Duration parsed from metadata.
  Duration get duration {
    final durationMs = int.tryParse(metadata[ContextTrackMetadata.keyDuration] ?? '');
    if (durationMs != null) {
      return Duration(milliseconds: durationMs);
    }
    return Duration.zero;
  }

  /// Returns true if this track was explicitly queued by the user (from Spotify ybb1.L).
  bool get isQueued =>
      metadata[ContextTrackMetadata.keyIsQueued]?.toLowerCase() == 'true';

  /// Returns true if this track is 19+ (from Spotify ybb1.z).
  bool get is19Plus =>
      metadata[ContextTrackMetadata.keyIs19Plus]?.toLowerCase() == 'true';

  /// Returns true if this track is explicit (from Spotify ybb1.G).
  bool get isExplicit =>
      metadata[ContextTrackMetadata.keyIsExplicit]?.toLowerCase() == 'true';

  /// Returns true if this track is a podcast ad (from Spotify ybb1.K).
  bool get isPodcastAdvertisement =>
      metadata[ContextTrackMetadata.keyIsPodcastAdvertisement]?.toLowerCase() ==
      'true';

  /// Returns true if this track is a standard track (from Spotify ybb1.P).
  bool get isStandardTrack => uri.startsWith('spotify:track:');

  /// Returns true if this track is an episode or podcast (from Spotify ybb1.J).
  bool get isEpisodeOrPodcast =>
      uri.startsWith('spotify:episode:') ||
      uri.startsWith('spotify:podcast-chapter:') ||
      uri.startsWith('spotify:clip:');

  /// Returns true if this track is video playback (from Spotify ybb1.Q).
  bool get isVideo =>
      metadata[ContextTrackMetadata.keyTrackPlayer]?.toLowerCase() == 'video';

  /// Returns true if this track has ephemeral URI (from Spotify ybb1.y).
  bool get hasEphemeralUri =>
      metadata['has_ephemeral_uri']?.toLowerCase() == 'true';

  /// Returns true if this track is banned in collection (from Spotify s5j.b).
  bool get isCollectionBanned =>
      metadata[ContextTrackMetadata.keyCollectionIsBanned]?.toLowerCase() ==
      'true';

  /// Returns true if this track is hidden (from Spotify s5j.b).
  bool get isHidden =>
      metadata[ContextTrackMetadata.keyHidden]?.toLowerCase() == 'true';
}
