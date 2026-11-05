import 'dart:async';
import 'dart:developer' as dev;

import '../../../../core/audio/musify_native_audio_engine.dart';
import '../../../../core/media/extended_metadata_service.dart';
import '../../../../core/network/spotify/auth/auth_session_provider.dart';
import '../../../../core/network/spotify/auth/spotify_client_token.dart';
import '../../domain/models/audio_stream_metadata_keys.dart';
import '../../domain/models/context_track.dart';
import 'spotify_head_resolver.dart';
import 'spotify_license_resolver.dart';
import 'spotify_storage_resolver.dart';

/// Coordinator for Spotify audio streaming pipelines, head-chunk prefetching,
/// secondary stream attaching, Widevine DRM licensing, and handover.
///
/// Preserves all metadata keys defined in AudioStreamMetadataKeys:
/// - [AudioStreamMetadataKeys.keyPreviewOggUrl]
/// - [AudioStreamMetadataKeys.keyHeadFileUrl]
/// - [AudioStreamMetadataKeys.keyFileId]
/// - [AudioStreamMetadataKeys.keyAacFileId]
/// - [AudioStreamMetadataKeys.keyCdnAacUrl]
/// - [AudioStreamMetadataKeys.keyLicenseServerUrl]
/// - [AudioStreamMetadataKeys.keyDrmAuthHeader]
/// - [AudioStreamMetadataKeys.keyHandoffPositionMs]
class SpotifyAudioStreamCoordinator {
  final MusifyNativeAudioEngine _engine;
  final ExtendedMetadataService? _metadataService;
  final SpotifyStorageResolver? _storageResolver;
  final SpotifyLicenseResolver? _licenseResolver;
  final AuthSessionProvider? _authSessionProvider;
  final SpotifyClientTokenFetcher? _clientTokenFetcher;

  Timer? _secondaryStreamDebounceTimer;
  String? _currentlyResolvingUri;

  /// Callback fired when JIT metadata resolution resolves full metadata for an active track.
  Future<void> Function(ContextTrack updatedTrack)? onTrackMetadataResolved;

  SpotifyAudioStreamCoordinator({
    required MusifyNativeAudioEngine engine,
    ExtendedMetadataService? metadataService,
    SpotifyStorageResolver? storageResolver,
    SpotifyLicenseResolver? licenseResolver,
    AuthSessionProvider? authSessionProvider,
    SpotifyClientTokenFetcher? clientTokenFetcher,
  })  : _engine = engine,
        _metadataService = metadataService,
        _storageResolver = storageResolver,
        _licenseResolver = licenseResolver,
        _authSessionProvider = authSessionProvider,
        _clientTokenFetcher = clientTokenFetcher;

  void cancelPendingResolutions() {
    _secondaryStreamDebounceTimer?.cancel();
    _secondaryStreamDebounceTimer = null;
    _currentlyResolvingUri = null;
  }

