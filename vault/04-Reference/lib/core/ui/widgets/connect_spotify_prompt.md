---
title: "connect_spotify_prompt.dart"
path: "lib/core/ui/widgets/connect_spotify_prompt.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, ui]
lines: 63
incoming_dependencies: 1
outgoing_dependencies: 0
---

# connect_spotify_prompt.dart

> Source File: `[lib/core/ui/widgets/connect_spotify_prompt.dart](file:///c:/Users/Admin/Musify_MU/lib/core/ui/widgets/connect_spotify_prompt.dart)`
> Layer: `lib/core/ui/widgets`

## Executive Summary
`connect_spotify_prompt.dart` is an essential file in `lib/core/ui/widgets` providing definitions for `ConnectSpotifyPrompt`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
- No internal project dependencies (leaf component or SDK only).

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `main_screen.dart` | `lib/features/shell/presentation` | [[04-Reference/lib/features/shell/presentation/main_screen|main_screen.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class ConnectSpotifyPrompt`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `icon` | `IconData` |
| `title` | `String` |
| `subtitle` | `String` |

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

/// Prompt shown in online-mode tabs when the user is not authenticated.
///
/// Displays a contextual icon, message, and a connect button.
/// Used by the Browse and Library tabs as their unauthenticated state body.
class ConnectSpotifyPrompt extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ConnectSpotifyPrompt({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: Colors.white38, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.3,
// ... [remaining code in source file] ...
```
