library;

import 'package:flutter/foundation.dart';
import 'playlist_item.dart';
import 'playlist_metadata.dart';
import 'sort_order.dart';

/// 1:1 replica of Spotify's `akb0.java` playlist entity model.
@immutable
class PlaylistEntity {
  final PlaylistMetadata metadata;
  final List<PlaylistItem> items;
  final int totalLength;
  final int unfilteredLength;
  final bool isLoaded;
  final bool hasMore;
  final ProvidedSortOrder sortOrder;
  final bool isShuffled;
  final bool isDownloaded;

  const PlaylistEntity({
    required this.metadata,
    this.items = const [],
    this.totalLength = 0,
    this.unfilteredLength = 0,
    this.isLoaded = false,
    this.hasMore = false,
    this.sortOrder = ProvidedSortOrder.custom,
    this.isShuffled = false,
    this.isDownloaded = false,
  });

  String get uri => metadata.uri;
  String get name => metadata.name;
  String get description => metadata.description;
  String get ownerName => metadata.ownerName.isNotEmpty ? metadata.ownerName : metadata.ownerUsername;
  String get ownerAvatarUrl => metadata.ownerAvatarUrl;
  String get pictureUrl => metadata.picture;
  int get followersCount => metadata.followersCount;
  int get totalDurationMs => metadata.totalDurationMs;
  bool get isFollowed => metadata.isFollowed;
  bool get isCollaborative => metadata.isCollaborative;
  bool get canEdit => metadata.canEdit;

  PlaylistEntity copyWith({
    PlaylistMetadata? metadata,
    List<PlaylistItem>? items,
    int? totalLength,
    int? unfilteredLength,
    bool? isLoaded,
    bool? hasMore,
    ProvidedSortOrder? sortOrder,
    bool? isShuffled,
    bool? isDownloaded,
  }) {
    return PlaylistEntity(
      metadata: metadata ?? this.metadata,
      items: items ?? this.items,
      totalLength: totalLength ?? this.totalLength,
      unfilteredLength: unfilteredLength ?? this.unfilteredLength,
      isLoaded: isLoaded ?? this.isLoaded,
      hasMore: hasMore ?? this.hasMore,
      sortOrder: sortOrder ?? this.sortOrder,
      isShuffled: isShuffled ?? this.isShuffled,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistEntity &&
          runtimeType == other.runtimeType &&
          metadata == other.metadata &&
          listEquals(items, other.items) &&
          totalLength == other.totalLength &&
          unfilteredLength == other.unfilteredLength &&
          isLoaded == other.isLoaded &&
          hasMore == other.hasMore &&
          sortOrder == other.sortOrder &&
          isShuffled == other.isShuffled &&
          isDownloaded == other.isDownloaded);

  @override
  int get hashCode => Object.hash(
        metadata,
        Object.hashAll(items),
        totalLength,
        unfilteredLength,
        isLoaded,
        hasMore,
        sortOrder,
        isShuffled,
        isDownloaded,
      );

  @override
  String toString() =>
      'PlaylistEntity(uri: $uri, name: $name, itemsCount: ${items.length}, total: $totalLength)';
}
