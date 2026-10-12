import 'package:flutter/widgets.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';

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
  void register<T extends ScrollCardDescriptor>(ScrollCardWidgetBuilder<T> builder) {
    _builders[T] = (context, descriptor) => builder(context, descriptor as T);
  }

  /// Builds the widget for the given descriptor, or returns null if not registered.
  Widget? buildCard(BuildContext context, ScrollCardDescriptor descriptor) {
    final builder = _builders[descriptor.runtimeType];
    return builder?.call(context, descriptor);
  }
}
