import 'package:flutter/foundation.dart';

import 'trait.dart';

/// Video card metadata for video podcasts and watch feed items.
@immutable
final class VideoCardTrait extends Trait {
  final String title;
  final String subtitle;
  final String? videoThumbnailUrl;
  final String? showArtworkUrl;
  final String durationString;
  final String overline;
  final bool isPlaying;

  const VideoCardTrait({
    required this.title,
    this.subtitle = '',
    this.videoThumbnailUrl,
    this.showArtworkUrl,
    this.durationString = '',
    this.overline = '',
    this.isPlaying = false,
  });
}
