---
title: "runtime_context.dart"
path: "lib/core/config/runtime_context.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, config]
lines: 86
incoming_dependencies: 11
outgoing_dependencies: 0
---

# runtime_context.dart

> Source File: `[lib/core/config/runtime_context.dart](file:///c:/Users/Admin/Musify_MU/lib/core/config/runtime_context.dart)`
> Layer: `lib/core/config`

## Executive Summary
`runtime_context.dart` is an essential file in `lib/core/config` providing definitions for `RuntimeContext`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `library_remote_source.dart` | `lib/features/library/data/sources` | [[04-Reference/lib/features/library/data/sources/library_remote_source|library_remote_source.dart]] |
| `home_repository.dart` | `lib/features/home_feed/data` | [[04-Reference/lib/features/home_feed/data/home_repository|home_repository.dart]] |
| `browse_metadata_fetcher.dart` | `lib/features/browse/data` | [[04-Reference/lib/features/browse/data/browse_metadata_fetcher|browse_metadata_fetcher.dart]] |
| `browse_repository.dart` | `lib/features/browse/data` | [[04-Reference/lib/features/browse/data/browse_repository|browse_repository.dart]] |
| `spotify_profile_fetcher.dart` | `lib/features/auth/data` | [[04-Reference/lib/features/auth/data/spotify_profile_fetcher|spotify_profile_fetcher.dart]] |
| `extended_metadata_service.dart` | `lib/core/media` | [[04-Reference/lib/core/media/extended_metadata_service|extended_metadata_service.dart]] |
| `spotify_client_token.dart` | `lib/core/network/spotify/auth` | [[04-Reference/lib/core/network/spotify/auth/spotify_client_token|spotify_client_token.dart]] |
| `android_transport.dart` | `lib/core/network/spotify/transport` | [[04-Reference/lib/core/network/spotify/transport/android_transport|android_transport.dart]] |
| `web_player_transport.dart` | `lib/core/network/spotify/transport` | [[04-Reference/lib/core/network/spotify/transport/web_player_transport|web_player_transport.dart]] |
| `extended_metadata_client.dart` | `lib/core/kodiak/extendedmetadataimpl` | [[04-Reference/lib/core/kodiak/extendedmetadataimpl/extended_metadata_client|extended_metadata_client.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |

## Declarations & API Breakdown

### Enums
#### `enum DeviceProfile`
Values: `webPlayer(
    appPlatform: 'WebPlayer'`, `appVersion: '1.2.87.215.g6e7e7fc2'`, `userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML`, `like Gecko) Chrome/146.0.0.0 Safari/537.36'`, `)`, `android(
    appPlatform: 'Android'`, `appVersion: '9.1.76.2045'`, `userAgent: 'Spotify/9.1.76.2045 Android/29 (Pixel 4 XL)'`, `);

  final String appPlatform;
  final String appVersion;
  final String userAgent;

  const DeviceProfile({
    required this.appPlatform`, `required this.appVersion`, `required this.userAgent`

### Classes & Mixins
#### `class RuntimeContext`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `country` | `String` |
| `catalogue` | `String` |
| `timezone` | `String` |
| `timezoneInfo` | `TimezoneInfo?` |
| `acceptLanguage` | `String` |
| `tz` | `final` |
| `raw` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `init` | `Future<void>` | `(none)` |
| `updateFromProfile` | `void` | `{String? userCountry, String? product}` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:io';

import 'package:flutter_timezone/flutter_timezone.dart';

/// Device identity profiles for Spotify API communication.
///
/// Each profile carries the platform string, app version, and user-agent
/// that the corresponding Spotify client would send. Transports select
/// the appropriate profile and read these values instead of hardcoding them.
enum DeviceProfile {
  webPlayer(
    appPlatform: 'WebPlayer',
    appVersion: '1.2.87.215.g6e7e7fc2',
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36',
  ),
  android(
    appPlatform: 'Android',
    appVersion: '9.1.76.2045',
    userAgent: 'Spotify/9.1.76.2045 Android/29 (Pixel 4 XL)',
  );

  final String appPlatform;
  final String appVersion;
  final String userAgent;

  const DeviceProfile({
    required this.appPlatform,
    required this.appVersion,
    required this.userAgent,
  });
}

/// Centralized runtime context for locale, market, device identity,
/// and header policy.
///
/// Populated at startup from system settings (timezone, locale), then
/// updated with live values from the Spotify profile after login
/// (country, catalogue tier). All repositories, transports, and metadata
/// fetchers read from this single source instead of hardcoding values.
class RuntimeContext {
  String country;
  String catalogue;
  String timezone;
  TimezoneInfo? timezoneInfo;
// ... [remaining code in source file] ...
```
