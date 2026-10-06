import 'trait.dart';

/// Audiobook pricing and purchase metadata (ExtensionKind 64).
class AudiobookPriceTrait extends Trait {
  final String formattedPrice;
  final String currency;
  final bool isPurchasable;

  const AudiobookPriceTrait({
    this.formattedPrice = '',
    this.currency = '',
    this.isPurchasable = false,
  });

  @override
  Map<String, dynamic> toJson() => {
    'formattedPrice': formattedPrice,
    'currency': currency,
    'isPurchasable': isPurchasable,
  };

  factory AudiobookPriceTrait.fromJson(Map<String, dynamic> json) =>
      AudiobookPriceTrait(
        formattedPrice: json['formattedPrice'] ?? '',
        currency: json['currency'] ?? '',
        isPurchasable: json['isPurchasable'] ?? false,
      );
}
