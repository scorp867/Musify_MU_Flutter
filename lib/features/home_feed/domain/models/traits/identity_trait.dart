import 'package:flutter/foundation.dart';

import 'trait.dart';

/// ExtensionKind 178 (IDENTITY_TRAIT).
/// Equivalent to Spotify Android's `k020`.
@immutable
final class IdentityTrait extends Trait {
  final String name;
  final String type;
  final String description;
  final List<String> contributors;
  final String? parentUri;
  final String? parentName;

  String get title => name;

  const IdentityTrait({
    required this.name,
    this.type = '',
    this.description = '',
    this.contributors = const [],
    this.parentUri,
    this.parentName,
  });

  factory IdentityTrait.fromTitle(String title) => IdentityTrait(name: title);
}
