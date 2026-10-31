import 'dart:async';
import 'dart:developer' as dev;

import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/protocol/generated/spotify/scrollsita/v1/scrollsita.pb.dart';
import 'package:musify_mu/features/player/data/datasources/scrollsita_client.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';
import 'package:musify_mu/features/player/domain/repositories/scrollsita_repository.dart';

/// Concrete repository implementation coordinating Now Playing scroll section layout.
///
/// 1:1 replica of decompiled Spotify Android RxJava3/Retrofit pipeline:
/// - Invokes `wl21.m89119a` (`ScrollSitaClient`) with 1000ms timeout (`h010.java#L148`)
/// - Maps `NpvScrollStructure.sections` to `ScrollCardDescriptor` (`lq90.java#L205-L245`)
/// - Emits deterministic offline fallback on timeout or error (`vqy.java#L258-L298`)
/// - Dispatches Kodiak DataStatements to [DataPool] for eager trait preloading.
class ScrollSitaRepositoryImpl implements ScrollSitaRepository {
  final ScrollSitaClient? client;
  final DataPool? dataPool;

  const ScrollSitaRepositoryImpl({
    this.client,
    this.dataPool,
  });

  @override
  Future<List<ScrollCardDescriptor>> getScrollCards([String? trackId]) async {
    final trackUri = _resolveTrackUri(trackId);
    final activeClient = client;
    if (trackUri == null || activeClient == null) {
      return _buildOfflineFallback(trackId);
    }

    try {
      // 1:1 Spotify h010.java#L148: strict 1000ms timeout before falling back
      final response = await activeClient
          .getNpvScroll(nowPlayingUri: trackUri)
          .timeout(const Duration(milliseconds: 1000));

      if (response != null && response.hasStructure()) {
        final cards = _mapSectionsToDescriptors(response.structure, trackUri);
        if (cards.isNotEmpty) {
          // 1:1 Spotify: Preload Kodiak traits for cards declaring DataStatements
          final pool = dataPool;
          if (pool != null) {
            for (final card in cards) {
              final statement = card.dataStatement;
              if (statement != null && card.entityUris.isNotEmpty) {
                pool.loadBatch(uris: card.entityUris, statement: statement);
              }
            }
          }
          return cards;
        }
      }
      return _buildOfflineFallback(trackId);
    } catch (e, st) {
      dev.log(
        'ScrollSitaRepository: Fetch failed or timed out for $trackUri, falling back to offline structure',
        error: e,
        stackTrace: st,
        name: 'ScrollSita',
      );
      // 1:1 Spotify h010.java: on error/timeout, return offline fallback (vqy.java)
      return _buildOfflineFallback(trackId);
    }
  }

  /// 1:1 Replica of Spotify Android `lq90.java` (lines 205–245).
  List<ScrollCardDescriptor> _mapSectionsToDescriptors(
    NpvScrollStructure structure,
    String trackUri,
  ) {
    final descriptors = <ScrollCardDescriptor>[];
    for (final section in structure.sections) {
      if (section.hasLyrics()) {
        final uri = section.lyrics.entityUri.isNotEmpty
            ? section.lyrics.entityUri
            : trackUri;
        descriptors.add(LyricsCardDescriptor(entityUri: uri));
      } else if (section.hasCreatorBio()) {
        final creatorUri = section.creatorBio.creatorUri;
        final title = section.creatorBio.title.isNotEmpty
            ? section.creatorBio.title
            : 'About the artist';
        descriptors.add(CreatorBioCardDescriptor(
          creatorUri: creatorUri,
          title: title,
        ));
      } else if (section.hasCredits()) {
        final uri = section.credits.entityUri.isNotEmpty
            ? section.credits.entityUri
            : trackUri;
        descriptors.add(CreditsCardDescriptor(
          entityUri: uri,
          contributorUris: section.credits.contributorUri.toList(),
        ));
      } else if (section.hasLiveEvents()) {
        descriptors.add(LiveEventsCardDescriptor(
          artistUri: section.liveEvents.artistUri,
          concertUris: section.liveEvents.concertUri.toList(),
        ));
      } else if (section.hasMerch()) {
        final uri = section.merch.entityUri.isNotEmpty
            ? section.merch.entityUri
            : trackUri;
        descriptors.add(MerchCardDescriptor(entityUri: uri));
      } else if (section.hasDiscoveryFeed()) {
        descriptors.add(DiscoveryFeedCardDescriptor(
          title: 'Recommended for you',
          itemUris: section.discoveryFeed.items.toList(),
        ));
      }
    }
    return descriptors;
  }

  /// 1:1 Replica of Spotify Android `vqy.java` (lines 258–298).
  List<ScrollCardDescriptor> _buildOfflineFallback([String? trackId]) {
    final trackUri = _resolveTrackUri(trackId) ?? 'spotify:track:default';

    return [
      LyricsCardDescriptor(entityUri: trackUri),
      const CreatorBioCardDescriptor(
        creatorUri: '',
        title: 'About the artist',
      ),
      CreditsCardDescriptor(
        entityUri: trackUri,
        contributorUris: const [],
      ),
    ];
  }

  /// URI prefixes that cannot resolve to a valid track URI.
  static const _nonTrackPrefixes = [
    'spotify:ad:',
    'spotify:interruption:',
    'spotify:delimiter',
    'spotify:local:',
    'spotify:meta:',
    'spotify:episode:',
    'spotify:podcast-chapter:',
    'spotify:clip:',
  ];

  String? _resolveTrackUri(String? trackId) {
    if (trackId == null || trackId.isEmpty) return null;
    for (final prefix in _nonTrackPrefixes) {
      if (trackId.startsWith(prefix)) return null;
    }
    if (trackId.startsWith('spotify:track:')) return trackId;
    return 'spotify:track:$trackId';
  }
}
