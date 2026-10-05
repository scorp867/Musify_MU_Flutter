import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:musify_mu/core/protocol/generated/spotify/playlist/playlist_detail.pb.dart'
    as detail_pb;
import 'package:musify_mu/core/protocol/generated/spotify/playlist/rootlist.pb.dart'
    as rootlist_pb;
import 'package:musify_mu/features/library/domain/models/playlist_snapshot.dart';
import 'package:musify_mu/features/library/domain/services/cover_resolver.dart';
import 'package:musify_mu/features/library/domain/services/diff_op.dart';

/// Result of parsing a diff response.
class DiffResult {
  final String fromRevision;
  final String toRevision;
  final List<DiffOp> ops;
  final DiffCoverChange? coverChange;
  final String? updatedName;
  final bool changesRequireResync;
  final bool upToDate;

  const DiffResult({
    required this.fromRevision,
    required this.toRevision,
    required this.ops,
    this.coverChange,
    this.updatedName,
    this.changesRequireResync = false,
    this.upToDate = false,
  });
}

/// Converts protobuf playlist bytes into domain types.
/// All proto knowledge is confined to this class.
class PlaylistMapper {
  const PlaylistMapper._();

  /// Parses a full playlist response into a [PlaylistSnapshot].
  /// Safe to run in an isolate (static, no closures).
  static PlaylistSnapshot? parseFullResponse(
    Uint8List bytes,
    String playlistId,
  ) {
    try {
      final response = detail_pb.PlaylistResponse.fromBuffer(bytes);

      return PlaylistSnapshot(
        playlistId: playlistId,
        revision: _revisionToString(response.revision),
        name: response.attributes.name,
        description: response.attributes.description.isNotEmpty
            ? response.attributes.description
            : null,
        ownerUsername: response.ownerUsername,
        trackCount: response.length,
        trackUris: _extractTrackUris(response.contents.items),
        coverUrl: _extractCoverUrl(response.attributes),
      );
    } catch (_) {
      // Fallback: try SelectedListContent format.
      try {
        final response = rootlist_pb.SelectedListContent.fromBuffer(bytes);
        return PlaylistSnapshot(
          playlistId: playlistId,
          revision: _revisionToString(response.revision),
          name: response.attributes.name,
          ownerUsername: response.ownerUsername,
          trackCount: response.length,
          trackUris: _extractTrackUris(response.contents.items),
          coverUrl: _extractCoverUrl(response.attributes),
        );
      } catch (e) {
        dev.log('PlaylistMapper: parse failed: $e');
        return null;
      }
    }
  }

  /// Parses a diff response into a [DiffResult] with domain-level ops.
  static DiffResult parseDiffResponse(Uint8List bytes) {
    final response = detail_pb.PlaylistResponse.fromBuffer(bytes);
    final newRevision = _revisionToString(response.revision);

    if (!response.hasDiff()) {
      return DiffResult(
        fromRevision: newRevision,
        toRevision: newRevision,
        ops: const [],
        changesRequireResync: response.changesRequireResync,
        upToDate: response.upToDate,
      );
    }

    final diff = response.diff;
    final ops = <DiffOp>[];
    DiffCoverChange? coverChange;
    String? updatedName;

    for (final op in diff.ops) {
      switch (op.kind) {
        case detail_pb.OpKind.ADD:
          if (op.hasAdd()) {
            final a = op.add;
            final uris = <String>[];
            for (final item in a.items) {
              if (item.uri.isNotEmpty) uris.add(item.uri);
            }
            if (uris.isNotEmpty) {
              ops.add(AddOp(
                fromIndex: a.fromIndex,
                uris: uris,
                addFirst: a.addFirst,
                addLast: a.addLast,
              ));
            }
          }

        case detail_pb.OpKind.REM:
          if (op.hasRem()) {
            ops.add(RemOp(
              fromIndex: op.rem.fromIndex,
              length: op.rem.length,
            ));
          }

        case detail_pb.OpKind.MOV:
          if (op.hasMov()) {
            ops.add(MovOp(
              fromIndex: op.mov.fromIndex,
              toIndex: op.mov.toIndex,
              length: op.mov.length,
            ));
          }

        case detail_pb.OpKind.UPDATE_LIST_ATTRIBUTES:
          if (op.hasUpdateListAttributes()) {
            final ula = op.updateListAttributes;

            // Check if cover was removed (no_value contains LIST_PICTURE).
            if (ula.hasNewAttributes()) {
              for (final cleared in ula.newAttributes.noValue) {
                if (cleared == detail_pb.ListAttributeKind.LIST_PICTURE) {
                  coverChange = const CoverRemoved();
                  break;
                }
              }
            }

            // Check if a new cover was set.
            if (coverChange == null &&
                ula.hasNewAttributes() &&
                ula.newAttributes.hasValues()) {
              final newCover =
                  _extractCoverUrl(ula.newAttributes.values);
              if (newCover != null) {
                coverChange = CoverSet(newCover);
              } else if (ula.newAttributes.values.picture.isEmpty) {
                // Picture field present but empty -> cover removed.
                coverChange = const CoverRemoved();
              }

              // Extract updated name if present.
              final name = ula.newAttributes.values.name;
              if (name.isNotEmpty) updatedName = name;
            }
          }

        default:
          break;
      }
    }

    return DiffResult(
      fromRevision: _revisionToString(diff.fromRevision),
      toRevision: _revisionToString(diff.toRevision),
      ops: ops,
      coverChange: coverChange,
      updatedName: updatedName,
      changesRequireResync: response.changesRequireResync,
      upToDate: response.upToDate,
    );
  }

  // ─── Shared helpers ─────────────────────────────────────────────────

  static List<String> _extractTrackUris(List<rootlist_pb.Item> items) {
    final uris = <String>[];
    for (final item in items) {
      if (item.uri.isNotEmpty) uris.add(item.uri);
    }
    return uris;
  }

  /// Converts protobuf revision bytes to "{counter},{sha1hex}".
  static String revisionToString(List<int> revisionBytes) =>
      _revisionToString(revisionBytes);

  static String _revisionToString(List<int> revisionBytes) {
    if (revisionBytes.length < 24) {
      return revisionBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
    }

    final counter = (revisionBytes[0] << 24) |
        (revisionBytes[1] << 16) |
        (revisionBytes[2] << 8) |
        revisionBytes[3];

    final hash = revisionBytes
        .sublist(4)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '$counter,$hash';
  }

  /// Extracts cover image URL from ListAttributes.
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
}
