---
title: "network_priority.dart"
path: "lib/core/network/priority/network_priority.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, network]
lines: 26
incoming_dependencies: 16
outgoing_dependencies: 0
---

# network_priority.dart

> Source File: `[lib/core/network/priority/network_priority.dart](file:///c:/Users/Admin/Musify_MU/lib/core/network/priority/network_priority.dart)`
> Layer: `lib/core/network/priority`

## Executive Summary
`network_priority.dart` is an essential file in `lib/core/network/priority` providing definitions for Top-level functions/constants.

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `color_lyrics_client.dart` | `lib/features/player/data/datasources` | [[04-Reference/lib/features/player/data/datasources/color_lyrics_client|color_lyrics_client.dart]] |
| `scrollsita_client.dart` | `lib/features/player/data/datasources` | [[04-Reference/lib/features/player/data/datasources/scrollsita_client|scrollsita_client.dart]] |
| `library_remote_source.dart` | `lib/features/library/data/sources` | [[04-Reference/lib/features/library/data/sources/library_remote_source|library_remote_source.dart]] |
| `home_repository.dart` | `lib/features/home_feed/data` | [[04-Reference/lib/features/home_feed/data/home_repository|home_repository.dart]] |
| `browse_metadata_fetcher.dart` | `lib/features/browse/data` | [[04-Reference/lib/features/browse/data/browse_metadata_fetcher|browse_metadata_fetcher.dart]] |
| `browse_repository.dart` | `lib/features/browse/data` | [[04-Reference/lib/features/browse/data/browse_repository|browse_repository.dart]] |
| `spotify_profile_fetcher.dart` | `lib/features/auth/data` | [[04-Reference/lib/features/auth/data/spotify_profile_fetcher|spotify_profile_fetcher.dart]] |
| `dio_network_client.dart` | `lib/core/network/client` | [[04-Reference/lib/core/network/client/dio_network_client|dio_network_client.dart]] |
| `network_client.dart` | `lib/core/network/client` | [[04-Reference/lib/core/network/client/network_client|network_client.dart]] |
| `queued_network_client.dart` | `lib/core/network/client` | [[04-Reference/lib/core/network/client/queued_network_client|queued_network_client.dart]] |
| `network_traffic_controller.dart` | `lib/core/network/queue` | [[04-Reference/lib/core/network/queue/network_traffic_controller|network_traffic_controller.dart]] |
| `queued_request.dart` | `lib/core/network/queue` | [[04-Reference/lib/core/network/queue/queued_request|queued_request.dart]] |
| `base_spotify_transport.dart` | `lib/core/network/spotify/transport` | [[04-Reference/lib/core/network/spotify/transport/base_spotify_transport|base_spotify_transport.dart]] |
| `spotify_transport.dart` | `lib/core/network/spotify/transport` | [[04-Reference/lib/core/network/spotify/transport/spotify_transport|spotify_transport.dart]] |
| `extended_metadata_client.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/extended_metadata_client|extended_metadata_client.dart]] |
| `network_traffic_controller_test.dart` | `test/core/network/queue` | [[04-Reference/test/core/network/queue/network_traffic_controller_test|network_traffic_controller_test.dart]] |

## Declarations & API Breakdown

### Enums
#### `enum NetworkPriority`
Values: `bypasses background throttling.
  /// Used for playback tokens`, `audio stream CDN URLs`, `and decryption keys.
  playback(0)`, `screen navigation`, `and tab switches.
  interactive(1)`, `library playlist syncs`, `and prefetching.
  background(2);

  final int value;

  const NetworkPriority(this.value);

  bool operator <(NetworkPriority other) => value < other.value;
  bool operator <=(NetworkPriority other) => value <= other.value;
  bool operator >(NetworkPriority other) => value > other.value;
  bool operator >=(NetworkPriority other) => value >= other.value;`

This file contains top-level functions or standalone variables.

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
/// Priority levels for network requests across Musify_MU.
///
/// Ensures audio playback traffic is never queued behind bulk background
/// syncs (e.g., 30+ playlist diffs or Kodiak viewport trait batches).
enum NetworkPriority {
  /// Priority 0: Immediate dispatch, bypasses background throttling.
  /// Used for playback tokens, audio stream CDN URLs, and decryption keys.
  playback(0),

  /// Priority 1: High-priority interactive requests triggered by explicit user actions.
  /// Used for search queries, screen navigation, and tab switches.
  interactive(1),

  /// Priority 2: Background tasks that can tolerate queue delays and throttling.
  /// Used for Kodiak viewport trait batching, library playlist syncs, and prefetching.
  background(2);

  final int value;

  const NetworkPriority(this.value);

  bool operator <(NetworkPriority other) => value < other.value;
  bool operator <=(NetworkPriority other) => value <= other.value;
  bool operator >(NetworkPriority other) => value > other.value;
  bool operator >=(NetworkPriority other) => value >= other.value;
}
```
