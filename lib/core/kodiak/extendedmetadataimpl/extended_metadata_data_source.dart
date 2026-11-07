import 'dart:typed_data';

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

  /// Global in-memory cache of resolved traits (`t1w.d`).
  final Map<CellKey, Trait> _cellStore = {};

  /// Raw binary Protobuf extension payloads indexed by `(extensionKind, entityUri)`.
  final Map<(int, String), Uint8List> _rawPayloads = {};

  /// Set of resolved cell keys confirmed unavailable from backend.
  final Set<CellKey> _unavailableCells = {};

  /// Active subscriptions (`t1w.c`).
  final List<MetadataSubscription> _subscriptions = [];

  ExtendedMetadataDataSourceImpl({ExtendedMetadataClient? client})
    : _client = client;

  ExtendedMetadataClient? get client => _client;

  Map<(int, String), Uint8List> get rawPayloads => _rawPayloads;

  Set<CellKey> get unavailableCells => _unavailableCells;

  void ingestRawPayloads(Map<(int, String), Uint8List> raw) {
    if (raw.isEmpty) return;
    _rawPayloads.addAll(raw);
  }

  /// Ingests eager traits or external batches into the global cache (`t1w.f(Map)`).
  void f(Map<CellKey, Trait> eagerMap) {
    if (eagerMap.isEmpty) return;

    _cellStore.addAll(eagerMap);

    final updatedKeys = eagerMap.keys.toList();
    for (final sub in List<MetadataSubscription>.from(_subscriptions)) {
      sub.onDataSourceUpdated(updatedKeys);
    }
  }

  @override
  DataSourceSubscription subscribe(
    void Function(List<CellKey> updatedKeys) onUpdate, {
    void Function(Set<CellKey> failedKeys)? onNetworkFailure,
  }) {
    final sub = MetadataSubscription(
      client: _client,
      dataSource: this,
      onUpdate: onUpdate,
      onNetworkFailure: onNetworkFailure,
      initialCacheSnapshot: Map.unmodifiable(_cellStore),
    );
    _subscriptions.add(sub);
    return sub;
  }

  void removeSubscription(MetadataSubscription sub) {
    _subscriptions.remove(sub);
  }

  /// Synchronous cache query (`t1w.c(Set)`).
  @override
  Map<CellKey, DataSourceResult<Trait>> getCached(Set<CellKey> keys) {
    final results = <CellKey, DataSourceResult<Trait>>{};

    for (final key in keys) {
      final value = _cellStore[key];
      if (value != null) {
        results[key] = Available(value);
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
      if (_client?.registry.pluginForType(key.table.traitType)
          case final plugin?) {
        _rawPayloads.remove((plugin.extensionKindValue, key.entityUri));
      }
    }
  }

  @override
  bool supports(CellKey key) {
    return _client?.registry.pluginForType(key.table.traitType) != null;
  }

  /// Direct cache read for synchronous inspection.
  T? getTrait<T extends Trait>(CellKey key) {
    final value = _cellStore[key];
    if (value is T) return value;
    return null;
  }

  void dispose() {
    _subscriptions.clear();
  }
}
