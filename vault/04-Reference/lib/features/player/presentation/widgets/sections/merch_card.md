---
title: "merch_card.dart"
path: "lib/features/player/presentation/widgets/sections/merch_card.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 171
incoming_dependencies: 1
outgoing_dependencies: 0
---

# merch_card.dart

> Source File: `[lib/features/player/presentation/widgets/sections/merch_card.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/presentation/widgets/sections/merch_card.dart)`
> Layer: `lib/features/player/presentation/widgets/sections`

## Executive Summary
`merch_card.dart` is an essential file in `lib/features/player/presentation/widgets/sections` providing definitions for `MerchItem`, `PlayerMerchSection`, `_MerchRow`.
**Primary Architecture Role**: Core Component, Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `debug_now_playing_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/debug_now_playing_screen|debug_now_playing_screen.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class MerchItem`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `title` | `String` |
| `price` | `String` |
| `imageUrl` | `String?` |
| `onTap` | `VoidCallback?` |

#### `class PlayerMerchSection`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `items` | `List<MerchItem>` |
| `onShowAll` | `VoidCallback?` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |

#### `class _MerchRow`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `item` | `MerchItem` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `network` | `dynamic` | `item.imageUrl!, fit: BoxFit.cover, errorBuilder...` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter/material.dart';

/// Item data model for Now Playing merch rows (`merch_row_now_playing.xml`).
class MerchItem {
  final String title;
  final String price;
  final String? imageUrl;
  final VoidCallback? onTap;

  const MerchItem({
    required this.title,
    required this.price,
    this.imageUrl,
    this.onTap,
  });
}

/// Spotify-identical Merch card
/// (`ScrollCardType.MERCH` / `merch_card_now_playing.xml`).
///
/// Features:
/// - 16dp rounded corners (`widgets_corner_radius`)
/// - Elevated base background (#242424)
/// - Header with "Merch" title and "Show all" action
/// - Clean item rows with 48x48 rounded thumbnail, title, price, and chevron
class PlayerMerchSection extends StatelessWidget {
  const PlayerMerchSection({
    super.key,
    required this.items,
    this.onShowAll,
  });

  final List<MerchItem> items;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(16),
      ),
// ... [remaining code in source file] ...
```
