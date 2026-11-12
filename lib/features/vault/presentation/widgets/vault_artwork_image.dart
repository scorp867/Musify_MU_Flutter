import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/media/local_file_image_loader.dart';
import 'package:musify_mu/core/widgets/app_network_image.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file_uri.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';

/// Size-bounded artwork widget for Private Vault playlists and tracks.
///
/// Supports:
/// - Network artwork URLs (`http://`, `https://`) via bounded `cacheWidth` decoding.
/// - Local MediaStore / embedded ID3 artwork (`spotify:localfileimage:...`, `spotify:local:...`).
/// - Direct filesystem audio URIs (`file://...`, `/...`) including `.nomedia` sandbox files
///   via native `MediaMetadataRetriever` through [LocalFileImageLoader].
/// - Raster image files (`.jpg`, `.jpeg`, `.png`, `.webp`, `.gif`, `.bmp`).
/// - Legacy [TrackSourceTypeEnum.localSandbox] tracks lacking a stored `artworkUri`,
///   resolved asynchronously via [IVaultMediaIsolationManager.getIsolatedTrackFile].
class VaultArtworkImage extends StatefulWidget {
  final String? imageUrl;
  final PrivateTrackRef? track;
  final List<PrivateTrackRef> fallbackTracks;
  final double width;
  final double height;
  final double placeholderIconSize;
  final IconData placeholderIcon;
  final VaultThemeData? vaultTheme;
  final LocalFileImageLoader? localFileImageLoader;
  final IVaultMediaIsolationManager? isolationManager;

  const VaultArtworkImage({
    super.key,
    this.imageUrl,
    this.track,
    this.fallbackTracks = const <PrivateTrackRef>[],
    required this.width,
    required this.height,
    this.placeholderIconSize = 20.0,
    this.placeholderIcon = Icons.music_note_rounded,
    this.vaultTheme,
    this.localFileImageLoader,
    this.isolationManager,
  });

  factory VaultArtworkImage.forTrack(
    PrivateTrackRef track, {
    Key? key,
    double size = 36.0,
    double placeholderIconSize = 18.0,
    VaultThemeData? vaultTheme,
    LocalFileImageLoader? localFileImageLoader,
    IVaultMediaIsolationManager? isolationManager,
  }) {
    final fallbackIcon = switch (track.sourceType) {
      TrackSourceTypeEnum.spotify => Icons.music_note_rounded,
      TrackSourceTypeEnum.localReference => Icons.file_present_rounded,
      TrackSourceTypeEnum.localSandbox => Icons.lock_outline_rounded,
    };
    return VaultArtworkImage(
      key: key,
      track: track,
      width: size,
      height: size,
      placeholderIconSize: placeholderIconSize,
      placeholderIcon: fallbackIcon,
      vaultTheme: vaultTheme,
      localFileImageLoader: localFileImageLoader,
      isolationManager: isolationManager,
    );
  }

  factory VaultArtworkImage.forPlaylist(
    PrivatePlaylist playlist, {
    Key? key,
    double size = 140.0,
    double placeholderIconSize = 56.0,
    VaultThemeData? vaultTheme,
    LocalFileImageLoader? localFileImageLoader,
    IVaultMediaIsolationManager? isolationManager,
  }) {
    return VaultArtworkImage(
      key: key,
      imageUrl: playlist.coverUri,
      fallbackTracks: playlist.trackRefs,
      width: size,
      height: size,
      placeholderIconSize: placeholderIconSize,
      placeholderIcon: Icons.album_outlined,
      vaultTheme: vaultTheme,
      localFileImageLoader: localFileImageLoader,
      isolationManager: isolationManager,
    );
  }

  @override
  State<VaultArtworkImage> createState() => _VaultArtworkImageState();
}

class _VaultArtworkImageState extends State<VaultArtworkImage> {
  static const int _maxFallbackTracks = 4;

  int _generation = 0;
  int _lastFailureGen = -1;
  int _lastFailureCandidateIndex = -1;
  List<String> _candidates = const <String>[];
  int _candidateIndex = 0;
  ImageProvider? _resolvedLocalProvider;

  int get _decodeWidthPx {
    final w = widget.width;
    if (!w.isFinite || w <= 0) return 256;
    final scaled = (w * 2.0).round();
    return scaled < 96 ? 96 : (scaled > 720 ? 720 : scaled);
  }

  int get _decodeHeightPx {
    final h = widget.height;
    if (!h.isFinite || h <= 0) return _decodeWidthPx;
    final scaled = (h * 2.0).round();
    return scaled < 96 ? 96 : (scaled > 720 ? 720 : scaled);
  }

