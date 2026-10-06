import 'trait.dart';

/// Promotion V1 banner trait (ExtensionKind 167).
class PromoV1Trait extends Trait {
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
  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'actionText': actionText,
    'actionUri': actionUri,
  };

  factory PromoV1Trait.fromJson(Map<String, dynamic> json) => PromoV1Trait(
    title: json['title'] ?? '',
    subtitle: json['subtitle'] ?? '',
    imageUrl: json['imageUrl'],
    actionText: json['actionText'] ?? '',
    actionUri: json['actionUri'] ?? '',
  );
}
