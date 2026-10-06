import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/core/kodiak/table/data_source_result.dart';
import 'package:musify_mu/core/kodiak/table/data_source_subscription.dart';

/// Central data provider contract for the Kodiak framework.
/// Direct 1:1 equivalent to Spotify Android's `p.gk51` (`DataSource`).
abstract interface class DataSource {
  /// Registers an active subscription callback for changes in cells.
  DataSourceSubscription subscribe(void Function(List<CellKey> updatedKeys) onUpdate);

  /// Synchronously checks the cache for the specified set of cell keys.
  Map<CellKey, DataSourceResult<dynamic>> getCached(Set<CellKey> keys);

  /// Checks whether this DataSource supports the given cell key.
  bool supports(CellKey key);
}
