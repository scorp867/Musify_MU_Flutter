import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:musify_mu/core/protocol/generated/spotify/ondemand_selector.pb.dart'
    as ods;
import 'package:musify_mu/core/protocol/generated/spotify/playlist/recents_list.pb.dart'
    as recents;
import 'package:musify_mu/features/home_feed/data/casita_parser.dart';
import 'package:musify_mu/features/home_feed/data/extended_metadata_fetcher.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:musify_mu/features/spotify_client/spotify_client.dart';
import 'package:path_provider/path_provider.dart';

/// Repository for home feed data. Implements SWR (Stale-While-Revalidate).
///
/// Spotify's exact home feed pipeline:
///   1. GET /casita/v1/home/default?eagerload=...  → ResolvedHome protobuf
///   2. Parse ResolvedHome:
///      - field 1: HomeStructure (section layout)
///      - field 2: EagerlyLoadedTraits (pre-loaded traits for eagerload-covered items)
///      - field 999: OndemandSet (URIs that still need trait resolution)
///   3. GET /ondemand-selector/v1/select-ondemand-set  → filtered URI list
///   4. POST /extended-metadata/v0/extended-metadata  → SimpleCardTrait for those URIs
///   5. Merge traits into entities → render
class HomeRepository {
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

  static const _cacheMaxAge = Duration(hours: 24);

  final SpotifyClient _client;

  HomeRepository({required SpotifyClient client}) : _client = client;

  /// Fetches home feed with SWR pattern.
  Stream<HomeViewData> getHomeFeed() async* {
    final cached = await _loadFromDisk();
    if (cached != null) {
      yield cached;
    }

    final fresh = await fetchFresh();
    if (fresh != null) {
      yield fresh;
    }
  }

  /// Fetches fresh home feed data using Spotify's exact pipeline.
  Future<HomeViewData?> fetchFresh() async {
    try {
      // Step 1: Fetch Casita home + recents in parallel
      final results = await Future.wait([
        _fetchCasitaHome(),
        _fetchRecentsItems(),
      ]);

      final casitaBytes = results[0] as Uint8List?;
      final recentItems = results[1] as List<_RecentsItem>;

      if (casitaBytes == null || casitaBytes.isEmpty) return null;

      // Step 2: Parse the Casita response
      final parser = CasitaParser(casitaBytes);
      final casitaResult = await parser.parse();
      final sections = casitaResult.homeData.sections.toList();

      // Step 3: Inject recents into the recents section
      if (recentItems.isNotEmpty) {
        _injectRecents(sections, recentItems, parser);
      }

      // Step 4: Resolve traits for items not covered by eagerload
      // This follows Spotify's exact flow:
      //   a. Read ondemandSet.uris from the Casita response
      //   b. Call /ondemand-selector/v1/select-ondemand-set to filter them
      //   c. Call /extended-metadata/v0/extended-metadata for SimpleCardTrait
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

      await _saveToDisk(result);
      return result;
    } catch (e) {
      print('❌ HomeRepository.fetchFresh: $e');
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
        print('📦 OnDemandSelector: ${selectorUris.length} additional URIs');
      }
    } catch (e) {
      print('⚠️ OnDemandSelector failed (non-critical): $e');
    }

    if (urisToResolve.isEmpty) return;

    // Step 4b: Fetch SimpleCardTrait via Extended Metadata API
    final uriList = urisToResolve.toList();
    print('🌐 HomeRepository: Resolving SimpleCardTrait for ${uriList.length} URIs...');
    final fetcher = ExtendedMetadataFetcher(client: _client);
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

