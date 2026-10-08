import 'dart:async';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/dataloader/kodiak_disk_cache.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_data_source.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/plugins/builtin_plugins.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/core/kodiak/table/data_source_subscription.dart';
import 'package:musify_mu/core/kodiak/table/table_key.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Concrete implementation of Kodiak DataPool.
/// Direct 1:1 equivalent to Spotify Android's `p.s3n` (`DataPoolImpl`).
class DataPoolImpl implements DataPool {
  final ExtendedMetadataDataSourceImpl _dataSource;
  final KodiakDiskCache? _diskCache;
  final NetworkMonitorService? _networkMonitor;
  final ExtendedMetadataPluginRegistry? _pluginRegistry;

  /// In-memory trait store: URI -> { TraitTypeName -> Trait }
  /// Direct equivalent to Spotify Android `s3n.i` (`iur0`).
  final Map<String, Map<String, Trait>> _store = {};

  /// Tracks resolved extension kinds per URI to avoid duplicate querying.
  final Map<String, Set<int>> _resolvedKinds = {};

  /// Reactive stream controllers per URI for live UI updates.
  final Map<String, StreamController<Map<String, Trait>>> _controllers = {};

  /// Active subscription to the ExtendedMetadataDataSource.
  /// Direct equivalent to Spotify Android `s3n.h` (`fk51`).
  late final DataSourceSubscription _subscription;

  /// Pending batched cell keys to query.
  /// Direct equivalent to Spotify Android `s3n.j` (`LinkedHashSet`).
  final Set<CellKey> _pendingBatch = {};

  /// Failed cell keys awaiting network restoration to retry.
  final Set<CellKey> _failedRetryKeys = {};

  StreamSubscription<NetworkStatus>? _networkSubscription;
  Timer? _debounceTimer;
  Timer? _retryDebounceTimer;
  bool _diskLoaded = false;
  bool _isDisposed = false;

  ExtendedMetadataPluginRegistry get _effectiveRegistry =>
      _pluginRegistry ??
      _dataSource.client?.registry ??
      _fallbackRegistry;

  static final _fallbackRegistry = ExtendedMetadataPluginRegistry(
    createDefaultExtendedMetadataPlugins(),
  );

  DataPoolImpl({
    required ExtendedMetadataDataSourceImpl dataSource,
    KodiakDiskCache? diskCache,
    NetworkMonitorService? networkMonitor,
    ExtendedMetadataPluginRegistry? registry,
  })  : _dataSource = dataSource,
        _diskCache = diskCache,
        _networkMonitor = networkMonitor,
        _pluginRegistry = registry {
    _subscription = _dataSource.subscribe(
      _onDataSourceUpdated,
      onNetworkFailure: _onNetworkFailure,
    );
    _initNetworkListener();
  }

  @override
  Future<void> ensureDiskLoaded() async {
    if (_diskLoaded || _diskCache == null) return;
    _diskLoaded = true;

    final cached = await _diskCache.load();
    if (cached != null) {
      for (final entry in cached.traits.entries) {
        final existing = _store.putIfAbsent(entry.key, () => {});
        existing.addAll(entry.value);
      }
      for (final entry in cached.resolvedKinds.entries) {
        final existing = _resolvedKinds.putIfAbsent(entry.key, () => {});
        existing.addAll(entry.value);
      }
    }
  }

  @override
  T? getTrait<T extends Trait>(String uri) {
    // 1. Check local in-memory store
    final uriTraits = _store[uri];
    if (uriTraits != null) {
      final t = uriTraits[T.toString()];
      if (t is T) return t;
    }

    // 2. Fall back to underlying DataSource
    final cellKey = CellKey(TableKey<T>(), uri);
    final trait = _dataSource.getTrait<T>(cellKey);
    if (trait != null) {
      _store.putIfAbsent(uri, () => {})[T.toString()] = trait;
      return trait;
    }

    return null;
  }

  @override
  Map<String, Trait>? getTraits(String uri) => _store[uri];

  @override
  bool hasRequiredTraits(String uri, DataStatement statement) {
    final uriTraits = _store[uri];
    if (uriTraits == null) return false;

    for (final req in statement.requiredRequirements) {
      if (!uriTraits.containsKey(req.traitType.toString())) {
        return false;
      }
    }
    return true;
  }

  @override
  bool isKindResolved(String uri, int kind) {
    return _resolvedKinds[uri]?.contains(kind) ?? false;
  }

  @override
  Stream<Map<String, Trait>> watchEntity(String uri) {
    final controller = _controllers.putIfAbsent(
      uri,
      () => StreamController<Map<String, Trait>>.broadcast(),
    );

    final current = _store[uri];
    if (current != null) {
      Timer.run(() {
        if (!controller.isClosed) controller.add(Map.unmodifiable(current));
      });
    }
    return controller.stream;
  }

