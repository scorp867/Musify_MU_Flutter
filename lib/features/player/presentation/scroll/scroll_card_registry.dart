import 'package:flutter/material.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_sections.dart';

typedef ScrollCardWidgetBuilder<T extends ScrollCardDescriptor> = Widget Function(
  BuildContext context,
  T descriptor,
);

/// Card view factory registry for the Now Playing scroll view.
///
/// 1:1 replica of Spotify Android's `p/s400.java`:
/// ```java
/// public final class s400 {
///     public final DataPool a;
///     public final LinkedHashMap b = new LinkedHashMap();
/// }
/// ```
class ScrollCardRegistry {
  final DataPool? dataPool;
  final Map<Type, ScrollCardWidgetBuilder> _builders = {};

  ScrollCardRegistry({this.dataPool});

  /// Registers a widget builder for a specific card descriptor type.
  void register<T extends ScrollCardDescriptor>(
    ScrollCardWidgetBuilder<T> builder,
  ) {
    _builders[T] = (context, descriptor) => builder(context, descriptor as T);
  }

  /// Builds the widget for the given descriptor, or returns null if not registered.
  Widget? buildCard(BuildContext context, ScrollCardDescriptor descriptor) {
    final builder = _builders[descriptor.runtimeType];
    return builder?.call(context, descriptor);
  }

  /// 1:1 Factory helper configuring standard Spotify card view binders (`p/ifn0.java:220-235`).
  void registerDefaultCards({
    required String defaultArtistName,
    ColorLyricsResponse? colorLyrics,
    int activeLineIndex = 0,
    VoidCallback? onTapLyrics,
    VoidCallback? onShowAllCredits,
    VoidCallback? onShowAllEvents,
  }) {
    register<LyricsCardDescriptor>((context, desc) {
      return PlayerLyricsSection(
        key: ValueKey('lyrics_${desc.entityUri}'),
        trackUri: desc.entityUri,
        dataPool: dataPool,
        colorLyrics: colorLyrics,
        activeLineIndex: activeLineIndex,
        onTapHeader: onTapLyrics,
      );
    });

    register<CreatorBioCardDescriptor>((context, desc) {
      return PlayerAboutArtistSection(
        key: ValueKey('bio_${desc.creatorUri}'),
        artistName: defaultArtistName,
        dataPool: dataPool,
        artistUri: desc.creatorUri,
      );
    });

    register<CreditsCardDescriptor>((context, desc) {
      return PlayerCreditsSection(
        key: ValueKey('credits_${desc.entityUri}'),
        artistName: defaultArtistName,
        dataPool: dataPool,
        trackUri: desc.entityUri,
        contributorUris: desc.contributorUris,
        onShowAll: onShowAllCredits,
      );
    });

    register<LiveEventsCardDescriptor>((context, desc) {
      return PlayerEventsSection(
        key: ValueKey('events_${desc.artistUri}'),
        artistName: defaultArtistName,
        dataPool: dataPool,
        artistUri: desc.artistUri,
        onShowAll: onShowAllEvents,
      );
    });

    register<MerchCardDescriptor>((context, desc) {
      return PlayerMerchSection(
        key: ValueKey('merch_${desc.entityUri}'),
        items: const [],
      );
    });
  }
}
