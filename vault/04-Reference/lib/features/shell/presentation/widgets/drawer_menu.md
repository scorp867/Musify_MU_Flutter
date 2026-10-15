---
title: "drawer_menu.dart"
path: "lib/features/shell/presentation/widgets/drawer_menu.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, shell]
lines: 152
incoming_dependencies: 1
outgoing_dependencies: 4
---

# drawer_menu.dart

> Source File: `[lib/features/shell/presentation/widgets/drawer_menu.dart](file:///c:/Users/Admin/Musify_MU/lib/features/shell/presentation/widgets/drawer_menu.dart)`
> Layer: `lib/features/shell/presentation/widgets`

## Executive Summary
`drawer_menu.dart` is an essential file in `lib/features/shell/presentation/widgets` providing definitions for `DrawerMenu`, `_DrawerMenuItem`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `auth_bloc.dart` | `lib/features/auth/application` | [[04-Reference/lib/features/auth/application/auth_bloc|auth_bloc.dart]] |
| `auth_event.dart` | `lib/features/auth/application` | [[04-Reference/lib/features/auth/application/auth_event|auth_event.dart]] |
| `auth_state.dart` | `lib/features/auth/domain/entities` | [[04-Reference/lib/features/auth/domain/entities/auth_state|auth_state.dart]] |
| `debug_now_playing_screen.dart` | `lib/features/player/presentation/screens` | [[04-Reference/lib/features/player/presentation/screens/debug_now_playing_screen|debug_now_playing_screen.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `hidden_drawer_scaffold.dart` | `lib/features/shell/presentation` | [[04-Reference/lib/features/shell/presentation/hidden_drawer_scaffold|hidden_drawer_scaffold.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class DrawerMenu`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `user` | `final` |
| `displayName` | `final` |
| `handle` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `GestureDetector` | `dynamic` | `onTap: (` |
| `push` | `dynamic` | `MaterialPageRoute<void>( builder: (_` |
| `GestureDetector` | `dynamic` | `onTap: (` |
| `_buildAvatar` | `Widget` | `String? avatarUrl, String displayName` |

#### `class _DrawerMenuItem`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `icon` | `IconData` |
| `title` | `String` |
| `color` | `Color` |

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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/application/auth_event.dart';
import 'package:musify_mu/features/auth/domain/entities/auth_state.dart';
import 'package:musify_mu/features/player/presentation/screens/debug_now_playing_screen.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
          builder: (context, authState) {
            final user =
                authState is Authenticated ? authState.user : null;
            final displayName = user?.displayName ?? 'Musify';
            final handle = user != null ? '@${user.id}' : 'Offline Mode';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(user?.avatarUrl, displayName),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  handle,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 48),
                _DrawerMenuItem(
// ... [remaining code in source file] ...
```
