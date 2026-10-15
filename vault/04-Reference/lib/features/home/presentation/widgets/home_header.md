---
title: "home_header.dart"
path: "lib/features/home/presentation/widgets/home_header.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, home]
lines: 147
incoming_dependencies: 2
outgoing_dependencies: 4
---

# home_header.dart

> Source File: `[lib/features/home/presentation/widgets/home_header.dart](file:///c:/Users/Admin/Musify_MU/lib/features/home/presentation/widgets/home_header.dart)`
> Layer: `lib/features/home/presentation/widgets`

## Executive Summary
`home_header.dart` is an essential file in `lib/features/home/presentation/widgets` providing definitions for `HomeHeaderTitleRow`, `HomeFilterChips`.
**Primary Architecture Role**: Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `app_header.dart` | `lib/core/ui/widgets` | [[04-Reference/lib/core/ui/widgets/app_header|app_header.dart]] |
| `home_feed_bloc.dart` | `lib/features/home_feed/application` | [[04-Reference/lib/features/home_feed/application/home_feed_bloc|home_feed_bloc.dart]] |
| `home_view_data.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/home_view_data|home_view_data.dart]] |
| `facet_chip_row.dart` | `lib/features/home_feed/presentation/widgets` | [[04-Reference/lib/features/home_feed/presentation/widgets/facet_chip_row|facet_chip_row.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `home_feed_view.dart` | `lib/features/home_feed/presentation` | [[04-Reference/lib/features/home_feed/presentation/home_feed_view|home_feed_view.dart]] |
| `home_tab.dart` | `lib/features/home/presentation` | [[04-Reference/lib/features/home/presentation/home_tab|home_tab.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class HomeHeaderTitleRow`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `isOnlineMode` | `bool` |
| `onMenuPressed` | `VoidCallback` |
| `onToggleMode` | `VoidCallback` |
| `iconKey` | `GlobalKey` |
| `iconVisible` | `bool` |
| `spotifyDisplayName` | `String?` |
| `spotifyAvatarUrl` | `String?` |
| `displayName` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `_buildAvatar` | `Widget` | `(none)` |

#### `class HomeFilterChips`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `chips` | `List<HomeChip>?` |
| `prevFacet` | `final` |
| `currFacet` | `final` |
| `activeFacet` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `HomeFeedLoaded` | `dynamic` | `:final activeFacet` |
| `HomeFeedLoading` | `dynamic` | `:final activeFacet` |
| `HomeFeedLoaded` | `dynamic` | `:final activeFacet` |
| `HomeFeedLoading` | `dynamic` | `:final activeFacet` |
| `HomeFeedLoaded` | `dynamic` | `:final activeFacet` |
| `HomeFeedLoading` | `dynamic` | `:final activeFacet` |
| `FacetChipRow` | `return` | `selectedFacet: activeFacet, chips: chips, onSel...` |

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
import 'package:musify_mu/core/ui/widgets/app_header.dart';
import 'package:musify_mu/features/home_feed/application/home_feed_bloc.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/facet_chip_row.dart';

/// Builds the home header title row (app icon + name + avatar).
/// Used as a scrollable SliverToBoxAdapter in the feed.
class HomeHeaderTitleRow extends StatelessWidget {
  final bool isOnlineMode;
  final VoidCallback onMenuPressed;
  final VoidCallback onToggleMode;
  final GlobalKey iconKey;
  final bool iconVisible;
  final String? spotifyDisplayName;
  final String? spotifyAvatarUrl;

  const HomeHeaderTitleRow({
    super.key,
    required this.isOnlineMode,
    required this.onMenuPressed,
    required this.onToggleMode,
    required this.iconKey,
    this.iconVisible = true,
    this.spotifyDisplayName,
    this.spotifyAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = isOnlineMode && spotifyDisplayName != null
        ? spotifyDisplayName!
        : 'Musify';

    return AppHeader(
      leading: GestureDetector(
        onTap: onMenuPressed,
        child: _buildAvatar(),
      ),
      title: displayName,
      trailing: [
        GestureDetector(
          onTap: onToggleMode,
// ... [remaining code in source file] ...
```
