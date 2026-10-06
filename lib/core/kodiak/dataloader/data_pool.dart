import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Central Kodiak SDUI DataPool contract.
/// Direct 1:1 equivalent to Spotify Android's `com.spotify.kodiak.dataloader.DataPool`.
abstract interface class DataPool {
  /// Ensures offline disk cache is loaded into memory.
  Future<void> ensureDiskLoaded();

  /// Synchronously gets a specific typed trait for an entity URI.
  T? getTrait<T extends Trait>(String uri);

  /// Synchronously gets all known traits for an entity URI.
  Map<String, Trait>? getTraits(String uri);

  /// Checks whether an entity URI has all required traits declared by a DataStatement.
  bool hasRequiredTraits(String uri, DataStatement statement);

  /// Checks whether an extension kind has already been queried and resolved for an entity URI.
  bool isKindResolved(String uri, int kind);

  /// Reactive stream listening for trait updates on a specific URI.
  Stream<Map<String, Trait>> watchEntity(String uri);

  /// Ingests pre-loaded traits (e.g. from Casita's eagerlyLoadedTraits).
  void ingestTraits(String uri, Map<String, Trait> traits);

  /// Ingests a batch of pre-loaded traits.
  void ingestBatch(Map<String, Map<String, Trait>> batch);

  /// Ingests typed cell keys directly into the underlying DataSource.
  void ingestCells(Map<CellKey, Trait> cells);

  /// Element/viewport-scoped batch loader.
  /// Identifies missing traits for the given URIs according to the DataStatement
  /// and queries the underlying DataSource.
  Future<void> loadBatch({
    required List<String> uris,
    required DataStatement statement,
  });

  /// Releases resources and closes stream controllers.
  void dispose();
}
