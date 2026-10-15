---
title: "full_bleed_banner_section.dart"
path: "lib/features/home_feed/presentation/widgets/sections/full_bleed_banner_section.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home_feed]
lines: 94
incoming_dependencies: 3
outgoing_dependencies: 2
---

# full_bleed_banner_section.dart

> Source File: `[lib/features/home_feed/presentation/widgets/sections/full_bleed_banner_section.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home_feed/presentation/widgets/sections/full_bleed_banner_section.dart)`
> Layer: `lib/features/home_feed/presentation/widgets/sections`

## Executive Summary
`full_bleed_banner_section.dart` is an essential file in `lib/features/home_feed/presentation/widgets/sections` providing definitions for `FullBleedBannerSection`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `app_network_image.dart` | `lib/core/widgets` | [[04-Reference/lib/core/widgets/app_network_image|app_network_image.dart]] |
| `home_view_data.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/home_view_data|home_view_data.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `section_registry.dart` | `lib/features/home_feed/presentation` | [[04-Reference/lib/features/home_feed/presentation/section_registry|section_registry.dart]] |
| `banner_sections_widget_test.dart` | `test/features/home_feed` | [[04-Reference/test/features/home_feed/banner_sections_widget_test|banner_sections_widget_test.dart]] |
| `kodiak_data_layer_test.dart` | `test/features/home_feed` | [[04-Reference/test/features/home_feed/kodiak_data_layer_test|kodiak_data_layer_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class FullBleedBannerSection`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `section` | `HomeSection` |
| `clean` | `final` |
| `fallback` | `return` |
| `bannerColor` | `final` |
| `imageUrl` | `final` |
| `subtitle` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `_parseColor` | `Color` | `String? hexString, Color fallback` |
| `build` | `Widget` | `BuildContext context` |
| `AspectRatio` | `dynamic` | `aspectRatio: 2226 / 294, child: imageUrl.isNotE...` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter/material.dart';
import 'package:musify_mu/core/widgets/app_network_image.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';

/// FullBleedBanner section matching Spotify's exact edge-to-edge promotional hero card
/// (e.g. "New Music Friday").
///
/// Layout based on Spotify Casita SDUI:
/// ┌──────────────────────────────────────────────────────────────┐
/// │                     [ NEW MUSIC FRIDAY ]                     │  <- colorCode background (#83E6BD)
/// └──────────────────────────────────────────────────────────────┘
///        New music from Drake, Mac Miller, Quavo and more!          <- description subtitle
///
/// The image provided by Spotify is a 2226x294 stencil mask where all RGB pixels
/// are jet black (0,0,0) and the typography/cutouts have alpha transparency.
/// Placing it edge-to-edge over a background filled with `colorCode` allows
/// the dynamic color to shine through the transparent stencil cutouts seamlessly.
class FullBleedBannerSection extends StatelessWidget {
  final HomeSection section;

  const FullBleedBannerSection({
    super.key,
    required this.section,
  });

  static Color _parseColor(String? hexString, Color fallback) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final clean = hexString.replaceFirst('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
    } catch (_) {}
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final bannerColor = _parseColor(section.colorCode, const Color(0xFF83E6BD));
    final imageUrl = section.imageUrl ?? '';
    final subtitle = section.subtitle;

    return RepaintBoundary(
// ... [remaining code in source file] ...
```
