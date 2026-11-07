import 'package:flutter/foundation.dart';

import 'trait.dart';

/// ExtensionKind 118 (PREVIEW_CARD_TRAIT).
@immutable
final class PreviewCardTrait extends Trait {
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
}
