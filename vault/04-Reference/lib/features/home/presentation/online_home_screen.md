---
title: "online_home_screen.dart"
path: "lib/features/home/presentation/online_home_screen.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home]
lines: 183
incoming_dependencies: 1
outgoing_dependencies: 7
---

# online_home_screen.dart

> Source File: `[lib/features/home/presentation/online_home_screen.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home/presentation/online_home_screen.dart)`
> Layer: `lib/features/home/presentation`

## Executive Summary
`online_home_screen.dart` is an essential file in `lib/features/home/presentation` providing definitions for `OnlineHomeScreen`, `_OnlineHomeScreenState`, `_AuthErrorView`.
**Primary Architecture Role**: Widget State Lifecycle Handler, Stateful Widget, Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `auth_bloc.dart` | `lib/features/auth/application` | [[04-Reference/lib/features/auth/application/auth_bloc|auth_bloc.dart]] |
| `auth_event.dart` | `lib/features/auth/application` | [[04-Reference/lib/features/auth/application/auth_event|auth_event.dart]] |
| `auth_state.dart` | `lib/features/auth/domain/entities` | [[04-Reference/lib/features/auth/domain/entities/auth_state|auth_state.dart]] |
| `spotify_login_webview.dart` | `lib/features/auth/presentation/widgets` | [[04-Reference/lib/features/auth/presentation/widgets/spotify_login_webview|spotify_login_webview.dart]] |
| `spotify_welcome_landing.dart` | `lib/features/auth/presentation/widgets` | [[04-Reference/lib/features/auth/presentation/widgets/spotify_welcome_landing|spotify_welcome_landing.dart]] |
| `home_feed_bloc.dart` | `lib/features/home_feed/application` | [[04-Reference/lib/features/home_feed/application/home_feed_bloc|home_feed_bloc.dart]] |
| `home_feed_view.dart` | `lib/features/home_feed/presentation` | [[04-Reference/lib/features/home_feed/presentation/home_feed_view|home_feed_view.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `home_tab.dart` | `lib/features/home/presentation` | [[04-Reference/lib/features/home/presentation/home_tab|home_tab.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class OnlineHomeScreen`
- **Archetype**: Stateful Widget
- **Extends**: `StatefulWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `headerTitleRow` | `Widget?` |
| `isActive` | `bool` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `createState` | `State<OnlineHomeScreen>` | `(none)` |

#### `class _OnlineHomeScreenState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<OnlineHomeScreen>`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_showWebView` | `bool` |
| `body` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `_onConnectTapped` | `void` | `(none)` |
| `setState` | `dynamic` | `(` |
| `_onWebViewCancel` | `void` | `(none)` |
| `setState` | `dynamic` | `(` |
| `_onLoginSuccess` | `void` | `String spDcCookie, String bearerToken` |
| `setState` | `dynamic` | `(` |
| `build` | `Widget` | `BuildContext context` |
| `Unauthenticated` | `dynamic` | `(none)` |
| `Authenticating` | `dynamic` | `(none)` |
| `SpotifyWelcomeLanding` | `dynamic` | `isLoading: true, onConnect: (` |
| `AuthError` | `dynamic` | `:final message` |
| `_AuthErrorView` | `dynamic` | `message: message, onRetry: (` |
| `Authenticated` | `dynamic` | `(none)` |
| `_buildUnauthenticatedView` | `Widget` | `(none)` |
| `_buildAuthenticatedFeed` | `Widget` | `(none)` |
| `BlocProvider` | `return` | `create: (_` |

#### `class _AuthErrorView`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `message` | `String` |
| `onRetry` | `VoidCallback` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Synchronous setState() invoked without mounted check; can throw if widget is unmounted during async gaps.

## Implementation Highlight
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/application/auth_event.dart';
import 'package:musify_mu/features/auth/domain/entities/auth_state.dart';
import 'package:musify_mu/features/auth/presentation/widgets/spotify_login_webview.dart';
import 'package:musify_mu/features/auth/presentation/widgets/spotify_welcome_landing.dart';
import 'package:musify_mu/features/home_feed/application/home_feed_bloc.dart';
import 'package:musify_mu/features/home_feed/presentation/home_feed_view.dart';

class OnlineHomeScreen extends StatefulWidget {
  final Widget? headerTitleRow;
  final bool isActive;
  final HomeFeedBloc Function() createHomeFeedBloc;

  const OnlineHomeScreen({
    super.key,
    this.headerTitleRow,
    this.isActive = true,
    required this.createHomeFeedBloc,
  });

  @override
  State<OnlineHomeScreen> createState() => _OnlineHomeScreenState();
}

class _OnlineHomeScreenState extends State<OnlineHomeScreen> {
  bool _showWebView = false;

  void _onConnectTapped() {
    setState(() => _showWebView = true);
  }

  void _onWebViewCancel() {
    setState(() => _showWebView = false);
  }

  void _onLoginSuccess(String spDcCookie, String bearerToken) {
    setState(() => _showWebView = false);
    context.read<AuthBloc>().add(AuthTokensCaptured(
          spDcCookie: spDcCookie,
          accessToken: bearerToken,
        ));
  }

// ... [remaining code in source file] ...
```
