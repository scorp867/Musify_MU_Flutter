import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/core/kodiak/table/data_source_result.dart';

/// Subscription to a Kodiak DataSource.
/// Direct 1:1 equivalent to Spotify Android's `p.fk51` (`DataSourceSubscription`).
abstract interface class DataSourceSubscription {
  /// Queries and registers observation for the specified set of cell keys.
  /// Synchronously returns current availability for each key.
  Map<CellKey, DataSourceResult<dynamic>> request(Set<CellKey> keys);

  /// Invalidates cached state for the given keys.
  void invalidate(Set<CellKey> keys);

  /// Disposes the subscription and releases all active resources/in-flight calls.
  void dispose();
}
