import 'dart:async';
import 'package:musify_mu/core/kodiak/dataloader/kodiak_disk_cache.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/features/home_feed/data/extended_metadata_fetcher.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Central reactive in-memory trait repository and query coordinator.
/// Direct equivalent to Spotify Android's `com.spotify.kodiak.dataloader.DataPool`.
class DataPool {
  /// URI -> { traitTypeName -> Trait }
  final Map<String, Map<String, Trait>> _store = {};

  /// Tracks queried and resolved ExtensionKind values per URI.
  /// Mirroring Spotify Android Kodiak's cell status (bhc0.java / xgc0.java),
  /// once an extension kind has been queried from ExtendedMetadata, even if
  /// the server returns no trait for it (e.g. SHOW_ACCESS for music albums),
  /// it is marked as resolved so viewport scrolls don't repeatedly re-query.
  final Map<String, Set<int>> _resolvedKinds = {};

  /// Tracks active in-flight requests: URI -> `Set<ExtensionKindValue>`
  final Map<String, Set<int>> _inFlight = {};

  /// Reactive stream controllers per URI for live UI updates.
  final Map<String, StreamController<Map<String, Trait>>> _controllers = {};

  final ExtendedMetadataFetcher? _fetcher;
  final KodiakDiskCache? _diskCache;

  bool _diskLoaded = false;

  DataPool({
    ExtendedMetadataFetcher? fetcher,
    KodiakDiskCache? diskCache,
  })  : _fetcher = fetcher,
        _diskCache = diskCache;

  /// Loads persisted traits and resolution statuses from disk cache.
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

  /// Ingests pre-loaded traits (e.g. from Casita's eagerlyLoadedTraits).
  void ingestTraits(String uri, Map<String, Trait> traits) {
    if (uri.isEmpty || traits.isEmpty) return;

    final existing = _store.putIfAbsent(uri, () => {});
    existing.addAll(traits);
    _notify(uri);
    _schedulePersist();
  }

  /// Ingests a batch of pre-loaded traits.
  void ingestBatch(Map<String, Map<String, Trait>> batch) {
    for (final entry in batch.entries) {
      if (entry.key.isEmpty || entry.value.isEmpty) continue;
      final existing = _store.putIfAbsent(entry.key, () => {});
      existing.addAll(entry.value);
      _notify(entry.key);
    }
    _schedulePersist();
  }

  /// Synchronously gets all known traits for an entity URI.
  Map<String, Trait>? getTraits(String uri) => _store[uri];

  /// Synchronously gets a specific typed trait for an entity URI.
  T? getTrait<T extends Trait>(String uri) {
    final uriTraits = _store[uri];
    if (uriTraits == null) return null;
    return uriTraits[T.toString()] as T?;
  }

  /// Checks whether an extension kind has already been queried and resolved for an entity URI.
  bool isKindResolved(String uri, int kind) {
    return _resolvedKinds[uri]?.contains(kind) ?? false;
  }

  /// Reactive stream listening for trait updates on a specific URI.
  Stream<Map<String, Trait>> watchEntity(String uri) {
    final controller = _controllers.putIfAbsent(
      uri,
      () => StreamController<Map<String, Trait>>.broadcast(),
    );
    // Emit current value immediately if available
    final current = _store[uri];
    if (current != null) {
      Timer.run(() {
        if (!controller.isClosed) controller.add(Map.unmodifiable(current));
      });
    }
    return controller.stream;
  }

  /// Checks whether a URI has all required traits declared by a DataStatement.
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

  /// Viewport-scoped batch loader.
  /// Identifies missing required & optional traits for the given URIs,
  /// deduplicates in-flight requests, and queries ExtendedMetadataFetcher.
  Future<void> loadBatch({
    required List<String> uris,
    required DataStatement statement,
    ExtendedMetadataFetcher? fetcher,
  }) async {
    await ensureDiskLoaded();

    final activeFetcher = fetcher ?? _fetcher;
    if (activeFetcher == null) return;

    final Map<String, List<int>> entityQueries = {};

    for (final uri in uris) {
      if (uri.isEmpty) continue;

      final existingTraits = _store[uri] ?? const {};
      final inFlightForUri = _inFlight[uri] ?? const {};
      final resolvedForUri = _resolvedKinds[uri] ?? const {};

      final missingKinds = <int>[];
      for (final req in statement.requirements) {
        final traitName = req.traitType.toString();
        final kind = req.extensionKindValue;

        // Skip if trait is present, already resolved as unavailable from backend,
        // or currently in-flight
        if (!existingTraits.containsKey(traitName) &&
            !resolvedForUri.contains(kind) &&
            !inFlightForUri.contains(kind)) {
          missingKinds.add(kind);
        }
      }

      if (missingKinds.isNotEmpty) {
        entityQueries[uri] = missingKinds;
        _inFlight.putIfAbsent(uri, () => {}).addAll(missingKinds);
      }
    }

    if (entityQueries.isEmpty) return;

    try {
      final fetchedBatch = await activeFetcher.fetchEntityTraits(entityQueries);
      for (final entry in fetchedBatch.entries) {
        final uri = entry.key;
        final newTraits = entry.value;
        if (newTraits.isNotEmpty) {
          final existing = _store.putIfAbsent(uri, () => {});
          existing.addAll(newTraits);
          _notify(uri);
        }
      }

      // Record all queried kinds as resolved (mirroring Kodiak bhc0.java / xgc0.java NotAvailable cell state)
      for (final entry in entityQueries.entries) {
        final uri = entry.key;
        final queriedKinds = entry.value;
        _resolvedKinds.putIfAbsent(uri, () => {}).addAll(queriedKinds);
      }

      _schedulePersist();
    } finally {
      // Clear in-flight markers
      for (final entry in entityQueries.entries) {
        final uri = entry.key;
        _inFlight[uri]?.removeAll(entry.value);
        if (_inFlight[uri]?.isEmpty == true) {
          _inFlight.remove(uri);
        }
      }
    }
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

  void dispose() {
    _diskCache?.dispose();
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
    _store.clear();
    _resolvedKinds.clear();
    _inFlight.clear();
  }
}
