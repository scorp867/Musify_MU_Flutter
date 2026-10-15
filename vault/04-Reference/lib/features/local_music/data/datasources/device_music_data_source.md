---
title: "device_music_data_source.dart"
path: "lib/features/local_music/data/datasources/device_music_data_source.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, local_music]
lines: 58
incoming_dependencies: 3
outgoing_dependencies: 0
---

# device_music_data_source.dart

> Source File: `[lib/features/local_music/data/datasources/device_music_data_source.dart](file:///c:/Users/Admin/Musify_MU/lib/features/local_music/data/datasources/device_music_data_source.dart)`
> Layer: `lib/features/local_music/data/datasources`

## Executive Summary
`device_music_data_source.dart` is an essential file in `lib/features/local_music/data/datasources` providing definitions for `DeviceMusicDataSource`, `OnAudioQueryDeviceMusicDataSource`.
**Primary Architecture Role**: Data Source / Remote Client

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `local_music_repository_impl.dart` | `lib/features/local_music/data/repositories` | [[04-Reference/lib/features/local_music/data/repositories/local_music_repository_impl|local_music_repository_impl.dart]] |
| `local_music_sync_service.dart` | `lib/features/local_music/data/services` | [[04-Reference/lib/features/local_music/data/services/local_music_sync_service|local_music_sync_service.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class DeviceMusicDataSource`
- **Archetype**: Data Source / Remote Client

#### `class OnAudioQueryDeviceMusicDataSource`
- **Archetype**: Data Source / Remote Client
- **Implements**: `DeviceMusicDataSource`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_audioQuery` | `OnAudioQuery` |
| `false` | `return` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `hasPermission` | `Future<bool>` | `(none)` |
| `requestPermission` | `Future<bool>` | `(none)` |
| `querySongs` | `Future<List<SongModel>>` | `(none)` |
| `queryArtwork` | `Future<Uint8List?>` | `int songId, {int size = 80}` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:developer' as dev;
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';

abstract interface class DeviceMusicDataSource {
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<List<SongModel>> querySongs();
  Future<Uint8List?> queryArtwork(int songId, {int size});
  Stream<void> get changes;
}

class OnAudioQueryDeviceMusicDataSource implements DeviceMusicDataSource {
  static const _mediaStoreChannel = EventChannel(
    'musify_mu/mediastore_observer',
  );

  final OnAudioQuery _audioQuery;

  OnAudioQueryDeviceMusicDataSource(this._audioQuery);

  @override
  Future<bool> hasPermission() => _audioQuery.permissionsStatus();

  @override
  Future<bool> requestPermission() async {
    try {
      return await _audioQuery.permissionsRequest();
    } catch (e) {
      // on_audio_query PluginProvider may not be initialized yet.
      dev.log('Permission request failed: $e');
      return false;
    }
  }

  @override
  Future<List<SongModel>> querySongs() {
    return _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
  }

// ... [remaining code in source file] ...
```
