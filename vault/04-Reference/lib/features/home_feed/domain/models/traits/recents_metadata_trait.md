---
title: "recents_metadata_trait.dart"
path: "lib/features/home_feed/domain/models/traits/recents_metadata_trait.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 38
incoming_dependencies: 0
outgoing_dependencies: 0
---

# recents_metadata_trait.dart

> Source File: `[lib/features/home_feed/domain/models/traits/recents_metadata_trait.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/traits/recents_metadata_trait.dart)`
> Layer: `lib/features/home_feed/domain/models/traits`

## Executive Summary
`recents_metadata_trait.dart` is an essential file in `lib/features/home_feed/domain/models/traits` providing definitions for `RecentsMetadataTrait`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class RecentsMetadataTrait`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Extends**: `Trait`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `songsCount` | `int` |
| `recentType` | `String` |
| `contentCategory` | `String` |
| `groupName` | `String` |
| `timestamp` | `int` |
| `entityUris` | `List<String>` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `toJson` | `dynamic>` | `(none)` |
| `fromJson` | `dynamic` | `Map<String, dynamic> json` |
| `map` | `dynamic` | `(e` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'trait.dart';

class RecentsMetadataTrait extends Trait {
  final int songsCount;
  final String recentType;
  final String contentCategory;
  final String groupName;
  final int timestamp;
  final List<String> entityUris;

  const RecentsMetadataTrait({
    this.songsCount = 0,
    this.recentType = 'played',
    this.contentCategory = '',
    this.groupName = '',
    this.timestamp = 0,
    this.entityUris = const [],
  });

  @override
  Map<String, dynamic> toJson() => {
    'songsCount': songsCount,
    'recentType': recentType,
    'contentCategory': contentCategory,
    'groupName': groupName,
    'timestamp': timestamp,
    'entityUris': entityUris,
  };

  factory RecentsMetadataTrait.fromJson(Map<String, dynamic> json) => RecentsMetadataTrait(
    songsCount: json['songsCount'] ?? 0,
    recentType: json['recentType'] ?? 'played',
    contentCategory: json['contentCategory'] ?? '',
    groupName: json['groupName'] ?? '',
    timestamp: json['timestamp'] ?? 0,
    entityUris: (json['entityUris'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
  );
}
```
