import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Uniquely identifies a typed trait table within the Kodiak framework.
/// Direct 1:1 equivalent to Spotify Android's `p.k2w` (`ExtendedMetadataTable<T>`).
class TableKey<T extends Trait> {
  final Type traitType;

  const TableKey([Type? type]) : traitType = type ?? T;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableKey && traitType == other.traitType;

  @override
  int get hashCode => traitType.hashCode;

  @override
  String toString() => 'TableKey<$traitType>';
}
