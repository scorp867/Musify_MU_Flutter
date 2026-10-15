---
title: "preview_card_trait.dart"
path: "lib/features/home_feed/domain/models/traits/preview_card_trait.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 79
incoming_dependencies: 0
outgoing_dependencies: 0
---

# preview_card_trait.dart

> Source File: `[lib/features/home_feed/domain/models/traits/preview_card_trait.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/domain/models/traits/preview_card_trait.dart)`
> Layer: `lib/features/home_feed/domain/models/traits`

## Executive Summary
`preview_card_trait.dart` is an essential file in `lib/features/home_feed/domain/models/traits` providing definitions for `PreviewCardTrait`.
**Primary Architecture Role**: Kodiak Trait Plugin / Reactive Element

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
- No internal files directly import this file (entry point, test file, or dynamic provider).

## Declarations & API Breakdown

### Classes & Mixins
#### `class PreviewCardTrait`
- **Archetype**: Kodiak Trait Plugin / Reactive Element
- **Extends**: `Trait`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `title` | `String` |
| `contentTypeName` | `String` |
| `description` | `String` |
| `imageUrl` | `String?` |
| `backgroundColor` | `String?` |
| `waveformColor` | `String?` |
| `trackCount` | `int` |
| `entityUri` | `String?` |
| `navigateUri` | `String?` |
| `tags` | `List<String>` |
| `previewLabel` | `String` |
| `playingLabel` | `String` |
| `creatorName` | `String` |
| `creatorUri` | `String` |
| `creatorImageUrl` | `String` |
| `image` | `final` |
| `bg` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `toJson` | `dynamic>` | `(none)` |
| `fromJson` | `dynamic` | `Map<String, dynamic> json` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'trait.dart';

/// ExtensionKind 118 (PREVIEW_CARD_TRAIT).
class PreviewCardTrait extends Trait {
  final String title;
  final String contentTypeName;
  final String description;
  final String? imageUrl;
  final String? backgroundColor;
  final String? waveformColor;
  final int trackCount;
  final String? entityUri;
  final String? navigateUri;
  final List<String> tags;
  final String previewLabel;
  final String playingLabel;
  final String creatorName;
  final String creatorUri;
  final String creatorImageUrl;

  const PreviewCardTrait({
    required this.title,
    this.contentTypeName = '',
    this.description = '',
    this.imageUrl,
    this.backgroundColor,
    this.waveformColor,
    this.trackCount = 0,
    this.entityUri,
    this.navigateUri,
    this.tags = const [],
    this.previewLabel = '',
    this.playingLabel = '',
    this.creatorName = '',
    this.creatorUri = '',
    this.creatorImageUrl = '',
  });

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'contentTypeName': contentTypeName,
    'description': description,
    'imageUrl': imageUrl,
    'backgroundColor': backgroundColor,
// ... [remaining code in source file] ...
```