  /// Plays a track using the optimal streaming pipeline:
  /// 1. Local disk file if available
  /// 2. Head-chunk (128 KB) fast-path for < 30ms TTFA
  /// 3. Asynchronous full-stream AAC attach + Widevine DRM resolution
  /// 4. Fallback to standard Vorbis/AAC pipeline
  Future<bool> playTrack(
    ContextTrack track, {
    ContextTrack? nextTrackToPrefetch,
  }) async {
    cancelPendingResolutions();
    _currentlyResolvingUri = track.uri;

    final localPath = switch (track.metadata['local_path']) {
      final p? when p.isNotEmpty => p,
      _ => switch (track.metadata['offline_path']) {
          final op? when op.isNotEmpty => op,
          _ => null,
        },
    };

    if (localPath case final path?) {
      final status = _engine.loadLocal(path);
      if (status == NativeEngineStatus.ok) {
        _engine.play();
        final handoffStr = track.metadata[AudioStreamMetadataKeys.keyHandoffPositionMs];
        if (handoffStr case final str?) {
          final parsed = int.tryParse(str);
          if (parsed case final validParsed? when validParsed > 0) {
            _engine.seekMs(validParsed);
          }
        }
        return true;
      }
      return false;
    }

    String? fileId = switch (track.metadata[AudioStreamMetadataKeys.keyFileId]) {
      final fid? when fid.isNotEmpty => fid,
      _ => switch (track.metadata['file_id']) {
          final fid? when fid.isNotEmpty => fid,
          _ => switch (track.metadata['audio.file_id']) {
              final fid? when fid.isNotEmpty => fid,
              _ => null,
            },
        },
    };

    String? aacFileId = switch (track.metadata[AudioStreamMetadataKeys.keyAacFileId]) {
      final fid? when fid.isNotEmpty => fid,
      _ => switch (track.metadata['aac_file_id']) {
          final fid? when fid.isNotEmpty => fid,
          _ => null,
        },
    };

    String? headUrl = switch (track.metadata[AudioStreamMetadataKeys.keyHeadFileUrl]) {
      final url? when url.isNotEmpty => url,
      _ => switch (track.metadata['head_url']) {
          final url? when url.isNotEmpty => url,
          _ => null,
        },
    };

    if (fileId == null && headUrl != null && headUrl.isNotEmpty) {
      final lastSlash = headUrl.lastIndexOf('/');
      if (lastSlash != -1 && lastSlash < headUrl.length - 1) {
        final extracted = headUrl.substring(lastSlash + 1);
        final normalized = SpotifyHeadResolver.instance.normalizeFileId(extracted);
        if (normalized.isNotEmpty) {
          fileId = normalized;
        }
      }
    }

    // JIT Metadata Resolution if required fields are missing
    final durationMeta = track.metadata[ContextTrackMetadata.keyDuration];
    final bool hasDuration = durationMeta != null && durationMeta.isNotEmpty;

    if ((fileId == null || aacFileId == null || !hasDuration) &&
        track.uri.startsWith('spotify:track:')) {
      final metadataService = _metadataService;
      if (metadataService != null) {
        try {
          final meta = await metadataService.resolve(track.uri).timeout(const Duration(seconds: 8));
          if (meta case final validMeta? when (validMeta.fileId.isNotEmpty || validMeta.aacFileId.isNotEmpty || validMeta.cdnUrl.isNotEmpty)) {
            if (validMeta.fileId.isNotEmpty) fileId = validMeta.fileId;
            if (validMeta.headUrl.isNotEmpty) {
              headUrl = validMeta.headUrl;
            } else if (validMeta.fileId.isNotEmpty) {
              headUrl = SpotifyHeadResolver.instance.buildHeadUrl(validMeta.fileId);
            }
            if (validMeta.aacFileId.isNotEmpty) aacFileId = validMeta.aacFileId;

            final updatedMetadata = Map<String, String>.from(track.metadata);
            if (validMeta.title.isNotEmpty) {
              updatedMetadata[ContextTrackMetadata.keyTitle] = validMeta.title;
            }
            if (validMeta.subtitle.isNotEmpty) {
              updatedMetadata[ContextTrackMetadata.keyArtistName] = validMeta.subtitle;
            }
            if (validMeta.albumName.isNotEmpty) {
              updatedMetadata[ContextTrackMetadata.keyAlbumTitle] = validMeta.albumName;
            }
            if (validMeta.imageUrl.isNotEmpty) {
              updatedMetadata[ContextTrackMetadata.keyImageUrl] = validMeta.imageUrl;
            }
            if (validMeta.thumbnailImageUrl.isNotEmpty) {
              updatedMetadata[ContextTrackMetadata.keyThumbnailImageUrl] = validMeta.thumbnailImageUrl;
            }
            if (validMeta.durationMs > 0) {
              updatedMetadata[ContextTrackMetadata.keyDuration] = validMeta.durationMs.toString();
            }
            if (validMeta.fileId.isNotEmpty) {
              updatedMetadata[AudioStreamMetadataKeys.keyFileId] = validMeta.fileId;
            }
            if (validMeta.aacFileId.isNotEmpty) {
              updatedMetadata[AudioStreamMetadataKeys.keyAacFileId] = validMeta.aacFileId;
            }
            if (headUrl != null && headUrl.isNotEmpty) {
              updatedMetadata[AudioStreamMetadataKeys.keyHeadFileUrl] = headUrl;
            }
            if (validMeta.cdnUrl.isNotEmpty) {
              updatedMetadata[AudioStreamMetadataKeys.keyCdnAacUrl] = validMeta.cdnUrl;
            }

            final updatedTrack = ContextTrack.builder(track.uri)
                .uid(track.uid)
                .metadata(updatedMetadata)
                .build();

            unawaited(onTrackMetadataResolved?.call(updatedTrack));
          }
        } catch (e, stack) {
          dev.log(
            'SpotifyAudioStreamCoordinator: JIT metadata resolution failed for ${track.uri}: $e',
            name: 'AudioStreamCoordinator',
            error: e,
            stackTrace: stack,
          );
        }
      }
    }

    // Canonical Head URL synthesis if fileId is available
    if (fileId != null && fileId.isNotEmpty && (headUrl == null || headUrl.isEmpty)) {
      headUrl = SpotifyHeadResolver.instance.buildHeadUrl(fileId);
    }

    // TTFA Fast Path: Chunk 0 head file playback
    if (fileId != null && fileId.isNotEmpty) {
      final canonicalHeadUrl = (headUrl != null && headUrl.isNotEmpty)
          ? headUrl
          : SpotifyHeadResolver.instance.buildHeadUrl(fileId);

      await SpotifyHeadResolver.instance.resolveOrPrefetchHead(fileId);
      final headsCacheParentDir = await SpotifyHeadResolver.instance.getCacheParentDirectory();

      final cdnAac = track.metadata[AudioStreamMetadataKeys.keyCdnAacUrl];
      final licenseUrl = track.metadata[AudioStreamMetadataKeys.keyLicenseServerUrl];
      final cachedAuth = track.metadata[AudioStreamMetadataKeys.keyDrmAuthHeader];

      String fullTrackUrl = '';
      if (cdnAac case final validAac? when validAac.isNotEmpty) {
        fullTrackUrl = validAac;
      }

      int handoffMs = -1;
      final handoffStr = track.metadata[AudioStreamMetadataKeys.keyHandoffPositionMs];
      if (handoffStr case final str?) {
        final parsed = int.tryParse(str);
        if (parsed case final validParsed?) {
          handoffMs = validParsed;
        }
      }

      int trackDurationMs = -1;
      final metaDurationStr = track.metadata[ContextTrackMetadata.keyDuration];
      if (metaDurationStr != null && metaDurationStr.isNotEmpty) {
        final parsed = int.tryParse(metaDurationStr);
        if (parsed != null && parsed > 0) {
          trackDurationMs = parsed;
        }
      }

      dev.log(
        'SpotifyAudioStreamCoordinator: TTFA fast-path loadTrackWithHead fileId=$fileId, headUrl=$canonicalHeadUrl, fullUrl=$fullTrackUrl',
        name: 'AudioStreamCoordinator',
      );

      final status = _engine.loadTrackWithHead(
        fileIdHex: fileId,
        fullTrackUrl: fullTrackUrl,
        cacheDir: headsCacheParentDir,
        licenseServerUrl: licenseUrl,
        authHeader: cachedAuth,
        trackDurationMs: trackDurationMs,
      );

      if (status == NativeEngineStatus.ok) {
        _engine.play();
        if (handoffMs > 0) {
          _engine.seekMs(handoffMs);
        }

        // Secondary full-track stream attach
        if (fullTrackUrl.isEmpty) {
          _scheduleSecondaryStreamAttach(track, aacFileId);
        }

        // Prefetch next track head
        if (nextTrackToPrefetch != null) {
          unawaited(prefetchHead(nextTrackToPrefetch));
        }

        return true;
      }
    }

    // Fallback: Standard Vorbis or Encrypted playback
    return _playTrackStandardPipeline(
      track: track,
      fileId: fileId,
      aacFileId: aacFileId,
      headUrl: headUrl,
    );
  }

