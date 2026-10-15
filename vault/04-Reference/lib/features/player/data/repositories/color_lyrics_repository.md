---
title: "color_lyrics_repository.dart"
path: "lib/features/player/data/repositories/color_lyrics_repository.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player]
lines: 54
incoming_dependencies: 1
outgoing_dependencies: 2
---

# color_lyrics_repository.dart

> Source File: `[lib/features/player/data/repositories/color_lyrics_repository.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/data/repositories/color_lyrics_repository.dart)`
> Layer: `lib/features/player/data/repositories`

## Executive Summary
`color_lyrics_repository.dart` is an essential file in `lib/features/player/data/repositories` providing definitions for `ColorLyricsRepositoryImpl`.
**Primary Architecture Role**: Repository Pattern

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `color_lyrics_client.dart` | `lib/features/player/data/datasources` | [[04-Reference/lib/features/player/data/datasources/color_lyrics_client|color_lyrics_client.dart]] |
| `lyrics_repository.dart` | `lib/features/player/domain/repositories` | [[04-Reference/lib/features/player/domain/repositories/lyrics_repository|lyrics_repository.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class ColorLyricsRepositoryImpl`
- **Archetype**: Repository Pattern
- **Implements**: `LyricsRepository`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_client` | `ColorLyricsClient` |
| `cleanId` | `final` |
| `response` | `final` |
| `response` | `return` |
| `argb` | `final` |
| `fullArgb` | `final` |
| `input` | `return` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `getLyrics` | `Future<ColorLyricsResponse?>` | `String trackId` |
| `_sanitizeTrackId` | `String` | `String input` |
| `clearCache` | `void` | `(none)` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:ui';
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';
import 'package:musify_mu/features/player/data/datasources/color_lyrics_client.dart';
import 'package:musify_mu/features/player/domain/repositories/lyrics_repository.dart';

/// Concrete repository implementation for Spotify Color Lyrics.
///
/// Fetches, caches, and parses lyrics responses from Spotify's
/// `color-lyrics/v2/track/{trackId}` endpoint.
class ColorLyricsRepositoryImpl implements LyricsRepository {
  final ColorLyricsClient _client;
  final Map<String, ColorLyricsResponse> _cache = {};

  ColorLyricsRepositoryImpl({required ColorLyricsClient client}) : _client = client;

  @override

  /// Fetches lyrics with colors for the given Spotify track ID.
  Future<ColorLyricsResponse?> getLyrics(String trackId) async {
    final cleanId = _sanitizeTrackId(trackId);
    if (cleanId.isEmpty) return null;

    if (_cache.containsKey(cleanId)) {
      return _cache[cleanId];
    }

    final response = await _client.getColorLyrics(trackId: cleanId);
    if (response != null) {
      _cache[cleanId] = response;
    }
    return response;
  }

  /// Converts signed 32-bit protobuf color integer into a Flutter [Color].
  static Color parseProtoColor(int rawValue, {Color defaultColor = const Color(0xFF242424)}) {
    if (rawValue == 0) return defaultColor;
    // Protobuf stores as signed 32-bit (e.g. -8686235 for 0xFF7B7565)
    final argb = rawValue & 0xFFFFFFFF;
    // If alpha channel is 0, default to opaque 0xFF
    final fullArgb = (argb & 0xFF000000) == 0 ? (0xFF000000 | argb) : argb;
    return Color(fullArgb);
  }

  String _sanitizeTrackId(String input) {
    if (input.startsWith('spotify:track:')) {
// ... [remaining code in source file] ...
```
