library;

import 'dart:typed_data';

import 'package:musify_mu/core/protocol/generated/spotify/playlist/playlist_detail.pb.dart'
    as detail_pb;
import 'package:musify_mu/core/protocol/generated/spotify/playlist/rootlist.pb.dart'
    as rootlist_pb;
import '../../domain/models/playlist_entity.dart';
import '../../domain/models/playlist_item.dart';
import '../../domain/models/playlist_metadata.dart';
import '../../domain/models/sort_order.dart';
import '../../domain/models/track_item_metadata.dart';

/// 1:1 Proto mapper translating Spotify's protobuf wire structures
/// (PlaylistResponse, SelectedListContent, Item) into domain PlaylistEntity & PlaylistItem.
class PlaylistProtoMappers {
  const PlaylistProtoMappers._();

  /// Converts raw binary payload from PlaylistDataService or PlaylistRemoteSource into PlaylistEntity.
  static PlaylistEntity fromBytes(
    Uint8List bytes, {
    required String playlistUri,
    String currentUsername = '',
    ProvidedSortOrder sortOrder = ProvidedSortOrder.custom,
  }) {
    detail_pb.PlaylistResponse? response;
    rootlist_pb.SelectedListContent? selected;

    try {
      response = detail_pb.PlaylistResponse.fromBuffer(bytes);
    } catch (_) {
      try {
        selected = rootlist_pb.SelectedListContent.fromBuffer(bytes);
      } catch (_) {
        // Corrupted or unrecognized wire format
        return PlaylistEntity(
          metadata: PlaylistMetadata(
            uri: playlistUri,
            name: 'Playlist',
          ),
          items: const [],
          isLoaded: false,
        );
      }
    }

    if (response != null) {
      return _fromPlaylistResponse(
        response,
        playlistUri: playlistUri,
        currentUsername: currentUsername,
        sortOrder: sortOrder,
      );
    } else {
      return _fromSelectedListContent(
        selected!,
        playlistUri: playlistUri,
        currentUsername: currentUsername,
        sortOrder: sortOrder,
      );
    }
  }

  static PlaylistEntity _fromPlaylistResponse(
    detail_pb.PlaylistResponse response, {
    required String playlistUri,
    required String currentUsername,
    required ProvidedSortOrder sortOrder,
  }) {
    final attrs = response.attributes;
    final coverUrl = _extractCoverUrl(attrs);
    final ownerUsername = response.ownerUsername;
    final isOwn = currentUsername.isNotEmpty && ownerUsername == currentUsername;

    final metadata = PlaylistMetadata(
      uri: playlistUri,
      name: attrs.name.isNotEmpty ? attrs.name : 'Untitled Playlist',
      description: attrs.description,
      ownerUsername: ownerUsername,
      ownerName: ownerUsername,
      ownerAvatarUrl: '',
      isCollaborative: attrs.collaborative,
      isFollowed: false,
      isPublished: true,
      canEdit: isOwn,
      canReport: !isOwn,
      canAnnotate: isOwn,
      canDelete: isOwn,
      totalDurationMs: 0,
      followersCount: 0,
      picture: coverUrl ?? '',
      customAttributes: _extractFormatAttributes(attrs.formatAttributes),
    );

    final rawItems = response.contents.items;
    final items = <PlaylistItem>[];
    int totalDurationMs = 0;

    for (int i = 0; i < rawItems.length; i++) {
      final item = rawItems[i];
      final mappedItem = _mapItem(item, i, currentUsername);
      items.add(mappedItem);
      totalDurationMs += mappedItem.durationMs;
    }

    final sortedItems = _sortItems(items, sortOrder);

    return PlaylistEntity(
      metadata: metadata.copyWith(totalDurationMs: totalDurationMs),
      items: sortedItems,
      totalLength: response.length > 0 ? response.length : items.length,
      unfilteredLength: items.length,
      isLoaded: true,
      hasMore: !response.upToDate,
      sortOrder: sortOrder,
    );
  }

  static PlaylistEntity _fromSelectedListContent(
    rootlist_pb.SelectedListContent selected, {
    required String playlistUri,
    required String currentUsername,
    required ProvidedSortOrder sortOrder,
  }) {
    final attrs = selected.attributes;
    final coverUrl = _extractCoverUrl(attrs);
    final ownerUsername = selected.ownerUsername;
    final isOwn = currentUsername.isNotEmpty && ownerUsername == currentUsername;

    final metadata = PlaylistMetadata(
      uri: playlistUri,
      name: attrs.name.isNotEmpty ? attrs.name : 'Untitled Playlist',
      description: attrs.description,
      ownerUsername: ownerUsername,
      ownerName: ownerUsername,
      isCollaborative: attrs.collaborative,
      canEdit: isOwn,
      picture: coverUrl ?? '',
      customAttributes: _extractFormatAttributes(attrs.formatAttributes),
    );

    final rawItems = selected.contents.items;
    final items = <PlaylistItem>[];
    int totalDurationMs = 0;

    for (int i = 0; i < rawItems.length; i++) {
      final item = rawItems[i];
      final mappedItem = _mapItem(item, i, currentUsername);
      items.add(mappedItem);
      totalDurationMs += mappedItem.durationMs;
    }

    final sortedItems = _sortItems(items, sortOrder);

    return PlaylistEntity(
      metadata: metadata.copyWith(totalDurationMs: totalDurationMs),
      items: sortedItems,
      totalLength: selected.length > 0 ? selected.length : items.length,
      unfilteredLength: items.length,
      isLoaded: true,
      hasMore: false,
      sortOrder: sortOrder,
    );
  }

