import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/core/kodiak/table/table_key.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Maps nested entity trait maps into Kodiak CellKey flat maps.
/// Direct 1:1 equivalent to Spotify Android's `p.aba1.r`.
class KodiakCellMapper {
  /// Converts `EntityUri -> (TraitType -> Trait)` into `Map<CellKey, Trait>`.
  static Map<CellKey, Trait> map(Map<String, Map<Type, Trait>> traitsMap) {
    final cells = <CellKey, Trait>{};

    for (final entry in traitsMap.entries) {
      final uri = entry.key;
      for (final traitEntry in entry.value.entries) {
        final traitType = traitEntry.key;
        final trait = traitEntry.value;
        final cellKey = CellKey(TableKey(traitType), uri);
        cells[cellKey] = trait;
      }
    }

    return cells;
  }
}
