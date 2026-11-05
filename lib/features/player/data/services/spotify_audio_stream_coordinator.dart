import 'dart:async';
import 'dart:developer' as dev;

import '../../../../core/audio/musify_native_audio_engine.dart';
import '../../../../core/media/extended_metadata_service.dart';
import '../../../../core/network/spotify/auth/auth_session_provider.dart';
import '../../../../core/network/spotify/auth/spotify_client_token.dart';
import '../../domain/models/context_track.dart';
import 'spotify_audio_stream_registry.dart';
import 'spotify_head_resolver.dart';
import 'spotify_license_resolver.dart';
import 'spotify_storage_resolver.dart';

/// Coordinator for Spotify audio streaming pipelines, head-chunk prefetching,
/// secondary stream attaching, Widevine DRM licensing, and handover.
///
/// Handles audio stream transport metadata (file IDs, CDN URLs, DRM auth headers)
/// privately via [SpotifyAudioStreamRegistry], preserving Spotify's canonical
/// [ContextTrack] domain models cleanly without pollution.
class SpotifyAudioStreamCoordinator {
  final MusifyNativeAudioEngine _engine;
  final ExtendedMetadataService? _metadataService;
  final SpotifyStorageResolver? _storageResolver;
  final SpotifyLicenseResolver? _licenseResolver;
  final AuthSessionProvider? _authSessionProvider;
  final SpotifyClientTokenFetcher? _clientTokenFetcher;

  Timer? _secondaryStreamDebounceTimer;
  String? _currentlyResolvingUri;

  /// Callback fired when JIT metadata resolution resolves full canonical metadata for an active track.
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

    final streamInfo = SpotifyAudioStreamRegistry.instance.get(track.uri);

    final localPath = switch (streamInfo?.localPath) {
      final lp? when lp.isNotEmpty => lp,
      _ => switch (track.metadata['local_path']) {
          final p? when p.isNotEmpty => p,
          _ => switch (track.metadata['offline_path']) {
              final op? when op.isNotEmpty => op,
              _ => null,
            },
        },
    };

    if (localPath case final path?) {
      final status = _engine.loadLocal(path);
      if (status == NativeEngineStatus.ok) {
        _engine.play();
        final handoffPos = streamInfo?.handoffPositionMs;
        if (handoffPos case final validPos? when validPos > 0) {
          _engine.seekMs(validPos);
        } else if (track.metadata['handoff_position_ms'] case final str? when str.isNotEmpty) {
          final parsed = int.tryParse(str);
          if (parsed case final validParsed? when validParsed > 0) {
            _engine.seekMs(validParsed);
          }
        }
        return true;
      }
      return false;
    }

    String? fileId = switch (streamInfo?.fileId) {
      final fid? when fid.isNotEmpty => fid,
      _ => switch (track.metadata['file_id']) {
          final fid? when fid.isNotEmpty => fid,
          _ => switch (track.metadata['audio.file_id']) {
              final fid? when fid.isNotEmpty => fid,
              _ => null,
            },
        },
    };

    String? aacFileId = switch (streamInfo?.aacFileId) {
      final fid? when fid.isNotEmpty => fid,
      _ => switch (track.metadata['aac_file_id']) {
          final fid? when fid.isNotEmpty => fid,
          _ => null,
        },
    };

