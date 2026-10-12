import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/core/media/media_item_mapper.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'player_theme.dart';

/// Singleton in-memory LRU cache of canonical [ImageProvider]s for local song
/// artwork.
///
/// Why this is critical for 120fps scrolling & ReorderableListView dragging:
/// `QueryArtworkWidget` from `on_audio_query` calls `OnAudioQuery().queryArtwork()`
/// inside `StatelessWidget.build()` and wraps the returned `Uint8List` in a new
/// `MemoryImage` on every build. Because `Uint8List` uses identity equality,
/// every rebuild during drag-reordering bypassed Flutter's `ImageCache`,
/// triggered native Android JPEG re-encoding (`vendor.vivo.imageencoder.dump`),
/// and forced Skia (`SkJpegCodec::onGetPixels`) to re-decode JPEGs on the fly.
///
/// By caching the canonical [ImageProvider] instance per `(songId, version, isLarge)`,
/// Flutter's GPU `ImageCache` recognizes the provider in O(1) and renders the
/// decoded GPU texture synchronously on frame 0 with zero MethodChannel or
/// Skia decode overhead.
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
      // Refresh LRU order
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
      final Uint8List? bytes = await _audioQuery.queryArtwork(
        key.songId,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: key.querySize,
        quality: key.isLarge ? 90 : 70,
      );

      if (bytes == null || bytes.isEmpty) {
        _knownMissing.add(key);
        return null;
      }

      // Wrap in ResizeImage so Skia decodes thumbnails directly to target
      // pixel dimensions (e.g. 144x144 instead of 571x571 or 1000x1000).
      final ImageProvider provider = ResizeImage(
        MemoryImage(bytes),
        width: key.decodeWidthPx,
        height: key.decodeWidthPx,
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

@immutable
class _ArtworkCacheKey {
  const _ArtworkCacheKey({
    required this.songId,
    required this.version,
    required this.isLarge,
    required this.querySize,
    required this.decodeWidthPx,
  });

  final int songId;
  final Object? version;
  final bool isLarge;
  final int querySize;
  final int decodeWidthPx;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ArtworkCacheKey &&
          other.songId == songId &&
          other.version == version &&
          other.isLarge == isLarge &&
          other.decodeWidthPx == decodeWidthPx;

  @override
  int get hashCode => Object.hash(songId, version, isLarge, decodeWidthPx);
}

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
        child: RepaintBoundary(
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
              child: PlayerArtworkImage(item: item),
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
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.artworkWidth != widget.artworkWidth ||
        oldWidget.size != widget.size) {
      _resolveArtwork();
    }
  }

  void _resolveArtwork() {
    final songId = MediaItemMapper.songId(widget.item);
    if (songId == null) {
      _cacheKey = null;
      _imageProvider = null;
      return;
    }

    final artworkVersion =
        widget.item.extras?[MediaItemMapper.artworkVersionKey] ??
            widget.item.extras?[MediaItemMapper.dateModifiedKey];

    final bool isLarge =
        widget.artworkWidth == null || widget.artworkWidth! > 100;
    final int querySize = widget.size ?? (isLarge ? 800 : 200);
    final int decodeWidthPx = isLarge ? 720 : 144;

    final key = _ArtworkCacheKey(
      songId: songId,
      version: artworkVersion,
      isLarge: isLarge,
      querySize: querySize,
      decodeWidthPx: decodeWidthPx,
    );
    _cacheKey = key;

    // Fast synchronous path: if already cached in memory, assign immediately
    // so build() renders on frame 0 without waiting for any Future!
    final syncHit = _ArtworkMemoryCache.getSync(key);
    if (syncHit != null) {
      _imageProvider = syncHit;
      return;
    }

    if (_ArtworkMemoryCache.isKnownMissing(key)) {
      _imageProvider = null;
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
