import 'package:flutter/foundation.dart';

import 'trait.dart';

/// ExtensionKind 97 (SIMPLE_TRAIT).
/// Equivalent to Spotify Android's `c6y0` / `e6y0`.
@immutable
final class SimpleCardTrait extends Trait {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? navigationUri;
  final String? accessibility;

  const SimpleCardTrait({
    required this.title,
    this.subtitle = '',
    this.imageUrl,
    this.navigationUri,
    this.accessibility,
  });
}
