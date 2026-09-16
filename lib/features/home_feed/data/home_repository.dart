import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:musify_mu/core/protocol/protobuf_utils.dart';
import 'package:musify_mu/features/home_feed/data/casita_parser.dart';
import 'package:musify_mu/features/home_feed/data/extended_metadata_fetcher.dart';
import 'package:musify_mu/features/home_feed/domain/models/content_item.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:musify_mu/features/spotify_client/spotify_client.dart';
import 'package:path_provider/path_provider.dart';

/// Repository for home feed data. Implements SWR (Stale-While-Revalidate):
///
///   1. Return cached data immediately (if available)
///   2. Trigger background network refresh
///   3. Emit updated data when fresh response arrives
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
  final ExtendedMetadataFetcher _metadataFetcher;

  HomeRepository({required SpotifyClient client})
      : _client = client,
        _metadataFetcher = ExtendedMetadataFetcher(client: client);

  /// Fetches home feed with SWR pattern.
  ///
  /// Returns a stream that emits:
  ///   1. Cached data (if available) — immediate
  ///   2. Fresh data (from network) — when ready
  Stream<HomeViewData> getHomeFeed() async* {
    // 1. Serve cached data instantly.
    final cached = await _loadFromDisk();
    if (cached != null) {
      yield cached;
    }

    // 2. Always fetch fresh data from network.
    final fresh = await fetchFresh();
    if (fresh != null) {
      yield fresh;
    }
  }

  /// Fetches fresh data from Casita endpoint. Returns null on failure.
  Future<HomeViewData?> fetchFresh() async {
    try {
      // Fetch casita home and recents list in parallel.
      final results = await Future.wait([
        _fetchCasitaHome(),
        _fetchRecentsItems(),
      ]);

      final casitaBytes = results[0] as Uint8List?;
      final recentItems = results[1] as List<_RecentsItem>;

      if (casitaBytes == null || casitaBytes.isEmpty) return null;
      
      // DUMP BINARY FOR REVERSE ENGINEERING (App Directory)
      try {
        final dir = await getApplicationDocumentsDirectory();
        final f = File('${dir.path}/casita.bin');
        f.writeAsBytesSync(casitaBytes);
        print('✅ DUMPED casita.bin TO ${f.path}');
      } catch (e) {
        print('❌ DUMP FAILED: $e');
      }

      final parser = CasitaParser(casitaBytes);
      final homeData = parser.parse();

      // Inject recents items into the recents section (or create one).
      final sections = homeData.sections.toList();
      if (recentItems.isNotEmpty) {
        // Hydrate each URI: Casita trait → known special URI → bare type label.
        final hydratedItems = <ContentItem>[];
        final seen = <String>{};
        for (final item in recentItems) {
          if (item.uri.isEmpty || !seen.add(item.uri)) continue;
          // Skip child items (non-group-headers that are children of a group)
          // Only show group headers in the recents carousel.
          final trait = parser.traitForUri(item.uri);
          final type = ContentType.fromUri(item.uri);

          // Determine title: Casita trait > special URI > empty
          String title = trait?.title ?? '';
          String subtitle = trait?.subtitle ?? '';
          String? imageUrl = trait?.imageUrl;

          // Hardcoded fallbacks for special collection URIs
          if (title.isEmpty) {
            title = _specialUriTitle(item.uri);
          }
          // Type label as subtitle fallback
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

          hydratedItems.add(ContentItem(
            uri: item.uri,
            title: title,
            subtitle: subtitle,
            imageUrl: imageUrl,
            type: type,
            badge: item.badge,
          ));
        }

        // Batch-fetch metadata for items still missing title/image.
        final missingUris = hydratedItems
            .where((item) => item.title.isEmpty && !item.uri.startsWith('spotify:collection:'))
            .map((item) => item.uri)
            .toList();

        if (missingUris.isNotEmpty) {
          final fetched = await _metadataFetcher.fetchMetadata(missingUris);
          for (int i = 0; i < hydratedItems.length; i++) {
            final meta = fetched[hydratedItems[i].uri];
            if (meta != null) {
              hydratedItems[i] = ContentItem(
                uri: hydratedItems[i].uri,
                title: meta.title.isNotEmpty ? meta.title : hydratedItems[i].title,
                subtitle: meta.subtitle.isNotEmpty ? meta.subtitle : hydratedItems[i].subtitle,
                imageUrl: meta.imageUrl ?? hydratedItems[i].imageUrl,
                type: hydratedItems[i].type,
                badge: hydratedItems[i].badge,
              );
            }
          }
        }

        // Find existing recents section and replace it.
        bool found = false;
        for (int i = 0; i < sections.length; i++) {
          if (sections[i].sectionType == 'recents') {
            sections[i] = HomeSection(
              title: sections[i].title.isEmpty
                  ? 'Recents'
                  : sections[i].title,
              items: hydratedItems,
              layout: SectionLayout.carousel,
              sectionType: 'recents',
            );
            found = true;
            break;
          }
        }

        // No recents section in Casita → create one after shortcuts.
        if (!found && hydratedItems.isNotEmpty) {
          final insertIdx = sections.indexWhere(
              (s) => s.sectionType != 'shortcuts');
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

      final result = HomeViewData(
        greeting: homeData.greeting,
        sections: sections,
        chips: homeData.chips,
      );

      // Cache to disk.
      await _saveToDisk(result);

      return result;
    } catch (e) {
      print('❌ HomeRepository.fetchFresh: $e');
      return null;
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

  Future<List<_RecentsItem>> _fetchRecentsItems() async {
    try {
      final data = await _client.get(
        '/playlist/v2/list/recents/main',
        extraHeaders: _playlistHeaders,
      );
      if (data == null || data.isEmpty) return [];
      return _parseRecentsItems(data);
    } catch (e) {
      print('❌ HomeRepository: Recents fetch failed: $e');
      return [];
    }
  }

  /// Parses recents/main protobuf response.
  ///
  /// Structure (from playlist4_external.proto):
  /// ```
  /// F5: ListItems { F3 repeated: Item { F1: uri, F2: ItemAttributes {
  ///   F11 repeated: FormatListAttribute { F1: key, F2: value }
  /// }}}
  /// ```
  List<_RecentsItem> _parseRecentsItems(Uint8List data) {
    final items = <_RecentsItem>[];

    // Navigate to F5 (ListItems)
    final listBytes = protoNavTo(data, 5);
    if (listBytes == null) return items;

    // Collect all F3 (Item) entries
    final itemBlobs = protoCollectField(listBytes, 3);
    for (final itemBytes in itemBlobs) {
      final uri = protoReadStringField(itemBytes, 1) ?? '';
      if (uri.isEmpty) continue;

      // Parse F2 (ItemAttributes) for format_attributes
      final attrsBytes = protoNavTo(itemBytes, 2);
      int songsCount = 0;
      bool isSaved = false;
      bool isGroupHeader = false;

      if (attrsBytes != null) {
        // F11 repeated: FormatListAttribute { F1: key, F2: value }
        final formatAttrs = protoCollectField(attrsBytes, 11);
        for (final attrBytes in formatAttrs) {
          final key = protoReadStringField(attrBytes, 1) ?? '';
          final value = protoReadStringField(attrBytes, 2) ?? '';

          switch (key) {
            case 'group_id_0':
              isGroupHeader = true;
            case 'recent_type_saved':
              isSaved = true;
            case 'group_metadata':
              // Base64-encoded protobuf: F1(varint) = songs count
              try {
                final decoded = base64.decode(value);
                if (decoded.length >= 2 && decoded[0] == 8) {
                  songsCount = decoded[1];
                }
              } catch (_) {}
          }
        }
      }

      items.add(_RecentsItem(
        uri: uri,
        songsCount: songsCount,
        isSaved: isSaved,
        isGroupHeader: isGroupHeader,
      ));
    }

    print('✅ Recents: ${items.length} items parsed');
    return items;
  }

  /// Known special collection URIs that will never appear in Casita traits.
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
                  'items': s.items
                      .map((i) => {
                            'uri': i.uri,
                            'title': i.title,
                            'subtitle': i.subtitle,
                            'imageUrl': i.imageUrl,
                            'type': i.type.name,
                            if (i.badge != null) 'badge': i.badge,
                          })
                      .toList(),
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

      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
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
                    .map((i) => ContentItem(
                          uri: i['uri'] ?? '',
                          title: i['title'] ?? '',
                          subtitle: i['subtitle'] ?? '',
                          imageUrl: i['imageUrl'],
                          type: ContentType.values.firstWhere(
                            (t) => t.name == i['type'],
                            orElse: () => ContentType.unknown,
                          ),
                          badge: i['badge'],
                        ))
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

/// Internal model for a parsed recents item with protobuf attributes.
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

  /// Builds a badge string from the attributes.
  /// Examples: "2 songs added", "1 song played"
  String? get badge {
    if (!isGroupHeader || songsCount <= 0) return null;
    final action = isSaved ? 'added' : 'played';
    final songText = songsCount == 1 ? 'song' : 'songs';
    return '$songsCount $songText $action';
  }
}
