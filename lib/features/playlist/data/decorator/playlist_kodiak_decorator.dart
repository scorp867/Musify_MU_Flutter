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
    extensionKindValue: 212,
    priority: DataPriority.required,
    traitType: PlaybackTrait,
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

/// Decorates playlist items with rich metadata (titles, artists, album, covers, duration, fileId, headUrl, cdnUrl)
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

        final imageXlarge = meta.imageXlargeUrl;
        final imageLarge = meta.imageLargeUrl;
        final imageDefault = meta.imageUrl;
        final imageSmall = meta.imageSmallUrl;

        final albumCovers = <String>[
          if (imageXlarge.isNotEmpty) imageXlarge,
          if (imageLarge.isNotEmpty && imageLarge != imageXlarge) imageLarge,
          if (imageDefault.isNotEmpty && imageDefault != imageLarge && imageDefault != imageXlarge) imageDefault,
          if (imageSmall.isNotEmpty && imageSmall != imageDefault) imageSmall,
        ];

        final durationMs = meta.durationMs > 0
            ? meta.durationMs
            : switch (existingMeta?.durationMs) {
                final d? => d,
                null => 0,
              };

        final primaryCover = switch (imageXlarge) {
          final u when u.isNotEmpty => u,
          _ => switch (imageLarge) {
            final u when u.isNotEmpty => u,
            _ => imageDefault,
          },
        };

        if (derivedFirstCover == null && primaryCover.isNotEmpty) {
          derivedFirstCover = primaryCover;
        } else if (derivedFirstCover == null && albumCovers.isNotEmpty) {
          derivedFirstCover = albumCovers.first;
        }

        final fileId = meta.fileId;
        final headUrl = meta.headUrl;
        final cdnUrl = meta.cdnUrl.isNotEmpty
            ? meta.cdnUrl
            : switch (existingMeta?.cdnUrl) {
                final c? => c,
                null => '',
              };
        final aacFileId = meta.aacFileId.isNotEmpty
            ? meta.aacFileId
            : switch (existingMeta?.aacFileId) {
                final a? => a,
                null => '',
              };
        final canonicalUri = switch (existingMeta?.canonicalUri) {
          final c? when c.isNotEmpty => c,
          _ => '',
        };

        final enrichedMetadata = TrackItemMetadata(
          title: title,
          uri: item.uri,
          isPlayable: switch (existingMeta?.isPlayable) {
            final p? => p,
            null => true,
          },
          isExplicit: switch (existingMeta?.isExplicit) {
            final e? => e,
            null => false,
          },
          durationMs: durationMs,
          albumName: albumName,
          albumCovers: albumCovers.isNotEmpty
              ? albumCovers
              : switch (existingMeta?.albumCovers) {
                  final c? => c,
                  null => const [],
                },
          imageXlargeUrl: imageXlarge,
          imageLargeUrl: imageLarge,
          imageUrl: imageDefault,
          imageSmallUrl: imageSmall,
          artists: artists,
          fileId: fileId,
          aacFileId: aacFileId,
          headUrl: headUrl,
          cdnUrl: cdnUrl,
          canonicalUri: canonicalUri,
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
