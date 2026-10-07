import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/core/media/media_item_mapper.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'player_theme.dart';

class PlayerBackdrop extends StatelessWidget {
  const PlayerBackdrop({super.key, required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final songId = MediaItemMapper.songId(item);

    if (songId == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.30,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: PlayerArtworkImage(
              item: item,
              artworkWidth: double.infinity,
              artworkHeight: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerAlbumArtwork extends StatelessWidget {
  const PlayerAlbumArtwork({super.key, required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.48),
                  blurRadius: 34,
                  offset: const Offset(0, 22),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: PlayerArtworkImage(item: item),
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerArtworkImage extends StatelessWidget {
  const PlayerArtworkImage({
    super.key,
    required this.item,
    this.artworkWidth,
    this.artworkHeight,
    this.placeholderIconSize,
    this.size,
  });

  final MediaItem item;
  final double? artworkWidth;
  final double? artworkHeight;
  final double? placeholderIconSize;
  final int? size;

  @override
  Widget build(BuildContext context) {
    final songId = MediaItemMapper.songId(item);

    if (songId == null) {
      final placeholder = PlayerArtworkPlaceholder(
        iconSize: placeholderIconSize ?? 82,
      );
      if (artworkWidth == null && artworkHeight == null) {
        return placeholder;
      }
      return SizedBox(
        width: artworkWidth,
        height: artworkHeight,
        child: placeholder,
      );
    }

    final artworkVersion =
        item.extras?[MediaItemMapper.artworkVersionKey] ??
        item.extras?[MediaItemMapper.dateModifiedKey];

    final bool isLarge = artworkWidth == null || artworkWidth! > 100;
    final int resolvedSize = size ?? (isLarge ? 1000 : 200);

    return QueryArtworkWidget(
      key: ValueKey('${item.id}_${artworkVersion}_$resolvedSize'),
      id: songId,
      type: ArtworkType.AUDIO,
      artworkWidth: artworkWidth ?? double.infinity,
      artworkHeight: artworkHeight ?? double.infinity,
      size: resolvedSize,
      artworkBorder: BorderRadius.zero,
      artworkQuality: isLarge ? FilterQuality.high : FilterQuality.low,
      quality: isLarge ? 100 : 50,
      keepOldArtwork: true,
      nullArtworkWidget: PlayerArtworkPlaceholder(
        iconSize: placeholderIconSize ?? 82,
      ),
    );
  }
}

class PlayerArtworkPlaceholder extends StatelessWidget {
  const PlayerArtworkPlaceholder({super.key, this.iconSize});

  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C1C1C), Color(0xFF0F0F0F)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: PlayerColors.muted,
          size: iconSize ?? 82,
        ),
      ),
    );
  }
}
