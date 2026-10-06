import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_client.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/metadata_subscription.dart';
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/core/kodiak/table/data_source.dart';
import 'package:musify_mu/core/kodiak/table/data_source_result.dart';
import 'package:musify_mu/core/kodiak/table/data_source_subscription.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Central Kodiak DataSource for Spotify Extended Metadata.
/// Direct 1:1 equivalent to Spotify Android's `p.t1w` (`ExtendedMetadataDataSourceImpl`).
class ExtendedMetadataDataSourceImpl implements DataSource {
  final ExtendedMetadataClient? _client;

  /// Global in-memory cache of resolved traits.
  /// Direct equivalent to Spotify Android `t1w.d` (`ConcurrentHashMap`).
  final Map<CellKey, Trait> _cellStore = {};

  /// Set of resolved cell keys that have been confirmed unavailable from backend.
  /// Prevents infinite viewport re-fetching.
  final Set<CellKey> _unavailableCells = {};

  /// Active subscriptions.
  /// Direct equivalent to Spotify Android `t1w.c` (`CopyOnWriteArrayList`).
  final List<MetadataSubscription> _subscriptions = [];

  ExtendedMetadataDataSourceImpl({
    ExtendedMetadataClient? client,
  }) : _client = client;

  ExtendedMetadataClient? get client => _client;

  /// Ingests eager traits or external batches into the global cache.
  /// Direct 1:1 equivalent to Spotify Android's `t1w.f(Map)`.
  /// Called right after Casita response is parsed for 0ms cache warmup.
  void f(Map<CellKey, Trait> eagerMap) {
    if (eagerMap.isEmpty) return;

    _cellStore.addAll(eagerMap);

    // Notify all active subscriptions with the updated keys
    final updatedKeys = eagerMap.keys.toList();
    for (final sub in List<MetadataSubscription>.from(_subscriptions)) {
      sub.onDataSourceUpdated(updatedKeys);
    }
  }

  @override
  DataSourceSubscription subscribe(
    void Function(List<CellKey> updatedKeys) onUpdate,
  ) {
    final sub = MetadataSubscription(
      client: _client,
      dataSource: this,
      onUpdate: onUpdate,
      initialCacheSnapshot: Map.unmodifiable(_cellStore),
    );
    _subscriptions.add(sub);
    return sub;
  }

  void removeSubscription(MetadataSubscription sub) {
    _subscriptions.remove(sub);
  }

  /// Synchronous cache query.
  /// Direct 1:1 equivalent to Spotify Android's `t1w.c(Set)`.
  @override
  Map<CellKey, DataSourceResult<dynamic>> getCached(Set<CellKey> keys) {
    final results = <CellKey, DataSourceResult<dynamic>>{};

    for (final key in keys) {
      final value = _cellStore[key];
      if (value != null) {
        results[key] = Available(value);
      } else if (_unavailableCells.contains(key)) {
        results[key] = const NotAvailable();
      } else {
        results[key] = const NotAvailable();
      }
    }

    return results;
  }

  /// Records that remote backend returned no trait for this key.
  void markUnavailable(CellKey key) {
    _unavailableCells.add(key);
  }

  /// Invalidates specified keys from cache.
  void invalidate(Set<CellKey> keys) {
    for (final key in keys) {
      _cellStore.remove(key);
      _unavailableCells.remove(key);
    }
  }

  @override
  bool supports(CellKey key) {
    return _client?.registry.pluginForType(key.table.traitType) != null;
  }

  /// Direct cache read for synchronous inspection.
  T? getTrait<T extends Trait>(CellKey key) => _cellStore[key] as T?;

  void dispose() {
    _subscriptions.clear();
  }
}
