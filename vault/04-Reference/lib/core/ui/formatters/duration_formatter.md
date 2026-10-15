---
title: "duration_formatter.dart"
path: "lib/core/ui/formatters/duration_formatter.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, ui]
lines: 16
incoming_dependencies: 6
outgoing_dependencies: 0
---

# duration_formatter.dart

> Source File: `[lib/core/ui/formatters/duration_formatter.dart](file:///c:/Users/Admin/Musify_MU/lib/core/ui/formatters/duration_formatter.dart)`
> Layer: `lib/core/ui/formatters`

## Executive Summary
`duration_formatter.dart` is an essential file in `lib/core/ui/formatters` providing definitions for `DurationFormatter`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `player_controls.dart` | `lib/features/player/presentation/widgets` | [[04-Reference/lib/features/player/presentation/widgets/player_controls|player_controls.dart]] |
| `player_sheets.dart` | `lib/features/player/presentation/widgets` | [[04-Reference/lib/features/player/presentation/widgets/player_sheets|player_sheets.dart]] |
| `queue_track_tile.dart` | `lib/features/player/presentation/widgets` | [[04-Reference/lib/features/player/presentation/widgets/queue_track_tile|queue_track_tile.dart]] |
| `local_music_screen.dart` | `lib/features/local_music/presentation/screens` | [[04-Reference/lib/features/local_music/presentation/screens/local_music_screen|local_music_screen.dart]] |
| `offline_library_view.dart` | `lib/features/library/presentation` | [[04-Reference/lib/features/library/presentation/offline_library_view|offline_library_view.dart]] |
| `offline_browse_view.dart` | `lib/features/browse/presentation` | [[04-Reference/lib/features/browse/presentation/offline_browse_view|offline_browse_view.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class DurationFormatter`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `hours` | `final` |
| `minutes` | `final` |
| `seconds` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `milliseconds` | `String` | `int milliseconds` |
| `duration` | `String` | `Duration value` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
abstract final class DurationFormatter {
  static String milliseconds(int milliseconds) {
    return duration(Duration(milliseconds: milliseconds.abs()));
  }

  static String duration(Duration value) {
    if (value.isNegative) value = Duration.zero;
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    final seconds = value.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
```
