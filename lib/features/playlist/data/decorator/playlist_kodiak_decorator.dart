import 'package:musify_mu/core/kodiak/statement/data_requirement.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/media/extended_metadata_service.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_entity.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_item.dart';
import 'package:musify_mu/features/playlist/domain/models/track_item_metadata.dart';

/// Kodiak DataStatement declaration for Spotify playlist rows (`skr0.java` / `ybm0.java`).
const playlistTrackDataStatement = DataStatement([
  DataRequirement(
    extensionKindValue: 10,
    priority: DataPriority.required,
    traitType: TrackV4,
  ),
  DataRequirement(
    extensionKindValue: 12,
    priority: DataPriority.optional,
    traitType: EpisodeV4,
  ),
  DataRequirement(
    extensionKindValue: 179,
    priority: DataPriority.optional,
    traitType: VisualIdentityTrait,
  ),
  DataRequirement(
    extensionKindValue: 178,
    priority: DataPriority.optional,
    traitType: IdentityTrait,
  ),
  DataRequirement(
    extensionKindValue: 194,
    priority: DataPriority.optional,
    traitType: ConsumptionExperienceTrait,
  ),
]);

/// Decorates playlist items with `TrackV4` and `EpisodeV4` metadata in a single flight request.
///
/// `is19Plus`, `isPlayable`, and `offlineState` originate from the playlist service row
/// (cosmos `TrackMetadata`) and are never derived from Kodiak traits.
class PlaylistKodiakDecorator {
  static const CoverImage _emptyCover = CoverImage();

  final ExtendedMetadataService _metadataService;

  const PlaylistKodiakDecorator({
    required ExtendedMetadataService metadataService,
  }) : _metadataService = metadataService;

  Future<PlaylistEntity> decorate(PlaylistEntity playlist) async {
    if (playlist.items.isEmpty) {
      return playlist;
    }

    final uris = playlist.items
        .map((item) => item.uri)
        .where((uri) => uri.isNotEmpty)
        .toList(growable: false);

    if (uris.isEmpty) {
      return playlist;
    }

    final resolved = await _metadataService.fetchEntitiesSingleRequest(uris);
    if (resolved.tracks.isEmpty && resolved.episodes.isEmpty) {
      return playlist;
    }

    final enrichedItems = <PlaylistItem>[];
    var calculatedTotalDurationMs = 0;
    String? derivedFirstCover;

    for (final item in playlist.items) {
      final existingMeta = item.trackMetadata;
      final TrackItemMetadata? enriched;
      if (resolved.tracks[item.uri] case final trackV4?) {
        enriched = _fromTrack(item, trackV4, existingMeta);
      } else if (resolved.episodes[item.uri] case final episodeV4?) {
        enriched = _fromEpisode(item, episodeV4, existingMeta);
      } else {
        enriched = existingMeta;
      }

      if (enriched != null) {
        calculatedTotalDurationMs += enriched.durationMs;
        if (derivedFirstCover == null) {
          final cover = enriched.coverUrlForSize(ImageSize.large);
          if (cover.isNotEmpty) derivedFirstCover = cover;
        }
      }

      enrichedItems.add(
        identical(enriched, existingMeta)
            ? item
            : item.copyWith(trackMetadata: enriched),
      );
    }

    final String coverPicture;
    if (playlist.pictureUrl.isNotEmpty) {
      coverPicture = playlist.pictureUrl;
    } else if (derivedFirstCover case final derived?) {
      coverPicture = derived;
    } else {
      coverPicture = '';
    }

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

  static TrackItemMetadata _fromTrack(
    PlaylistItem item,
    TrackV4 track,
    TrackItemMetadata? existing,
  ) {
    final artistNames = track.artists
        .map((a) => a.name)
        .where((n) => n.isNotEmpty)
        .toList(growable: false);
    final artistUris = track.artists
        .map((a) => a.uri)
        .where((u) => u.isNotEmpty)
        .toList(growable: false);

    return TrackItemMetadata(
      coverImage: existing != null ? existing.coverImage : _emptyCover,
      title: track.name.isNotEmpty
          ? track.name
          : (existing != null ? existing.title : ''),
      uri: item.uri,
      isPlayable: existing != null ? existing.isPlayable : true,
      isExplicit: track.isExplicit,
      is19Plus: existing != null ? existing.is19Plus : false,
      durationMs: track.duration > 0
          ? track.duration
          : (existing != null ? existing.durationMs : 0),
      albumName: track.albumName.isNotEmpty
          ? track.albumName
          : (existing != null ? existing.albumName : ''),
      albumUri: track.albumUri.isNotEmpty
          ? track.albumUri
          : (existing != null ? existing.albumUri : ''),
      albumCoverImage: track.albumCover != _emptyCover
          ? track.albumCover
          : (existing != null ? existing.albumCoverImage : _emptyCover),
      artists: artistNames.isNotEmpty
          ? List<String>.unmodifiable(artistNames)
          : (existing != null ? existing.artists : const <String>[]),
      artistUris: artistUris.isNotEmpty
          ? List<String>.unmodifiable(artistUris)
          : (existing != null ? existing.artistUris : const <String>[]),
      offlineState: existing != null ? existing.offlineState : 0,
      canonicalUri: track.id.isNotEmpty
          ? 'spotify:track:${track.id}'
          : (existing != null ? existing.canonicalUri : ''),
    );
  }

  static TrackItemMetadata _fromEpisode(
    PlaylistItem item,
    EpisodeV4 episode,
    TrackItemMetadata? existing,
  ) {
    final String showName;
    if (episode.show case final show? when show.name.isNotEmpty) {
      showName = show.name;
    } else {
      showName = existing != null ? existing.showName : '';
    }

    final publish = episode.publishTime;
    final publishDate = publish.year > 0
        ? _formatPublishDate(publish)
        : (existing != null ? existing.publishDate : '');

    return TrackItemMetadata(
      coverImage: episode.coverImage != _emptyCover
          ? episode.coverImage
          : (existing != null ? existing.coverImage : _emptyCover),
      title: episode.name.isNotEmpty
          ? episode.name
          : (existing != null ? existing.title : ''),
      uri: item.uri,
      isPlayable: existing != null ? existing.isPlayable : true,
      isExplicit: episode.isExplicit,
      is19Plus: existing != null ? existing.is19Plus : false,
      durationMs: episode.duration > 0
          ? episode.duration
          : (existing != null ? existing.durationMs : 0),
      albumCoverImage: existing != null ? existing.albumCoverImage : _emptyCover,
      offlineState: existing != null ? existing.offlineState : 0,
      canonicalUri: episode.uri.isNotEmpty ? episode.uri : item.uri,
      isEpisode: true,
      description: episode.description.isNotEmpty
          ? episode.description
          : (existing != null ? existing.description : ''),
      publishDate: publishDate,
      playbackPositionMs: existing != null ? existing.playbackPositionMs : 0,
      showName: showName,
    );
  }

  static String _formatPublishDate(EpisodePublishDate d) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (d.month >= 1 && d.month <= 12 && d.day > 0) {
      return '${months[d.month - 1]} ${d.day}';
    }
    return '${d.year}';
  }
}
