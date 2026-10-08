import 'trait.dart';

/// ExtensionKind 178 (IDENTITY_TRAIT).
/// Equivalent to Spotify Android's `k020`.
class IdentityTrait extends Trait {
  final String name;
  final String type;
  final String description;
  final List<String> contributors;
  final String? parentUri;
  final String? parentName;

  /// Compatibility getter for legacy callers expecting `title`.
  String get title => name;

  const IdentityTrait({
    required this.name,
    this.type = '',
    this.description = '',
    this.contributors = const [],
    this.parentUri,
    this.parentName,
  });

  /// Convenience constructor for title-only callers.
  factory IdentityTrait.fromTitle(String title) => IdentityTrait(name: title);

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'description': description,
    'contributors': contributors,
    if (parentUri != null) 'parentUri': parentUri,
    if (parentName != null) 'parentName': parentName,
  };

  factory IdentityTrait.fromJson(Map<String, dynamic> json) => IdentityTrait(
    name: json['name'] ?? json['title'] ?? '',
    type: json['type'] ?? '',
    description: json['description'] ?? '',
    contributors: (json['contributors'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    parentUri: json['parentUri'] as String?,
    parentName: json['parentName'] as String?,
  );
}
