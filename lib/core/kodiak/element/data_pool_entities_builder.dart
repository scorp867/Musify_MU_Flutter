import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Lifecycle-safe reactive widget that subscribes to one or more entity URIs in
/// a Kodiak [DataPool] and triggers a scoped rebuild whenever any watched
/// entity's traits update.
///
/// Unlike creating a `StreamBuilder(stream: dataPool.watchEntity(uri))` inside
/// `build()`, subscriptions are bound once in [initState], updated only when
/// [dataPool] or the deduplicated URI list changes in [didUpdateWidget], and
/// deterministically canceled in [dispose].
class DataPoolEntitiesBuilder extends StatefulWidget {
  final DataPool? dataPool;
  final List<String> uris;
  final Widget Function(BuildContext context, DataPool? dataPool) builder;

  const DataPoolEntitiesBuilder({
    super.key,
    required this.dataPool,
    required this.uris,
    required this.builder,
  });

  @override
  State<DataPoolEntitiesBuilder> createState() =>
      _DataPoolEntitiesBuilderState();
}

class _DataPoolEntitiesBuilderState extends State<DataPoolEntitiesBuilder> {
  final List<StreamSubscription<Map<String, Trait>>> _subscriptions = [];
  List<String> _watchedUris = const [];

  @override
  void initState() {
    super.initState();
    _resubscribe();
  }

  @override
  void didUpdateWidget(covariant DataPoolEntitiesBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextUris = _normalizeUris(widget.uris);
    if (!identical(oldWidget.dataPool, widget.dataPool) ||
        !listEquals(_watchedUris, nextUris)) {
      _resubscribe(preNormalized: nextUris);
    }
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  List<String> _normalizeUris(List<String> raw) {
    final seen = <String>{};
    final result = <String>[];
    for (final uri in raw) {
      final trimmed = uri.trim();
      if (trimmed.isNotEmpty && seen.add(trimmed)) {
        result.add(trimmed);
      }
    }
    return result;
  }

  void _cancelSubscriptions() {
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
  }

  void _resubscribe({List<String>? preNormalized}) {
    _cancelSubscriptions();
    final uris = switch (preNormalized) {
      final normalized? => normalized,
      null => _normalizeUris(widget.uris),
    };
    _watchedUris = uris;

    final pool = widget.dataPool;
    if (pool == null || uris.isEmpty) {
      return;
    }

    for (final uri in uris) {
      _subscriptions.add(
        pool.watchEntity(uri).listen((_) {
          if (mounted) {
            setState(() {});
          }
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.dataPool);
  }
}
