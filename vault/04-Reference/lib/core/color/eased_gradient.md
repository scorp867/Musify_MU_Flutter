---
title: "eased_gradient.dart"
path: "lib/core/color/eased_gradient.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, color]
lines: 64
incoming_dependencies: 2
outgoing_dependencies: 1
---

# eased_gradient.dart

> Source File: `[lib/core/color/eased_gradient.dart](file:///c:/Users/Admin/Musify_MU/lib/core/color/eased_gradient.dart)`
> Layer: `lib/core/color`

## Executive Summary
`eased_gradient.dart` is an essential file in `lib/core/color` providing definitions for `EasedGradient`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `artwork_color_scheme.dart` | `lib/core/color` | [[04-Reference/lib/core/color/artwork_color_scheme|artwork_color_scheme.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `playlist_detail_bloc.dart` | `lib/features/playlist_detail/application` | [[04-Reference/lib/features/playlist_detail/application/playlist_detail_bloc|playlist_detail_bloc.dart]] |
| `player_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/player_screen|player_screen.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class EasedGradient`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `bottomColor` | `Color` |
| `begin` | `AlignmentGeometry` |
| `end` | `AlignmentGeometry` |
| `bottomColor` | `Color` |
| `begin` | `AlignmentGeometry` |
| `end` | `AlignmentGeometry` |
| `colors` | `final` |
| `stops` | `final` |
| `hsv` | `final` |
| `matteColor` | `final` |
| `t` | `final` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter/widgets.dart';

import 'package:musify_mu/core/color/artwork_color_scheme.dart';

/// Builds a Spotify-style atmospheric gradient between an extracted color
/// and the app's dark background color (#121212).
///
/// Matches Spotify's decompiled playlist header rendering (p.wma1.f and p.n6r.d):
/// - Continuous linear-diffuse interpolation across 21 stops without a harsh specular shelf
/// - Eliminates glossy highlight glare, giving the header an authentic velvety matte finish
class EasedGradient {
  static const _stopCount = 21;

  const EasedGradient._();

  /// Builds from an [ArtworkColorScheme], using its primary color.
  static Gradient fromScheme(
    ArtworkColorScheme scheme, {
    Color bottomColor = const Color(0xFF121212),
    AlignmentGeometry begin = Alignment.topCenter,
    AlignmentGeometry end = Alignment.bottomCenter,
  }) {
    return build(
      topColor: scheme.primary,
      bottomColor: bottomColor,
      begin: begin,
      end: end,
    );
  }

  /// Builds a vertical [Gradient] from [topColor] to [bottomColor]
  /// using Spotify's smooth matte interpolation.
  ///
  /// [topColor] is typically the extracted swatch color.
  /// [bottomColor] defaults to `#121212` (Spotify's dark background).
  static Gradient build({
    required Color topColor,
    Color bottomColor = const Color(0xFF121212),
    AlignmentGeometry begin = Alignment.topCenter,
    AlignmentGeometry end = Alignment.bottomCenter,
  }) {
    final colors = <Color>[];
    final stops = <double>[];

    // Primary is already post-processed (matte ceiling applied by SpotifyPostProcessor),
// ... [remaining code in source file] ...
```
