---
title: "oklab.dart"
path: "lib/core/color/oklab.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, color, oklab, perceptual-color]
lines: 102
incoming_dependencies: 2
outgoing_dependencies: 0
---

# oklab.dart

> Source File: `[lib/core/color/oklab.dart](file:///c:/Users/Admin/Musify_MU/lib/core/color/oklab.dart)`
> Layer: `lib/core/color` (Perceptual Color Space Engine)

## Executive Summary
`oklab.dart` implements the OKLab perceptual color space (Björn Ottosson, 2020) for Musify MU. Unlike CIELAB, OKLab exhibits no blue-to-purple hue shifts, making it optimal for album cover palette derivation where blue artwork is prevalent. All operations manipulate raw 32-bit ARGB integers without referencing `dart:ui`, allowing color calculations to execute inside background Dart isolates.

**Primary Architecture Role**: Isolate-Safe Perceptual Color Space Mathematics

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- Standard Dart SDK (`dart:math`).
- Zero internal dependencies.

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `scheme_deriver.dart` | `lib/core/color` | [[04-Reference/lib/core/color/scheme_deriver|scheme_deriver.dart]] |
| `spotify_post_processor.dart` | `lib/core/color` | [[04-Reference/lib/core/color/spotify_post_processor|spotify_post_processor.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class OkLabColor`

**Color Coordinate Fields:**
- `final double L`: Perceptual lightness (`0.0` = pure black, `1.0` = diffuse white).
- `final double a`: Green-to-red opponent color axis.
- `final double b`: Blue-to-yellow opponent color axis.

**Constructors & Factories:**
- `const OkLabColor(this.L, this.a, this.b)`: Direct coordinate constructor.
- `factory OkLabColor.fromArgb(int argb)`: Converts sRGB 32-bit ARGB integer to linear sRGB, transforms through LMS cone space via cube-root non-linearities, and returns `OkLabColor`.

**Color Conversion & Distance Methods:**
| Method / Getter | Return Type | Description |
|-----------------|-------------|-------------|
| `toArgb` | `int` | Converts OKLab coordinates back to 32-bit sRGB ARGB integer |
| `chroma` | `double` | Color saturation / colorfulness metric: `sqrt(a² + b²)` |
| `hue` | `double` | Perceptual hue angle in degrees `[0, 360)`: `atan2(b, a)` |
| `distanceSquaredTo` | `double` | Squared Euclidean distance in OKLab space (fast comparison avoiding `sqrt`) |
| `distanceTo` | `double` | True Euclidean perceptual distance `ΔE_ok` |

## State & Data Flow Analysis
- **Isolate Offloading**: Because `OkLabColor` avoids `dart:ui` or `package:flutter`, `ColorExtractionService` can offload thousands of pixel comparisons to `Isolate.run` without running into native C++ engine binding errors.

## Implementation Highlight
```dart
factory OkLabColor.fromArgb(int argb) {
  final r = _srgbToLinear(((argb >> 16) & 0xFF) / 255.0);
  final g = _srgbToLinear(((argb >> 8) & 0xFF) / 255.0);
  final b = _srgbToLinear((argb & 0xFF) / 255.0);

  final l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b;
  final m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b;
  final s = 0.0883024619 * r + 0.2024326033 * g + 0.6992649378 * b;

  final lc = _cbrt(l);
  final mc = _cbrt(m);
  final sc = _cbrt(s);

  return OkLabColor(
    0.2104542553 * lc + 0.7936177850 * mc - 0.0040720468 * sc,
    1.9779984951 * lc - 2.4285922050 * mc + 0.4505937099 * sc,
    0.0259040371 * lc + 0.7827717662 * mc - 0.8086757660 * sc,
  );
}
```
