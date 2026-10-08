import 'dart:async';
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

  /// Local snapshot of traits for this subscription.
  /// Direct equivalent to Spotify Android `r1w.h`.
  final Map<CellKey, Trait> _localCache = {};

  /// Actively requested keys for this subscription.
  /// Direct equivalent to Spotify Android `r1w.g`.
  Set<CellKey> _activeKeys = {};

  /// Set of currently in-flight cell keys to prevent duplicate network requests.
  final Set<CellKey> _inFlight = {};

  bool _isDisposed = false;

  final void Function(Set<CellKey> failedKeys)? _onNetworkFailure;

  MetadataSubscription({
    ExtendedMetadataClient? client,
    required ExtendedMetadataDataSourceImpl dataSource,
    required void Function(List<CellKey> updatedKeys) onUpdate,
    void Function(Set<CellKey> failedKeys)? onNetworkFailure,
    Map<CellKey, Trait>? initialCacheSnapshot,
  })  : _client = client,
        _dataSource = dataSource,
        _onUpdate = onUpdate,
        _onNetworkFailure = onNetworkFailure {
    if (initialCacheSnapshot != null) {
      _localCache.addAll(initialCacheSnapshot);
    }
  }

  /// Direct 1:1 equivalent to Spotify Android's `r1w.a(Set)`.
  @override
  Map<CellKey, DataSourceResult<dynamic>> request(Set<CellKey> keys) {
    if (_isDisposed) return const {};

    _activeKeys = Set.of(keys);

    final results = <CellKey, DataSourceResult<dynamic>>{};
    final missingKeys = <CellKey>{};

    for (final key in keys) {
      final cachedTrait = _localCache[key] ?? _dataSource.getTrait(key);
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

  /// Dispatches network batch via ExtendedMetadataClient asynchronously.
  Future<void> _dispatchBatch(Set<CellKey> keysToFetch) async {
    final client = _client;
    if (client == null) return;

    _inFlight.addAll(keysToFetch);

    try {
      final result = await client.fetchCellsResult(keysToFetch);
      if (_isDisposed) return;

      if (result is NetworkFailure<Map<CellKey, Trait>>) {
        // If this is a transport glitch (timeout, offline, serverError, rateLimited),
        // DO NOT poison the cache with markUnavailable.
        // Leaving keys un-poisoned allows them to recover when network restores.
        _onNetworkFailure?.call(keysToFetch);
        return;
      }

      final fetchedCells =
          (result as NetworkSuccess<Map<CellKey, Trait>>).data;
      final updatedKeys = <CellKey>[];

      // Record fetched traits
      for (final entry in fetchedCells.entries) {
        _localCache[entry.key] = entry.value;
        updatedKeys.add(entry.key);
      }

      // Record unavailable traits ONLY for keys confirmed empty by successful backend response
      for (final key in keysToFetch) {
        if (!fetchedCells.containsKey(key)) {
          _dataSource.markUnavailable(key);
        }
      }

      if (fetchedCells.isNotEmpty) {
        _dataSource.f(fetchedCells);
        _onUpdate(updatedKeys);
      }
    } catch (_) {
      // Non-critical network failure
      _onNetworkFailure?.call(keysToFetch);
    } finally {
      _inFlight.removeAll(keysToFetch);
    }
  }

  /// Called when parent DataSource receives traits (e.g. from Casita eagerload warmup).
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
