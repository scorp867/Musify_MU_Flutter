import '../../domain/models/context_track.dart';

extension ContextTrackExtensions on ContextTrack {
  /// Compounded unique key identifying a track instance in the queue (from Spotify ock1.m68168i0).
  /// Format: uid + uri + provider + iteration
  String get queueKey {
    final iter = switch (metadata[ContextTrackMetadata.keyIteration]) {
      final val? => val,
      null => '',
    };
    return '$uid$uri$provider$iter';
  }

  /// Title resolved from metadata (from Spotify ybb1.X).
  String get title => switch (metadata[ContextTrackMetadata.keyTitle]) {
    final t? => t,
    null => '',
  };

  /// Artist name resolved from metadata.
  String get artist => switch (metadata[ContextTrackMetadata.keyArtistName]) {
    final a? => a,
    null => '',
  };

  /// Album title resolved from metadata.
  String get album => switch (metadata[ContextTrackMetadata.keyAlbumTitle]) {
    final a? => a,
    null => '',
  };

  /// High-resolution artwork URL for PlayerScreen and expanded displays (prioritizes xlarge, large, default, small).
  String? get imageUrl {
    if (metadata[ContextTrackMetadata.keyImageXlargeUrl] case final xlarge? when xlarge.isNotEmpty) {
      return xlarge;
    }
    if (metadata[ContextTrackMetadata.keyImageLargeUrl] case final large? when large.isNotEmpty) {
      return large;
    }
    if (metadata[ContextTrackMetadata.keyImageUrl] case final normal? when normal.isNotEmpty) {
      return normal;
    }
    if (metadata[ContextTrackMetadata.keyImageSmallUrl] case final small? when small.isNotEmpty) {
      return small;
    }
    return null;
  }

  /// Explicit high-resolution artwork URL.
  String? get imageLargeUrl => imageUrl;

  /// Lightweight thumbnail artwork URL (~64px) for track rows, queue lists, and mini player.
  String? get thumbnailImageUrl {
    if (metadata[ContextTrackMetadata.keyImageSmallUrl] case final small? when small.isNotEmpty) {
      return small;
    }
    if (metadata[ContextTrackMetadata.keyThumbnailImageUrl] case final thumb? when thumb.isNotEmpty) {
      return thumb;
    }
    if (metadata[ContextTrackMetadata.keyImageUrl] case final normal? when normal.isNotEmpty) {
      return normal;
    }
    if (metadata[ContextTrackMetadata.keyImageLargeUrl] case final large? when large.isNotEmpty) {
      return large;
    }
    if (metadata[ContextTrackMetadata.keyImageXlargeUrl] case final xlarge? when xlarge.isNotEmpty) {
      return xlarge;
    }
    return null;
  }

  /// Duration parsed from metadata.
  Duration get duration {
    final raw = metadata[ContextTrackMetadata.keyDuration];
    if (raw != null && raw.isNotEmpty) {
      final durationMs = int.tryParse(raw);
      if (durationMs != null && durationMs >= 0) {
        return Duration(milliseconds: durationMs);
      }
    }
    return Duration.zero;
  }

  /// Returns true if this track was explicitly queued by the user (from Spotify ock1.m68146V / ybb1.L).
  bool get isQueued =>
      metadata[ContextTrackMetadata.keyIsQueued]?.toLowerCase() == 'true';

  /// Returns true if this track is 19+ (from Spotify ybb1.z).
  bool get is19Plus =>
      metadata[ContextTrackMetadata.keyIs19Plus]?.toLowerCase() == 'true';

  /// Returns true if this track is explicit (from Spotify ybb1.G).
  bool get isExplicit =>
      metadata[ContextTrackMetadata.keyIsExplicit]?.toLowerCase() == 'true';

  /// Returns true if this track is a podcast ad (from Spotify ock1.m68145U / ybb1.K).
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
