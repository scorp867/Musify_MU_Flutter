import 'package:flutter/material.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Reactive wrapper that binds a [SpotifyEntity] to live updates from [DataPool].
///
/// Follows Spotify Android Kodiak's architecture:
/// - Immediately renders with whatever traits are currently available (e.g. Level 1).
/// - Listens reactively to [DataPool.watchEntity] for the entity's URI.
/// - Merges incoming traits (e.g. Level 2 optional: VisualIdentity, Identity)
///   and triggers a targeted widget rebuild.
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
