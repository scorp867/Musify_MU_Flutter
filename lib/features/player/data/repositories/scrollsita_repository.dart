import 'dart:async';
import 'dart:developer' as dev;

import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/protocol/generated/spotify/scrollsita/v1/scrollsita.pb.dart';
import 'package:musify_mu/features/player/data/datasources/scrollsita_client.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';
import 'package:musify_mu/features/player/domain/policies/spotify_track_eligibility_policy.dart';
import 'package:musify_mu/features/player/domain/repositories/scrollsita_repository.dart';

/// Concrete repository implementation coordinating Now Playing scroll section layout.
///
/// Enforces strict Spotify-song eligibility via [SpotifyTrackEligibilityPolicy]
/// so local songs, vault songs, episodes, and ads never trigger Scrollsita or
/// Kodiak Extended Metadata network requests.
class ScrollSitaRepositoryImpl implements ScrollSitaRepository {
  static const Duration defaultTimeout = Duration(milliseconds: 3500);

  final ScrollSitaClient? client;
  final DataPool? dataPool;
  final Duration requestTimeout;

  const ScrollSitaRepositoryImpl({
    this.client,
    this.dataPool,
    this.requestTimeout = defaultTimeout,
  });

  @override
  Future<List<ScrollCardDescriptor>> getScrollCards([
    String? trackId,
    String? artistUri,
  ]) async {
    final trackUri =
        SpotifyTrackEligibilityPolicy.resolveCanonicalSpotifyTrackUri(trackId);
    if (trackUri == null) {
      // Ineligible track (empty, local, vault, episode, ad): zero network or DataPool work.
      return const <ScrollCardDescriptor>[];
    }

    final resolvedArtistUri =
        switch (SpotifyTrackEligibilityPolicy.resolveCanonicalSpotifyArtistUri(
          artistUri,
        )) {
          final uri? => uri,
          null => '',
        };

    final activeClient = client;
    if (activeClient == null) {
      final fallback = _buildFallbackDescriptors(
        trackUri: trackUri,
        artistUri: resolvedArtistUri,
      );
      _preloadDescriptors(fallback);
      return fallback;
    }

    try {
      final response = await activeClient
          .getNpvScroll(nowPlayingUri: trackUri)
          .timeout(requestTimeout);

      if (response != null && response.hasStructure()) {
        final cards = _mapSectionsToDescriptors(
          response.structure,
          trackUri: trackUri,
          fallbackArtistUri: resolvedArtistUri,
        );
        if (cards.isNotEmpty) {
          _preloadDescriptors(cards);
          return cards;
        }
      }

      final fallback = _buildFallbackDescriptors(
        trackUri: trackUri,
        artistUri: resolvedArtistUri,
      );
      _preloadDescriptors(fallback);
      return fallback;
    } catch (e, st) {
      dev.log(
        'ScrollSitaRepository: Fetch failed or timed out for $trackUri, falling back with Kodiak preloading',
        error: e,
        stackTrace: st,
        name: 'ScrollSita',
      );
      final fallback = _buildFallbackDescriptors(
        trackUri: trackUri,
        artistUri: resolvedArtistUri,
      );
      _preloadDescriptors(fallback);
      return fallback;
    }
  }

  /// Dispatches each descriptor's targeted [EntityDataBatchRequest]s into [dataPool].
  void _preloadDescriptors(List<ScrollCardDescriptor> cards) {
    final pool = dataPool;
    if (pool == null) {
      return;
    }
    for (final card in cards) {
      for (final request in card.batchRequests) {
        final uris = request.nonEmptyUris;
        if (uris.isNotEmpty) {
          unawaited(
            pool.loadBatch(uris: uris, statement: request.statement),
          );
        }
      }
    }
  }

  /// 1:1 Replica of Spotify Android `lq90.java` (lines 205–245).
  List<ScrollCardDescriptor> _mapSectionsToDescriptors(
    NpvScrollStructure structure, {
    required String trackUri,
    required String fallbackArtistUri,
  }) {
    final descriptors = <ScrollCardDescriptor>[];
    for (final section in structure.sections) {
      if (section.hasLyrics()) {
        final uri = section.lyrics.entityUri.isNotEmpty
            ? section.lyrics.entityUri
            : trackUri;
        descriptors.add(LyricsCardDescriptor(entityUri: uri));
      } else if (section.hasCreatorBio()) {
        final creatorUri = section.creatorBio.creatorUri.isNotEmpty
            ? section.creatorBio.creatorUri
            : fallbackArtistUri;
        final title = section.creatorBio.title.isNotEmpty
            ? section.creatorBio.title
            : 'About the artist';
        descriptors.add(
          CreatorBioCardDescriptor(
            creatorUri: creatorUri,
            title: title,
          ),
        );
      } else if (section.hasCredits()) {
        final uri = section.credits.entityUri.isNotEmpty
            ? section.credits.entityUri
            : trackUri;
        descriptors.add(
          CreditsCardDescriptor(
            entityUri: uri,
            contributorUris: section.credits.contributorUri.toList(),
          ),
        );
      } else if (section.hasLiveEvents()) {
        final eventsArtistUri = section.liveEvents.artistUri.isNotEmpty
            ? section.liveEvents.artistUri
            : fallbackArtistUri;
        descriptors.add(
          LiveEventsCardDescriptor(
            artistUri: eventsArtistUri,
            concertUris: section.liveEvents.concertUri.toList(),
          ),
        );
      } else if (section.hasMerch()) {
        final uri = section.merch.entityUri.isNotEmpty
            ? section.merch.entityUri
            : trackUri;
        descriptors.add(MerchCardDescriptor(entityUri: uri));
      } else if (section.hasDiscoveryFeed()) {
        descriptors.add(
          DiscoveryFeedCardDescriptor(
            title: 'Recommended for you',
            itemUris: section.discoveryFeed.items.toList(),
          ),
        );
      }
    }
    return descriptors;
  }

  /// Fallback descriptor list for an eligible Spotify track when Scrollsita
  /// times out or returns empty, retaining [artistUri] for Kodiak preloading.
  List<ScrollCardDescriptor> _buildFallbackDescriptors({
    required String trackUri,
    required String artistUri,
  }) {
    return <ScrollCardDescriptor>[
      LyricsCardDescriptor(entityUri: trackUri),
      CreatorBioCardDescriptor(
        creatorUri: artistUri,
        title: 'About the artist',
      ),
      CreditsCardDescriptor(
        entityUri: trackUri,
        contributorUris: const [],
      ),
    ];
  }
}
