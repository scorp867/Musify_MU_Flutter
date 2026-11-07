import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/core/navigation/spotify_uri_navigator.dart';
import 'package:musify_mu/core/widgets/app_network_image.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';
import 'package:musify_mu/features/home_feed/presentation/extensions/spotify_entity_presentation.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';

/// Renders an audio episode preview card matching Spotify Android's 1:1 layout.
class EpisodePreviewCard extends StatefulWidget {
  final SpotifyEntity item;

  const EpisodePreviewCard({super.key, required this.item});

  @override
  State<EpisodePreviewCard> createState() => _EpisodePreviewCardState();
}

class _EpisodePreviewCardState extends State<EpisodePreviewCard> {
  Color? _extractedColor;

  @override
  void initState() {
    super.initState();
    _resolveColor();
  }

  @override
  void didUpdateWidget(EpisodePreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.cardImageUrl != widget.item.cardImageUrl ||
        oldWidget.item.backgroundColorHex != widget.item.backgroundColorHex) {
      _resolveColor();
    }
  }

  void _resolveColor() {
    final colorHex = widget.item.backgroundColorHex;
    if (colorHex != null && colorHex.isNotEmpty) return;

    final url = _resolvePrimaryImageUrl(widget.item);
    if (url == null || url.isEmpty) return;

    ColorExtractionService? service;
    try {
      service = context.read<ColorExtractionService>();
    } catch (e, stack) {
      dev.log(
        'Failed to read ColorExtractionService: $e',
        name: 'EpisodePreviewCard',
        error: e,
        stackTrace: stack,
      );
    }

    if (service != null) {
      final cached = service.getCached(url);
      if (cached != null) {
        _extractedColor = _sanitizeColor(cached.primary);
        return;
      }

      service
          .extractFromUrl(url)
          .then((color) {
            if (mounted) {
              setState(() {
                _extractedColor = _sanitizeColor(color.primary);
              });
            }
          })
          .catchError((Object e, StackTrace stack) {
            dev.log(
              'Failed to extract color from url: $e',
              name: 'EpisodePreviewCard',
              error: e,
              stackTrace: stack,
            );
          });
    }
  }

  static String? _resolvePrimaryImageUrl(SpotifyEntity entity) {
    if (entity.cardImageUrl case final url? when url.isNotEmpty) return url;
    if (entity.previewImageUrl case final url? when url.isNotEmpty) return url;
    return null;
  }

  static Color _sanitizeColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    if (hsl.hue >= 260 && hsl.hue <= 325) {
      final newSat = hsl.saturation * 0.7;
      final boundedSat = newSat > 1.0 ? 1.0 : (newSat < 0.0 ? 0.0 : newSat);
      return hsl.withHue(230).withSaturation(boundedSat).toColor();
    }
    return color;
  }

  Color _cardBackgroundColor() {
    if (widget.item.backgroundColorHex case final rawHex?
        when rawHex.isNotEmpty) {
      try {
        final hex = rawHex.replaceAll('#', '').trim();
        final String argbHex;
        if (hex.length == 6) {
          argbHex = 'FF$hex';
        } else if (hex.length == 8) {
          argbHex = '${hex.substring(6, 8)}${hex.substring(0, 6)}';
        } else {
          argbHex = hex;
        }
        final base = Color(int.parse(argbHex, radix: 16));
        if (Color.lerp(base, const Color(0xFF1E1E1E), 0.7)
            case final blended?) {
          return blended;
        }
        return const Color(0xFF282828);
      } catch (e, stack) {
        dev.log(
          'Failed to parse hex color: $e',
          name: 'EpisodePreviewCard',
          error: e,
          stackTrace: stack,
        );
      }
    }
    if (_extractedColor case final extracted?) {
      if (Color.lerp(extracted, const Color(0xFF1E1E1E), 0.7)
          case final blended?) {
        return blended;
      }
    }
    return const Color(0xFF282828);
  }

  String _formatDuration(int ms) {
    if (ms <= 0) return '';
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${remainingMinutes}min';
    }
    return '$minutes min';
  }

  static String _resolveEpisodeTitle(
    SpotifyEntity item,
    EpisodeV4? episode,
    PreviewCardTrait? preview,
  ) {
    if (episode != null && episode.name.isNotEmpty) return episode.name;
    if (item.cardTitle.isNotEmpty) return item.cardTitle;
    if (preview != null && preview.title.isNotEmpty) return preview.title;
    return 'Episode';
  }

  static String _resolveShowName(
    SpotifyEntity item,
    EpisodeV4? episode,
    PreviewCardTrait? preview,
    SimpleCardTrait? simple,
  ) {
    if (episode?.show?.name case final showName? when showName.isNotEmpty) {
      return showName;
    }
    if (preview != null && preview.creatorName.isNotEmpty) {
      return preview.creatorName;
    }
    if (item.cardSubtitle.isNotEmpty) return item.cardSubtitle;
    if (simple != null && simple.subtitle.isNotEmpty) return simple.subtitle;
    return '';
  }

  static String? _resolveArtworkUrl(
    SpotifyEntity item,
    EpisodeV4? episode,
    PreviewCardTrait? preview,
  ) {
    if (item.cardImageUrl case final url? when url.isNotEmpty) return url;
    if (item.previewImageUrl case final url? when url.isNotEmpty) return url;
    if (episode != null) {
      final largeUrl = episode.coverImage.urlForSize(ImageSize.large);
      if (largeUrl.isNotEmpty) return largeUrl;
    }
    if (preview?.imageUrl case final url? when url.isNotEmpty) return url;
    return null;
  }

  void _playWithMetadata() {
    final episodeTrait = widget.item.getTrait<EpisodeV4>();
    final previewTrait = widget.item.getTrait<PreviewCardTrait>();
    final simpleTrait = widget.item.getTrait<SimpleCardTrait>();
    final title = _resolveEpisodeTitle(widget.item, episodeTrait, previewTrait);
    final showName = _resolveShowName(
      widget.item,
      episodeTrait,
      previewTrait,
      simpleTrait,
    );
    final artworkUrl = _resolveArtworkUrl(
      widget.item,
      episodeTrait,
      previewTrait,
    );
    final durationMs =
        episodeTrait != null && episodeTrait.duration > 0
        ? episodeTrait.duration
        : 0;

    final track = ContextTrack.builder(widget.item.uri).metadata({
      ContextTrackMetadata.keyTitle: title,
      if (showName.isNotEmpty) ContextTrackMetadata.keyArtistName: showName,
      if (artworkUrl != null && artworkUrl.isNotEmpty)
        ContextTrackMetadata.keyImageUrl: artworkUrl,
      if (durationMs > 0)
        ContextTrackMetadata.keyDuration: durationMs.toString(),
    }).build();
    SpotifyUriNavigator.playUri(context, widget.item.uri, track: track);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final previewTrait = item.getTrait<PreviewCardTrait>();
    final episodeTrait = item.getTrait<EpisodeV4>();
    final simpleTrait = item.getTrait<SimpleCardTrait>();

    final title = _resolveEpisodeTitle(item, episodeTrait, previewTrait);
    final showName = _resolveShowName(
      item,
      episodeTrait,
      previewTrait,
      simpleTrait,
    );

    final description =
        previewTrait != null && previewTrait.description.isNotEmpty
        ? previewTrait.description
        : (episodeTrait != null && episodeTrait.description.isNotEmpty
              ? episodeTrait.description
              : '');

    final durationStr =
        episodeTrait != null && episodeTrait.duration > 0
        ? _formatDuration(episodeTrait.duration)
        : '';

    final subtitleParts = <String>[];
    if (showName.isNotEmpty) subtitleParts.add(showName);
    if (durationStr.isNotEmpty) subtitleParts.add(durationStr);
    final subtitleLine = subtitleParts.join(' \u2022 ');

    final artworkUrl = _resolveArtworkUrl(item, episodeTrait, previewTrait);
    final bgColor = _cardBackgroundColor();
    final previewLabel =
        previewTrait != null && previewTrait.previewLabel.isNotEmpty
        ? previewTrait.previewLabel
        : 'Preview episode';

    return GestureDetector(
      onTap: () => SpotifyUriNavigator.openUri(context, widget.item.uri),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 88,
                        height: 88,
                        child: artworkUrl != null && artworkUrl.isNotEmpty
                            ? AppNetworkImage(
                                imageUrl: artworkUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 176,
                                memCacheHeight: 176,
                                errorWidget: (_, _, _) => Container(
                                  color: const Color(0xFF333333),
                                  child: const Icon(
                                    Icons.podcasts,
                                    color: Colors.white24,
                                    size: 36,
                                  ),
                                ),
                              )
                            : Container(
                                color: const Color(0xFF333333),
                                child: const Icon(
                                  Icons.podcasts,
                                  color: Colors.white24,
                                  size: 36,
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6D00),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.podcasts,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.more_vert,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                        ],
                      ),
                      if (subtitleLine.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitleLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: _playWithMetadata,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.volume_up_outlined,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          previewLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 26,
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: _playWithMetadata,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
