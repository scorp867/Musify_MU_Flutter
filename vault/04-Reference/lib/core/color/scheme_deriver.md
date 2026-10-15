---
title: "scheme_deriver.dart"
path: "lib/core/color/scheme_deriver.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, color]
lines: 208
incoming_dependencies: 1
outgoing_dependencies: 2
---

# scheme_deriver.dart

> Source File: `[lib/core/color/scheme_deriver.dart](file:///c:/Users/Admin/Musify_MU/lib/core/color/scheme_deriver.dart)`
> Layer: `lib/core/color`

## Executive Summary
`scheme_deriver.dart` is an essential file in `lib/core/color` providing definitions for `SchemeDeriver`, `_Candidate`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `oklab.dart` | `lib/core/color` | [[04-Reference/lib/core/color/oklab|oklab.dart]] |
| `spotify_post_processor.dart` | `lib/core/color` | [[04-Reference/lib/core/color/spotify_post_processor|spotify_post_processor.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `color_extraction_service.dart` | `lib/core/color` | [[04-Reference/lib/core/color/color_extraction_service|color_extraction_service.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class SchemeDeriver`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `neutralResult` | `const` |
| `totalPop` | `final` |
| `safeTotalPop` | `final` |
| `candidates` | `final` |
| `argb` | `final` |
| `pop` | `final` |
| `hsv` | `final` |
| `lab` | `final` |
| `popRatio` | `final` |
| `argb` | `final` |
| `pop` | `final` |
| `hsv` | `final` |
| `lab` | `final` |
| `hasNonYellow` | `final` |
| `sScore` | `final` |
| `vScore` | `final` |
| `pScore` | `final` |
| `yPenalty` | `final` |
| `best` | `final` |
| `isNeutral` | `final` |
| `primaryArgb` | `int` |
| `primaryLab` | `final` |
| `secondaryArgb` | `int` |
| `secV` | `final` |
| `hsv` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `derive` | `List<int>` | `Map<int, int> colorToPopulation` |
| `any` | `dynamic` | `(c` |
| `sort` | `dynamic` | `(a, b` |
| `sort` | `dynamic` | `(a, b` |

#### `class _Candidate`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `argb` | `int` |
| `pop` | `int` |
| `popRatio` | `double` |
| `h` | `double` |
| `s` | `double` |
| `v` | `double` |
| `lab` | `OkLabColor` |
| `score` | `double` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:math' as math;

import 'package:musify_mu/core/color/oklab.dart';
import 'package:musify_mu/core/color/spotify_post_processor.dart';

/// Derives a full 5-color [ArtworkColorScheme] from quantized clusters.
///
/// Features:
/// 1. Strict filtering of extreme dark sludge (V < 0.12) and blown-out whites (V > 0.94, S < 0.12).
/// 2. Saturation-forward candidate scoring with bell-curve luminance targeting.
/// 3. Yellow/olive suppression penalty when other vibrant colors exist.
/// 4. Non-destructive tone mapping that preserves authentic album hue and saturation.
/// 5. Secondary selection guaranteed free of dark sludge (V >= 0.35, S >= 0.20).
/// 6. Electric accent selection allowing full unconstrained vibrancy for highlights.
/// 7. Deep, tinted surface generation for cards/sheets.
/// 8. Graceful dark slate handling for monochrome/black-and-white artwork.
class SchemeDeriver {
  static const _secondaryMinDistance = 0.12;
  static const _minColorfulSat = 0.18;

  /// Derives scheme from Quantizer result.
  ///
  /// [colorToPopulation]: map of ARGB32 int -> pixel count.
  /// Returns list of 6 ints: [primary, secondary, accent, onPrimary, surface, isNeutral].
  static List<int> derive(Map<int, int> colorToPopulation) {
    const neutralResult = [
      0xFF282828, 0xFF333333, 0xFF535353, 0xFFFFFFFF, 0xFF181818, 1,
    ];

    if (colorToPopulation.isEmpty) return neutralResult;

    final totalPop =
        colorToPopulation.values.fold<int>(0, (sum, p) => sum + p);
    final safeTotalPop = totalPop > 0 ? totalPop : 1;

    // Build candidates, rejecting extreme dark sludge and blown-out whites
    final candidates = <_Candidate>[];
    for (final entry in colorToPopulation.entries) {
      final argb = entry.key;
      final pop = entry.value;
      final hsv = SpotifyPostProcessor.argbToHsv(argb);
      final lab = OkLabColor.fromArgb(argb);
      final popRatio = pop / safeTotalPop;

      // Filter extreme blacks/dark sludge (V < 0.12)
// ... [remaining code in source file] ...
```
