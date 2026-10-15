---
title: "cache_policy.dart"
path: "lib/core/cache/cache_policy.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, cache]
lines: 25
incoming_dependencies: 5
outgoing_dependencies: 0
---

# cache_policy.dart

> Source File: `[lib/core/cache/cache_policy.dart](file:///c:/Users/Admin/Musify_MU/lib/core/cache/cache_policy.dart)`
> Layer: `lib/core/cache`

## Executive Summary
`cache_policy.dart` is an essential file in `lib/core/cache` providing definitions for `CachePolicy`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `home_feed_cache.dart` | `lib/features/home_feed/data` | [[04-Reference/lib/features/home_feed/data/home_feed_cache|home_feed_cache.dart]] |
| `browse_cache.dart` | `lib/features/browse/data` | [[04-Reference/lib/features/browse/data/browse_cache|browse_cache.dart]] |
| `color_cache.dart` | `lib/core/color` | [[04-Reference/lib/core/color/color_cache|color_cache.dart]] |
| `extended_metadata_service.dart` | `lib/core/media` | [[04-Reference/lib/core/media/extended_metadata_service|extended_metadata_service.dart]] |
| `kodiak_disk_cache.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/kodiak_disk_cache|kodiak_disk_cache.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class CachePolicy`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `ttl` | `Duration` |
| `maxEntries` | `int?` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `isExpired` | `bool` | `int cachedAtMs` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
/// Standardized cache expiration policy.
///
/// Each feature cache declares its policy as a first-class object
/// instead of scattering magic Duration constants across files.
class CachePolicy {
  final Duration ttl;
  final int? maxEntries;

  const CachePolicy({required this.ttl, this.maxEntries});

  /// Structure data that changes frequently (library rootlist, collections).
  static const frequent = CachePolicy(ttl: Duration(hours: 1));

  /// View-level data with moderate freshness (home feed, decorations, playlists).
  static const standard = CachePolicy(ttl: Duration(hours: 24));

  /// Stable reference data (browse genre traits, track metadata).
  static const durable = CachePolicy(ttl: Duration(days: 7));

  /// Returns true if an entry cached at [cachedAtMs] has exceeded the TTL.
  bool isExpired(int cachedAtMs) {
    return DateTime.now().millisecondsSinceEpoch - cachedAtMs >
        ttl.inMilliseconds;
  }
}
```
