import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:musify_mu/core/protocol/generated/spotify/collection/collection_paging.pb.dart'
    as col_pb;
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/identity_trait.pb.dart'
    as identity_pb;
import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/protocol/generated/spotify/metadata.pb.dart'
    as meta_pb;
import 'package:musify_mu/core/protocol/generated/spotify/playlist/rootlist.pb.dart'
    as rootlist_pb;
import 'package:musify_mu/features/library/domain/models/library_item.dart';

/// Converts protobuf library bytes into domain types.
/// All proto knowledge for rootlist/collection/artist is confined here.
class LibraryMapper {
  const LibraryMapper._();

  /// Parses rootlist protobuf into [LibraryItem] list. Isolate-safe.
  static List<LibraryItem> parseRootlist(Uint8List bytes) {
    final response = rootlist_pb.SelectedListContent.fromBuffer(bytes);
    final items = <LibraryItem>[];

    final listItems = response.contents.items;
    final metaItems = response.contents.metaItems;

    for (var i = 0; i < listItems.length; i++) {
      final item = listItems[i];
      final uri = item.uri;
      if (uri.isEmpty) continue;

      final meta = (i < metaItems.length) ? metaItems[i] : null;
      final name = meta?.attributes.name ?? _playlistNameFromUri(uri);
      final owner = meta?.ownerUsername ?? '';
      final timestamp = meta?.timestamp.toInt() ?? 0;

      String? imageUrl;
      if (meta != null) {
        imageUrl = _extractCoverFromAttributes(meta.attributes);
      }

      items.add(LibraryItem(
        uri: uri,
        type: _typeFromUri(uri),
        name: name,
        imageUrl: imageUrl,
        ownerName: owner.isNotEmpty ? owner : null,
        addedAt: timestamp > 0
            ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
            : null,
        trackCount: meta?.length,
      ));
    }

    return items;
  }

  /// Parses collection paging protobuf into [LibraryItem] list. Isolate-safe.
  static List<LibraryItem> parseCollection(
    Uint8List bytes,
    String setName,
  ) {
    final response = col_pb.PageResponse.fromBuffer(bytes);
    final items = <LibraryItem>[];

    for (final item in response.items) {
      final uri = item.uri;
      if (uri.isEmpty) continue;

      final addedAt = item.addedAt.toInt();

      items.add(LibraryItem(
        uri: uri,
        type: _typeFromUri(uri),
        name: _nameFromUri(uri),
        addedAt: addedAt > 0
            ? DateTime.fromMillisecondsSinceEpoch(addedAt * 1000)
            : null,
      ));
    }

    return items;
  }

  /// Parses artist decoration response and applies names/images to items.
  /// Isolate-safe.
  static List<LibraryItem> parseArtistDecorations(
    List<LibraryItem> artists,
    Uint8List data,
  ) {
    final response = BatchedExtensionResponse.fromBuffer(data);

    final nameMap = <String, String>{};
    final imageMap = <String, String>{};

    for (final array in response.extendedMetadata) {
      final kind = array.extensionKind;

      for (final extData in array.extensionData) {
        final uri = extData.entityUri;
        if (uri.isEmpty || !extData.hasExtensionData()) continue;

        final payload = extData.extensionData.value;
        if (payload.isEmpty) continue;

        try {
          if (kind == ExtensionKind.IDENTITY_TRAIT) {
            final trait = identity_pb.IdentityTrait.fromBuffer(payload);
            if (trait.name.isNotEmpty) {
              nameMap[uri] = trait.name;
            }
          } else if (kind == ExtensionKind.ARTIST_V4) {
            final artist = meta_pb.Artist.fromBuffer(payload);
            if (!nameMap.containsKey(uri) && artist.name.isNotEmpty) {
              nameMap[uri] = artist.name;
            }
            if (artist.hasPortraitGroup()) {
              final images = artist.portraitGroup.image;
              if (images.isNotEmpty) {
                final best = images.reduce(
                  (a, b) => (a.width > b.width) ? a : b,
                );
                if (best.fileId.isNotEmpty) {
                  final hex = best.fileId
                      .map((b) => b.toRadixString(16).padLeft(2, '0'))
                      .join();
                  imageMap[uri] = 'https://i.scdn.co/image/$hex';
                }
              }
            }
          }
        } catch (e) {
          dev.log('LibraryMapper: parse artist extension failed: $e');
        }
      }
    }

    return artists.map((item) {
      return item.copyWith(
        name: nameMap[item.uri],
        imageUrl: imageMap[item.uri],
      );
    }).toList();
  }

  // ─── URI helpers ──────────────────────────────────────────────────

  static String _typeFromUri(String uri) {
    final parts = uri.split(':');
    if (parts.length >= 2) return parts[1];
    return 'unknown';
  }

  static String _nameFromUri(String uri) {
    final parts = uri.split(':');
    if (parts.length >= 3) return parts[2];
    return uri;
  }

  static String _playlistNameFromUri(String uri) {
    final parts = uri.split(':');
    if (parts.length >= 3) return 'Playlist ${parts[2].substring(0, 6)}';
    return uri;
  }

  /// Extracts cover image URL from ListAttributes proto.
  static String? _extractCoverFromAttributes(
    rootlist_pb.ListAttributes attrs,
  ) {
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
}