  int get _querySize => widget.width > 220 || widget.height > 220 ? 720 : 256;

  static bool _sameFallbackSlice(
    List<PrivateTrackRef> a,
    List<PrivateTrackRef> b,
  ) {
    final countA = a.length < _maxFallbackTracks ? a.length : _maxFallbackTracks;
    final countB = b.length < _maxFallbackTracks ? b.length : _maxFallbackTracks;
    if (countA != countB) return false;
    for (var i = 0; i < countA; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _rebuildCandidatesAndResolve();
  }

  @override
  void didUpdateWidget(covariant VaultArtworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.track != widget.track ||
        !_sameFallbackSlice(oldWidget.fallbackTracks, widget.fallbackTracks) ||
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height) {
      _rebuildCandidatesAndResolve();
    }
  }

  LocalFileImageLoader? _resolveLoader() {
    if (widget.localFileImageLoader case final injected?) {
      return injected;
    }
    if (getIt.isRegistered<LocalFileImageLoader>()) {
      return getIt<LocalFileImageLoader>();
    }
    return null;
  }

  IVaultMediaIsolationManager? _resolveIsolationManager() {
    if (widget.isolationManager case final injected?) {
      return injected;
    }
    if (getIt.isRegistered<IVaultMediaIsolationManager>()) {
      return getIt<IVaultMediaIsolationManager>();
    }
    return null;
  }

  List<String> _candidatesForTrack(PrivateTrackRef track) {
    final result = <String>[];
    if (track.artworkUri case final art? when art.trim().isNotEmpty) {
      result.add(art.trim());
    }
    switch (track.sourceType) {
      case TrackSourceTypeEnum.spotify:
        break;
      case TrackSourceTypeEnum.localReference:
      case TrackSourceTypeEnum.localSandbox:
        if (LocalFileUri.isFileSystemUri(track.trackUri)) {
          final fileUri = LocalFileUri.toFileUri(track.trackUri);
          if (!result.contains(fileUri)) {
            result.add(fileUri);
          }
        }
    }
    return result;
  }

  List<String> _buildInitialCandidates() {
    final seen = <String>{};
    final result = <String>[];

    void addCandidate(String? raw) {
      if (raw == null) return;
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return;
      if (seen.add(trimmed)) {
        result.add(trimmed);
      }
    }

    addCandidate(widget.imageUrl);
    if (widget.track case final track?) {
      for (final uri in _candidatesForTrack(track)) {
        addCandidate(uri);
      }
    }
    for (final fallback in widget.fallbackTracks.take(_maxFallbackTracks)) {
      for (final uri in _candidatesForTrack(fallback)) {
        addCandidate(uri);
      }
    }
    return result;
  }

  void _rebuildCandidatesAndResolve() {
    _generation++;
    _lastFailureGen = -1;
    _lastFailureCandidateIndex = -1;
    _candidates = _buildInitialCandidates();
    _candidateIndex = 0;
    _resolvedLocalProvider = null;

    final exhausted = _resolveCurrentCandidate();
    if (exhausted) {
      unawaited(_attemptSandboxTrackRecovery(_generation));
    }
  }

  Future<void> _attemptSandboxTrackRecovery(int gen) async {
    final sandboxTracks = <PrivateTrackRef>[
      if (widget.track case final t?
          when t.sourceType == TrackSourceTypeEnum.localSandbox)
        t,
      ...widget.fallbackTracks
          .where((t) => t.sourceType == TrackSourceTypeEnum.localSandbox)
          .take(_maxFallbackTracks),
    ];
    if (sandboxTracks.isEmpty) return;

    final isolationManager = _resolveIsolationManager();
    final loader = _resolveLoader();
    if (isolationManager == null || loader == null) return;

    final decodeWidth = _decodeWidthPx;
    final decodeHeight = _decodeHeightPx;
    for (final sandboxTrack in sandboxTracks.take(_maxFallbackTracks)) {
      if (!mounted || gen != _generation) return;
      try {
        final isolatedFile =
            await isolationManager.getIsolatedTrackFile(sandboxTrack.id);
        final provider = await loader.loadFileProvider(
          isolatedFile.path,
          decodeWidthPx: decodeWidth,
          decodeHeightPx: decodeHeight,
        );
        if (!mounted || gen != _generation) return;
        if (provider != null) {
          setState(() {
            _resolvedLocalProvider = provider;
          });
          return;
        }
      } on FileSystemException {
        continue;
      }
    }
  }

  static bool _isNetworkUrl(String uri) =>
      uri.startsWith('http://') || uri.startsWith('https://');

  static bool _isRasterImagePath(String uri) {
    final lower = uri.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp');
  }

