---
title: "facet_chip_row.dart"
path: "lib/features/home_feed/presentation/widgets/facet_chip_row.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 92
incoming_dependencies: 1
outgoing_dependencies: 1
---

# facet_chip_row.dart

> Source File: `[lib/features/home_feed/presentation/widgets/facet_chip_row.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/facet_chip_row.dart)`
> Layer: `lib/features/home_feed/presentation/widgets`

## Executive Summary
`facet_chip_row.dart` is an essential file in `lib/features/home_feed/presentation/widgets` providing definitions for `FacetChipRow`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `home_view_data.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/home_view_data|home_view_data.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `home_header.dart` | `lib/features/home/presentation/widgets` | [[04-Reference/lib/features/home/presentation/widgets/home_header|home_header.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class FacetChipRow`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `selectedFacet` | `HomeFacet` |
| `onSelected` | `ValueChanged<HomeFacet>` |
| `chips` | `List<HomeChip>?` |
| `hasDynamicChips` | `final` |
| `count` | `final` |
| `label` | `String` |
| `isSelected` | `bool` |
| `onTap` | `VoidCallback` |
| `chip` | `final` |
| `lowerId` | `final` |
| `lowerLabel` | `final` |
| `isMusic` | `final` |
| `isPodcast` | `final` |
| `facet` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';

/// Horizontal filter chip row for home feed facets.
/// Controlled widget: selectedFacet and onSelected are owned by the parent.
class FacetChipRow extends StatelessWidget {
  final HomeFacet selectedFacet;
  final ValueChanged<HomeFacet> onSelected;
  final List<HomeChip>? chips;

  const FacetChipRow({
    super.key,
    required this.selectedFacet,
    required this.onSelected,
    this.chips,
  });

  @override
  Widget build(BuildContext context) {
    final hasDynamicChips = chips != null && chips!.isNotEmpty;
    final count = hasDynamicChips ? chips!.length : HomeFacet.values.length;

    return Container(
      height: 32,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final String label;
          final bool isSelected;
          final VoidCallback onTap;

          if (hasDynamicChips) {
            final chip = chips![index];
            label = chip.label;
            final lowerId = chip.id.toLowerCase();
            final lowerLabel = chip.label.toLowerCase();

            final isMusic = lowerId.contains('music') || lowerLabel.contains('music');
            final isPodcast = lowerId.contains('podcast') || lowerLabel.contains('podcast');

            isSelected = (selectedFacet == HomeFacet.music && isMusic) ||
// ... [remaining code in source file] ...
```