  Future<Uint8List?> _fetchCasitaHome() {
    const path = '/casita/v1/home/default'
        '?eagerload=$_casitaEagerload'
        '&timezone=Asia/Calcutta'
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

  Future<List<_RecentsItem>> _fetchRecentsItems() async {
    try {
      final data = await _client.get(
        '/playlist/v2/list/recents/main',
        extraHeaders: _playlistHeaders,
      );
      if (data == null || data.isEmpty) return [];
      return await Isolate.run(() => _parseRecentsItemsSync(data));
    } catch (e) {
      print('❌ HomeRepository: Recents fetch failed: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Recents injection
  // ═══════════════════════════════════════════════════════════════════

  void _injectRecents(
    List<HomeSection> sections,
    List<_RecentsItem> recentItems,
    CasitaParser parser,
  ) {
    final hydratedItems = <SpotifyEntity>[];
    final seen = <String>{};

    for (final item in recentItems) {
      if (item.uri.isEmpty || !seen.add(item.uri)) continue;
      final traits = parser.traitsForUri(item.uri) ?? {};
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

      hydratedItems.add(SpotifyEntity(
        uri: item.uri,
        type: type,
        traits: traits,
      ));
    }

    bool found = false;
    for (int i = 0; i < sections.length; i++) {
      if (sections[i].sectionType == 'recents') {
        sections[i] = HomeSection(
          title: sections[i].title.isEmpty ? 'Recents' : sections[i].title,
          items: hydratedItems,
          layout: SectionLayout.carousel,
          sectionType: 'recents',
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
          sectionType: 'recents',
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════

  static List<_RecentsItem> _parseRecentsItemsSync(Uint8List data) {
    final items = <_RecentsItem>[];

    try {
      final response = recents.RecentsListResponse.fromBuffer(data);

      for (final listItem in response.list.items) {
        final uri = listItem.uri;
        if (uri.isEmpty) continue;

        int songsCount = 0;
        bool isSaved = false;
        bool isGroupHeader = false;

        for (final attr in listItem.attributes.formatAttributes) {
          switch (attr.key) {
            case 'group_id_0':
              isGroupHeader = true;
            case 'recent_type_saved':
              isSaved = true;
            case 'group_metadata':
              try {
                final decoded = base64.decode(attr.value);
                if (decoded.length >= 2 && decoded[0] == 8) {
                  songsCount = decoded[1];
                }
              } catch (_) {}
          }
        }

        items.add(_RecentsItem(
          uri: uri,
          songsCount: songsCount,
          isSaved: isSaved,
          isGroupHeader: isGroupHeader,
        ));
      }
    } catch (e) {
      print('⚠️ HomeRepository: Recents parse error: $e');
    }

    print('✅ Recents: ${items.length} items parsed');
    return items;
  }

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

  // ═══════════════════════════════════════════════════════════════════
  // Disk cache (JSON serialization)
  // ═══════════════════════════════════════════════════════════════════

  Future<File> get _cacheFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/spotify_home_cache.json');
  }

  Future<void> _saveToDisk(HomeViewData data) async {
    try {
      final file = await _cacheFile;
      final json = {
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'greeting': data.greeting,
        'sections': data.sections
            .map((s) => {
                  'title': s.title,
                  'subtitle': s.subtitle,
                  'layout': s.layout.name,
                  'sectionType': s.sectionType,
                  'sectionUri': s.sectionUri,
                  'items': s.items.map((i) => i.toJson()).toList(),
                })
            .toList(),
        'chips': data.chips
            .map((c) => {'id': c.id, 'label': c.label})
            .toList(),
      };
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      print('❌ HomeRepository: Cache write failed: $e');
    }
  }

  Future<HomeViewData?> _loadFromDisk() async {
    try {
      final file = await _cacheFile;
      if (!await file.exists()) return null;

      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final cachedAt = json['cachedAt'] as int? ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - cachedAt;

      if (age > _cacheMaxAge.inMilliseconds) {
        await file.delete();
        return null;
      }

      final sections = (json['sections'] as List)
          .map((s) => HomeSection(
                title: s['title'] ?? '',
                subtitle: s['subtitle'] ?? '',
                layout: SectionLayout.values.firstWhere(
                  (l) => l.name == s['layout'],
                  orElse: () => SectionLayout.carousel,
                ),
                sectionType: s['sectionType'] ?? '',
                sectionUri: s['sectionUri'],
                items: (s['items'] as List)
                    .map((i) =>
                        SpotifyEntity.fromJson(i as Map<String, dynamic>))
                    .toList(),
              ))
          .toList();

      final chips = (json['chips'] as List? ?? [])
          .map((c) => HomeChip(id: c['id'] ?? '', label: c['label'] ?? ''))
          .toList();

      return HomeViewData(
        greeting: json['greeting'] ?? '',
        sections: sections,
        chips: chips,
      );
    } catch (e) {
      print('❌ HomeRepository: Cache read failed: $e');
      return null;
    }
  }
}

class _RecentsItem {
  final String uri;
  final int songsCount;
  final bool isSaved;
  final bool isGroupHeader;

  const _RecentsItem({
    required this.uri,
    this.songsCount = 0,
    this.isSaved = false,
    this.isGroupHeader = false,
  });
}
