import 'package:flutter/foundation.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/image_size.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_item_type.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_section_type.dart';
import 'package:musify_mu/features/playlist/domain/models/track_item_metadata.dart';

export 'playlist_item_type.dart';
export 'playlist_section_type.dart';

/// 1:1 Spotify playlist item model (`p.amb0`).
@immutable
final class PlaylistItem {
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

  /// 1:1 with `amb0.m27460a`: resolves cover URL for [size].
  String coverUrlForSize(ImageSize size) {
    final meta = trackMetadata;
    if (meta == null) return '';
    return meta.coverUrlForSize(size);
  }

  /// Entity type matching Spotify URI scheme and metadata (`qcb0.java`).
  PlaylistItemType get itemType {
    if (uri.startsWith('spotify:episode:') ||
        (trackMetadata?.isEpisode ?? false)) {
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
  bool get isPlayable => trackMetadata?.isPlayable ?? true;

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
}
