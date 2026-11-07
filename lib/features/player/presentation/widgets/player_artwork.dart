import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/media/local_file_image_loader.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file_uri.dart';

import 'player_theme.dart';

class PlayerBackdrop extends StatelessWidget {
  const PlayerBackdrop({
    super.key,
    this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = imageUrl;
    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Opacity(
            opacity: 0.30,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: PlayerArtworkImage(
                imageUrl: resolvedUrl,
                artworkWidth: double.infinity,
                artworkHeight: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerAlbumArtwork extends StatelessWidget {
  const PlayerAlbumArtwork({
    super.key,
    this.imageUrl,
  });

  final String? imageUrl;

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
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: PlayerArtworkImage(
                imageUrl: imageUrl,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerArtworkImage extends StatefulWidget {
  const PlayerArtworkImage({
    super.key,
    this.imageUrl,
    this.artworkWidth,
    this.artworkHeight,
    this.placeholderIconSize,
    this.placeholderIcon,
    this.size,
  });

  final String? imageUrl;
  final double? artworkWidth;
  final double? artworkHeight;
  final double? placeholderIconSize;
  final IconData? placeholderIcon;
  final int? size;

  @override
  State<PlayerArtworkImage> createState() => _PlayerArtworkImageState();
}

class _PlayerArtworkImageState extends State<PlayerArtworkImage> {
  String? _activeLocalUri;
  ImageProvider? _localImageProvider;

  bool get _isLarge {
    final w = widget.artworkWidth;
    return w == null || w > 100;
  }

  int get _decodeWidthPx => _isLarge ? 720 : 144;

  int get _querySize => switch (widget.size) {
    final s? => s,
    null => _isLarge ? 800 : 200,
  };

  @override
  void initState() {
    super.initState();
    _resolveLocalArtwork();
  }

  @override
  void didUpdateWidget(covariant PlayerArtworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.artworkWidth != widget.artworkWidth ||
        oldWidget.size != widget.size) {
      _resolveLocalArtwork();
    }
  }

  void _resolveLocalArtwork() {
    final url = widget.imageUrl;
    if (url == null || !LocalFileUri.isAnyLocalUri(url)) {
      _activeLocalUri = null;
      _localImageProvider = null;
      return;
    }

    _activeLocalUri = url;
    final loader = getIt.isRegistered<LocalFileImageLoader>()
        ? getIt<LocalFileImageLoader>()
        : null;
    if (loader == null) {
      _localImageProvider = null;
      return;
    }

    final querySize = _querySize;
    final decodeWidthPx = _decodeWidthPx;
    final syncHit = loader.getProviderSync(
      url,
      querySize: querySize,
      decodeWidthPx: decodeWidthPx,
    );
    _localImageProvider = syncHit;
    if (syncHit != null || loader.isKnownMissing(url, querySize: querySize)) {
      return;
    }

    unawaited(
      loader
          .loadProvider(
            url,
            querySize: querySize,
            decodeWidthPx: decodeWidthPx,
          )
          .then((provider) {
            if (mounted &&
                _activeLocalUri == url &&
                provider != _localImageProvider) {
              setState(() {
                _localImageProvider = provider;
              });
            }
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLarge;
    final resolvedWidth = switch (widget.artworkWidth) {
      final w? => w,
      null => double.infinity,
    };
    final resolvedHeight = switch (widget.artworkHeight) {
      final h? => h,
      null => double.infinity,
    };

    if (_localImageProvider case final provider?) {
      return Image(
        image: provider,
        width: resolvedWidth,
        height: resolvedHeight,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: isLarge ? FilterQuality.medium : FilterQuality.low,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    final url = widget.imageUrl;
    if (url != null && url.isNotEmpty && !LocalFileUri.isAnyLocalUri(url)) {
      return Image.network(
        url,
        width: resolvedWidth,
        height: resolvedHeight,
        cacheWidth: _decodeWidthPx,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: isLarge ? FilterQuality.medium : FilterQuality.low,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final placeholder = PlayerArtworkPlaceholder(
      iconSize: widget.placeholderIconSize,
      icon: widget.placeholderIcon,
    );
    if (widget.artworkWidth == null && widget.artworkHeight == null) {
      return placeholder;
    }
    return SizedBox(
      width: widget.artworkWidth,
      height: widget.artworkHeight,
      child: placeholder,
    );
  }
}

class PlayerArtworkPlaceholder extends StatelessWidget {
  const PlayerArtworkPlaceholder({
    super.key,
    this.iconSize,
    this.icon,
  });

  final double? iconSize;
  final IconData? icon;

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
          switch (icon) {
            final ic? => ic,
            null => Icons.music_note_rounded,
          },
          color: PlayerColors.muted,
          size: switch (iconSize) {
            final sz? => sz,
            null => 82,
          },
        ),
      ),
    );
  }
}
