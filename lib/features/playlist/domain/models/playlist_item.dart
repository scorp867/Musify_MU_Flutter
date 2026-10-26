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

  String get title => trackMetadata?.title ?? '';
  String get subtitle => trackMetadata?.artistNamesString ?? '';
  String get albumName => trackMetadata?.albumName ?? '';
  String get coverUrl => trackMetadata?.primaryCoverUrl ?? '';
  int get durationMs => trackMetadata?.durationMs ?? 0;
  bool get isPlayable => trackMetadata?.isPlayable ?? true;
  bool get isExplicit => trackMetadata?.isExplicit ?? false;

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
      'PlaylistItem(uri: $uri, uid: $uid, title: $title, row: $rowPosition, section: $sectionType)';
}
