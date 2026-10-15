---
title: "spotify_welcome_landing.dart"
path: "lib/features/auth/presentation/widgets/spotify_welcome_landing.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, auth]
lines: 177
incoming_dependencies: 1
outgoing_dependencies: 0
---

# spotify_welcome_landing.dart

> Source File: `[lib/features/auth/presentation/widgets/spotify_welcome_landing.dart](file:///c:/Users/Admin/Musify_MU/lib/features/auth/presentation/widgets/spotify_welcome_landing.dart)`
> Layer: `lib/features/auth/presentation/widgets`

## Executive Summary
`spotify_welcome_landing.dart` is an essential file in `lib/features/auth/presentation/widgets` providing definitions for `SpotifyWelcomeLanding`, `_FeatureRow`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `online_home_screen.dart` | `lib/features/home/presentation` | [[04-Reference/lib/features/home/presentation/online_home_screen|online_home_screen.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class SpotifyWelcomeLanding`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `onConnect` | `VoidCallback` |
| `isLoading` | `bool` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |

#### `class _FeatureRow`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `icon` | `IconData` |
| `text` | `String` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
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

/// Spotify-green accent for auth-related UI.
const _kSpotifyGreen = Color(0xFF1DB954);

/// Welcome landing shown inside OnlineHomeScreen when user is not logged in.
/// Not a separate screen  -  inline within the existing home tab.
class SpotifyWelcomeLanding extends StatelessWidget {
  final VoidCallback onConnect;
  final bool isLoading;

  const SpotifyWelcomeLanding({
    super.key,
    required this.onConnect,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // App icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/app_icon.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 32),

              // Headline
// ... [remaining code in source file] ...
```
