---
title: "spotify_user.dart"
path: "lib/features/auth/domain/entities/spotify_user.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, auth]
lines: 25
incoming_dependencies: 4
outgoing_dependencies: 0
---

# spotify_user.dart

> Source File: `[lib/features/auth/domain/entities/spotify_user.dart](file:///c:/Users/Admin/Musify_MU/lib/features/auth/domain/entities/spotify_user.dart)`
> Layer: `lib/features/auth/domain/entities`

## Executive Summary
`spotify_user.dart` is an essential file in `lib/features/auth/domain/entities` providing definitions for `SpotifyUser`.
**Primary Architecture Role**: Domain Model / Entity

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `auth_bloc.dart` | `lib/features/auth/application` | [[04-Reference/lib/features/auth/application/auth_bloc|auth_bloc.dart]] |
| `spotify_profile_fetcher.dart` | `lib/features/auth/data` | [[04-Reference/lib/features/auth/data/spotify_profile_fetcher|spotify_profile_fetcher.dart]] |
| `injection.dart` | `lib/app/di` | [[04-Reference/lib/app/di/injection|injection.dart]] |
| `auth_bloc_test.dart` | `test/features/auth` | [[04-Reference/test/features/auth/auth_bloc_test|auth_bloc_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class SpotifyUser`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `id` | `String` |
| `displayName` | `String` |
| `avatarUrl` | `String?` |
| `email` | `String?` |
| `country` | `String?` |
| `product` | `String?` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:equatable/equatable.dart';

/// Represents a minimal authenticated Spotify user profile.
class SpotifyUser extends Equatable {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? email;
  final String? country;
  final String? product; // "premium", "free", etc.

  const SpotifyUser({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.email,
    this.country,
    this.product,
  });

  bool get isPremium => product == 'premium';

  @override
  List<Object?> get props => [id, displayName, avatarUrl, email, country, product];
}
```
