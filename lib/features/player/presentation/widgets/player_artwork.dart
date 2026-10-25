import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'player_theme.dart';

/// Singleton in-memory LRU cache of canonical [ImageProvider]s for local song artwork.
class _ArtworkMemoryCache {
  _ArtworkMemoryCache._();

  static final OnAudioQuery _audioQuery = OnAudioQuery();

  static const int _maxCachedProviders = 350;

  static final LinkedHashMap<_ArtworkCacheKey, ImageProvider> _providers =
      LinkedHashMap<_ArtworkCacheKey, ImageProvider>();

  static final Set<_ArtworkCacheKey> _knownMissing = <_ArtworkCacheKey>{};

  static final Map<_ArtworkCacheKey, Future<ImageProvider?>> _inFlight =
      <_ArtworkCacheKey, Future<ImageProvider?>>{};

  static ImageProvider? getSync(_ArtworkCacheKey key) {
    final existing = _providers.remove(key);
    if (existing != null) {
      _providers[key] = existing;
    }
    return existing;
  }

  static bool isKnownMissing(_ArtworkCacheKey key) =>
      _knownMissing.contains(key);

  static Future<ImageProvider?> load(_ArtworkCacheKey key) {
    final syncHit = getSync(key);
    if (syncHit != null) return Future<ImageProvider?>.value(syncHit);
    if (_knownMissing.contains(key)) return Future<ImageProvider?>.value(null);

    final existingFuture = _inFlight[key];
    if (existingFuture != null) return existingFuture;

    final future = _fetchAndCache(key);
    _inFlight[key] = future;
    return future;
  }

  static Future<ImageProvider?> _fetchAndCache(_ArtworkCacheKey key) async {
    try {
      final bytes = await _audioQuery.queryArtwork(
        key.songId,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: key.querySize,
        quality: 85,
      );

      if (bytes == null || bytes.isEmpty) {
        _knownMissing.add(key);
        return null;
      }

      final provider = ResizeImage(
        MemoryImage(bytes),
        width: key.decodeWidthPx,
        allowUpscaling: false,
      );

      if (_providers.length >= _maxCachedProviders) {
        _providers.remove(_providers.keys.first);
      }
      _providers[key] = provider;
      return provider;
    } catch (_) {
      _knownMissing.add(key);
      return null;
    } finally {
      _inFlight.remove(key);
    }
  }
}

class _ArtworkCacheKey {
  final int songId;
  final dynamic version;
  final bool isLarge;
  final int decodeWidthPx;
  final int querySize;

  const _ArtworkCacheKey({
    required this.songId,
    required this.version,
    required this.isLarge,
    required this.decodeWidthPx,
    required this.querySize,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ArtworkCacheKey &&
          runtimeType == other.runtimeType &&
          songId == other.songId &&
          version == other.version &&
          isLarge == other.isLarge &&
          decodeWidthPx == other.decodeWidthPx;

  @override
  int get hashCode => Object.hash(songId, version, isLarge, decodeWidthPx);
}

class PlayerBackdrop extends StatelessWidget {
  const PlayerBackdrop({
    super.key,
    this.songId,
    this.imageUrl,
  });

  final int? songId;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (songId == null && (imageUrl == null || imageUrl!.isEmpty)) {
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
                songId: songId,
                imageUrl: imageUrl,
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
    this.songId,
    this.imageUrl,
  });

  final int? songId;
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
                songId: songId,
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
    this.songId,
    this.imageUrl,
    this.artworkWidth,
    this.artworkHeight,
    this.placeholderIconSize,
    this.size,
  });

  final int? songId;
  final String? imageUrl;
  final double? artworkWidth;
  final double? artworkHeight;
  final double? placeholderIconSize;
  final int? size;

  @override
  State<PlayerArtworkImage> createState() => _PlayerArtworkImageState();
}

class _PlayerArtworkImageState extends State<PlayerArtworkImage> {
  _ArtworkCacheKey? _cacheKey;
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    _resolveArtwork();
  }

  @override
  void didUpdateWidget(covariant PlayerArtworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songId != widget.songId ||
        oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.artworkWidth != widget.artworkWidth ||
        oldWidget.size != widget.size) {
      _resolveArtwork();
    }
  }

  void _resolveArtwork() {
    final songId = widget.songId;
    if (songId == null) {
      _cacheKey = null;
      _imageProvider = null;
      return;
    }

    final bool isLarge =
        widget.artworkWidth == null || widget.artworkWidth! > 100;
    final int querySize = widget.size ?? (isLarge ? 800 : 200);
    final int decodeWidthPx = isLarge ? 720 : 144;

    final key = _ArtworkCacheKey(
      songId: songId,
      version: null,
      isLarge: isLarge,
      querySize: querySize,
      decodeWidthPx: decodeWidthPx,
    );
    _cacheKey = key;

    final syncHit = _ArtworkMemoryCache.getSync(key);
    _imageProvider = syncHit;
    if (syncHit != null) {
      return;
    }

    if (_ArtworkMemoryCache.isKnownMissing(key)) {
      return;
    }

    _ArtworkMemoryCache.load(key).then((provider) {
      if (mounted && _cacheKey == key && provider != _imageProvider) {
        setState(() {
          _imageProvider = provider;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = _imageProvider;
    final bool isLarge =
        widget.artworkWidth == null || widget.artworkWidth! > 100;

    if (provider != null) {
      return Image(
        image: provider,
        width: widget.artworkWidth ?? double.infinity,
        height: widget.artworkHeight ?? double.infinity,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: isLarge ? FilterQuality.medium : FilterQuality.low,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return Image.network(
        widget.imageUrl!,
        width: widget.artworkWidth ?? double.infinity,
        height: widget.artworkHeight ?? double.infinity,
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
      iconSize: widget.placeholderIconSize ?? 82,
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
