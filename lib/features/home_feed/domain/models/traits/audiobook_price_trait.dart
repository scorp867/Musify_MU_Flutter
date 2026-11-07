import 'package:flutter/foundation.dart';

import 'trait.dart';

/// Audiobook pricing and purchase metadata (ExtensionKind 64).
@immutable
final class AudiobookPriceTrait extends Trait {
  final String formattedPrice;
  final String currency;
  final bool isPurchasable;

  const AudiobookPriceTrait({
    this.formattedPrice = '',
    this.currency = '',
    this.isPurchasable = false,
  });
}
