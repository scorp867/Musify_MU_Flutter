import 'dart:async';
import 'dart:developer' as dev;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';
import 'package:musify_mu/features/home_feed/data/casita_parser.dart';
import 'package:musify_mu/features/home_feed/data/eagerload/eagerload_payload_builder.dart';
import 'package:musify_mu/features/home_feed/data/home_feed_cache.dart';
import 'package:musify_mu/features/home_feed/data/recents_parser.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';
import 'package:musify_mu/features/home_feed/domain/repositories/home_repository.dart';

/// Repository for home feed data implementing Stale-While-Revalidate (SWR)
/// backed by binary Casita + Recents protobuf payloads and Kodiak DataPool.
class HomeRepositoryImpl implements HomeRepository {
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
  final DataPool _dataPool;

  HomeRepositoryImpl({
    required SpotifyTransport client,
    required RuntimeContext ctx,
    required AppCacheManager cacheManager,
    required DataPool dataPool,
  }) : _client = client,
       _ctx = ctx,
       _cache = HomeFeedCache(cacheManager: cacheManager),
       _dataPool = dataPool;

  @override
  DataPool get dataPool => _dataPool;

  @override
  Stream<HomeViewData> getHomeFeed({
    HomeFacet facet = HomeFacet.all,
    CancelToken? cancelToken,
  }) async* {
    await _dataPool.ensureDiskLoaded();

    final cachedRaw = await _cache.loadRaw(facet: facet);
    if (cachedRaw != null) {
      try {
        final cachedView = await _buildHomeViewData(
          casitaBytes: cachedRaw.casitaBytes,
          recentsBytes: cachedRaw.recentsBytes,
          facet: facet,
        );
        yield cachedView;
      } catch (e) {
        dev.log('HomeRepository: cached payload parse failed: $e');
      }
    }

    if (cancelToken?.isCancelled == true) return;

    final fresh = await fetchFresh(facet: facet, cancelToken: cancelToken);
    if (fresh != null) {
      yield fresh;
    }
  }

  @override
  Future<HomeViewData?> fetchFresh({
    HomeFacet facet = HomeFacet.all,
    CancelToken? cancelToken,
  }) async {
    try {
      if (cancelToken?.isCancelled == true) return null;

      final casitaFuture = _fetchCasitaHome(facet, cancelToken: cancelToken);
      final recentsFuture = _fetchRecentsBytes(facet, cancelToken: cancelToken);
      final casitaBytes = await casitaFuture;
      final recentsBytes = await recentsFuture;

      if (casitaBytes == null || casitaBytes.isEmpty) return null;
      if (cancelToken?.isCancelled == true) return null;

      final result = await _buildHomeViewData(
        casitaBytes: casitaBytes,
        recentsBytes: recentsBytes,
        facet: facet,
      );

      await _cache.saveRaw(
        casitaBytes: casitaBytes,
        recentsBytes: recentsBytes,
        facet: facet,
      );
      return result;
    } catch (e) {
      dev.log('HomeRepository.fetchFresh: $e');
      return null;
    }
  }

  Future<HomeViewData> _buildHomeViewData({
    required Uint8List casitaBytes,
    required Uint8List? recentsBytes,
    required HomeFacet facet,
  }) async {
    final parser = CasitaParser(casitaBytes);
    final casitaResult = await parser.parse();
    final sections = casitaResult.homeData.sections.toList();
    dev.log(
      'Casita parsed ${sections.length} sections for ${facet.name}: '
      '${sections.map((s) => s.sectionType).toList()}',
    );

    if (casitaResult.traits.isNotEmpty) {
      _dataPool.ingestBatch(casitaResult.traits);
    }
    if (casitaResult.eagerCells.isNotEmpty) {
      _dataPool.ingestCells(casitaResult.eagerCells);
    }
    if (casitaResult.eagerRawPayloads.isNotEmpty) {
      _dataPool.ingestRawPayloads(casitaResult.eagerRawPayloads);
    }

    if (recentsBytes != null && recentsBytes.isNotEmpty) {
      try {
        final recentItems = await Isolate.run(
          () => parseRecentsItems(recentsBytes),
        );
        if (recentItems.isNotEmpty) {
          _injectRecents(sections, recentItems, casitaResult.traits);
        }
      } catch (e) {
        dev.log('HomeRepository: Recents parse failed for ${facet.name}: $e');
      }
    }

    return HomeViewData(
      greeting: casitaResult.homeData.greeting,
      sections: List<HomeSection>.unmodifiable(sections),
      chips: casitaResult.homeData.chips,
    );
  }

