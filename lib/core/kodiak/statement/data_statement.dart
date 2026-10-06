import 'package:musify_mu/core/kodiak/statement/data_requirement.dart';

/// Immutable declaration of required and optional traits for a Kodiak element.
/// Direct equivalent to Spotify Android's `com.spotify.kodiak.dataloader.statement.DataStatement`.
class DataStatement {
  final List<DataRequirement> requirements;

  const DataStatement(this.requirements);

  /// All required (Level 1) traits for the element.
  List<DataRequirement> get requiredRequirements =>
      requirements.where((r) => r.isRequired).toList();

  /// All optional (Level 2) traits for the element.
  List<DataRequirement> get optionalRequirements =>
      requirements.where((r) => r.isOptional).toList();

  /// List of all extension kind integers required by this statement.
  List<int> get extensionKindValues =>
      requirements.map((r) => r.extensionKindValue).toList();

  /// Checks if this statement contains a specific trait requirement.
  bool hasKind(int kind) =>
      requirements.any((r) => r.extensionKindValue == kind);

  /// Checks if this statement requires a specific trait type.
  bool hasTraitType(Type type) => requirements.any((r) => r.traitType == type);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataStatement &&
          runtimeType == other.runtimeType &&
          requirements.length == other.requirements.length &&
          requirements.every((r) => other.requirements.contains(r));

  @override
  int get hashCode => Object.hashAll(requirements);

  @override
  String toString() => 'DataStatement(${requirements.length} traits)';
}
