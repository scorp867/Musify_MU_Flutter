---
title: "playlist_detail_screen.dart"
path: "lib/features/playlist_detail/presentation/playlist_detail_screen.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, playlist_detail]
lines: 546
incoming_dependencies: 1
outgoing_dependencies: 6
---

# playlist_detail_screen.dart

> Source File: `[lib/features/playlist_detail/presentation/playlist_detail_screen.dart](file:///c:/Users/Admin/Musify_MU/lib/features/playlist_detail/presentation/playlist_detail_screen.dart)`
> Layer: `lib/features/playlist_detail/presentation`

## Executive Summary
`playlist_detail_screen.dart` is an essential file in `lib/features/playlist_detail/presentation` providing definitions for `PlaylistDetailScreen`, `_PlaylistDetailScreenState`, `_DetailView`, `_SingleArtwork`, `_MosaicArtwork`, `_PlaylistMetadata`, `_LoadingView`, `_ErrorView`.
**Primary Architecture Role**: Widget State Lifecycle Handler, Stateful Widget, Stateless Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `color_extraction_service.dart` | `lib/core/color` | [[04-Reference/lib/core/color/color_extraction_service|color_extraction_service.dart]] |
| `app_network_image.dart` | `lib/core/widgets` | [[04-Reference/lib/core/widgets/app_network_image|app_network_image.dart]] |
| `auth_bloc.dart` | `lib/features/auth/application` | [[04-Reference/lib/features/auth/application/auth_bloc|auth_bloc.dart]] |
| `library_bloc.dart` | `lib/features/library/application` | [[04-Reference/lib/features/library/application/library_bloc|library_bloc.dart]] |
| `library_item.dart` | `lib/features/library/domain/models` | [[04-Reference/lib/features/library/domain/models/library_item|library_item.dart]] |
| `playlist_detail_bloc.dart` | `lib/features/playlist_detail/application` | [[04-Reference/lib/features/playlist_detail/application/playlist_detail_bloc|playlist_detail_bloc.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `library_view.dart` | `lib/features/library/presentation` | [[04-Reference/lib/features/library/presentation/library_view|library_view.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class PlaylistDetailScreen`
- **Archetype**: Stateful Widget
- **Extends**: `StatefulWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `item` | `LibraryItem` |
| `libraryBloc` | `final` |
| `authBloc` | `final` |
| `colorService` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `open` | `void` | `BuildContext context, LibraryItem item` |
| `push` | `dynamic` | `MaterialPageRoute<void>( builder: (_` |
| `MultiBlocProvider` | `return` | `providers: [ BlocProvider<PlaylistDetailBloc>( ...` |
| `createState` | `State<PlaylistDetailScreen>` | `(none)` |

#### `class _PlaylistDetailScreenState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<PlaylistDetailScreen>`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `items` | `final` |
| `null` | `return` |
| `updatedItem` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `_findCurrentItem` | `LibraryItem?` | `LibraryState libraryState` |
| `firstWhere` | `dynamic` | `(i` |
| `build` | `Widget` | `BuildContext context` |
| `PlaylistDetailLoading` | `dynamic` | `(none)` |
| `PlaylistDetailLoaded` | `dynamic` | `(none)` |
| `PlaylistDetailError` | `dynamic` | `:final message` |

#### `class _DetailView`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `state` | `PlaylistDetailLoaded` |
| `statusBarHeight` | `final` |
| `screenHeight` | `final` |
| `gradientHeight` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `firstWhere` | `dynamic` | `(s` |

#### `class _SingleArtwork`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `url` | `String?` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |
| `AppNetworkImage` | `return` | `imageUrl: url!, fit: BoxFit.cover, memCacheWidt...` |

#### `class _MosaicArtwork`
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

#### `class _PlaylistMetadata`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `state` | `PlaylistDetailLoaded` |
| `item` | `final` |
| `colorHex` | `final` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |

#### `class _LoadingView`
- **Archetype**: Stateless Widget
- **Extends**: `StatelessWidget`

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `build` | `Widget` | `BuildContext context` |

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

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/core/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/library/application/library_bloc.dart';
import 'package:musify_mu/features/library/domain/models/library_item.dart';
import 'package:musify_mu/features/playlist_detail/application/playlist_detail_bloc.dart';

/// Screen for displaying playlist detail with Spotify-accurate color extraction
/// and 21-stop eased atmospheric gradient background.
///
/// Supports pull-to-refresh which dispatches a library refresh and reactively
/// re-extracts color when artwork changes.
class PlaylistDetailScreen extends StatefulWidget {
  final LibraryItem item;

  const PlaylistDetailScreen({super.key, required this.item});

  /// Opens the playlist detail screen via standard navigation.
  static void open(BuildContext context, LibraryItem item) {
    final libraryBloc = context.read<LibraryBloc>();
    final authBloc = context.read<AuthBloc>();
    final colorService = context.read<ColorExtractionService>();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return MultiBlocProvider(
            providers: [
              BlocProvider<PlaylistDetailBloc>(
                create: (_) => PlaylistDetailBloc(
                  colorService: colorService,
                )..add(PlaylistDetailLoadRequested(item)),
              ),
              BlocProvider.value(value: libraryBloc),
              BlocProvider.value(value: authBloc),
            ],
            child: PlaylistDetailScreen(item: item),
          );
        },
      ),
    );
  }
// ... [remaining code in source file] ...
```
