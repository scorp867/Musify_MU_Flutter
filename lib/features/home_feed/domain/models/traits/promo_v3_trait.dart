import 'trait.dart';

/// Promotion V3 card trait (ExtensionKind 171).
class PromoV3Trait extends Trait {
  final String title;
  final String? imageUrl;
  final String actionUri;

  const PromoV3Trait({
    required this.title,
    this.imageUrl,
    this.actionUri = '',
  });

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'imageUrl': imageUrl,
    'actionUri': actionUri,
  };

  factory PromoV3Trait.fromJson(Map<String, dynamic> json) => PromoV3Trait(
    title: json['title'] ?? '',
    imageUrl: json['imageUrl'],
    actionUri: json['actionUri'] ?? '',
  );
}