  @override
  void ingestTraits(String uri, Map<String, Trait> traits) {
    if (uri.isEmpty || traits.isEmpty) return;

    final existing = _store.putIfAbsent(uri, () => {});
    existing.addAll(traits);
    _notify(uri);
    _schedulePersist();
  }

  @override
  void ingestBatch(Map<String, Map<String, Trait>> batch) {
    for (final entry in batch.entries) {
      if (entry.key.isEmpty || entry.value.isEmpty) continue;
      final existing = _store.putIfAbsent(entry.key, () => {});
      existing.addAll(entry.value);
      _notify(entry.key);
    }
    _schedulePersist();
  }

  @override
  void ingestCells(Map<CellKey, Trait> cells) {
    _dataSource.f(cells);
    for (final entry in cells.entries) {
      final uri = entry.key.entityUri;
      final trait = entry.value;
      _store.putIfAbsent(uri, () => {})[trait.runtimeType.toString()] = trait;
      final plugin = _effectiveRegistry.pluginForType(
        entry.key.table.traitType,
      );
      if (plugin != null) {
        _resolvedKinds
            .putIfAbsent(uri, () => {})
            .add(plugin.extensionKindValue);
      }
      _failedRetryKeys.remove(entry.key);
      _notify(uri);
    }
    _schedulePersist();
  }

  @override
  Future<void> loadBatch({
    required List<String> uris,
    required DataStatement statement,
  }) async {
    await ensureDiskLoaded();

    final keysToRequest = <CellKey>{};

    for (final uri in uris) {
      if (uri.isEmpty) continue;

      final existingTraits = _store[uri] ?? const {};
      final resolvedForUri = _resolvedKinds[uri] ?? const {};

      for (final req in statement.requirements) {
        final traitName = req.traitType.toString();
        final kind = req.extensionKindValue;

        if (!existingTraits.containsKey(traitName) &&
            !resolvedForUri.contains(kind)) {
          final cellKey = CellKey(TableKey(req.traitType), uri);
          keysToRequest.add(cellKey);
        }
      }
    }

    if (keysToRequest.isEmpty) return;

    // Direct equivalent to Spotify Android s3n.c() -> subscription.request()
    _pendingBatch.addAll(keysToRequest);
    _scheduleBatch();
  }

  /// Debounces and dispatches batched queries to the subscription.
  /// Direct equivalent to Spotify Android `s3n.n()` posted to looper via `r3n`.
  void _scheduleBatch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 16), () {
      if (_isDisposed || _pendingBatch.isEmpty) return;

      final batch = Set<CellKey>.of(_pendingBatch);
      _pendingBatch.clear();

      _subscription.request(batch);
      _schedulePersist();
    });
  }

  /// Callback when DataSource resolves traits.
  void _onDataSourceUpdated(List<CellKey> updatedKeys) {
    if (_isDisposed) return;

    final touchedUris = <String>{};

    for (final cellKey in updatedKeys) {
      final uri = cellKey.entityUri;
      final trait = _dataSource.getTrait(cellKey);
      if (trait != null) {
        _store.putIfAbsent(uri, () => {})[trait.runtimeType.toString()] = trait;
        final plugin = _effectiveRegistry.pluginForType(
          cellKey.table.traitType,
        );
        if (plugin != null) {
          _resolvedKinds
              .putIfAbsent(uri, () => {})
              .add(plugin.extensionKindValue);
        }
        _failedRetryKeys.remove(cellKey);
        touchedUris.add(uri);
      }
    }

    for (final uri in touchedUris) {
      _notify(uri);
    }

    _schedulePersist();
  }

  void _onNetworkFailure(Set<CellKey> failedKeys) {
    if (_isDisposed) return;
    _failedRetryKeys.addAll(failedKeys);
  }

  void _initNetworkListener() {
    final monitor = _networkMonitor;
    if (monitor == null) return;

    _networkSubscription = monitor.statusStream.listen((status) {
      if (_isDisposed) return;
      if (status == NetworkStatus.restored || status == NetworkStatus.online) {
        _scheduleRetry();
      }
    });
  }

  void _scheduleRetry() {
    _retryDebounceTimer?.cancel();
    _retryDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (_isDisposed || _failedRetryKeys.isEmpty) return;
      final retryBatch = Set<CellKey>.of(_failedRetryKeys);
      _failedRetryKeys.clear();
      _subscription.request(retryBatch);
    });
  }

  void _schedulePersist() {
    _diskCache?.scheduleSave(traits: _store, resolvedKinds: _resolvedKinds);
  }

  void _notify(String uri) {
    final controller = _controllers[uri];
    if (controller != null && !controller.isClosed) {
      final traits = _store[uri] ?? const {};
      controller.add(Map.unmodifiable(traits));
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _retryDebounceTimer?.cancel();
    _networkSubscription?.cancel();
    _subscription.dispose();
    _diskCache?.dispose();
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
    _store.clear();
    _resolvedKinds.clear();
    _pendingBatch.clear();
    _failedRetryKeys.clear();
  }
}
