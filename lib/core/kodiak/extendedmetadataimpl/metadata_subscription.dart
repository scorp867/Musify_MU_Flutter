import 'dart:async';
import 'dart:developer' as dev;

import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_client.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_data_source.dart';
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/core/kodiak/table/data_source_result.dart';
import 'package:musify_mu/core/kodiak/table/data_source_subscription.dart';
import 'package:musify_mu/core/network/result/network_result.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Subscription managing element trait queries and dispatching batch network requests.
/// Direct 1:1 equivalent to Spotify Android's `p.r1w` (`MetadataSubscription`).
class MetadataSubscription implements DataSourceSubscription {
  final ExtendedMetadataClient? _client;
  final ExtendedMetadataDataSourceImpl _dataSource;
  final void Function(List<CellKey> updatedKeys) _onUpdate;

  final Map<CellKey, Trait> _localCache = {};
  Set<CellKey> _activeKeys = {};
  final Set<CellKey> _inFlight = {};
  bool _isDisposed = false;

  final void Function(Set<CellKey> failedKeys)? _onNetworkFailure;

  MetadataSubscription({
    ExtendedMetadataClient? client,
    required ExtendedMetadataDataSourceImpl dataSource,
    required void Function(List<CellKey> updatedKeys) onUpdate,
    void Function(Set<CellKey> failedKeys)? onNetworkFailure,
    Map<CellKey, Trait>? initialCacheSnapshot,
  }) : _client = client,
       _dataSource = dataSource,
       _onUpdate = onUpdate,
       _onNetworkFailure = onNetworkFailure {
    if (initialCacheSnapshot != null) {
      _localCache.addAll(initialCacheSnapshot);
    }
  }

  @override
  Map<CellKey, DataSourceResult<Trait>> request(Set<CellKey> keys) {
    if (_isDisposed) return const {};

    _activeKeys = Set.of(keys);

    final results = <CellKey, DataSourceResult<Trait>>{};
    final missingKeys = <CellKey>{};

    for (final key in keys) {
      Trait? cachedTrait = _localCache[key];
      cachedTrait ??= _dataSource.getTrait(key);
      if (cachedTrait != null) {
        _localCache[key] = cachedTrait;
        results[key] = Available(cachedTrait);
      } else {
        results[key] = const NotAvailable();
        if (!_inFlight.contains(key)) {
          missingKeys.add(key);
        }
      }
    }

    if (missingKeys.isNotEmpty) {
      _dispatchBatch(missingKeys);
    }

    return results;
  }

  Future<void> _dispatchBatch(Set<CellKey> keysToFetch) async {
    final client = _client;
    if (client == null) return;

    _inFlight.addAll(keysToFetch);

    try {
      final result = await client.fetchCellsRawResult(keysToFetch);
      if (_isDisposed) return;

      switch (result) {
        case NetworkFailure():
          _onNetworkFailure?.call(keysToFetch);
          return;

        case NetworkSuccess(:final data):
          final fetchedCells = data.cells;
          final rawPayloads = data.rawPayloads;
          if (rawPayloads.isNotEmpty) {
            _dataSource.ingestRawPayloads(rawPayloads);
          }

          final updatedKeys = <CellKey>[];
          for (final entry in fetchedCells.entries) {
            _localCache[entry.key] = entry.value;
            updatedKeys.add(entry.key);
          }

          final resolvedNegativeKeys = <CellKey>[];
          for (final key in keysToFetch) {
            if (!fetchedCells.containsKey(key)) {
              _dataSource.markUnavailable(key);
              resolvedNegativeKeys.add(key);
            }
          }

          if (fetchedCells.isNotEmpty) {
            _dataSource.f(fetchedCells);
            _onUpdate([...updatedKeys, ...resolvedNegativeKeys]);
          } else if (resolvedNegativeKeys.isNotEmpty) {
            _onUpdate(resolvedNegativeKeys);
          }
      }
    } catch (e, stack) {
      dev.log(
        '[MetadataSubscription] Batch dispatch failed: $e',
        name: 'Metadata',
        error: e,
        stackTrace: stack,
      );
      _onNetworkFailure?.call(keysToFetch);
    } finally {
      _inFlight.removeAll(keysToFetch);
    }
  }

  void onDataSourceUpdated(List<CellKey> updatedKeys) {
    if (_isDisposed) return;

    final relevant = <CellKey>[];
    for (final key in updatedKeys) {
      final fresh = _dataSource.getTrait(key);
      if (fresh != null) {
        _localCache[key] = fresh;
        if (_activeKeys.contains(key)) {
          relevant.add(key);
        }
      }
    }

    if (relevant.isNotEmpty) {
      _onUpdate(relevant);
    }
  }

  @override
  void invalidate(Set<CellKey> keys) {
    for (final key in keys) {
      _localCache.remove(key);
      _activeKeys.remove(key);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _dataSource.removeSubscription(this);
  }

  void cancel() => dispose();
}
