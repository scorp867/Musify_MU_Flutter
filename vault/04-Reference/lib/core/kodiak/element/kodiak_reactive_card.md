---
title: "kodiak_reactive_card.dart"
path: "lib/core/kodiak/element/kodiak_reactive_card.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, kodiak, widget, sdui, reactive-card]
lines: 42
incoming_dependencies: 1
outgoing_dependencies: 2
---

# kodiak_reactive_card.dart

> Source File: `[lib/core/kodiak/element/kodiak_reactive_card.dart](file:///c:/Users/Admin/Musify_MU/lib/core/kodiak/element/kodiak_reactive_card.dart)`
> Layer: `lib/core/kodiak/element` (Reactive SDUI Card Widget)

## Executive Summary
`kodiak_reactive_card.dart` implements `KodiakReactiveCard`, a lightweight presentation widget that binds a `SpotifyEntity` to live trait updates from `DataPool`. It renders immediately using eager Level 1 traits (title, artwork URI), listens to `dataPool.watchEntity(item.uri)`, and lazily merges Level 2 optional traits (`VisualIdentityTrait`, `CreditsTrait`) as they arrive from background network batches, re-rendering only the specific card without triggering parent feed rebuilds.

**Primary Architecture Role**: Targeted SDUI Reactive Entity Widget Wrapper

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `data_pool.dart` | `lib/core/kodiak/dataloader` | [[04-Reference/lib/core/kodiak/dataloader/data_pool|data_pool.dart]] |
| `spotify_entity.dart` | `lib/features/home_feed/domain/models` | [[04-Reference/lib/features/home_feed/domain/models/spotify_entity|spotify_entity.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `kodiak_data_layer_test.dart` | `test/features/home_feed` | [[04-Reference/test/features/home_feed/kodiak_data_layer_test|kodiak_data_layer_test.dart]] |

## Declarations & API Breakdown

### Classes & Mixins
#### `class KodiakReactiveCard extends StatelessWidget`

**Fields:**
- `final SpotifyEntity item`: The underlying Spotify entity holding current trait snapshot.
- `final DataPool? dataPool`: The active Kodiak data pool; if null, falls back to direct rendering.
- `final Widget Function(BuildContext context, SpotifyEntity entity) builder`: Render closure returning the specific card widget (e.g. `SquareCard`, `PreviewCard`, `EpisodePreviewCard`).

**Methods:**
- `Widget build(BuildContext context)`: Wraps `builder` in a `StreamBuilder<Map<String, Trait>>` listening to `dataPool.watchEntity(item.uri)`.

## State & Data Flow Analysis
- **Immediate First-Frame Paint**:
  `initialData: dataPool!.getTraits(item.uri)` ensures that if traits are already cached in memory from initial Casita protobuf parsing, the widget paints completely on frame 0 without displaying placeholder loading spinners.
- **In-Place Trait Mutation**:
  When new traits arrive over the stream, `item.traits.addAll(snapshot.data!)` merges the newly resolved traits and invokes `builder(context, item)`.

## Implementation Highlight
```dart
class KodiakReactiveCard extends StatelessWidget {
  final SpotifyEntity item;
  final DataPool? dataPool;
  final Widget Function(BuildContext context, SpotifyEntity entity) builder;

  const KodiakReactiveCard({
    super.key,
    required this.item,
    this.dataPool,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPool == null) {
      return builder(context, item);
    }

    return StreamBuilder<Map<String, Trait>>(
      stream: dataPool!.watchEntity(item.uri),
      initialData: dataPool!.getTraits(item.uri),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          item.traits.addAll(snapshot.data!);
        }
        return builder(context, item);
      },
    );
  }
}
```
