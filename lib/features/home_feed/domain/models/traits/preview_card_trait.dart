import 'trait.dart';

/// ExtensionKind 118 (PREVIEW_CARD_TRAIT).
class PreviewCardTrait extends Trait {
  final String title;
  final String contentTypeName;
  final String description;
  final String? imageUrl;
  final String? backgroundColor;
  final String? waveformColor;
  final int trackCount;
  final String? entityUri;
  final String? navigateUri;
  final List<String> tags;
  final String previewLabel;
  final String playingLabel;
  final String creatorName;
  final String creatorUri;
  final String creatorImageUrl;

  const PreviewCardTrait({
    required this.title,
    this.contentTypeName = '',
    this.description = '',
    this.imageUrl,
    this.backgroundColor,
    this.waveformColor,
    this.trackCount = 0,
    this.entityUri,
    this.navigateUri,
    this.tags = const [],
    this.previewLabel = '',
    this.playingLabel = '',
    this.creatorName = '',
    this.creatorUri = '',
    this.creatorImageUrl = '',
  });

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'contentTypeName': contentTypeName,
    'description': description,
    'imageUrl': imageUrl,
    'backgroundColor': backgroundColor,
    'waveformColor': waveformColor,
    'trackCount': trackCount,
    'entityUri': entityUri,
    'navigateUri': navigateUri,
    'tags': tags,
    'previewLabel': previewLabel,
    'playingLabel': playingLabel,
    'creatorName': creatorName,
    'creatorUri': creatorUri,
    'creatorImageUrl': creatorImageUrl,
  };

  factory PreviewCardTrait.fromJson(Map<String, dynamic> json) {
    final image = json['imageUrl'] as String?;
    final bg = json['backgroundColor'] as String?;
    return PreviewCardTrait(
      title: json['title'] ?? '',
      contentTypeName: json['contentTypeName'] ?? '',
      description: json['description'] ?? '',
      imageUrl: image?.isEmpty == true ? null : image,
      backgroundColor: bg?.isEmpty == true ? null : bg,
      waveformColor: json['waveformColor'],
      trackCount: json['trackCount'] ?? 0,
      entityUri: json['entityUri'],
      navigateUri: json['navigateUri'],
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      previewLabel: json['previewLabel'] ?? '',
      playingLabel: json['playingLabel'] ?? '',
      creatorName: json['creatorName'] ?? '',
      creatorUri: json['creatorUri'] ?? '',
      creatorImageUrl: json['creatorImageUrl'] ?? '',
    );
  }
}
