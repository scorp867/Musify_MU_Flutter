import 'trait.dart';

/// ExtensionKind 97 (SIMPLE_TRAIT).
/// Equivalent to Spotify Android's `c6y0` / `e6y0`.
class SimpleCardTrait extends Trait {
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

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'navigationUri': navigationUri,
    'accessibility': accessibility,
  };

  factory SimpleCardTrait.fromJson(Map<String, dynamic> json) {
    final image = json['imageUrl'] as String?;
    return SimpleCardTrait(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: image?.isEmpty == true ? null : image,
      navigationUri: json['navigationUri'],
      accessibility: json['accessibility'],
    );
  }
}
