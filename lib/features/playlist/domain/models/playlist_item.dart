library;

import 'package:flutter/foundation.dart';
import 'track_item_metadata.dart';

/// Section categories for tracks in Spotify's playlist view.
/// Matches 1:1 with Spotify's section categorizer in `dg80.java`.
enum PlaylistSectionType {
  standard,
  youAdded,
  includes,
  weAdded,
}

/// Spotify entity types represented inside playlists (`qcb0.java`).
enum PlaylistItemType {
  track,
  episode,
  show,
}

/// 1:1 replica of Spotify's `amb0.java` playlist item model.
@immutable
class PlaylistItem {
  final String uri;
  final String uid;
  final int rowPosition;
  final String addedBy;
  final int addedAt;
  final TrackItemMetadata? trackMetadata;
  final bool isHearted;
  final bool isDownloaded;
  final int offlineState;
  final PlaylistSectionType sectionType;

  const PlaylistItem({
    required this.uri,
    required this.uid,
    required this.rowPosition,
    this.addedBy = '',
    this.addedAt = 0,
    this.trackMetadata,
    this.isHearted = false,
    this.isDownloaded = false,
    this.offlineState = 0,
    this.sectionType = PlaylistSectionType.standard,
  });

  /// Identifies entity type matching Spotify URI scheme and metadata (`qcb0.java`)
  PlaylistItemType get itemType {
    if (uri.startsWith('spotify:episode:') || (trackMetadata?.isEpisode ?? false)) {
      return PlaylistItemType.episode;
    }
    if (uri.startsWith('spotify:show:') || (trackMetadata?.isShow ?? false)) {
      return PlaylistItemType.show;
    }
    return PlaylistItemType.track;
  }

  bool get isEpisode => itemType == PlaylistItemType.episode;
  bool get isShow => itemType == PlaylistItemType.show;
  bool get isTrack => itemType == PlaylistItemType.track;

  String get title => switch (trackMetadata?.title) {
    final t? => t,
    null => '',
  };
  String get subtitle => switch (trackMetadata?.artistNamesString) {
    final s? => s,
    null => '',
  };
  String get albumName => switch (trackMetadata?.albumName) {
    final a? => a,
    null => '',
  };
  String get showName {
    if (trackMetadata case final meta? when meta.showName.isNotEmpty) {
      return meta.showName;
    }
    return albumName;
  }
  String get coverUrl => switch (trackMetadata?.highResCoverUrl) {
    final c? => c,
    null => '',
  };
  String get imageXlargeUrl => switch (trackMetadata?.imageXlargeUrl) {
    final u? when u.isNotEmpty => u,
    _ => coverUrl,
  };
  String get imageLargeUrl => switch (trackMetadata?.imageLargeUrl) {
    final u? when u.isNotEmpty => u,
    _ => coverUrl,
  };
  String get imageUrl => switch (trackMetadata?.imageUrl) {
    final u? when u.isNotEmpty => u,
    _ => coverUrl,
  };
  String get imageSmallUrl => switch (trackMetadata?.imageSmallUrl) {
    final u? when u.isNotEmpty => u,
    _ => thumbnailUrl,
  };
  String get thumbnailUrl => switch (trackMetadata?.thumbnailCoverUrl) {
    final t? when t.isNotEmpty => t,
    _ => coverUrl,
  };
  int get durationMs => switch (trackMetadata?.durationMs) {
    final d? => d,
    null => 0,
  };
  bool get isPlayable => switch (trackMetadata?.isPlayable) {
    final p? => p,
    null => true,
  };
  bool get isExplicit => switch (trackMetadata?.isExplicit) {
    final e? => e,
    null => false,
  };
  String get description => switch (trackMetadata?.description) {
    final d? => d,
    null => '',
  };
  String get publishDate => switch (trackMetadata?.publishDate) {
    final p? => p,
    null => '',
  };
  int get playbackPositionMs => switch (trackMetadata?.playbackPositionMs) {
    final p? => p,
    null => 0,
  };

  PlaylistItem copyWith({
    String? uri,
    String? uid,
    int? rowPosition,
    String? addedBy,
    int? addedAt,
    TrackItemMetadata? trackMetadata,
    bool? isHearted,
    bool? isDownloaded,
    int? offlineState,
    PlaylistSectionType? sectionType,
  }) {
    return PlaylistItem(
      uri: uri ?? this.uri,
      uid: uid ?? this.uid,
      rowPosition: rowPosition ?? this.rowPosition,
      addedBy: addedBy ?? this.addedBy,
      addedAt: addedAt ?? this.addedAt,
      trackMetadata: trackMetadata ?? this.trackMetadata,
      isHearted: isHearted ?? this.isHearted,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      offlineState: offlineState ?? this.offlineState,
      sectionType: sectionType ?? this.sectionType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistItem &&
          runtimeType == other.runtimeType &&
          uri == other.uri &&
          uid == other.uid &&
          rowPosition == other.rowPosition &&
          addedBy == other.addedBy &&
          addedAt == other.addedAt &&
          trackMetadata == other.trackMetadata &&
          isHearted == other.isHearted &&
          isDownloaded == other.isDownloaded &&
          offlineState == other.offlineState &&
          sectionType == other.sectionType);

  @override
  int get hashCode => Object.hash(
        uri,
        uid,
        rowPosition,
        addedBy,
        addedAt,
        trackMetadata,
        isHearted,
        isDownloaded,
        offlineState,
        sectionType,
      );

  @override
  String toString() =>
      'PlaylistItem(uri: $uri, uid: $uid, type: $itemType, title: $title, subtitle: $subtitle)';
}
