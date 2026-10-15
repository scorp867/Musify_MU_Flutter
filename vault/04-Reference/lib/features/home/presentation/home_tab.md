---
title: "home_tab.dart"
path: "lib/features/home/presentation/home_tab.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home]
lines: 84
incoming_dependencies: 1
outgoing_dependencies: 7
---

# home_tab.dart

> Source File: `[lib/features/home/presentation/home_tab.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home/presentation/home_tab.dart)`
> Layer: `lib/features/home/presentation`

## Executive Summary
`home_tab.dart` is an essential file in `lib/features/home/presentation` providing definitions for `HomeTab`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `playback_controller.dart` | `lib/core/audio` | [[04-Reference/lib/core/audio/playback_controller|playback_controller.dart]] |
| `auth_bloc.dart` | `lib/features/auth/application` | [[04-Reference/lib/features/auth/application/auth_bloc|auth_bloc.dart]] |
| `auth_state.dart` | `lib/features/auth/domain/entities` | [[04-Reference/lib/features/auth/domain/entities/auth_state|auth_state.dart]] |
| `online_home_screen.dart` | `lib/features/home/presentation` | [[04-Reference/lib/features/home/presentation/online_home_screen|online_home_screen.dart]] |
| `home_header.dart` | `lib/features/home/presentation/widgets` | [[04-Reference/lib/features/home/presentation/widgets/home_header|home_header.dart]] |
| `home_feed_bloc.dart` | `lib/features/home_feed/application` | [[04-Reference/lib/features/home_feed/application/home_feed_bloc|home_feed_bloc.dart]] |
| `local_music_screen.dart` | `lib/features/local_music/presentation/screens` | [[04-Reference/lib/features/local_music/presentation/screens/local_music_screen|local_music_screen.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `main_screen.dart` | `lib/features/shell/presentation` | [[04-Reference/lib/features/shell/presentation/main_screen|main_screen.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class HomeTab`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `isOnlineMode` | `bool` |
| `isActive` | `bool` |
| `onMenuPressed` | `VoidCallback` |
| `onToggleMode` | `VoidCallback` |
| `iconKey` | `GlobalKey` |
| `iconVisible` | `bool` |
| `playbackController` | `PlaybackController?` |
| `user` | `final` |
| `titleRow` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `SafeArea` | `dynamic` | `bottom: false, child: BlocBuilder<AuthBloc, Aut...` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/domain/entities/auth_state.dart';
import 'package:musify_mu/features/home/presentation/online_home_screen.dart';
import 'package:musify_mu/features/home/presentation/widgets/home_header.dart';
import 'package:musify_mu/features/home_feed/application/home_feed_bloc.dart';
import 'package:musify_mu/features/local_music/presentation/screens/local_music_screen.dart';

class HomeTab extends StatelessWidget {
  final bool isOnlineMode;
  final bool isActive;
  final VoidCallback onMenuPressed;
  final VoidCallback onToggleMode;
  final GlobalKey iconKey;
  final bool iconVisible;
  final PlaybackController? playbackController;
  final HomeFeedBloc Function() createHomeFeedBloc;

  const HomeTab({
    super.key,
    required this.isOnlineMode,
    this.isActive = true,
    required this.onMenuPressed,
    required this.onToggleMode,
    required this.iconKey,
    required this.createHomeFeedBloc,
    this.iconVisible = true,
    this.playbackController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (prev, curr) =>
              prev.runtimeType != curr.runtimeType,
          builder: (context, authState) {
            final user = authState is Authenticated
                ? authState.user
                : null;
// ... [remaining code in source file] ...
```