  void _scheduleCandidateAdvance(int gen, int candidateIndex) {
    if (_lastFailureGen == gen &&
        _lastFailureCandidateIndex == candidateIndex) {
      return;
    }
    _lastFailureGen = gen;
    _lastFailureCandidateIndex = candidateIndex;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _advanceCandidateAfterFailure(gen),
    );
  }

  void _advanceCandidateAfterFailure(int gen) {
    if (!mounted || gen != _generation) return;
    if (_candidateIndex + 1 < _candidates.length) {
      var exhausted = false;
      setState(() {
        _candidateIndex++;
        _resolvedLocalProvider = null;
        exhausted = _resolveCurrentCandidate();
      });
      if (exhausted) {
        unawaited(_attemptSandboxTrackRecovery(gen));
      }
    } else {
      setState(() {
        _candidateIndex = _candidates.length;
        _resolvedLocalProvider = null;
      });
      unawaited(_attemptSandboxTrackRecovery(gen));
    }
  }

  /// Synchronously advances past unresolvable or known-missing candidates to
  /// eliminate multi-frame `addPostFrameCallback` cascades. Returns `true` when
  /// all candidates were exhausted synchronously.
  bool _resolveCurrentCandidate() {
    final gen = _generation;
    final loader = _resolveLoader();
    final querySize = _querySize;
    final decodeWidth = _decodeWidthPx;
    final decodeHeight = _decodeHeightPx;

    while (_candidateIndex < _candidates.length) {
      final candidate = _candidates[_candidateIndex];

      if (_isNetworkUrl(candidate)) {
        _resolvedLocalProvider = null;
        return false;
      }

      if (LocalFileUri.isFileSystemUri(candidate) &&
          _isRasterImagePath(candidate)) {
        final path = LocalFileUri.toFilePath(candidate);
        if (path == null || path.isEmpty) {
          _candidateIndex++;
          continue;
        }
        _resolvedLocalProvider = ResizeImage(
          FileImage(File(path)),
          width: decodeWidth,
          height: decodeHeight,
          policy: ResizeImagePolicy.fit,
          allowUpscaling: false,
        );
        return false;
      }

      if (LocalFileUri.isResolvableLocalArtworkUri(candidate) &&
          loader != null) {
        if (loader.isKnownMissing(candidate, querySize: querySize)) {
          _candidateIndex++;
          continue;
        }
        final syncHit = loader.getProviderSync(
          candidate,
          querySize: querySize,
          decodeWidthPx: decodeWidth,
          decodeHeightPx: decodeHeight,
        );
        if (syncHit != null) {
          _resolvedLocalProvider = syncHit;
          return false;
        }
        unawaited(
          loader
              .loadProvider(
                candidate,
                querySize: querySize,
                decodeWidthPx: decodeWidth,
                decodeHeightPx: decodeHeight,
              )
              .then((provider) {
                if (!mounted || gen != _generation) return;
                if (provider != null) {
                  setState(() {
                    _resolvedLocalProvider = provider;
                  });
                } else {
                  _advanceCandidateAfterFailure(gen);
                }
              }),
        );
        return false;
      }

      _candidateIndex++;
    }

    _resolvedLocalProvider = null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final gen = _generation;
    final currentCandidateIndex = _candidateIndex;
    final filterQuality = widget.width > 220 || widget.height > 220
        ? FilterQuality.medium
        : FilterQuality.low;

    if (_resolvedLocalProvider case final provider?) {
      return Image(
        image: provider,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: filterQuality,
        errorBuilder: (_, _, _) {
          _scheduleCandidateAdvance(gen, currentCandidateIndex);
          return _buildPlaceholder(context);
        },
      );
    }

    if (currentCandidateIndex < _candidates.length) {
      final candidate = _candidates[currentCandidateIndex];
      if (_isNetworkUrl(candidate)) {
        return AppNetworkImage(
          imageUrl: candidate,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.cover,
          memCacheWidth: _decodeWidthPx,
          memCacheHeight: _decodeHeightPx,
          fadeInDuration: Duration.zero,
          placeholder: (_, _) => _buildPlaceholder(context),
          errorWidget: (_, _, _) {
            _scheduleCandidateAdvance(gen, currentCandidateIndex);
            return _buildPlaceholder(context);
          },
        );
      }
    }

    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = widget.vaultTheme ?? VaultTheme.of(context);
    return Container(
      width: widget.width,
      height: widget.height,
      color: theme.surfaceSubtle,
      alignment: Alignment.center,
      child: Icon(
        widget.placeholderIcon,
        size: widget.placeholderIconSize,
        color: theme.textLowSalience,
      ),
    );
  }
}
