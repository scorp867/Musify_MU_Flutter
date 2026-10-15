---
title: "spotify_login_webview.dart"
path: "lib/features/auth/presentation/widgets/spotify_login_webview.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, auth]
lines: 307
incoming_dependencies: 1
outgoing_dependencies: 0
---

# spotify_login_webview.dart

> Source File: `[lib/features/auth/presentation/widgets/spotify_login_webview.dart](file:///c:/Users/Admin/Musify_MU/lib/features/auth/presentation/widgets/spotify_login_webview.dart)`
> Layer: `lib/features/auth/presentation/widgets`

## Executive Summary
`spotify_login_webview.dart` is an essential file in `lib/features/auth/presentation/widgets` providing definitions for `SpotifyLoginWebView`, `_SpotifyLoginWebViewState`.
**Primary Architecture Role**: Widget State Lifecycle Handler, Stateful Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `online_home_screen.dart` | `lib/features/home/presentation` | [[04-Reference/lib/features/home/presentation/online_home_screen|online_home_screen.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class SpotifyLoginWebView`
- **Archetype**: Stateful Widget
- **Extends**: `StatefulWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `onCancel` | `VoidCallback` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `createState` | `State<SpotifyLoginWebView>` | `(none)` |

#### `class _SpotifyLoginWebViewState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<SpotifyLoginWebView>`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_isLoading` | `bool` |
| `_capturedSpDc` | `String?` |
| `_capturedToken` | `String?` |
| `_loginCompleted` | `bool` |
| `origFetch` | `const` |
| `opts` | `const` |
| `token` | `let` |
| `check` | `const` |
| `body` | `final` |
| `start` | `final` |
| `end` | `final` |
| `xhr` | `var` |
| `data` | `var` |
| `cookieStr` | `final` |
| `trimmed` | `final` |
| `value` | `final` |
| `allCookiesJs` | `final` |
| `allCookies` | `final` |
| `trimmed` | `final` |
| `value` | `final` |
| `channel` | `const` |
| `result` | `final` |
| `result` | `return` |
| `null` | `return` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `function` | `dynamic` | `(none)` |
| `function` | `async` | `...args` |
| `initState` | `void` | `(none)` |
| `setNavigationDelegate` | `dynamic` | `NavigationDelegate( onPageStarted: (_` |
| `setState` | `dynamic` | `(` |
| `setState` | `dynamic` | `(` |
| `dispose` | `void` | `(none)` |
| `_onJsBridgeMessage` | `void` | `JavaScriptMessage message` |
| `_checkForLoginRedirect` | `Future<void>` | `String url` |
| `runJavaScript` | `dynamic` | `''' (function(` |
| `function` | `dynamic` | `(none)` |
| `_extractSpDcCookie` | `Future<void>` | `(none)` |
| `_getNativeCookies` | `Future<String?>` | `String url` |
| `_tryComplete` | `void` | `(none)` |
| `build` | `Widget` | `BuildContext context` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer';
import 'package:webview_flutter/webview_flutter.dart';

/// Inline WebView that loads Spotify's login page.
///
/// Captures the `sp_dc` cookie and Bearer token after successful login.
/// Embedded as a widget  -  NOT a full-screen route.
class SpotifyLoginWebView extends StatefulWidget {
  /// Called when both sp_dc cookie and Bearer token have been captured.
  final void Function(String spDcCookie, String bearerToken) onLoginSuccess;

  /// Called when the user cancels or an error occurs.
  final VoidCallback onCancel;

  const SpotifyLoginWebView({
    super.key,
    required this.onLoginSuccess,
    required this.onCancel,
  });

  @override
  State<SpotifyLoginWebView> createState() => _SpotifyLoginWebViewState();
}

class _SpotifyLoginWebViewState extends State<SpotifyLoginWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _capturedSpDc;
  String? _capturedToken;
  bool _loginCompleted = false;

  static const _loginUrl =
      'https://accounts.spotify.com/en/login?continue=https://open.spotify.com/';

  /// JS fetch interceptor  -  captures the first Bearer token from network calls.
  static const _fetchInterceptorJs = '''
    (function() {
      if (window._muIntercept) return;
      window._muIntercept = true;
      window._muTokenSent = false;

      const origFetch = window.fetch;
      window.fetch = async function(...args) {
// ... [remaining code in source file] ...
```
