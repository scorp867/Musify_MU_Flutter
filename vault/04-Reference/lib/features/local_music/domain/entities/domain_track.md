---
title: "domain_track.dart"
path: "lib/features/local_music/domain/entities/domain_track.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, local_music]
lines: 49
incoming_dependencies: 8
outgoing_dependencies: 0
---

# domain_track.dart

> Source File: `[lib/features/local_music/domain/entities/domain_track.dart](file:///c:/Users/Admin/Musify_MU/lib/features/local_music/domain/entities/domain_track.dart)`
> Layer: `lib/features/local_music/domain/entities`

## Executive Summary
`domain_track.dart` is an essential file in `lib/features/local_music/domain/entities` providing definitions for `DomainTrack`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `local_music_playback_synchronizer.dart` | `lib/features/local_music/application` | [[04-Reference/lib/features/local_music/application/local_music_playback_synchronizer|local_music_playback_synchronizer.dart]] |
| `local_music_bloc.dart` | `lib/features/local_music/presentation/bloc` | [[04-Reference/lib/features/local_music/presentation/bloc/local_music_bloc|local_music_bloc.dart]] |
| `local_music_state.dart` | `lib/features/local_music/presentation/bloc` | [[04-Reference/lib/features/local_music/presentation/bloc/local_music_state|local_music_state.dart]] |
| `local_music_repository.dart` | `lib/features/local_music/domain/repositories` | [[04-Reference/lib/features/local_music/domain/repositories/local_music_repository|local_music_repository.dart]] |
| `local_music_repository_impl.dart` | `lib/features/local_music/data/repositories` | [[04-Reference/lib/features/local_music/data/repositories/local_music_repository_impl|local_music_repository_impl.dart]] |
| `offline_library_view.dart` | `lib/features/library/presentation` | [[04-Reference/lib/features/library/presentation/offline_library_view|offline_library_view.dart]] |
| `offline_browse_view.dart` | `lib/features/browse/presentation` | [[04-Reference/lib/features/browse/presentation/offline_browse_view|offline_browse_view.dart]] |
| `local_music_playback_synchronizer_test.dart` | `test/features/local_music/application` | [[04-Reference/test/features/local_music/application/local_music_playback_synchronizer_test|local_music_playback_synchronizer_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class DomainTrack`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `id` | `String` |
| `title` | `String` |
| `artist` | `String` |
| `album` | `String?` |
| `duration` | `int?` |
| `dataPath` | `String?` |
| `songId` | `int?` |
| `artUri` | `String?` |
| `dateModified` | `DateTime?` |
| `isLocal` | `bool` |
| `operator` | `bool` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
class DomainTrack {
  final String
  id; // Use string to support both integer Local DB IDs and String Online API IDs
  final String title;
  final String artist;
  final String? album;
  final int? duration;
  final String? dataPath; // The local file path or the online stream URL
  final int? songId; // Original Android MediaStore ID (for artwork)
  final String? artUri; // Online image URL if available
  final DateTime? dateModified;
  final bool isLocal; // Flag to identify the source

  DomainTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.duration,
    this.dataPath,
    this.songId,
    this.artUri,
    this.dateModified,
    this.isLocal = true,
  });

  // Optional: equality override for Bloc diffing
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DomainTrack &&
        other.id == id &&
        other.title == title &&
        other.artist == artist &&
        other.album == album &&
        other.duration == duration &&
        other.dateModified == dateModified;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        artist.hashCode ^
        album.hashCode ^
// ... [remaining code in source file] ...
```
