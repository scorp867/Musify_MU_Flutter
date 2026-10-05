import 'dart:async';
import 'dart:developer' as dev;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:musify_mu/core/protocol/generated/spotify/ondemand_selector.pb.dart'
    as ods;
import 'package:musify_mu/features/home_feed/data/casita_parser.dart';
import 'package:musify_mu/features/home_feed/data/extended_metadata_fetcher.dart';
import 'package:musify_mu/features/home_feed/data/home_feed_cache.dart';
import 'package:musify_mu/features/home_feed/data/recents_parser.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/features/home_feed/domain/repositories/home_repository.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';

/// Repository for home feed data. Implements SWR (Stale-While-Revalidate).
///
/// Spotify's exact home feed pipeline:
///   1. GET /casita/v1/home/default?eagerload=...  -> ResolvedHome protobuf
///   2. Parse ResolvedHome:
///      - field 1: HomeStructure (section layout)
///      - field 2: EagerlyLoadedTraits (pre-loaded traits for eagerload-covered items)
///      - field 999: OndemandSet (URIs that still need trait resolution)
///   3. GET /ondemand-selector/v1/select-ondemand-set  -> filtered URI list
///   4. POST /extended-metadata/v0/extended-metadata  -> SimpleCardTrait for those URIs
///   5. Merge traits into entities -> render
class HomeRepositoryImpl implements HomeRepository {
  static const _casitaEagerload =
      'eyJtYXBwaW5nIjp7IjEyIjp7IjEiOlsxNjddfSwiMTMiOnsiMSI6WzE3MV19LCIxNSI6eyIxIjpbOTddLCIyIjpbOTddfSwiMTYiOnsiMSI6WzEyMiwxMjMsMTI0XX0sIjE3Ijp7IjEiOlsxNzgsMTY3LDE3OV19LCIxOCI6eyIxIjpbMTE4XSwiMiI6WzE4MSwyNDksMTE4LDE3OF19LCIyIjp7IjEiOlsxMTldLCIyIjpbMTE5XX0sIjIzIjp7IjEiOls5N119LCIyNCI6eyIxIjpbMTcxXSwiMiI6WzExNl19LCIyNSI6eyIxIjpbMTE4XSwiMiI6WzExOCwxNzgsMTE2XX0sIjI3Ijp7IjEiOlsxMTgsMTE2XSwiMiI6WzE3OF19LCIyOCI6eyIxIjpbMjI5XX0sIjMzIjp7IjEiOlsxMThdfSwiMzUiOnsiMSI6WzI0OF19LCIzNiI6eyIxIjpbMTE4XX0sIjM3Ijp7IjEiOlsxMThdLCIyIjpbMTE4LDE3OCwxMTZdfSwiMzkiOnsiMSI6WzExOF0sIjIiOlsxODEsMjQ5LDExOCwxNzhdfSwiNCI6eyIyIjpbMTE4LDExNl19LCI0MSI6eyIxIjpbMTc5LDE3OF19LCI2Ijp7IjEiOlsxMThdLCIyIjpbMTE2LDE3OF19LCI3Ijp7IjEiOlsxMTldfX19';

  static const _playlistHeaders = {
    'spotify-playlist-sync-reason': 'CAwQAQ==',
    'x-accept-list-items':
        'audio-track, audio-episode, video-episode, audiobook',
    'spotify-accept-geoblock': 'dummy',
    'spotify-dsa-mode-enabled': 'false',
    'cache-control': 'no-store',
  };

  final SpotifyTransport _client;
  final RuntimeContext _ctx;
  final HomeFeedCache _cache;

  HomeRepositoryImpl({
    required SpotifyTransport client,
    required RuntimeContext ctx,
    required AppCacheManager cacheManager,
  })  : _client = client,
        _ctx = ctx,
        _cache = HomeFeedCache(cacheManager: cacheManager);

  /// Fetches home feed with SWR pattern.
  @override
  Stream<HomeViewData> getHomeFeed({HomeFacet facet = HomeFacet.all}) async* {
    final cached = await _cache.load(facet: facet);
    if (cached != null) {
      yield cached;
    }

    final fresh = await fetchFresh(facet: facet);
    if (fresh != null) {
      yield fresh;
    }
  }

