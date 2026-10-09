import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

import 'package:musify_mu/features/browse/data/browse_cache.dart';
import 'package:musify_mu/features/browse/data/browse_metadata_fetcher.dart';
import 'package:musify_mu/features/browse/data/browsita_parser.dart';
import 'package:musify_mu/features/browse/domain/models/browse_view_data.dart';
import 'package:musify_mu/features/browse/domain/repositories/browse_repository.dart';
import 'package:dio/dio.dart';
import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';

/// Repository for browse tab data.
///
/// Implements Spotify's actual caching strategy (reverse-engineered):
///   - Individual item traits are cached per-URI (not the whole response)
///   - On load: fetch browsita (lightweight structure), then only query
///     extended-metadata for URIs NOT already in the local cache (delta)
///   - This means if 70/79 URIs are cached, only 9 get fetched
///
/// Loading strategies (from decompiled bq70 enum):
///   - CACHE_FIRST: show cached, then revalidate
///   - REVALIDATE: force network fetch
class BrowseRepositoryImpl implements BrowseRepository {
  final SpotifyTransport _client;
  final BrowseTraitCache _traitCache;
  final RuntimeContext _ctx;
  final AppCacheManager _cacheManager;

  BrowseRepositoryImpl({
    required SpotifyTransport client,
    required RuntimeContext ctx,
    required AppCacheManager cacheManager,
    BrowseTraitCache? traitCache,
  })  : _client = client,
        _ctx = ctx,
        _cacheManager = cacheManager,
        _traitCache = traitCache ??
            BrowseTraitCache(cacheManager: cacheManager);

  Future<File> get _browsitaFile async {
    final dir = await _cacheManager.featureDir('browse');
    return File('${dir.path}${Platform.pathSeparator}browsita_structure.bin');
  }

  Future<void> _saveBrowsita(Uint8List bytes) async {
    try {
      final file = await _browsitaFile;
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      dev.log('BrowseRepo: Failed to save browsita cache: $e', name: 'Browse');
    }
  }

  Future<Uint8List?> _loadCachedBrowsita() async {
    try {
      final file = await _browsitaFile;
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      dev.log('BrowseRepo: Failed to load browsita cache: $e', name: 'Browse');
    }
    return null;
  }

  /// Parses bytes and hydrates traits from local cache (and delta network if online).
  Future<BrowseViewData?> _buildFromBytes(
    Uint8List bytes, {
    bool allowNetwork = true,
    CancelToken? cancelToken,
  }) async {
    final parser = BrowsitaParser(bytes);
    final browseData = await parser.parse();

    if (browseData.sections.isEmpty) {
      dev.log('BrowseRepo: No sections parsed', name: 'Browse');
      return null;
    }

    final allUris = <String>[];
    for (final section in browseData.sections) {
      for (final item in section.items) {
        if (item.uri.isNotEmpty) {
          allUris.add(item.uri);
        }
      }
    }

    if (allUris.isEmpty) return browseData;

    final (:cached, :missing) = await _traitCache.partition(allUris);
    var allCards = Map<String, BrowseCardData>.from(cached);

    if (allowNetwork && missing.isNotEmpty) {
      dev.log(
        'BrowseRepo: Fetching delta: ${missing.length} URIs '
        '(${cached.length} from cache)',
        name: 'Browse',
      );

      try {
        final fetcher = BrowseMetadataFetcher(client: _client, ctx: _ctx);
        final freshCards = await fetcher.fetchBrowseTraits(missing);
        await _traitCache.putAll(freshCards);
        allCards.addAll(freshCards);
      } catch (e) {
        dev.log('BrowseRepo: Delta trait fetch skipped/failed (offline?): $e', name: 'Browse');
      }
    }

    final hydratedSections = browseData.sections.map((section) {
      final hydratedItems = section.items.map((item) {
        final card = allCards[item.uri];
        if (card == null) return item;

        return item.copyWith(
          title: card.name.isNotEmpty ? card.name : null,
          imageUrl: card.imageUrl,
          backgroundColor: card.bgColorArgb,
        );
      }).toList();

      return BrowseSection(
        sectionId: section.sectionId,
        sectionType: section.sectionType,
        title: section.title,
        iconName: section.iconName,
        items: hydratedItems,
        navigateUri: section.navigateUri,
      );
    }).toList();

    return BrowseViewData(sections: hydratedSections);
  }

  /// Loads cached browsita structure and cached traits from local disk immediately.
  @override
  Future<BrowseViewData?> loadCached() async {
    try {
      final bytes = await _loadCachedBrowsita();
      if (bytes == null || bytes.isEmpty) return null;
      return await _buildFromBytes(bytes, allowNetwork: false);
    } catch (e, stack) {
      dev.log('BrowseRepo loadCached error: $e\n$stack', name: 'Browse');
      return null;
    }
  }

  /// Fetches browse data with delta trait resolution.
  @override
  Future<BrowseViewData?> fetchBrowse({CancelToken? cancelToken}) async {
    try {
      final bytes = await _fetchBrowsita(cancelToken: cancelToken);
      if (bytes != null && bytes.isNotEmpty) {
        await _saveBrowsita(bytes);
        return await _buildFromBytes(bytes, allowNetwork: true, cancelToken: cancelToken);
      } else {
        dev.log('BrowseRepo: Network browsita unavailable', name: 'Browse');
        return null;
      }
    } catch (e, stack) {
      dev.log('BrowseRepo error: $e\n$stack', name: 'Browse');
      return null;
    }
  }

  /// GET /browsita/v1/browse
  Future<Uint8List?> _fetchBrowsita({CancelToken? cancelToken}) {
    return _client.get(
      '/browsita/v1/browse?timezone=${_ctx.timezone}',
      tag: 'browse_structure',
      ttl: const Duration(seconds: 30),
      priority: NetworkPriority.interactive,
      cancelToken: cancelToken,
    );
  }
}
