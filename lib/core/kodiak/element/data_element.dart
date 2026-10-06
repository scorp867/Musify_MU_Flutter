import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';

/// Contract for all Kodiak data-driven elements.
/// Direct equivalent to Spotify Android's `com.spotify.kodiak.element.compose.DataElement`
/// and `p.u091` / `p.v2n`.
abstract class DataElement {
  /// Unique identifier of this element.
  String get id;

  /// The declarative DataStatement specifying required & optional traits.
  DataStatement get dataStatement;

  /// The DataPool providing cached and asynchronously loaded traits.
  DataPool get dataPool;
}
