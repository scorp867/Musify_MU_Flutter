import 'package:musify_mu/core/kodiak/table/table_key.dart';

/// Uniquely identifies a single cell in the Kodiak SDUI cache.
/// Formed by combining a table identifier (`TableKey`) with an entity URI.
/// Direct 1:1 equivalent to Spotify Android's `p.vq4`.
class CellKey {
  final TableKey table;
  final String entityUri;
  final int _hash;

  CellKey(this.table, this.entityUri)
      : _hash = entityUri.hashCode ^ (table.hashCode * 31);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellKey &&
          runtimeType == other.runtimeType &&
          table == other.table &&
          entityUri == other.entityUri;

  @override
  int get hashCode => _hash;

  @override
  String toString() => 'CellKey(${table.traitType}, $entityUri)';
}