  Future<Uint8List?> _fetchCasitaHome(
    HomeFacet facet, {
    CancelToken? cancelToken,
  }) {
    final eagerload = EagerloadPayloadBuilder.build();
    final path =
        '/casita/v1/home/${facet.pathSegment}'
        '?eagerload=$eagerload'
        '&timezone=${_ctx.timezone}'
        '&mobile-only-dsa-enabled=false';
    return _client.get(
      path,
      tag: 'home_casita_${facet.name}',
      ttl: const Duration(seconds: 30),
      priority: NetworkPriority.interactive,
      cancelToken: cancelToken,
    );
  }

  Future<Uint8List?> _fetchRecentsBytes(
    HomeFacet facet, {
    CancelToken? cancelToken,
  }) async {
    try {
      final data = await _client.get(
        facet.recentsPath,
        extraHeaders: _playlistHeaders,
        tag: 'home_recents_${facet.name}',
        ttl: const Duration(seconds: 30),
        priority: NetworkPriority.interactive,
        cancelToken: cancelToken,
      );
      if (data == null || data.isEmpty) return null;
      return data;
    } catch (e) {
      dev.log('HomeRepository: Recents fetch failed for ${facet.name}: $e');
      return null;
    }
  }

  void _injectRecents(
    List<HomeSection> sections,
    List<RecentsItem> recentItems,
    Map<String, Map<String, Trait>> traitsMap,
  ) {
    final hydratedItems = <SpotifyEntity>[];
    final seen = <String>{};

    for (final item in recentItems) {
      if (item.uri.isEmpty || !seen.add(item.uri)) continue;
      final baseTraits =
          traitsMap[item.uri] ?? traitsMap[item.uri.toLowerCase()];
      final traits = baseTraits != null
          ? Map.of(baseTraits)
          : <String, Trait>{};
      final type = ContentType.fromUri(item.uri);

      final simpleTrait = traits['SimpleCardTrait'] as SimpleCardTrait?;
      final previewTrait = traits['PreviewCardTrait'] as PreviewCardTrait?;

      String title = simpleTrait?.title ?? previewTrait?.title ?? '';
      String subtitle = simpleTrait?.subtitle ?? '';
      final String? imageUrl = simpleTrait?.imageUrl ?? previewTrait?.imageUrl;

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

      traits['SimpleCardTrait'] = SimpleCardTrait(
        title: title,
        subtitle: subtitle,
        imageUrl: imageUrl,
      );

      traits['RecentsMetadataTrait'] = RecentsMetadataTrait(
        songsCount: item.songsCount,
        recentType: item.recentType.name,
        contentCategory: item.contentCategory.name,
        groupName: item.groupName,
        timestamp: item.timestamp,
        entityUris: item.entityUris,
      );

      _dataPool.ingestTraits(item.uri, traits);

      hydratedItems.add(
        SpotifyEntity(uri: item.uri, type: type, traits: traits),
      );
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
      final insertIdx = sections.indexWhere(
        (s) => s.sectionType != 'shortcuts',
      );
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

  String _specialUriTitle(String uri) {
    if (uri == 'spotify:collection:tracks' ||
        uri.endsWith(':collection') ||
        uri == 'spotify:collection') {
      return 'Liked Songs';
    }
    return switch (uri) {
      'spotify:collection:your-episodes' => 'Your Episodes',
      'spotify:collection:podcasts' => 'Your Podcasts',
      'spotify:collection:albums' => 'Saved Albums',
      'spotify:collection:artists' => 'Following',
      _ => '',
    };
  }
}
