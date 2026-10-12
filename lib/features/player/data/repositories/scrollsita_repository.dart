import 'dart:async';
import 'dart:developer' as dev;

import 'package:audio_service/audio_service.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/protocol/generated/spotify/scrollsita/v1/scrollsita.pb.dart';
import 'package:musify_mu/features/player/data/datasources/scrollsita_client.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';

import 'package:musify_mu/features/player/domain/repositories/scrollsita_repository.dart';

/// Concrete repository implementation coordinating Now Playing scroll section layout.
///
/// Implements the exact pipeline from Spotify Android:
/// 1. `p/u2x.java` (line 389): 1000ms timeout on `scrollsita` network fetch, falling
///    back to offline structure on timeout or error.
/// 2. `p/qb11.java`: Maps each [Section] to its respective [ScrollCardDescriptor].
/// 3. `p/bu1.java` (line 383): Extracts all [ScrollCardDescriptor.entityUris] and
///    triggers batch trait loading through [DataPool.loadBatch].
class ScrollSitaRepositoryImpl implements ScrollSitaRepository {
  final ScrollSitaClient _client;
  final DataPool? _dataPool;

  const ScrollSitaRepositoryImpl({
    required ScrollSitaClient client,
    DataPool? dataPool,
  })  : _client = client,
        _dataPool = dataPool;

  @override
  Future<List<ScrollCardDescriptor>> getScrollCards(MediaItem item) async {
    final trackUri = _resolveTrackUri(item);

    // 1. If not a Spotify track URI, return offline fallback immediately
    if (trackUri == null || !trackUri.startsWith('spotify:track:')) {
      return _buildOfflineFallback(item);
    }

    // 2. Fetch from scrollsita endpoint with strict 1000ms timeout (u2x.java:389)
    try {
      final response = await _client
          .getNpvScroll(nowPlayingUri: trackUri)
          .timeout(const Duration(milliseconds: 1000));

      if (response != null && response.hasStructure()) {
        final descriptors = _mapSectionsToDescriptors(response.structure.sections);
        if (descriptors.isNotEmpty) {
          // Preload entity traits via DataPool in the background (bu1.java:383)
          _batchPreloadTraits(descriptors);
          return descriptors;
        }
      }
    } catch (e) {
      dev.log(
        'ScrollSitaRepository: Network fetch failed or timed out. Falling back to offline cards.',
        error: e,
      );
    }

    // 3. Fallback when network fails or times out (yor.java:17)
    return _buildOfflineFallback(item);
  }

  /// Replicates Section mapping from `p/qb11.java`.
  List<ScrollCardDescriptor> _mapSectionsToDescriptors(List<Section> sections) {
    final descriptors = <ScrollCardDescriptor>[];

    for (final section in sections) {
      if (section.hasLyrics()) {
        descriptors.add(LyricsCardDescriptor(
          entityUri: section.lyrics.entityUri,
        ));
      } else if (section.hasCreatorBio()) {
        descriptors.add(CreatorBioCardDescriptor(
          creatorUri: section.creatorBio.creatorUri,
          title: section.creatorBio.title.isNotEmpty
              ? section.creatorBio.title
              : 'About the artist',
        ));
      } else if (section.hasCredits()) {
        descriptors.add(CreditsCardDescriptor(
          entityUri: section.credits.entityUri,
          contributorUris: section.credits.contributorUri,
        ));
      } else if (section.hasDiscoveryFeed()) {
        descriptors.add(DiscoveryFeedCardDescriptor(
          title: section.discoveryFeed.heading.title,
          itemUris: section.discoveryFeed.items,
        ));
      } else if (section.hasLiveEvents()) {
        descriptors.add(LiveEventsCardDescriptor(
          artistUri: section.liveEvents.artistUri,
          concertUris: section.liveEvents.concertUri,
        ));
      } else if (section.hasMerch()) {
        descriptors.add(MerchCardDescriptor(
          entityUri: section.merch.entityUri,
        ));
      }
    }

    return descriptors;
  }

  /// Triggers DataPool pre-loading for all entity URIs in the card stream.
  /// Replicates `p/bu1.java:383` and `p/kxk.java:a(Set set)`.
  void _batchPreloadTraits(List<ScrollCardDescriptor> descriptors) {
    if (_dataPool == null) return;

    for (final card in descriptors) {
      final statement = card.dataStatement;
      final uris = card.entityUris;
      if (statement != null && uris.isNotEmpty) {
        _dataPool.loadBatch(
          uris: uris,
          statement: statement,
        );
      }
    }
  }

  /// Builds local offline fallback cards matching `p/yor.java`.
  List<ScrollCardDescriptor> _buildOfflineFallback(MediaItem item) {
    final trackUri = _resolveTrackUri(item) ?? 'local:${item.id}';
    final artistUri = item.extras?['artistUri'] as String? ?? '';

    return [
      LyricsCardDescriptor(entityUri: trackUri),
      if (artistUri.isNotEmpty || item.artist?.isNotEmpty == true)
        CreatorBioCardDescriptor(
          creatorUri: artistUri,
          title: 'About the artist',
        ),
      CreditsCardDescriptor(
        entityUri: trackUri,
        contributorUris: artistUri.isNotEmpty ? [artistUri] : const [],
      ),
    ];
  }

  String? _resolveTrackUri(MediaItem item) {
    final uri = item.extras?['uri'] as String?;
    if (uri != null && uri.isNotEmpty) return uri;
    if (item.id.startsWith('spotify:track:')) return item.id;
    return null;
  }
}
