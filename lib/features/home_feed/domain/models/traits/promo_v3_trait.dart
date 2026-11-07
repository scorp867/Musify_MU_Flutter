import 'package:flutter/foundation.dart';

import 'trait.dart';

/// Promotion V3 card trait (ExtensionKind 171).
@immutable
final class PromoV3Trait extends Trait {
  final String title;
  final String? imageUrl;
  final String actionUri;

  const PromoV3Trait({
    required this.title,
    this.imageUrl,
    this.actionUri = '',
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PromoV3Trait &&
        other.title == title &&
        other.imageUrl == imageUrl &&
        other.actionUri == actionUri;
  }

  @override
  int get hashCode => Object.hash(title, imageUrl, actionUri);
}
