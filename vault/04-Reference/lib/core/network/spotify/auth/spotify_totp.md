---
title: "spotify_totp.dart"
path: "lib/core/network/spotify/auth/spotify_totp.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, network]
lines: 221
incoming_dependencies: 2
outgoing_dependencies: 0
---

# spotify_totp.dart

> Source File: `[lib/core/network/spotify/auth/spotify_totp.dart](file:///c:/Users/Admin/Musify_MU/lib/core/network/spotify/auth/spotify_totp.dart)`
> Layer: `lib/core/network/spotify/auth`

## Executive Summary
`spotify_totp.dart` is an essential file in `lib/core/network/spotify/auth` providing definitions for `SpotifyTotp`, `_CipherEntry`.
**Primary Architecture Role**: Core Component

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `auth_bloc.dart` | `lib/features/auth/application` | [[04-Reference/lib/features/auth/application/auth_bloc|auth_bloc.dart]] |
| `spotify_token_refresher.dart` | `lib/core/network/spotify/auth` | [[04-Reference/lib/core/network/spotify/auth/spotify_token_refresher|spotify_token_refresher.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class SpotifyTotp`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_activeVersion` | `int` |
| `_secretBytes` | `Uint8List` |
| `counter` | `final` |
| `counterBytes` | `final` |
| `c` | `var` |
| `hmacResult` | `final` |
| `offset` | `final` |
| `binary` | `final` |
| `prefs` | `final` |
| `secret` | `final` |
| `version` | `final` |
| `prefs` | `final` |
| `fetchedAt` | `final` |
| `age` | `final` |
| `transformed` | `final` |
| `keyString` | `final` |
| `jsUrl` | `final` |
| `jsContent` | `final` |
| `entries` | `final` |
| `best` | `final` |
| `prefs` | `final` |
| `urls` | `const` |
| `regex` | `final` |
| `html` | `final` |
| `match` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `_` | `dynamic` | `(none)` |
| `generate` | `String` | `int timestampMs` |
| `loadFromCache` | `Future<void>` | `(none)` |
| `ensureFreshCipher` | `Future<void>` | `(none)` |
| `refreshCipher` | `Future<void>` | `(none)` |
| `_setActiveCipher` | `void` | `String secret, int version` |
| `_deriveSecret` | `Uint8List` | `String secret` |
| `map` | `dynamic` | `(v` |
| `_fetchAndCacheCipher` | `Future<void>` | `(none)` |
| `sort` | `dynamic` | `(a, b` |
| `_findWebPlayerJsUrl` | `Future<String?>` | `(none)` |
| `_parseCipherEntries` | `List<_CipherEntry>` | `String js` |
| `_fetchUrl` | `Future<String?>` | `String urlString, {bool acceptHtml = false}` |

#### `class _CipherEntry`
- **Archetype**: Core Component

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `secret` | `String` |
| `version` | `int` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Generates TOTP codes for Spotify's internal token endpoint.
///
/// The TOTP cipher is scraped from Spotify's web-player JS bundle at runtime,
/// cached in SharedPreferences, and used to produce 6-digit HMAC-SHA1 codes.
///
/// If the cipher has been rotated by Spotify, call [refreshCipher] to re-fetch.
/// No app update is ever required.
class SpotifyTotp {
  // ── TOTP parameters (RFC 6238) ─────────────────────────────────────────
  static const _period = 30; // seconds per window
  static const _digits = 6;

  // ── Cache settings ─────────────────────────────────────────────────────
  static const _cacheMaxAgeMs = 6 * 60 * 60 * 1000; // 6 hours
  static const _keySecret = 'cipher_secret';
  static const _keyVersion = 'cipher_version';
  static const _keyFetchedAt = 'cipher_fetched_at';

  // ── Hardcoded fallback (v61, confirmed Feb 2026) ───────────────────────
  static const _fallbackSecret = ''',7/*F("rLJ2oxaKL^f+E1xvP@N''';
  static const _fallbackVersion = 61;

  // ── Active cipher (in-memory) ──────────────────────────────────────────
  int _activeVersion = _fallbackVersion;
  late Uint8List _secretBytes;

  static final SpotifyTotp _instance = SpotifyTotp._();

  SpotifyTotp._() {
    _secretBytes = _deriveSecret(_fallbackSecret);
  }

  factory SpotifyTotp() => _instance;

  /// The version of the currently active cipher (used in `totpVer` param).
  int get version => _activeVersion;

// ... [remaining code in source file] ...
```
