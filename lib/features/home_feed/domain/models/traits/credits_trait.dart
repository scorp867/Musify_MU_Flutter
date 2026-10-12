import 'trait.dart';

/// A single contributor on a track (artist, writer, producer, etc.).
class CreditContributor {
  final String name;
  final String role;
  final String uri;
  final String url;
  final String roleGroupName;

  const CreditContributor({
    required this.name,
    this.role = '',
    this.uri = '',
    this.url = '',
    this.roleGroupName = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'role': role,
    if (uri.isNotEmpty) 'uri': uri,
    if (url.isNotEmpty) 'url': url,
    if (roleGroupName.isNotEmpty) 'roleGroupName': roleGroupName,
  };

  factory CreditContributor.fromJson(Map<String, dynamic> json) =>
      CreditContributor(
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? '',
        uri: json['uri'] as String? ?? '',
        url: json['url'] as String? ?? '',
        roleGroupName: json['roleGroupName'] as String? ?? '',
      );
}

/// ExtensionKind 186 (CREDITS_V2_TRAIT).
/// Equivalent to Spotify Android's `bmk`.
class CreditsTrait extends Trait {
  final List<CreditContributor> contributors;
  final List<String> sourceNames;

  const CreditsTrait({
    this.contributors = const [],
    this.sourceNames = const [],
  });

  @override
  Map<String, dynamic> toJson() => {
    'contributors': contributors.map((c) => c.toJson()).toList(),
    'sourceNames': sourceNames,
  };

  factory CreditsTrait.fromJson(Map<String, dynamic> json) => CreditsTrait(
    contributors: (json['contributors'] as List<dynamic>?)
            ?.map((e) =>
                CreditContributor.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    sourceNames: (json['sourceNames'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
  );
}
