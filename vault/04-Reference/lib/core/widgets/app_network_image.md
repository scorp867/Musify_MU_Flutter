---
title: "app_network_image.dart"
path: "lib/core/widgets/app_network_image.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, widgets]
lines: 135
incoming_dependencies: 28
outgoing_dependencies: 2
---

# app_network_image.dart

> Source File: `[lib/core/widgets/app_network_image.dart](file:///c:/Users/Admin/Musify_MU/lib/core/widgets/app_network_image.dart)`
> Layer: `lib/core/widgets`

## Executive Summary
`app_network_image.dart` is an essential file in `lib/core/widgets` providing definitions for `AppNetworkImage`, `_AppNetworkImageState`.
**Primary Architecture Role**: Widget State Lifecycle Handler, Stateful Widget

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `network_status_bloc.dart` | `lib/core/network/status/bloc` | [[04-Reference/lib/core/network/status/bloc/network_status_bloc|network_status_bloc.dart]] |
| `network_status.dart` | `lib/core/network/status` | [[04-Reference/lib/core/network/status/network_status|network_status.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `playlist_detail_screen.dart` | `lib/features/playlist_detail/presentation` | [[04-Reference/lib/features/playlist_detail/presentation/playlist_detail_screen|playlist_detail_screen.dart]] |
| `library_view.dart` | `lib/features/library/presentation` | [[04-Reference/lib/features/library/presentation/library_view|library_view.dart]] |
| `quick_grid_section.dart` | `lib/features/home_feed/presentation/widgets` | [[04-Reference/lib/features/home_feed/presentation/widgets/quick_grid_section|quick_grid_section.dart]] |
| `artist_circle_card.dart` | `lib/features/home_feed/presentation/widgets/cards` | [[04-Reference/lib/features/home_feed/presentation/widgets/cards/artist_circle_card|artist_circle_card.dart]] |
| `episode_preview_card.dart` | `lib/features/home_feed/presentation/widgets/cards` | [[04-Reference/lib/features/home_feed/presentation/widgets/cards/episode_preview_card|episode_preview_card.dart]] |
| `preview_card.dart` | `lib/features/home_feed/presentation/widgets/cards` | [[04-Reference/lib/features/home_feed/presentation/widgets/cards/preview_card|preview_card.dart]] |
| `show_preview_card.dart` | `lib/features/home_feed/presentation/widgets/cards` | [[04-Reference/lib/features/home_feed/presentation/widgets/cards/show_preview_card|show_preview_card.dart]] |
| `square_card.dart` | `lib/features/home_feed/presentation/widgets/cards` | [[04-Reference/lib/features/home_feed/presentation/widgets/cards/square_card|square_card.dart]] |
| `action_card_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/action_card_section|action_card_section.dart]] |
| `audio_spotlight_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/audio_spotlight_section|audio_spotlight_section.dart]] |
| `campaign_carousel_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/campaign_carousel_section|campaign_carousel_section.dart]] |
| `episode_list_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/episode_list_section|episode_list_section.dart]] |
| `full_bleed_banner_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/full_bleed_banner_section|full_bleed_banner_section.dart]] |
| `immersive_preview_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/immersive_preview_section|immersive_preview_section.dart]] |
| `inline_card_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/inline_card_section|inline_card_section.dart]] |
| `live_event_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/live_event_section|live_event_section.dart]] |
| `play_link_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/play_link_section|play_link_section.dart]] |
| `promotion_banner_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/promotion_banner_section|promotion_banner_section.dart]] |
| `recents_carousel_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/recents_carousel_section|recents_carousel_section.dart]] |
| `reflection_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/reflection_section|reflection_section.dart]] |
| `showcase_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/showcase_section|showcase_section.dart]] |
| `story_bubble_carousel.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/story_bubble_carousel|story_bubble_carousel.dart]] |
| `vertical_card_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/vertical_card_section|vertical_card_section.dart]] |
| `video_carousel_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/video_carousel_section|video_carousel_section.dart]] |
| `video_promo_section.dart` | `lib/features/home_feed/presentation/widgets/sections` | [[04-Reference/lib/features/home_feed/presentation/widgets/sections/video_promo_section|video_promo_section.dart]] |
| `browse_view.dart` | `lib/features/browse/presentation` | [[04-Reference/lib/features/browse/presentation/browse_view|browse_view.dart]] |
| `banner_sections_widget_test.dart` | `test/features/home_feed` | [[04-Reference/test/features/home_feed/banner_sections_widget_test|banner_sections_widget_test.dart]] |
| `network_reconnect_retry_test.dart` | `test/core/kodiak` | [[04-Reference/test/core/kodiak/network_reconnect_retry_test|network_reconnect_retry_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class AppNetworkImage`
- **Archetype**: Stateful Widget
- **Extends**: `StatefulWidget`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `imageUrl` | `String` |
| `width` | `double?` |
| `height` | `double?` |
| `fit` | `BoxFit?` |
| `memCacheWidth` | `int?` |
| `memCacheHeight` | `int?` |
| `placeholder` | `PlaceholderWidgetBuilder?` |
| `errorWidget` | `LoadingErrorWidgetBuilder?` |
| `imageBuilder` | `ImageWidgetBuilder?` |
| `color` | `Color?` |
| `colorBlendMode` | `BlendMode?` |
| `alignment` | `Alignment` |
| `fadeInDuration` | `Duration` |
| `networkStatusBloc` | `NetworkStatusBloc?` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `createState` | `State<AppNetworkImage>` | `(none)` |

#### `class _AppNetworkImageState`
- **Archetype**: Widget State Lifecycle Handler
- **Extends**: `State<AppNetworkImage>`

**Key Fields & Properties:**
| Field Name | Type |
|------------|------|
| `_retryKey` | `int` |
| `_hasError` | `bool` |
| `null` | `return` |
| `imageWidget` | `final` |
| `bloc` | `final` |
| `imageWidget` | `return` |

**Methods & Handlers:**
| Method | Return Type | Parameters |
|--------|-------------|------------|
| `didUpdateWidget` | `void` | `covariant AppNetworkImage oldWidget` |
| `_onNetworkStatusChanged` | `void` | `BuildContext context, NetworkStatusState state` |
| `setState` | `dynamic` | `(` |
| `_resolveBloc` | `NetworkStatusBloc?` | `BuildContext context` |
| `build` | `Widget` | `BuildContext context` |
| `addPostFrameCallback` | `dynamic` | `(_` |

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
import 'package:musify_mu/core/network/status/bloc/network_status_bloc.dart';
import 'package:musify_mu/core/network/status/network_status.dart';

/// Connectivity-aware image widget that automatically retries failed downloads
/// as soon as the device reconnects to the network, without requiring the user
/// to scroll the card out of and back into the viewport.
///
/// Follows pure Flutter BLoC architecture: receives connectivity state reactively
/// via [BuildContext] / [BlocListener] with zero service locator dependencies.
class AppNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final ImageWidgetBuilder? imageBuilder;
  final Color? color;
  final BlendMode? colorBlendMode;
  final Alignment alignment;
  final Duration fadeInDuration;
  final NetworkStatusBloc? networkStatusBloc;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholder,
    this.errorWidget,
    this.imageBuilder,
    this.color,
    this.colorBlendMode,
    this.alignment = Alignment.center,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.networkStatusBloc,
  });
// ... [remaining code in source file] ...
```