  static PlaylistItem _mapItem(
    rootlist_pb.Item item,
    int index,
    String currentUsername,
  ) {
    final itemAttrs = item.hasAttributes() ? item.attributes : null;
    final addedBy = itemAttrs?.addedBy ?? '';
    final timestamp = itemAttrs?.timestamp.toInt() ?? 0;

    final formatMap = itemAttrs != null
        ? _extractFormatAttributes(itemAttrs.formatAttributes)
        : const <String, String>{};

    final title = formatMap['name'] ??
        formatMap['title'] ??
        _fallbackTitleFromUri(item.uri);

    final artistName = formatMap['artist_name'] ??
        formatMap['artists'] ??
        '';

    final albumName = formatMap['album_title'] ??
        formatMap['album_name'] ??
        '';

    final durationMs = int.tryParse(formatMap['duration'] ?? '') ??
        int.tryParse(formatMap['length'] ?? '') ??
        0;

    final cover = formatMap['image_url'] ??
        formatMap['picture'] ??
        formatMap['album_image'] ??
        '';

    final isExplicit = formatMap['explicit'] == 'true' ||
        formatMap['is_explicit'] == 'true';

    final isPlayable = formatMap['is_playable'] != 'false';

    // Section classification: matches Spotify's "You added" vs "Includes" vs "We added"
    PlaylistSectionType sectionType = PlaylistSectionType.standard;
    if (addedBy.isNotEmpty && currentUsername.isNotEmpty) {
      if (addedBy == currentUsername) {
        sectionType = PlaylistSectionType.youAdded;
      } else if (addedBy == 'spotify') {
        sectionType = PlaylistSectionType.weAdded;
      } else {
        sectionType = PlaylistSectionType.includes;
      }
    }

    final trackMetadata = TrackItemMetadata(
      title: title,
      uri: item.uri,
      isPlayable: isPlayable,
      isExplicit: isExplicit,
      durationMs: durationMs,
      albumName: albumName,
      albumCovers: cover.isNotEmpty ? [cover] : const [],
      artists: artistName.isNotEmpty ? [artistName] : const [],
    );

    return PlaylistItem(
      uri: item.uri,
      uid: '$index-${item.uri}',
      rowPosition: index,
      addedBy: addedBy,
      addedAt: timestamp,
      trackMetadata: trackMetadata,
      sectionType: sectionType,
    );
  }

  static List<PlaylistItem> _sortItems(
    List<PlaylistItem> items,
    ProvidedSortOrder sortOrder,
  ) {
    final copy = List<PlaylistItem>.from(items);
    switch (sortOrder) {
      case ProvidedSortOrder.custom:
        copy.sort((a, b) => a.rowPosition.compareTo(b.rowPosition));
      case ProvidedSortOrder.title:
        copy.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case ProvidedSortOrder.artist:
        copy.sort((a, b) => a.subtitle.toLowerCase().compareTo(b.subtitle.toLowerCase()));
      case ProvidedSortOrder.album:
        copy.sort((a, b) => a.albumName.toLowerCase().compareTo(b.albumName.toLowerCase()));
      case ProvidedSortOrder.dateAdded:
        copy.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    }
    return List.unmodifiable(copy);
  }

  static String? _extractCoverUrl(rootlist_pb.ListAttributes attrs) {
    if (attrs.pictureSize.isNotEmpty) {
      return attrs.pictureSize.first.url;
    }

    for (final attr in attrs.formatAttributes) {
      if (attr.key == 'picture') {
        final val = attr.value;
        if (val.startsWith('spotify:image:')) {
          return 'https://i.scdn.co/image/${val.split(':').last}';
        } else if (val.startsWith('http')) {
          return val;
        } else if (val.isNotEmpty) {
          return 'https://i.scdn.co/image/$val';
        }
      }
    }

    if (attrs.picture.isNotEmpty && attrs.picture.length == 20) {
      final hex = attrs.picture
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      return 'https://i.scdn.co/image/$hex';
    }

    return null;
  }

  static Map<String, String> _extractFormatAttributes(
    Iterable<rootlist_pb.FormatListAttribute> attrs,
  ) {
    final map = <String, String>{};
    for (final attr in attrs) {
      map[attr.key] = attr.value;
    }
    return map;
  }

  static String _fallbackTitleFromUri(String uri) {
    final parts = uri.split(':');
    return parts.isNotEmpty ? parts.last : 'Track';
  }
}
