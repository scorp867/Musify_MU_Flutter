import 'package:flutter/foundation.dart';

import 'trait.dart';

/// Promotion V1 banner trait (ExtensionKind 167).
@immutable
final class PromoV1Trait extends Trait {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String actionText;
  final String actionUri;

  const PromoV1Trait({
    required this.title,
    this.subtitle = '',
    this.imageUrl,
    this.actionText = '',
    this.actionUri = '',
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PromoV1Trait &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.imageUrl == imageUrl &&
        other.actionText == actionText &&
        other.actionUri == actionUri;
  }

  @override
  int get hashCode =>
      Object.hash(title, subtitle, imageUrl, actionText, actionUri);
}
