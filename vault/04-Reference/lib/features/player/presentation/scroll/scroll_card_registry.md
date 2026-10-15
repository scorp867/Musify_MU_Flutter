---
title: "scroll_card_registry.dart"
path: "lib/features/player/presentation/scroll/scroll_card_registry.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 35
incoming_dependencies: 3
outgoing_dependencies: 2
---

# scroll_card_registry.dart

> Source File: `[lib/features/player/presentation/scroll/scroll_card_registry.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/presentation/scroll/scroll_card_registry.dart)`
> Layer: `lib/features/player/presentation/scroll`

## Executive Summary
`scroll_card_registry.dart` is an essential file in `lib/features/player/presentation/scroll` providing definitions for `s400`, `ScrollCardRegistry`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `data_pool.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool|data_pool.dart]] |
| `scroll_card_descriptor.dart` | `lib/features/player/domain/models` | [[04-Reference/lib/features/player/domain/models/scroll_card_descriptor|scroll_card_descriptor.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `debug_now_playing_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/debug_now_playing_screen|debug_now_playing_screen.dart]] |
| `player_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/player_screen|player_screen.dart]] |
| `scroll_card_registry_test.dart` | `test/features/player/presentation/scroll` | [[04-Reference/test/features/player/presentation/scroll/scroll_card_registry_test|scroll_card_registry_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class s400`
- **Archetype**: Core Component

#### `class ScrollCardRegistry`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `dataPool` | `DataPool?` |
| `builder` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `buildCard` | `Widget?` | `BuildContext context, ScrollCardDescriptor desc...` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter/widgets.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';

typedef ScrollCardWidgetBuilder<T extends ScrollCardDescriptor> = Widget Function(
  BuildContext context,
  T descriptor,
);

/// Card view factory registry for the Now Playing scroll view.
///
/// 1:1 replica of Spotify Android's `p/s400.java`:
/// ```java
/// public final class s400 {
///     public final DataPool a;
///     public final LinkedHashMap b = new LinkedHashMap();
/// }
/// ```
class ScrollCardRegistry {
  final DataPool? dataPool;
  final Map<Type, ScrollCardWidgetBuilder> _builders = {};

  ScrollCardRegistry({this.dataPool});

  /// Registers a widget builder for a specific card descriptor type.
  void register<T extends ScrollCardDescriptor>(ScrollCardWidgetBuilder<T> builder) {
    _builders[T] = (context, descriptor) => builder(context, descriptor as T);
  }

  /// Builds the widget for the given descriptor, or returns null if not registered.
  Widget? buildCard(BuildContext context, ScrollCardDescriptor descriptor) {
    final builder = _builders[descriptor.runtimeType];
    return builder?.call(context, descriptor);
  }
}
```
