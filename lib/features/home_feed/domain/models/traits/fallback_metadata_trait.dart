import 'package:flutter/foundation.dart';

import 'trait.dart';

@immutable
final class FallbackMetadataTrait extends Trait {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? extractedColor;
  final String? badge;

  const FallbackMetadataTrait({
    required this.title,
    this.subtitle = '',
    this.imageUrl,
    this.extractedColor,
    this.badge,
  });
}
