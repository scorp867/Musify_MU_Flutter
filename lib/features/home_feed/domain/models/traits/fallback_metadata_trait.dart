import 'trait.dart';

class FallbackMetadataTrait extends Trait {
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

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'extractedColor': extractedColor,
    'badge': badge,
  };

  factory FallbackMetadataTrait.fromJson(Map<String, dynamic> json) => FallbackMetadataTrait(
    title: json['title'] ?? '',
    subtitle: json['subtitle'] ?? '',
    imageUrl: json['imageUrl'],
    extractedColor: json['extractedColor'],
    badge: json['badge'],
  );
}
