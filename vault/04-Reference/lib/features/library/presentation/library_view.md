---
title: "library_view.dart"
path: "lib/features/library/presentation/library_view.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, library]
lines: 670
incoming_dependencies: 1
outgoing_dependencies: 12
---

# library_view.dart

> Source File: `[lib/features/library/presentation/library_view.dart](file:///c:/Users/Admin/Musify_MU/lib/features/library/presentation/library_view.dart)`
> Layer: `lib/features/library/presentation`

## Executive Summary
`library_view.dart` is an essential file in `lib/features/library/presentation` providing definitions for `LibraryView`, `_LibraryViewState`, `_LibraryHeader`, `_FilterChipRow`, `_SortBar`, `_LibraryItemTile`, `_LibraryListShimmer`, `_ErrorView`, `_MosaicGrid`.
**Primary Architecture Role**: Widget State Lifecycle Handler, Stateful Widget, Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `app_network_image.dart` | `lib/core/widgets` | [[04-Reference/lib/core/widgets/app_network_image|app_network_image.dart]] |
| `color_extraction_service.dart` | `lib/core/color` | [[04-Reference/lib/core/color/color_extraction_service|color_extraction_service.dart]] |
| `app_header.dart` | `lib/core/ui/widgets` | [[04-Reference/lib/core/ui/widgets/app_header|app_header.dart]] |
| `app_snack_bar.dart` | `lib/core/ui/widgets` | [[04-Reference/lib/core/ui/widgets/app_snack_bar|app_snack_bar.dart]] |
| `sticky_header_delegate.dart` | `lib/core/ui/widgets` | [[04-Reference/lib/core/ui/widgets/sticky_header_delegate|sticky_header_delegate.dart]] |
| `shell_bottom_spacer.dart` | `lib/core/ui/widgets` | [[04-Reference/lib/core/ui/widgets/shell_bottom_spacer|shell_bottom_spacer.dart]] |
| `auth_bloc.dart` | `lib/features/auth/application` | [[04-Reference/lib/features/auth/application/auth_bloc|auth_bloc.dart]] |
| `auth_state.dart` | `lib/features/auth/domain/entities` | [[04-Reference/lib/features/auth/domain/entities/auth_state|auth_state.dart]] |
| `library_bloc.dart` | `lib/features/library/application` | [[04-Reference/lib/features/library/application/library_bloc|library_bloc.dart]] |
| `library_view_data.dart` | `lib/features/library/domain/models` | [[04-Reference/lib/features/library/domain/models/library_view_data|library_view_data.dart]] |
| `playlist_detail_bloc.dart` | `lib/features/playlist_detail/application` | [[04-Reference/lib/features/playlist_detail/application/playlist_detail_bloc|playlist_detail_bloc.dart]] |
| `playlist_detail_screen.dart` | `lib/features/playlist_detail/presentation` | [[04-Reference/lib/features/playlist_detail/presentation/playlist_detail_screen|playlist_detail_screen.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `main_screen.dart` | `lib/features/shell/presentation` | [[04-Reference/lib/features/shell/presentation/main_screen|main_screen.dart]] |

## Declarations & API Breakdown

### Enums
#### `enum LibraryFilter`
Values: `all`, `playlists`, `podcasts`, `artists`

### Classes & Mixins
#### `class LibraryView`
- **Archetype**: Stateful Widget
- **Extends**: `StatefulWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `onMenuPressed` | `VoidCallback?` |
| `onToggleMode` | `VoidCallback?` |
| `isActive` | `bool` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `createState` | `State<LibraryView>` | `(none)` |

#### `class _LibraryViewState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<LibraryView>`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_activeFilter` | `LibraryFilter` |
| `bloc` | `final` |
| `sorted` | `final` |
| `true` | `return` |
| `itemCount` | `final` |
| `bloc` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `didUpdateWidget` | `void` | `LibraryView oldWidget` |
| `_filterItems` | `List<LibraryItem>` | `LibraryViewData data` |
| `where` | `dynamic` | `(i` |
| `where` | `dynamic` | `(i` |
| `where` | `dynamic` | `(i` |
| `build` | `Widget` | `BuildContext context` |
| `LibraryLoaded` | `dynamic` | `:final data` |
| `LibraryError` | `dynamic` | `:final staleData` |
| `firstWhere` | `dynamic` | `(s` |
| `SliverPersistentHeader` | `dynamic` | `pinned: true, delegate: StickyHeaderDelegate( h...` |
| `setState` | `dynamic` | `(` |
| `_buildBodySlivers` | `List<Widget>` | `BuildContext context, LibraryState state` |
| `LibraryLoading` | `dynamic` | `(none)` |
| `LibraryLoaded` | `dynamic` | `:final data` |
| `LibraryError` | `dynamic` | `:final message, :final staleData` |
| `_buildListSlivers` | `List<Widget>` | `List<LibraryItem> items` |
| `builder` | `dynamic` | `itemCount: items.length + 1, itemBuilder: (cont...` |

#### `class _LibraryHeader`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `onMenuPressed` | `VoidCallback?` |
| `onToggleMode` | `VoidCallback?` |
| `user` | `final` |
| `avatar` | `Widget` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |

#### `class _FilterChipRow`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `active` | `LibraryFilter` |
| `onChanged` | `ValueChanged<LibraryFilter>` |
| `isActive` | `final` |
| `label` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `_buildClearButton` | `Widget` | `(none)` |
| `GestureDetector` | `dynamic` | `onTap: (` |
| `_buildChip` | `Widget` | `LibraryFilter filter` |
| `GestureDetector` | `return` | `onTap: (` |

#### `class _SortBar`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `itemCount` | `int` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |

#### `class _LibraryItemTile`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `item` | `LibraryItem` |
| `isLikedSongs` | `final` |
| `isArtist` | `final` |
| `count` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `push` | `dynamic` | `MaterialPageRoute<void>( builder: (_` |
| `MultiBlocProvider` | `return` | `providers: [ BlocProvider<PlaylistDetailBloc>( ...` |
| `_buildLikedSongsIcon` | `Widget` | `(none)` |
| `_buildItemImage` | `Widget` | `{required bool isArtist}` |
| `AppNetworkImage` | `dynamic` | `imageUrl: item.imageUrl!, fit: BoxFit.cover, me...` |
| `_placeholderIcon` | `Widget` | `{bool isCircle = false}` |
| `_buildSubtitle` | `String` | `(none)` |

#### `class _LibraryListShimmer`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `builder` | `dynamic` | `itemCount: 10, itemBuilder: (context, index` |

#### `class _ErrorView`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `message` | `String` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `TextButton` | `dynamic` | `onPressed: (` |

#### `class _MosaicGrid`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `urls` | `List<String>` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `_tile` | `Widget` | `String url` |
| `AppNetworkImage` | `return` | `imageUrl: url, fit: BoxFit.cover, memCacheWidth...` |

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Synchronous setState() invoked without mounted check; can throw if widget is unmounted during async gaps.

## Implementation Highlight
```dart
import 'package:musify_mu/core/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/core/ui/widgets/app_header.dart';
import 'package:musify_mu/core/ui/widgets/app_snack_bar.dart';
import 'package:musify_mu/core/ui/widgets/sticky_header_delegate.dart';
import 'package:musify_mu/core/ui/widgets/shell_bottom_spacer.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/domain/entities/auth_state.dart';
import 'package:musify_mu/features/library/application/library_bloc.dart';
import 'package:musify_mu/features/library/domain/models/library_view_data.dart';
import 'package:musify_mu/features/playlist_detail/application/playlist_detail_bloc.dart';
import 'package:musify_mu/features/playlist_detail/presentation/playlist_detail_screen.dart';

/// The Library tab view.
class LibraryView extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onToggleMode;
  final bool isActive;

  const LibraryView({
    super.key,
    this.onMenuPressed,
    this.onToggleMode,
    this.isActive = true,
  });

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

enum LibraryFilter { all, playlists, podcasts, artists }

class _LibraryViewState extends State<LibraryView> {
  LibraryFilter _activeFilter = LibraryFilter.all;

  @override
  void didUpdateWidget(LibraryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      AppSnackBar.clear(context);
      context.read<LibraryBloc>().add(const LibraryCancelRequested());
    } else if (!oldWidget.isActive && widget.isActive) {
      final bloc = context.read<LibraryBloc>();
// ... [remaining code in source file] ...
```
