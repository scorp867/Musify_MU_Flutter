import 'trait.dart';

/// ExtensionKind 119 (SHORTCUTS_CARD_TRAIT).
class ShortcutsCardTrait extends Trait {
  final String title;
  final String? imageUrl;

  const ShortcutsCardTrait({required this.title, this.imageUrl});

  @override
  Map<String, dynamic> toJson() => {'title': title, 'imageUrl': imageUrl};

  factory ShortcutsCardTrait.fromJson(Map<String, dynamic> json) => ShortcutsCardTrait(
    title: json['title'] ?? '',
    imageUrl: json['imageUrl'],
  );
}