  Future<void> prefetchHead(ContextTrack track) async {
    final fileId = switch (track.metadata[AudioStreamMetadataKeys.keyFileId]) {
      final fid? when fid.isNotEmpty => fid,
      _ => switch (track.metadata['file_id']) {
          final fid? when fid.isNotEmpty => fid,
          _ => null,
        },
    };

    if (fileId != null && fileId.isNotEmpty) {
      await SpotifyHeadResolver.instance.resolveOrPrefetchHead(fileId);
      final cacheDir = await SpotifyHeadResolver.instance.getCacheParentDirectory();
      _engine.prefetchHead(fileIdHex: fileId, cacheDir: cacheDir);
    }
  }

  void _scheduleSecondaryStreamAttach(ContextTrack track, String? aacFileId) {
    _secondaryStreamDebounceTimer?.cancel();
    _secondaryStreamDebounceTimer = Timer(const Duration(milliseconds: 50), () {
      if (_currentlyResolvingUri == track.uri) {
        unawaited(_resolveAndAttachSecondaryStream(track, aacFileId));
      }
    });
  }

  Future<void> _resolveAndAttachSecondaryStream(
    ContextTrack track,
    String? aacFileId,
  ) async {
    final storageResolver = _storageResolver;
    final licenseResolver = _licenseResolver;
    if (storageResolver == null) return;

    try {
      final targetAacId = switch (aacFileId) {
        final id? when id.isNotEmpty => id,
        _ => null,
      };

      if (targetAacId == null) return;

      final resolvedCdn = await storageResolver.resolveCdnUrl(targetAacId);
      if (resolvedCdn == null || resolvedCdn.isEmpty) return;

      String? resolvedLicense;
      if (licenseResolver != null) {
        resolvedLicense = await licenseResolver.resolveLicenseUrl();
      }

      String? authHeader;
      final authProvider = _authSessionProvider;
      if (authProvider != null) {
        final token = await authProvider.getAccessToken();
        if (token != null && token.isNotEmpty) {
          authHeader = 'Bearer $token';
        }
      }

      if (authHeader == null) {
        final clientFetcher = _clientTokenFetcher;
        if (clientFetcher != null) {
          try {
            final clientToken = await clientFetcher.getClientToken();
            if (clientToken != null && clientToken.isNotEmpty) {
              authHeader = 'client-token $clientToken';
            }
          } catch (e, stack) {
            dev.log(
              'SpotifyAudioStreamCoordinator: Failed to fetch client token: $e',
              name: 'AudioStreamCoordinator',
              error: e,
              stackTrace: stack,
            );
          }
        }
      }

      final handoffStr = track.metadata[AudioStreamMetadataKeys.keyHandoffPositionMs];
      int handoffMs = -1;
      if (handoffStr case final str?) {
        final parsed = int.tryParse(str);
        if (parsed case final validParsed?) {
          handoffMs = validParsed;
        }
      }

      _engine.attachSecondaryStream(
        secondaryUrl: resolvedCdn,
        licenseServerUrl: resolvedLicense,
        authHeader: authHeader,
        handoffPositionMs: handoffMs,
      );
    } catch (e, stack) {
      dev.log(
        'SpotifyAudioStreamCoordinator: Failed to attach secondary stream: $e',
        name: 'AudioStreamCoordinator',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<bool> _playTrackStandardPipeline({
    required ContextTrack track,
    String? fileId,
    String? aacFileId,
    String? headUrl,
  }) async {
    final previewOgg = switch (track.metadata[AudioStreamMetadataKeys.keyPreviewOggUrl]) {
      final p? when p.isNotEmpty => p,
      _ => switch (track.metadata['preview_url']) {
          final p? when p.isNotEmpty => p,
          _ => null,
        },
    };

    var cdnAac = track.metadata[AudioStreamMetadataKeys.keyCdnAacUrl];
    var licenseUrl = track.metadata[AudioStreamMetadataKeys.keyLicenseServerUrl];

    final storageResolver = _storageResolver;
    if (storageResolver != null && (cdnAac == null || cdnAac.isEmpty)) {
      final resolveId = switch (aacFileId) {
        final id? when id.isNotEmpty => id,
        _ => switch (fileId) {
            final id? when id.isNotEmpty => id,
            _ => null,
          },
      };

      if (resolveId != null) {
        try {
          final resolved = await storageResolver.resolveCdnUrl(resolveId);
          if (resolved != null && resolved.isNotEmpty) {
            cdnAac = resolved;
          }
        } catch (e, stack) {
          dev.log(
            'SpotifyAudioStreamCoordinator: Failed storageResolver.resolveCdnUrl: $e',
            name: 'AudioStreamCoordinator',
            error: e,
            stackTrace: stack,
          );
        }
      }
    }

    final licenseResolver = _licenseResolver;
    if (licenseResolver != null && (licenseUrl == null || licenseUrl.isEmpty)) {
      try {
        final resolved = await licenseResolver.resolveLicenseUrl();
        if (resolved.isNotEmpty) {
          licenseUrl = resolved;
        }
      } catch (e, stack) {
        dev.log(
          'SpotifyAudioStreamCoordinator: Failed licenseResolver.resolveLicenseUrl: $e',
          name: 'AudioStreamCoordinator',
          error: e,
          stackTrace: stack,
        );
      }
    }

    String? authHeader = track.metadata[AudioStreamMetadataKeys.keyDrmAuthHeader];
    if (authHeader == null || authHeader.isEmpty) {
      final authProvider = _authSessionProvider;
      if (authProvider != null) {
        final token = await authProvider.getAccessToken();
        if (token != null && token.isNotEmpty) {
          authHeader = 'Bearer $token';
        }
      }

      if (authHeader == null) {
        final clientFetcher = _clientTokenFetcher;
        if (clientFetcher != null) {
          try {
            final clientToken = await clientFetcher.getClientToken();
            if (clientToken != null && clientToken.isNotEmpty) {
              authHeader = 'client-token $clientToken';
            }
          } catch (e, stack) {
            dev.log(
              'SpotifyAudioStreamCoordinator: Failed clientFetcher.getClientToken: $e',
              name: 'AudioStreamCoordinator',
              error: e,
              stackTrace: stack,
            );
          }
        }
      }
    }

    // Attempt dual source or encrypted load
    if (previewOgg != null && previewOgg.isNotEmpty && cdnAac != null && cdnAac.isNotEmpty) {
      final status = _engine.loadDualSource(
        primaryPath: previewOgg,
        secondaryUrl: cdnAac,
        licenseServerUrl: licenseUrl,
        authHeader: authHeader,
      );
      if (status == NativeEngineStatus.ok) {
        _engine.play();
        return true;
      }
    }

    if (cdnAac != null && cdnAac.isNotEmpty && licenseUrl != null && licenseUrl.isNotEmpty) {
      final status = _engine.loadEncrypted(
        url: cdnAac,
        licenseServerUrl: licenseUrl,
        authHeader: authHeader,
      );
      if (status == NativeEngineStatus.ok) {
        _engine.play();
        return true;
      }
    }

    if (previewOgg != null && previewOgg.isNotEmpty) {
      final status = _engine.loadLocal(previewOgg);
      if (status == NativeEngineStatus.ok) {
        _engine.play();
        return true;
      }
    }

    return false;
  }
}
