---
title: "spotify_scroll_physics.dart"
path: "lib/features/player/presentation/widgets/spotify_scroll_physics.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 571
incoming_dependencies: 2
outgoing_dependencies: 0
---

# spotify_scroll_physics.dart

> Source File: `[lib/features/player/presentation/widgets/spotify_scroll_physics.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/presentation/widgets/spotify_scroll_physics.dart)`
> Layer: `lib/features/player/presentation/widgets`

## Executive Summary
`spotify_scroll_physics.dart` is an essential file in `lib/features/player/presentation/widgets` providing definitions for `AndroidEdgeEffect`, `SpotifyStretchController`, `SpotifyStretchScrollBehavior`, `SpotifyStretchOverscrollIndicator`, `SpotifyStretchOverscrollIndicatorState`.
**Primary Architecture Role**: Service / Controller, Widget State Lifecycle Handler, Stateful Widget, Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `queue_sheet_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/queue_sheet_screen|queue_sheet_screen.dart]] |
| `peek_scroll_view_test.dart` | `test/features/player/presentation/widgets` | [[04-Reference/test/features/player/presentation/widgets/peek_scroll_view_test|peek_scroll_view_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class AndroidEdgeEffect`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_state` | `int` |
| `_distance` | `double` |
| `_velocity` | `double` |
| `_pullDistance` | `double` |
| `_displacement` | `double` |
| `_targetDisplacement` | `double` |
| `_startTime` | `int` |
| `_duration` | `double` |
| `_width` | `double` |
| `_height` | `double` |
| `now` | `int` |
| `finalDistance` | `double` |
| `delta` | `double` |
| `delta` | `return` |
| `time` | `int` |
| `deltaT` | `double` |
| `false` | `return` |
| `false` | `return` |
| `sign` | `double` |
| `targetDistance` | `double` |
| `dampedFreq` | `double` |
| `cosCoeff` | `double` |
| `sinCoeff` | `double` |
| `expFactor` | `double` |
| `distance` | `double` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `setSize` | `void` | `double width, double height` |
| `finish` | `void` | `(none)` |
| `onPull` | `void` | `double deltaDistance, [double displacement = 0....` |
| `onPullDistance` | `double` | `double deltaDistance, [double displacement = 0....` |
| `getDistance` | `double` | `(none)` |
| `onRelease` | `void` | `[int? nowMillis]` |
| `onAbsorb` | `void` | `double impactVelocity, [int? nowMillis]` |
| `updateSpring` | `bool` | `[int? nowMillis]` |
| `isAtEquilibrium` | `bool` | `(none)` |
| `dampStretchVector` | `double` | `double normalizedVec` |
| `getDampedStretch` | `double` | `(none)` |

#### `class SpotifyStretchController`
- **Archetype**: Service / Controller
- **Extends**: `Listenable`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `vsync` | `TickerProvider` |
| `_controller` | `AnimationController?` |
| `_overscrollNotifier` | `ValueNotifier<double>` |
| `_interruptedOverscroll` | `double` |
| `pullDistance` | `double` |
| `absDistance` | `double` |
| `linearIntensity` | `double` |
| `exponentialIntensity` | `double` |
| `directionSign` | `double` |
| `newOverscroll` | `double` |
| `scaledVelocity` | `double` |
| `scaledVelocity` | `double` |
| `controller` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `overscroll` | `set` | `double newValue` |
| `addListener` | `void` | `VoidCallback listener` |
| `removeListener` | `void` | `VoidCallback listener` |
| `_createStretchSimulation` | `SpringSimulation` | `double velocity` |
| `pull` | `void` | `double normalizedOverscroll` |
| `scrollEnd` | `void` | `double velocity` |
| `absorbImpact` | `void` | `double velocity` |
| `animate` | `void` | `Simulation simulation` |
| `addListener` | `dynamic` | `(` |
| `whenComplete` | `dynamic` | `(` |
| `finish` | `void` | `(none)` |
| `dispose` | `void` | `(none)` |

#### `class SpotifyStretchScrollBehavior`
- **Archetype**: Core Component
- **Extends**: `MaterialScrollBehavior`

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `buildOverscrollIndicator` | `Widget` | `BuildContext context, Widget child, ScrollableD...` |
| `getScrollPhysics` | `ScrollPhysics` | `BuildContext context` |

#### `class SpotifyStretchOverscrollIndicator`
- **Archetype**: Stateful Widget
- **Extends**: `StatefulWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `axisDirection` | `AxisDirection` |
| `child` | `Widget` |
| `controller` | `SpotifyStretchController?` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `createState` | `State<SpotifyStretchOverscrollIndicator>` | `(none)` |

#### `class SpotifyStretchOverscrollIndicatorState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<SpotifyStretchOverscrollIndicator>`
- **With Mixins**: `TickerProviderStateMixin`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_internalController` | `SpotifyStretchController` |
| `_totalOverscroll` | `double` |
| `_activePointers` | `Set<int>` |
| `viewport` | `final` |
| `false` | `return` |
| `distanceForPull` | `double` |
| `clampedOverscroll` | `double` |
| `delta` | `double` |
| `previousSign` | `double` |
| `updatedTotal` | `double` |
| `distanceForPull` | `double` |
| `clampedOverscroll` | `double` |
| `false` | `return` |
| `velocity` | `double` |
| `false` | `return` |
| `stretch` | `double` |
| `overscroll` | `double` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `initState` | `void` | `(none)` |
| `dispose` | `void` | `(none)` |
| `_handlePointerDown` | `void` | `PointerDownEvent event` |
| `_handlePointerUp` | `void` | `PointerUpEvent event` |
| `_handlePointerCancel` | `void` | `PointerCancelEvent event` |
| `_handleScrollNotification` | `bool` | `ScrollNotification notification` |
| `build` | `Widget` | `BuildContext context` |
| `Listener` | `return` | `onPointerDown: _handlePointerDown, onPointerUp:...` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:math' as math;
import 'dart:ui' show clampDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Direct, line-by-line Dart implementation of Android's official
/// [android.widget.EdgeEffect](https://cs.android.com/android/platform/superproject/main/+/main:frameworks/base/core/java/android/widget/EdgeEffect.java).
///
/// Implements the exact Android 12+ stretch overscroll physical constants,
/// state machine, damped harmonic oscillator equations, linear take-over settling,
/// and stretch vector damping.
class AndroidEdgeEffect {
  AndroidEdgeEffect();

  // EdgeEffect types
  static const int typeNone = -1;
  static const int typeGlow = 0;
  static const int typeStretch = 1;

  // EdgeEffect states
  static const int stateIdle = 0;
  static const int statePull = 1;
  static const int stateAbsorb = 2;
  static const int stateRecede = 3;
  static const int statePullDecay = 4;

  // AOSP Physical Constants
  static const double velocityThreshold = 0.01;
  static const double linearVelocityTakeOver = 200.0;
  static const double valueThreshold = 0.001;
  static const double linearDistanceTakeOver = 8.0;
  static const double naturalFrequency = 24.657;
  static const double dampingRatio = 0.98;
  static const double onAbsorbVelocityAdjustment = 13.0;

  static const double linearStretchIntensity = 0.016;
  static const double expStretchIntensity = 0.016;
  static const double scrollDistAffectedByExpStretch = 0.33;

  static const int recedeTime = 600;
  static const int pullTime = 167;
  static const int pullDecayTime = 2000;

  // State variables
// ... [remaining code in source file] ...
```
