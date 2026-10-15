---
title: "queued_badge_view.dart"
path: "lib/features/player/presentation/widgets/queued_badge_view.dart"
type: "source-code"
tags: [code, dart, musify-mu, feature, player, queue, badge, encore]
lines: 30
incoming_dependencies: 1
outgoing_dependencies: 2
---

# queued_badge_view.dart

> Source File: `[lib/features/player/presentation/widgets/queued_badge_view.dart](file:///c:/Users/Admin/Musify_MU/lib/features/player/presentation/widgets/queued_badge_view.dart)`
> Layer: `lib/features/player/presentation/widgets`

## Executive Summary
`queued_badge_view.dart` is a 1:1 replica of Spotify's `QueuedBadgeView`. It renders a 13dp accent green badge in the subtitle row of track tiles to visually distinguish user-enqueued tracks from ambient playlist or album tracks.

## Core Architectural Mechanics
- Renders `SpotifyIcon.queueBadge(size: size, color: color ?? PlayerColors.accent)`.
- Applies a standard 5dp right margin to separate the icon from the artist subtitle string.
- Zero-overhead stateless widget used inside high-frequency `ListView` item builders.

## API Breakdown

### Classes

#### `class QueuedBadgeView extends StatelessWidget`
- **Fields**:
  - `size`: `double` (default: 13.0dp) badge icon dimension.
  - `color`: `Color?` optional color override, defaults to `PlayerColors.accent` (`#1DB954`).

## Dependency Mapping

### Incoming Dependencies (What imports this file)
- `queue_track_row.dart`: [[04-Reference/lib/features/player/presentation/widgets/queue_track_row|queue_track_row.dart]] displays badge for queued items.

### Outgoing Dependencies (What this file imports)
- `spotify_encore_icons.dart`: [[04-Reference/lib/core/ui/icons/spotify_encore_icons|spotify_encore_icons.dart]]
- `player_theme.dart`: [[04-Reference/lib/features/player/presentation/widgets/player_theme|player_theme.dart]]
