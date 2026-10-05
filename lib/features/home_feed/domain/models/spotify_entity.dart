export 'traits.dart';
import 'traits.dart';

/// The core SDUI container.
/// Each entity has a URI, content type, and a bag of traits
/// that different UI widgets read from based on their context.
class SpotifyEntity {
  final String uri;
  final ContentType type;
  final Map<String, Trait> traits;

  const SpotifyEntity({
    required this.uri,
    required this.type,
    required this.traits,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpotifyEntity && other.uri == uri;
  }

  @override
  int get hashCode => uri.hashCode;

  /// Convenience fetcher for specific traits
  T? getTrait<T extends Trait>() {
    final typeName = T.toString();
    return traits[typeName] as T?;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Context-specific title/image getters
  // Each widget context has a different trait priority chain.
  // ═══════════════════════════════════════════════════════════════════

  /// Shortcuts grid: prioritizes ShortcutsCardTrait from eagerload.
  String get shortcutTitle {
    final sct = getTrait<ShortcutsCardTrait>();
    if (sct != null && sct.title.isNotEmpty) return sct.title;
    final simple = getTrait<SimpleCardTrait>();
    if (simple != null && simple.title.isNotEmpty) return simple.title;
    final identity = getTrait<IdentityTrait>();
    if (identity != null && identity.title.isNotEmpty) return identity.title;
    return '';
  }

  String? get shortcutImageUrl {
    return getTrait<ShortcutsCardTrait>()?.imageUrl
        ?? getTrait<SimpleCardTrait>()?.imageUrl;
  }

  /// Standard cards (carousels, grids): prioritizes SimpleCardTrait.
  String get cardTitle {
    final simple = getTrait<SimpleCardTrait>();
    if (simple != null && simple.title.isNotEmpty) return simple.title;
    final identity = getTrait<IdentityTrait>();
    if (identity != null && identity.title.isNotEmpty) return identity.title;
    final preview = getTrait<PreviewCardTrait>();
    if (preview != null && preview.title.isNotEmpty) return preview.title;
    final sct = getTrait<ShortcutsCardTrait>();
    if (sct != null && sct.title.isNotEmpty) return sct.title;
    return '';
  }

  String? get cardImageUrl {
    return getTrait<SimpleCardTrait>()?.imageUrl
        ?? getTrait<PreviewCardTrait>()?.imageUrl
        ?? getTrait<ShortcutsCardTrait>()?.imageUrl;
  }

  /// Preview/showcase: prioritizes PreviewCardTrait from eagerload.
  String get previewTitle {
    final preview = getTrait<PreviewCardTrait>();
    if (preview != null && preview.title.isNotEmpty) return preview.title;
    final simple = getTrait<SimpleCardTrait>();
    if (simple != null && simple.title.isNotEmpty) return simple.title;
    return '';
  }

  String? get previewImageUrl {
    return getTrait<PreviewCardTrait>()?.imageUrl
        ?? getTrait<SimpleCardTrait>()?.imageUrl;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Serialization for cache
  // ═══════════════════════════════════════════════════════════════════

  Map<String, dynamic> toJson() {
    return {
      'uri': uri,
      'type': type.name,
      'traits': traits.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  factory SpotifyEntity.fromJson(Map<String, dynamic> json) {
    final rawTraits = json['traits'] as Map<String, dynamic>? ?? {};
    final mappedTraits = <String, Trait>{};

    for (final entry in rawTraits.entries) {
      final trait = Trait.fromJson(entry.key, entry.value as Map<String, dynamic>);
      if (trait != null) {
        mappedTraits[entry.key] = trait;
      }
    }

    return SpotifyEntity(
      uri: json['uri'] ?? '',
      type: ContentType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ContentType.unknown,
      ),
      traits: mappedTraits,
    );
  }
}