  /// Fetches fresh home feed data using Spotify's exact pipeline.
  @override
  Future<HomeViewData?> fetchFresh({HomeFacet facet = HomeFacet.all}) async {
    try {
      // Step 1: Fetch Casita home + recents in parallel
      // Only fetch recents for the "All" facet
      final futures = <Future>[_fetchCasitaHome(facet)];
      if (facet == HomeFacet.all) {
        futures.add(_fetchRecentsItems());
      }

      final results = await Future.wait(futures);

      final casitaBytes = results[0] as Uint8List?;
      final recentItems = facet == HomeFacet.all
          ? results[1] as List<RecentsItem>
          : <RecentsItem>[];

      if (casitaBytes == null || casitaBytes.isEmpty) return null;

      // Step 2: Parse the Casita response
      final parser = CasitaParser(casitaBytes);
      final casitaResult = await parser.parse();
      final sections = casitaResult.homeData.sections.toList();
      dev.log(
        'Casita parsed ${sections.length} sections for ${facet.name}: '
        '${sections.map((s) => s.sectionType).toList()}',
      );

      // Step 3: Inject recents into the recents section
      if (recentItems.isNotEmpty) {
        _injectRecents(sections, recentItems, parser);
      }

      // Step 4: Resolve traits for items not covered by eagerload
      final allEntities = <SpotifyEntity>[];
      for (final section in sections) {
        allEntities.addAll(section.items);
      }

      await _resolveOndemandTraits(
        allEntities,
        casitaResult.ondemandUris,
      );

      final result = HomeViewData(
        greeting: casitaResult.homeData.greeting,
        sections: sections,
        chips: casitaResult.homeData.chips,
      );

      await _cache.save(result, facet: facet);
      return result;
    } catch (e) {
      dev.log('HomeRepository.fetchFresh: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Step 4: On-demand trait resolution (Spotify's exact flow)
  // ═══════════════════════════════════════════════════════════════════

  /// Resolves SimpleCardTrait for items not covered by the eagerload config.
  ///
  /// Spotify's pipeline:
  ///   1. The Casita response includes ondemandSet (field 999) with URIs
  ///   2. GET /ondemand-selector/v1/select-ondemand-set filters them
  ///   3. POST /extended-metadata/v0/extended-metadata resolves SimpleCardTrait
  Future<void> _resolveOndemandTraits(
    List<SpotifyEntity> allEntities,
    List<String> ondemandUris,
  ) async {
    // Collect URIs that still need SimpleCardTrait
    final urisToResolve = allEntities
        .where((item) =>
            item.getTrait<SimpleCardTrait>() == null &&
            !item.uri.startsWith('spotify:collection:'))
        .map((item) => item.uri)
        .toSet();

    // Merge with ondemand set from the Casita response
    if (ondemandUris.isNotEmpty) {
      urisToResolve.addAll(ondemandUris);
    }

    // Also merge URIs from the on-demand selector API
    try {
      final selectorUris = await _fetchOndemandSelector();
      if (selectorUris.isNotEmpty) {
        urisToResolve.addAll(selectorUris);
        dev.log('OnDemandSelector: ${selectorUris.length} additional URIs');
      }
    } catch (e) {
      dev.log('OnDemandSelector failed (non-critical): $e');
    }

    if (urisToResolve.isEmpty) return;

    // Step 4b: Fetch SimpleCardTrait via Extended Metadata API
    final uriList = urisToResolve.toList();
    dev.log('HomeRepository: Resolving SimpleCardTrait for ${uriList.length} URIs...');
    final fetcher = ExtendedMetadataFetcher(client: _client, ctx: _ctx);
    final traitMap = await fetcher.fetchTraits(uriList);

    // Merge resolved traits into entities
    for (final entity in allEntities) {
      if (entity.getTrait<SimpleCardTrait>() != null) continue;
      final trait = traitMap[entity.uri];
      if (trait != null) {
        entity.traits['SimpleCardTrait'] = trait;
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Network calls
  // ═══════════════════════════════════════════════════════════════════

  Future<Uint8List?> _fetchCasitaHome(HomeFacet facet) {
    final path = '/casita/v1/home/${facet.pathSegment}'
        '?eagerload=$_casitaEagerload'
        '&timezone=${_ctx.timezone}'
        '&mobile-only-dsa-enabled=false';
    return _client.get(path);
  }

  /// GET /ondemand-selector/v1/select-ondemand-set
  /// Returns the filtered set of URIs that need trait resolution.
  Future<List<String>> _fetchOndemandSelector() async {
    final data = await _client.get(
      '/ondemand-selector/v1/select-ondemand-set',
    );
    if (data == null || data.isEmpty) return [];

    final response = await Isolate.run(
      () => ods.OndemandResponse.fromBuffer(data),
    );
    return response.uris.toList();
  }

  Future<List<RecentsItem>> _fetchRecentsItems() async {
    try {
      final data = await _client.get(
        '/playlist/v2/list/recents/main',
        extraHeaders: _playlistHeaders,
      );
      if (data == null || data.isEmpty) return [];
      return await Isolate.run(() => parseRecentsItems(data));
    } catch (e) {
      dev.log('HomeRepository: Recents fetch failed: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Recents injection
  // ═══════════════════════════════════════════════════════════════════

  void _injectRecents(
    List<HomeSection> sections,
    List<RecentsItem> recentItems,
    CasitaParser parser,
  ) {
    final hydratedItems = <SpotifyEntity>[];
    final seen = <String>{};

    for (final item in recentItems) {
      if (item.uri.isEmpty || !seen.add(item.uri)) continue;
      final baseTraits = parser.traitsForUri(item.uri);
      final traits = baseTraits != null ? Map.of(baseTraits) : <String, Trait>{};
      final type = ContentType.fromUri(item.uri);

      final simpleTrait = traits['SimpleCardTrait'] as SimpleCardTrait?;
      final previewTrait = traits['PreviewCardTrait'] as PreviewCardTrait?;

      String title = simpleTrait?.title ?? previewTrait?.title ?? '';
      String subtitle = simpleTrait?.subtitle ?? '';
      String? imageUrl = simpleTrait?.imageUrl ?? previewTrait?.imageUrl;

      if (title.isEmpty) title = _specialUriTitle(item.uri);
      if (subtitle.isEmpty) {
        subtitle = switch (type) {
          ContentType.album => 'Album',
          ContentType.playlist => 'Playlist',
          ContentType.artist => 'Artist',
          ContentType.podcast => 'Podcast',
          ContentType.episode => 'Episode',
          _ => '',
        };
      }

      if (title.isNotEmpty || imageUrl != null) {
        traits['SimpleCardTrait'] = SimpleCardTrait(
          title: title,
          subtitle: subtitle,
          imageUrl: imageUrl,
        );
      }

      traits['RecentsMetadataTrait'] = RecentsMetadataTrait(
        songsCount: item.songsCount,
        recentType: item.recentType.name,
        contentCategory: item.contentCategory.name,
        groupName: item.groupName,
        timestamp: item.timestamp,
      );

      hydratedItems.add(SpotifyEntity(
        uri: item.uri,
        type: type,
        traits: traits,
      ));
    }

    bool found = false;
    for (int i = 0; i < sections.length; i++) {
      if (sections[i].sectionType == 'recentsShelf') {
        sections[i] = HomeSection(
          title: sections[i].title.isEmpty ? 'Recents' : sections[i].title,
          items: hydratedItems,
          layout: SectionLayout.carousel,
          sectionType: 'recentsShelf',
        );
        found = true;
        break;
      }
    }

    if (!found && hydratedItems.isNotEmpty) {
      final insertIdx =
          sections.indexWhere((s) => s.sectionType != 'shortcuts');
      sections.insert(
        insertIdx >= 0 ? insertIdx : 0,
        HomeSection(
          title: 'Recents',
          items: hydratedItems,
          layout: SectionLayout.carousel,
          sectionType: 'recentsShelf',
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════

  String _specialUriTitle(String uri) {
    return switch (uri) {
      'spotify:collection:tracks' => 'Liked Songs',
      'spotify:collection:your-episodes' => 'Your Episodes',
      'spotify:collection:podcasts' => 'Your Podcasts',
      'spotify:collection:albums' => 'Saved Albums',
      'spotify:collection:artists' => 'Following',
      _ => '',
    };
  }
}
