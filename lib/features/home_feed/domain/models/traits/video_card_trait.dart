import 'trait.dart';

/// Video card metadata for video podcasts and watch feed items.
/// Carries the 16:9 video thumbnail, square show artwork, and duration badge.
class VideoCardTrait extends Trait {
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

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'videoThumbnailUrl': videoThumbnailUrl,
    'showArtworkUrl': showArtworkUrl,
    'durationString': durationString,
    'overline': overline,
    'isPlaying': isPlaying,
  };

  factory VideoCardTrait.fromJson(Map<String, dynamic> json) => VideoCardTrait(
    title: json['title'] ?? '',
    subtitle: json['subtitle'] ?? '',
    videoThumbnailUrl: json['videoThumbnailUrl'],
    showArtworkUrl: json['showArtworkUrl'],
    durationString: json['durationString'] ?? '',
    overline: json['overline'] ?? '',
    isPlaying: json['isPlaying'] ?? false,
  );
}
