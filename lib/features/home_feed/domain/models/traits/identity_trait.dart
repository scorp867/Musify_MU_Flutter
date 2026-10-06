import 'trait.dart';

/// ExtensionKind 178 (IDENTITY_TRAIT).
/// Equivalent to Spotify Android's `k020`.
class IdentityTrait extends Trait {
  final String name;
  final String type;
  final String description;

  /// Compatibility getter for legacy callers expecting `title`.
  String get title => name;

  const IdentityTrait({
    required this.name,
    this.type = '',
    this.description = '',
  });

  /// Convenience constructor for title-only callers.
  factory IdentityTrait.fromTitle(String title) => IdentityTrait(name: title);

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'description': description,
  };

  factory IdentityTrait.fromJson(Map<String, dynamic> json) => IdentityTrait(
    name: json['name'] ?? json['title'] ?? '',
    type: json['type'] ?? '',
    description: json['description'] ?? '',
  );
}
