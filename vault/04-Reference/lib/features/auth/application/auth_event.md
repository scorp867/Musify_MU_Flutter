---
title: "auth_event.dart"
path: "lib/features/auth/application/auth_event.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, auth]
lines: 37
incoming_dependencies: 5
outgoing_dependencies: 0
---

# auth_event.dart

> Source File: `[lib/features/auth/application/auth_event.dart](file:///c:/Users/Admin/Musify_MU/lib/features/auth/application/auth_event.dart)`
> Layer: `lib/features/auth/application`

## Executive Summary
`auth_event.dart` is an essential file in `lib/features/auth/application` providing definitions for `AuthEvent`, `AuthSessionRestored`, `AuthLoginRequested`, `AuthTokensCaptured`, `AuthLogoutRequested`.
**Primary Architecture Role**: Core Component, Domain Model / Entity

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `main.dart` | `lib` | [[04-Reference/lib/main|main.dart]] |
| `drawer_menu.dart` | `lib/features/shell/presentation/widgets` | [[04-Reference/lib/features/shell/presentation/widgets/drawer_menu|drawer_menu.dart]] |
| `online_home_screen.dart` | `lib/features/home/presentation` | [[04-Reference/lib/features/home/presentation/online_home_screen|online_home_screen.dart]] |
| `auth_bloc.dart` | `lib/features/auth/application` | [[04-Reference/lib/features/auth/application/auth_bloc|auth_bloc.dart]] |
| `auth_bloc_test.dart` | `test/features/auth` | [[04-Reference/test/features/auth/auth_bloc_test|auth_bloc_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class AuthEvent`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

#### `class AuthSessionRestored`
- **Archetype**: Core Component
- **Extends**: `AuthEvent`

#### `class AuthLoginRequested`
- **Archetype**: Core Component
- **Extends**: `AuthEvent`

#### `class AuthTokensCaptured`
- **Archetype**: Core Component
- **Extends**: `AuthEvent`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `spDcCookie` | `String` |
| `accessToken` | `String` |

#### `class AuthLogoutRequested`
- **Archetype**: Core Component
- **Extends**: `AuthEvent`

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check stored session on app launch.
final class AuthSessionRestored extends AuthEvent {
  const AuthSessionRestored();
}

/// User initiated login (tapped "Connect with Spotify").
final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested();
}

/// WebView captured tokens after successful Spotify login.
final class AuthTokensCaptured extends AuthEvent {
  final String spDcCookie;
  final String accessToken;

  const AuthTokensCaptured({
    required this.spDcCookie,
    required this.accessToken,
  });

  @override
  List<Object?> get props => [spDcCookie, accessToken];
}

/// User initiated logout.
final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
```
