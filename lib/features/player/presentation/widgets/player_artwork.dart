import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/media/local_file_image_loader.dart';
import 'package:musify_mu/core/widgets/app_network_image.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file_uri.dart';

import 'player_theme.dart';

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
    this.fallbackImageUrl,
    this.artworkWidth,
    this.artworkHeight,
    this.placeholderIconSize,
    this.placeholderIcon,
    this.size,
  });

  final String? imageUrl;
  final String? fallbackImageUrl;
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
    final h = widget.artworkHeight;
    if (w == null && h == null) return true;
    final maxDim = math.max(
      w != null && w.isFinite ? w : 0.0,
      h != null && h.isFinite ? h : 0.0,
    );
    return maxDim == 0.0 || maxDim > 220;
  }

  int _boundedDecodePx(double? dim, int fallbackPx) {
    if (dim == null || !dim.isFinite || dim <= 0) {
      return fallbackPx;
    }
    return (dim * 2.0).round().clamp(96, 720);
  }

  int get _decodeWidthPx {
    if (_isLarge) return 720;
    return _boundedDecodePx(widget.artworkWidth, 256);
  }

  int get _decodeHeightPx {
    if (_isLarge) return 720;
    return _boundedDecodePx(widget.artworkHeight, _decodeWidthPx);
  }

  int get _querySize => switch (widget.size) {
    final s? => s,
    null => _isLarge ? 720 : 256,
  };

  @override
  void initState() {
    super.initState();
    _resolveLocalArtwork(notifyIfSyncHit: false);
  }

  @override
  void didUpdateWidget(covariant PlayerArtworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.fallbackImageUrl != widget.fallbackImageUrl ||
        oldWidget.artworkWidth != widget.artworkWidth ||
        oldWidget.artworkHeight != widget.artworkHeight ||
        oldWidget.size != widget.size) {
      _resolveLocalArtwork(notifyIfSyncHit: false);
    }
  }

  void _resolveLocalArtwork({required bool notifyIfSyncHit}) {
    final url = widget.imageUrl;
    if (url == null || !LocalFileUri.isResolvableLocalArtworkUri(url)) {
      final fallback = widget.fallbackImageUrl;
      if (fallback != null &&
          LocalFileUri.isResolvableLocalArtworkUri(fallback)) {
        _resolveCandidateLocalUri(
          fallback,
          allowFallback: false,
          notifyIfSyncHit: notifyIfSyncHit,
        );
        return;
      }
      _activeLocalUri = null;
      _localImageProvider = null;
      return;
    }

    _resolveCandidateLocalUri(
      url,
      allowFallback: true,
      notifyIfSyncHit: notifyIfSyncHit,
    );
  }

  void _resolveCandidateLocalUri(
    String url, {
    required bool allowFallback,
    required bool notifyIfSyncHit,
  }) {
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
    final decodeHeightPx = _decodeHeightPx;
    final syncHit = loader.getProviderSync(
      url,
      querySize: querySize,
      decodeWidthPx: decodeWidthPx,
      decodeHeightPx: decodeHeightPx,
    );
    if (syncHit != null) {
      if (notifyIfSyncHit && syncHit != _localImageProvider && mounted) {
        setState(() {
          _localImageProvider = syncHit;
        });
      } else {
        _localImageProvider = syncHit;
      }
      return;
    }
    _localImageProvider = null;
    if (loader.isKnownMissing(url, querySize: querySize)) {
      if (allowFallback) {
        final fallback = widget.fallbackImageUrl;
        if (fallback != null &&
            fallback != url &&
            LocalFileUri.isResolvableLocalArtworkUri(fallback)) {
          _resolveCandidateLocalUri(
            fallback,
            allowFallback: false,
            notifyIfSyncHit: notifyIfSyncHit,
          );
        }
      }
      return;
    }

    unawaited(
      loader
          .loadProvider(
            url,
            querySize: querySize,
            decodeWidthPx: decodeWidthPx,
            decodeHeightPx: decodeHeightPx,
          )
          .then((provider) {
            if (!mounted || _activeLocalUri != url) return;
            if (provider != null) {
              if (provider != _localImageProvider) {
                setState(() {
                  _localImageProvider = provider;
                });
              }
              return;
            }
            if (allowFallback) {
              final fallback = widget.fallbackImageUrl;
              if (fallback != null &&
                  fallback != url &&
                  LocalFileUri.isResolvableLocalArtworkUri(fallback)) {
                _resolveCandidateLocalUri(
                  fallback,
                  allowFallback: false,
                  notifyIfSyncHit: true,
                );
              }
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
    if (url != null &&
        url.isNotEmpty &&
        !LocalFileUri.isResolvableLocalArtworkUri(url)) {
      return AppNetworkImage(
        imageUrl: url,
        width: resolvedWidth,
        height: resolvedHeight,
        fit: BoxFit.cover,
        memCacheWidth: _decodeWidthPx,
        memCacheHeight: _decodeHeightPx,
        fadeInDuration: Duration.zero,
        placeholder: (_, _) => _buildPlaceholder(),
        errorWidget: (_, _, _) => _buildPlaceholder(),
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
