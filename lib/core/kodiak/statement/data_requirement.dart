import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';

/// Priority level of a data requirement, matching Kodiak's levels:
/// - Level 1: Required (needed for base card layout & rendering)
/// - Level 2: Optional (enrichment traits: badges, visual identity, playback hooks, pricing)
enum DataPriority {
  required(1),
  optional(2);

  final int level;
  const DataPriority(this.level);
}

/// Represents a single trait requirement for a Kodiak DataElement.
/// Direct equivalent to Spotify Android's `p.y7n` / `p.l2t0` (`k2t0` / `j2t0`).
class DataRequirement {
  /// The integer ExtensionKind corresponding to the trait.
  final int extensionKindValue;

  /// The protobuf ExtensionKind enum if known.
  final ExtensionKind? extensionKind;

  /// Priority of this trait (Level 1 = Required, Level 2 = Optional).
  final DataPriority priority;

  /// The Dart model type of this trait (e.g. `SimpleCardTrait`).
  final Type traitType;

  const DataRequirement({
    required this.extensionKindValue,
    this.extensionKind,
    required this.priority,
    required this.traitType,
  });

  bool get isRequired => priority == DataPriority.required;
  bool get isOptional => priority == DataPriority.optional;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataRequirement &&
          runtimeType == other.runtimeType &&
          extensionKindValue == other.extensionKindValue &&
          priority == other.priority &&
          traitType == other.traitType;

  @override
  int get hashCode =>
      extensionKindValue.hashCode ^ priority.hashCode ^ traitType.hashCode;

  @override
  String toString() =>
      'DataRequirement(kind: $extensionKindValue, priority: ${priority.name}, type: $traitType)';
}
