---
title: "home_feed_cache.dart"
path: "lib/features/home_feed/data/home_feed_cache.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 106
incoming_dependencies: 1
outgoing_dependencies: 4
---

# home_feed_cache.dart

> Source File: `[lib/features/home_feed/data/home_feed_cache.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/data/home_feed_cache.dart)`
> Layer: `lib/features/home_feed/data`

## Executive Summary
`home_feed_cache.dart` is an essential file in `lib/features/home_feed/data` providing definitions for `HomeFeedCache`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `app_cache_manager.dart` | `lib/core/cache` | [[04-Reference/lib/core/cache/app_cache_manager|app_cache_manager.dart]] |
| `cache_policy.dart` | `lib/core/cache` | [[04-Reference/lib/core/cache/cache_policy|cache_policy.dart]] |
| `home_view_data.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/home_view_data|home_view_data.dart]] |
| `spotify_entity.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/spotify_entity|spotify_entity.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `home_repository.dart` | `lib/features/home_feed/data` | [[04-Reference/lib/features/home_feed/data/home_repository|home_repository.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class HomeFeedCache`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_cacheManager` | `AppCacheManager` |
| `dir` | `final` |
| `file` | `final` |
| `json` | `final` |
| `file` | `final` |
| `json` | `final` |
| `cachedAt` | `final` |
| `null` | `return` |
| `sections` | `final` |
| `chips` | `final` |
| `null` | `return` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `_getCacheFile` | `Future<File>` | `HomeFacet facet` |
| `save` | `Future<void>` | `HomeViewData data, {HomeFacet facet = HomeFacet...` |
| `map` | `dynamic` | `(s` |
| `map` | `dynamic` | `(i` |
| `map` | `dynamic` | `(c` |
| `load` | `Future<HomeViewData?>` | `{HomeFacet facet = HomeFacet.all}` |
| `map` | `dynamic` | `(s` |
| `HomeSection` | `dynamic` | `title: s['title'] ?? '', subtitle: s['subtitle'...` |
| `map` | `dynamic` | `(i` |
| `map` | `dynamic` | `(c` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
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
                  'colorCode': s.colorCode,
                  'imageUrl': s.imageUrl,
                  'metadata': s.metadata,
                  'items': s.items.map((i) => i.toJson()).toList(),
                })
// ... [remaining code in source file] ...
```
