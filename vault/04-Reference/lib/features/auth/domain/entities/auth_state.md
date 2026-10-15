---
title: "auth_state.dart"
path: "lib/features/auth/domain/entities/auth_state.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, auth]
lines: 40
incoming_dependencies: 8
outgoing_dependencies: 0
---

# auth_state.dart

> Source File: `[lib/features/auth/domain/entities/auth_state.dart](file:///c:/Users/Admin/Musify_MU/lib/features/auth/domain/entities/auth_state.dart)`
> Layer: `lib/features/auth/domain/entities`

## Executive Summary
`auth_state.dart` is an essential file in `lib/features/auth/domain/entities` providing definitions for `AuthState`, `Unauthenticated`, `Authenticating`, `Authenticated`, `AuthError`.
**Primary Architecture Role**: Core Component, Domain Model / Entity

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `drawer_menu.dart` | `lib/features/shell/presentation/widgets` | [[04-Reference/lib/features/shell/presentation/widgets/drawer_menu|drawer_menu.dart]] |
| `library_view.dart` | `lib/features/library/presentation` | [[04-Reference/lib/features/library/presentation/library_view|library_view.dart]] |
| `home_tab.dart` | `lib/features/home/presentation` | [[04-Reference/lib/features/home/presentation/home_tab|home_tab.dart]] |
| `online_home_screen.dart` | `lib/features/home/presentation` | [[04-Reference/lib/features/home/presentation/online_home_screen|online_home_screen.dart]] |
| `browse_view.dart` | `lib/features/browse/presentation` | [[04-Reference/lib/features/browse/presentation/browse_view|browse_view.dart]] |
| `auth_bloc.dart` | `lib/features/auth/application` | [[04-Reference/lib/features/auth/application/auth_bloc|auth_bloc.dart]] |
| `auth_gated_bloc_provider.dart` | `lib/core/ui/widgets` | [[04-Reference/lib/core/ui/widgets/auth_gated_bloc_provider|auth_gated_bloc_provider.dart]] |
| `auth_bloc_test.dart` | `test/features/auth` | [[04-Reference/test/features/auth/auth_bloc_test|auth_bloc_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class AuthState`
- **Archetype**: Domain Model / Entity
- **Extends**: `Equatable`

#### `class Unauthenticated`
- **Archetype**: Core Component
- **Extends**: `AuthState`

#### `class Authenticating`
- **Archetype**: Core Component
- **Extends**: `AuthState`

#### `class Authenticated`
- **Archetype**: Core Component
- **Extends**: `AuthState`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `user` | `SpotifyUser` |

#### `class AuthError`
- **Archetype**: Core Component
- **Extends**: `AuthState`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `message` | `String` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:equatable/equatable.dart';
import 'spotify_user.dart';

/// Sealed auth state  -  exhaustive matching at compile time.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// No user session. Show the welcome landing.
final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Auth flow is in progress (logging in, refreshing token, etc.).
final class Authenticating extends AuthState {
  const Authenticating();
}

/// User is logged in with a valid session.
final class Authenticated extends AuthState {
  final SpotifyUser user;

  const Authenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Auth failed  -  show error with option to retry.
final class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
```