    String? headUrl = switch (streamInfo?.headUrl) {
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

    // JIT Metadata Resolution if required canonical fields are missing
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

            SpotifyAudioStreamRegistry.instance.register(
              track.uri,
              TrackStreamInfo(
                fileId: validMeta.fileId.isNotEmpty ? validMeta.fileId : null,
                aacFileId: validMeta.aacFileId.isNotEmpty ? validMeta.aacFileId : null,
                headUrl: headUrl,
                cdnUrl: validMeta.cdnUrl.isNotEmpty ? validMeta.cdnUrl : null,
              ),
            );

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

      final currentStreamInfo = SpotifyAudioStreamRegistry.instance.get(track.uri);

      final cdnAac = switch (currentStreamInfo?.cdnUrl) {
        final cdn? when cdn.isNotEmpty => cdn,
        _ => track.metadata['cdn_aac_url'],
      };
      final licenseUrl = switch (currentStreamInfo?.licenseServerUrl) {
        final lic? when lic.isNotEmpty => lic,
        _ => track.metadata['license_server_url'],
      };
      final cachedAuth = switch (currentStreamInfo?.drmAuthHeader) {
        final auth? when auth.isNotEmpty => auth,
        _ => track.metadata['drm_auth_header'],
      };

      String fullTrackUrl = '';
      if (cdnAac case final validAac? when validAac.isNotEmpty) {
        fullTrackUrl = validAac;
      }

      int handoffMs = -1;
      if (currentStreamInfo?.handoffPositionMs case final pos? when pos > 0) {
        handoffMs = pos;
      } else if (track.metadata['handoff_position_ms'] case final str? when str.isNotEmpty) {
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
    final streamInfo = SpotifyAudioStreamRegistry.instance.get(track.uri);
    final fileId = switch (streamInfo?.fileId) {
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
      var streamInfo = SpotifyAudioStreamRegistry.instance.get(track.uri);

      // Robust target file ID resolution:
      // Priority: aacFileId param -> registry aacFileId -> registry fileId -> track metadata file_id
      String? targetId = switch (aacFileId) {
        final id? when id.isNotEmpty => id,
        _ => switch (streamInfo?.aacFileId) {
          final id? when id.isNotEmpty => id,
          _ => switch (streamInfo?.fileId) {
            final fid? when fid.isNotEmpty => fid,
            _ => switch (track.metadata['file_id']) {
              final fid? when fid.isNotEmpty => fid,
              _ => null,
            },
          },
        },
      };

      int trackDurationMs = -1;
      final metaDurationStr = track.metadata[ContextTrackMetadata.keyDuration];
      if (metaDurationStr != null && metaDurationStr.isNotEmpty) {
        final parsed = int.tryParse(metaDurationStr);
        if (parsed != null && parsed > 0) {
          trackDurationMs = parsed;
        }
      }

      // If targetId is missing or duration is unknown, perform JIT metadata resolution
      if (targetId == null || trackDurationMs <= 0) {
        final metadataService = _metadataService;
        if (metadataService != null && track.uri.startsWith('spotify:track:')) {
          try {
            final meta = await metadataService.resolve(track.uri).timeout(const Duration(seconds: 4));
            if (meta case final validMeta? when (validMeta.fileId.isNotEmpty || validMeta.aacFileId.isNotEmpty)) {
              targetId = switch (targetId) {
                final id? when id.isNotEmpty => id,
                _ => validMeta.aacFileId.isNotEmpty ? validMeta.aacFileId : validMeta.fileId,
              };
              if (trackDurationMs <= 0 && validMeta.durationMs > 0) {
                trackDurationMs = validMeta.durationMs;
              }
              SpotifyAudioStreamRegistry.instance.register(
                track.uri,
                TrackStreamInfo(
                  fileId: validMeta.fileId.isNotEmpty ? validMeta.fileId : null,
                  aacFileId: validMeta.aacFileId.isNotEmpty ? validMeta.aacFileId : null,
                  headUrl: validMeta.headUrl.isNotEmpty ? validMeta.headUrl : null,
                  cdnUrl: validMeta.cdnUrl.isNotEmpty ? validMeta.cdnUrl : null,
                ),
              );
              streamInfo = SpotifyAudioStreamRegistry.instance.get(track.uri);
            }
          } catch (e, stack) {
            dev.log(
              'SpotifyAudioStreamCoordinator: Secondary JIT resolve failed for ${track.uri}: $e',
              name: 'AudioStreamCoordinator',
              error: e,
              stackTrace: stack,
            );
          }
        }
      }

      if (targetId == null || targetId.isEmpty) {
        dev.log(
          'SpotifyAudioStreamCoordinator: No target file ID available for secondary attach (${track.uri})',
          name: 'AudioStreamCoordinator',
        );
        return;
      }

      // Parallel resolution of CDN URL, Widevine license URL, access token, and client token
      final authProvider = _authSessionProvider;
      final clientFetcher = _clientTokenFetcher;

      final results = await Future.wait([
        storageResolver.resolveCdnUrl(targetId),
        licenseResolver != null ? licenseResolver.resolveLicenseUrl() : Future<String>.value(''),
        authProvider != null ? authProvider.getAccessToken() : Future<String?>.value(null),
        clientFetcher != null ? clientFetcher.getClientToken() : Future<String?>.value(null),
      ]);

      final resolvedCdn = results[0];
      if (resolvedCdn == null || resolvedCdn.isEmpty) {
        dev.log(
          'SpotifyAudioStreamCoordinator: Failed to resolve CDN URL for $targetId (${track.uri})',
          name: 'AudioStreamCoordinator',
        );
        return;
      }

      final rawLicense = results[1];
      final resolvedLicense = (rawLicense != null && rawLicense.isNotEmpty) ? rawLicense : null;
      final token = results[2];
      final clientToken = results[3];

      final authHeaderBuffer = StringBuffer();
      if (token != null && token.isNotEmpty) {
        authHeaderBuffer.write('Bearer $token');
      }
      if (clientToken != null && clientToken.isNotEmpty) {
        if (authHeaderBuffer.isNotEmpty) {
          authHeaderBuffer.write('\n');
        }
        authHeaderBuffer.write('client-token: $clientToken');
      }
      final authHeader = authHeaderBuffer.isNotEmpty ? authHeaderBuffer.toString() : null;

      // Abort if user switched tracks while resolving
      if (_currentlyResolvingUri != track.uri) {
        dev.log(
          'SpotifyAudioStreamCoordinator: Track changed during secondary attach (${track.uri} -> $_currentlyResolvingUri), discarding',
          name: 'AudioStreamCoordinator',
        );
        return;
      }

      int handoffMs = -1;
      if (streamInfo?.handoffPositionMs case final pos? when pos > 0) {
        handoffMs = pos;
      } else if (track.metadata['handoff_position_ms'] case final str? when str.isNotEmpty) {
        final parsed = int.tryParse(str);
        if (parsed case final validParsed? when validParsed > 0) {
          handoffMs = validParsed;
        }
      }

      final status = _engine.attachSecondaryStream(
        secondaryUrl: resolvedCdn,
        licenseServerUrl: resolvedLicense,
        authHeader: authHeader,
        handoffPositionMs: handoffMs,
      );

      if (status == NativeEngineStatus.ok && _currentlyResolvingUri == track.uri) {
        SpotifyAudioStreamRegistry.instance.updateSecondaryStream(
          track.uri,
          cdnUrl: resolvedCdn,
          licenseServerUrl: resolvedLicense,
          drmAuthHeader: authHeader,
        );

        // Update C++ ContextPlayerImpl with canonical duration if known
        if (trackDurationMs > 0) {
          final updatedMetadata = Map<String, String>.from(track.metadata);
          updatedMetadata[ContextTrackMetadata.keyDuration] = trackDurationMs.toString();
          final updatedTrack = ContextTrack.builder(track.uri)
              .uid(track.uid)
              .metadata(updatedMetadata)
              .build();
          unawaited(onTrackMetadataResolved?.call(updatedTrack));
        }
      }
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
    final streamInfo = SpotifyAudioStreamRegistry.instance.get(track.uri);

    final previewOgg = switch (streamInfo?.previewOggUrl) {
      final p? when p.isNotEmpty => p,
      _ => switch (track.metadata['preview_url']) {
          final p? when p.isNotEmpty => p,
          _ => null,
        },
    };

    var cdnAac = switch (streamInfo?.cdnUrl) {
      final cdn? when cdn.isNotEmpty => cdn,
      _ => track.metadata['cdn_aac_url'],
    };
    var licenseUrl = switch (streamInfo?.licenseServerUrl) {
      final lic? when lic.isNotEmpty => lic,
      _ => track.metadata['license_server_url'],
    };

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

    String? authHeader = switch (streamInfo?.drmAuthHeader) {
      final auth? when auth.isNotEmpty => auth,
      _ => track.metadata['drm_auth_header'],
    };

    if (authHeader == null || authHeader.isEmpty) {
      final authProvider = _authSessionProvider;
      final clientFetcher = _clientTokenFetcher;

      String? token;
      if (authProvider != null) {
        token = await authProvider.getAccessToken();
      }

      String? clientToken;
      if (clientFetcher != null) {
        try {
          clientToken = await clientFetcher.getClientToken();
        } catch (e, stack) {
          dev.log(
            'SpotifyAudioStreamCoordinator: Failed clientFetcher.getClientToken: $e',
            name: 'AudioStreamCoordinator',
            error: e,
            stackTrace: stack,
          );
        }
      }

      final authHeaderBuffer = StringBuffer();
      if (token != null && token.isNotEmpty) {
        authHeaderBuffer.write('Bearer $token');
      }
      if (clientToken != null && clientToken.isNotEmpty) {
        if (authHeaderBuffer.isNotEmpty) {
          authHeaderBuffer.write('\n');
        }
        authHeaderBuffer.write('client-token: $clientToken');
      }
      if (authHeaderBuffer.isNotEmpty) {
        authHeader = authHeaderBuffer.toString();
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
