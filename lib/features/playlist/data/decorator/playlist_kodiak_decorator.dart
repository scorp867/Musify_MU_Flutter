library;

import 'package:musify_mu/core/kodiak/statement/data_requirement.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/media/extended_metadata_service.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_entity.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_item.dart';
import 'package:musify_mu/features/playlist/domain/models/track_item_metadata.dart';

/// Kodiak DataStatement declaration for Spotify playlist track rows.
/// 1:1 parity with Spotify Android's `skr0.java` / `ybm0.java` / `PlaylistRequestDecorationPolicy.java`.
///
/// Declares the exact required and optional traits requested for each entity:
/// - Level 1 (Required): TrackMetaTrait (ExtensionKind 10 TRACK_V4)
/// - Level 2 (Optional): EpisodeMetaTrait (ExtensionKind 12 EPISODE_V4)
/// - Level 2 (Optional): VisualIdentityTrait (ExtensionKind 1)
/// - Level 2 (Optional): IdentityTrait (ExtensionKind 2)
/// - Level 2 (Optional): ConsumptionExperienceTrait (ExtensionKind 3)
const playlistTrackDataStatement = DataStatement([
  DataRequirement(
    extensionKindValue: 10,
    priority: DataPriority.required,
    traitType: TrackMetaTrait,
  ),
  DataRequirement(
    extensionKindValue: 12,
    priority: DataPriority.optional,
    traitType: EpisodeMetaTrait,
  ),
  DataRequirement(
    extensionKindValue: 1,
    priority: DataPriority.optional,
    traitType: VisualIdentityTrait,
  ),
  DataRequirement(
    extensionKindValue: 2,
    priority: DataPriority.optional,
    traitType: IdentityTrait,
  ),
  DataRequirement(
    extensionKindValue: 3,
    priority: DataPriority.optional,
    traitType: ConsumptionExperienceTrait,
  ),
]);

/// Decorates playlist items with rich metadata (titles, artists, album, covers, duration)
/// via Spotify's Extended Metadata endpoint using a single flight request (no batching).
class PlaylistKodiakDecorator {
  final ExtendedMetadataService _metadataService;

  const PlaylistKodiakDecorator({
    required ExtendedMetadataService metadataService,
  }) : _metadataService = metadataService;

  /// Decorates the given [PlaylistEntity] by resolving metadata for all track & episode items
  /// in a single network request, updating item metadata and recalculating total duration.
  Future<PlaylistEntity> decorate(PlaylistEntity playlist) async {
    if (playlist.items.isEmpty) {
      return playlist;
    }

    final uris = playlist.items
        .map((item) => item.uri)
        .where((uri) => uri.isNotEmpty)
        .toList();

    if (uris.isEmpty) {
      return playlist;
    }

    // Execute single-flight request without batching
    final metaMap = await _metadataService.fetchTracksSingleRequest(uris);
    if (metaMap.isEmpty) {
      return playlist;
    }

    final enrichedItems = <PlaylistItem>[];
    int calculatedTotalDurationMs = 0;
    String? derivedFirstCover;

    for (final item in playlist.items) {
      final meta = metaMap[item.uri];
      final existingMeta = item.trackMetadata;

      if (meta != null) {
        final title = meta.title.isNotEmpty
            ? meta.title
            : (existingMeta?.title ?? '');
        final albumName = meta.albumName.isNotEmpty
            ? meta.albumName
            : (existingMeta?.albumName ?? '');
        final artists = meta.subtitle.isNotEmpty
            ? [meta.subtitle]
            : (existingMeta?.artists ?? const []);

        // Use lightweight thumbnail (~64px) for track tiles; retain high-res for header
        final thumbnailCover = meta.thumbnailImageUrl.isNotEmpty
            ? meta.thumbnailImageUrl
            : meta.imageUrl;
        final highResCover = meta.imageUrl;

        final albumCovers = thumbnailCover.isNotEmpty
            ? [
                thumbnailCover,
                if (highResCover.isNotEmpty && highResCover != thumbnailCover)
                  highResCover,
              ]
            : (existingMeta?.albumCovers ?? const []);

        final durationMs = meta.durationMs > 0
            ? meta.durationMs
            : (existingMeta?.durationMs ?? 0);

        if (derivedFirstCover == null && highResCover.isNotEmpty) {
          derivedFirstCover = highResCover;
        } else if (derivedFirstCover == null && albumCovers.isNotEmpty) {
          derivedFirstCover = albumCovers.first;
        }

        final enrichedMetadata = TrackItemMetadata(
          title: title,
          uri: item.uri,
          isPlayable: existingMeta?.isPlayable ?? true,
          isExplicit: existingMeta?.isExplicit ?? false,
          durationMs: durationMs,
          albumName: albumName,
          albumCovers: albumCovers,
          artists: artists,
        );

        calculatedTotalDurationMs += durationMs;

        enrichedItems.add(
          PlaylistItem(
            uri: item.uri,
            uid: item.uid,
            rowPosition: item.rowPosition,
            addedBy: item.addedBy,
            addedAt: item.addedAt,
            trackMetadata: enrichedMetadata,
            isHearted: item.isHearted,
            isDownloaded: item.isDownloaded,
            offlineState: item.offlineState,
            sectionType: item.sectionType,
          ),
        );
      } else {
        final itemDuration = existingMeta?.durationMs ?? 0;
        calculatedTotalDurationMs += itemDuration;
        final covers = existingMeta?.albumCovers ?? const [];
        if (derivedFirstCover == null && covers.isNotEmpty) {
          derivedFirstCover = covers.first;
        }
        enrichedItems.add(item);
      }
    }

    final coverPicture = playlist.pictureUrl.isNotEmpty
        ? playlist.pictureUrl
        : (derivedFirstCover ?? '');

    final updatedMetadata = playlist.metadata.copyWith(
      totalDurationMs: calculatedTotalDurationMs > 0
          ? calculatedTotalDurationMs
          : playlist.metadata.totalDurationMs,
      picture: coverPicture,
    );

    return playlist.copyWith(
      metadata: updatedMetadata,
      items: enrichedItems,
    );
  }
}
