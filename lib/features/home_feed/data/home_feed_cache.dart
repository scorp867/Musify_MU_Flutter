import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/cache/cache_policy.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Disk cache for the home feed response.
///
/// Stores per-facet HomeViewData (greeting, sections, chips) as separate
/// JSON blobs with timestamps for TTL-based expiration.
class HomeFeedCache {
  static const _policy = CachePolicy.standard;

  final AppCacheManager _cacheManager;

  HomeFeedCache({required AppCacheManager cacheManager})
      : _cacheManager = cacheManager;

  Future<File> _getCacheFile(HomeFacet facet) async {
    final dir = await _cacheManager.featureDir('home');
    return File('${dir.path}${Platform.pathSeparator}home_feed_${facet.name}.json');
  }

  /// Persists the home feed data to disk.
  Future<void> save(HomeViewData data, {HomeFacet facet = HomeFacet.all}) async {
    try {
      final file = await _getCacheFile(facet);
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
      dev.log('HomeFeedCache: write failed: $e');
    }
  }

  /// Loads the cached home feed from disk. Returns null if missing or expired.
  Future<HomeViewData?> load({HomeFacet facet = HomeFacet.all}) async {
    try {
      final file = await _getCacheFile(facet);
      if (!await file.exists()) return null;

      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final cachedAt = json['cachedAt'] as int? ?? 0;

      if (_policy.isExpired(cachedAt)) {
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
      dev.log('HomeFeedCache: read failed: $e');
      return null;
    }
  }
}
