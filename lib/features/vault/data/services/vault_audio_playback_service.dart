import 'dart:io';

import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/domain/commands/options/prepare_play_options.dart';
import 'package:musify_mu/features/player/domain/commands/options/skip_to_track.dart';
import 'package:musify_mu/features/player/domain/models/context.dart';
import 'package:musify_mu/features/player/domain/models/context_page.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/play_origin.dart';
import 'package:musify_mu/features/vault/data/cache/vault_session_cache.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';
import 'package:musify_mu/features/vault/data/services/playback_privacy_proxy.dart';
import 'package:musify_mu/features/vault/data/strategies/decoy_media_masking_strategy.dart';
import 'package:musify_mu/features/vault/data/strategies/passthrough_media_masking_strategy.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_media_masking_strategy.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';

/// Application service packaging private vault tracks into canonical [ContextTrack] objects
/// and coordinating audio playback via [PlayerQueueMobiusController.playContext].
///
/// Ensures strict integration with Musify's native C++ audio engine (`libmusify_audio.so`)
/// by configuring [ContextTrackMetadata.keyIsLocal] and [ContextTrackMetadata.keyLocalFilePath]
/// without intermediate decoders or secret keys in Dart memory.
class VaultAudioPlaybackService {
  final PlayerQueueMobiusController _mobiusController;
  final PlaybackPrivacyProxy? _privacyProxy;
  final IVaultMediaIsolationManager? _isolationManager;
  final VaultSessionCache? _sessionCache;
  final IMediaMaskingStrategy _decoyStrategy;
  final IMediaMaskingStrategy _passthroughStrategy;

  /// Pure constructor injection. Zero Service Locator calls.
  VaultAudioPlaybackService({
    required PlayerQueueMobiusController mobiusController,
    PlaybackPrivacyProxy? privacyProxy,
    IVaultMediaIsolationManager? isolationManager,
    VaultSessionCache? sessionCache,
    IMediaMaskingStrategy? decoyStrategy,
    IMediaMaskingStrategy? passthroughStrategy,
  })  : _mobiusController = mobiusController,
        _privacyProxy = privacyProxy,
        _isolationManager = isolationManager,
        _sessionCache = sessionCache,
        _decoyStrategy = switch (decoyStrategy) {
          final d? => d,
          null => const DecoyMediaMaskingStrategy(),
        },
        _passthroughStrategy = switch (passthroughStrategy) {
          final p? => p,
          null => const PassthroughMediaMaskingStrategy(),
        };

  VaultConfig _resolveEffectiveConfig(VaultConfig? explicitConfig) {
    return switch (explicitConfig) {
      final c? => c,
      null => switch (_privacyProxy?.cachedConfig) {
        final liveConfig? => liveConfig,
        null => const VaultConfig.constant(),
      },
    };
  }

  /// Packages an unmasked canonical [ContextTrack] preserving original metadata and artwork.
  ContextTrack buildUnmaskedPrivateTrack({
    required PrivateTrackRef trackRef,
    required String isolatedFilePath,
  }) {
    final isLocal = trackRef.sourceType == TrackSourceTypeEnum.localSandbox ||
        trackRef.sourceType == TrackSourceTypeEnum.localReference;

    final effectiveLocalPath = switch (trackRef.sourceType) {
      TrackSourceTypeEnum.localSandbox => isolatedFilePath,
      TrackSourceTypeEnum.localReference => isolatedFilePath.isNotEmpty
          ? isolatedFilePath
          : (trackRef.trackUri.startsWith('file://')
              ? Uri.parse(trackRef.trackUri).toFilePath()
              : trackRef.trackUri),
      TrackSourceTypeEnum.spotify => '',
    };

    final rawMetadata = <String, String>{
      ContextTrackMetadata.keyIsLocal: isLocal ? 'true' : 'false',
      if (effectiveLocalPath.isNotEmpty)
        ContextTrackMetadata.keyLocalFilePath: effectiveLocalPath,
      ContextTrackMetadata.keyDuration: trackRef.durationMs.toString(),
      ContextTrackMetadata.keyIsQueued: 'false',
      'is_vault_track': 'true',
      'vault_track_id': trackRef.id,
      'vault_playlist_id': trackRef.playlistId,
      'vault_source_type': trackRef.sourceType.id,
      ContextTrackMetadata.keyTitle: trackRef.title,
      ContextTrackMetadata.keyArtistName: trackRef.artistName,
      ContextTrackMetadata.keyAlbumArtistName: trackRef.artistName,
      ContextTrackMetadata.keyAlbumTitle: trackRef.albumTitle,
    };

    final artworkUri = switch (trackRef.artworkUri) {
      final art? when art.trim().isNotEmpty => art.trim(),
      _ => switch (trackRef.sourceType) {
        TrackSourceTypeEnum.localSandbox || TrackSourceTypeEnum.localReference
            when effectiveLocalPath.isNotEmpty =>
          'file://$effectiveLocalPath',
        _ => '',
      },
    };
    if (artworkUri.isNotEmpty) {
      rawMetadata[ContextTrackMetadata.keyImageUrl] = artworkUri;
      rawMetadata[ContextTrackMetadata.keyImageLargeUrl] = artworkUri;
      rawMetadata[ContextTrackMetadata.keyImageSmallUrl] = artworkUri;
      rawMetadata[ContextTrackMetadata.keyThumbnailImageUrl] = artworkUri;
    }

    final resolvedUri = trackRef.trackUri.trim().isNotEmpty
        ? trackRef.trackUri
        : (effectiveLocalPath.isNotEmpty ? 'file://$effectiveLocalPath' : 'vault:${trackRef.id}');

    return ContextTrack(
      uri: resolvedUri,
      uid: 'vault_${trackRef.id}',
      metadata: Map<String, String>.unmodifiable(rawMetadata),
      provider: 'musify_vault',
    );
  }

  /// Packages a [PrivateTrackRef] into a canonical [ContextTrack] configured
  /// with isolated local file paths and masked or unmasked metadata.
  ContextTrack packagePrivateTrack({
    required PrivateTrackRef trackRef,
    required String isolatedFilePath,
    VaultConfig? config,
  }) {
    final effectiveConfig = _resolveEffectiveConfig(config);
    final unmaskedTrack = buildUnmaskedPrivateTrack(
      trackRef: trackRef,
      isolatedFilePath: isolatedFilePath,
    );

    final strategy = switch (effectiveConfig.metadataVisibility) {
      MetadataVisibilityPolicyEnum.maskWithPlaceholder => _decoyStrategy,
      MetadataVisibilityPolicyEnum.showActualMetadata => _passthroughStrategy,
    };

    return strategy.projectTrack(
      originalTrack: unmaskedTrack,
      config: effectiveConfig,
    );
  }

  /// Plays a single private vault track through [PlayerQueueMobiusController.playContext].
  Future<void> playPrivateTrack({
    required PrivateTrackRef trackRef,
    required String isolatedFilePath,
    VaultConfig? config,
  }) async {
    final effectiveConfig = _resolveEffectiveConfig(config);
    final effectivePath = switch (trackRef.sourceType) {
      TrackSourceTypeEnum.localSandbox => isolatedFilePath,
      TrackSourceTypeEnum.localReference => isolatedFilePath.isNotEmpty
          ? isolatedFilePath
          : (trackRef.trackUri.startsWith('file://')
              ? Uri.parse(trackRef.trackUri).toFilePath()
              : trackRef.trackUri),
      TrackSourceTypeEnum.spotify => '',
    };

    final unmaskedTrack = buildUnmaskedPrivateTrack(
      trackRef: trackRef,
      isolatedFilePath: effectivePath,
    );

    final contextTrack = packagePrivateTrack(
      trackRef: trackRef,
      isolatedFilePath: effectivePath,
      config: effectiveConfig,
    );

    final effectiveTitle =
        switch (contextTrack.metadata[ContextTrackMetadata.keyTitle]) {
      final t? when t.isNotEmpty => t,
      _ => trackRef.title,
    };

    if (_privacyProxy case final proxy?) {
      proxy.registerOriginalVaultTracks([unmaskedTrack]);
    }

    final page = ContextPage.builder().tracks([contextTrack]).build();
    final contextModel =
        Context.builder('spotify:internal:vault-track:${trackRef.id}')
            .url('context://spotify:internal:vault-track:${trackRef.id}')
            .metadata({
              ContextTrackMetadata.keyTitle: effectiveTitle,
              'is_vault_context': 'true',
              'vault_track_id': trackRef.id,
            })
            .pages([page])
            .build();

    final playOptions = PreparePlayOptions.builder()
        .skipTo(
          SkipToTrack.builder()
              .trackUid(contextTrack.uid)
              .trackUri(contextTrack.uri)
              .build(),
        )
        .build();

    final playOrigin = PlayOrigin(
      featureIdentifier: 'vault_track',
      viewUri: 'spotify:internal:vault-track:${trackRef.id}',
    );

    await _mobiusController.playContext(
      contextModel,
      options: playOptions,
      playOrigin: playOrigin,
    );

    if (_privacyProxy case final proxy?) {
      proxy.notifyVaultTrackActivated(
        vaultTrackId: trackRef.id,
        track: contextTrack,
      );
    }
  }

  /// Plays an entire [PrivatePlaylist] starting at [startIndex] through
  /// [PlayerQueueMobiusController.playContext].
  Future<void> playPrivatePlaylist({
    required PrivatePlaylist playlist,
    List<String>? resolvedFilePaths,
    required int startIndex,
    VaultConfig? config,
  }) async {
    if (playlist.trackRefs.isEmpty) {
      throw StateError('Cannot play an empty private playlist.');
    }
    if (startIndex < 0 || startIndex >= playlist.trackRefs.length) {
      throw RangeError.index(startIndex, playlist.trackRefs, 'startIndex');
    }

    final effectiveConfig = _resolveEffectiveConfig(config);
    final sandboxPathsById = await _resolvePlaylistSandboxPaths(
      tracks: playlist.trackRefs,
      resolvedFilePaths: resolvedFilePaths,
    );
    final unmaskedTracks = <ContextTrack>[];
    final contextTracks = <ContextTrack>[];
    for (var i = 0; i < playlist.trackRefs.length; i++) {
      final trackRef = playlist.trackRefs[i];
      final String filePath;

      if (trackRef.sourceType == TrackSourceTypeEnum.localSandbox) {
        if (resolvedFilePaths case final paths?) {
          if (i >= paths.length) {
            throw RangeError.index(i, paths, 'resolvedFilePaths');
          }
          filePath = paths[i];
        } else if (sandboxPathsById[trackRef.id] case final resolvedPath?) {
          filePath = resolvedPath;
        } else {
          throw StateError(
            'Cannot resolve file paths for playlist: neither resolvedFilePaths nor isolationManager was provided.',
          );
        }
      } else if (trackRef.sourceType == TrackSourceTypeEnum.localReference) {
        if (resolvedFilePaths case final paths? when i < paths.length && paths[i].isNotEmpty) {
          filePath = paths[i];
        } else {
          filePath = trackRef.trackUri.startsWith('file://')
              ? Uri.parse(trackRef.trackUri).toFilePath()
              : trackRef.trackUri;
        }
      } else {
        filePath = '';
      }

      unmaskedTracks.add(
        buildUnmaskedPrivateTrack(
          trackRef: trackRef,
          isolatedFilePath: filePath,
        ),
      );
      contextTracks.add(
        packagePrivateTrack(
          trackRef: trackRef,
          isolatedFilePath: filePath,
          config: effectiveConfig,
        ),
      );
    }

    if (_privacyProxy case final proxy?) {
      proxy.registerOriginalVaultTracks(unmaskedTracks);
    }

    final tappedTrack = contextTracks[startIndex];
    final tappedTrackRef = playlist.trackRefs[startIndex];
    final contextTitle =
        effectiveConfig.metadataVisibility ==
                MetadataVisibilityPolicyEnum.maskWithPlaceholder
            ? effectiveConfig.decoyAlbum
            : playlist.name;

    final page = ContextPage.builder().tracks(contextTracks).build();
    final contextModel =
        Context.builder('spotify:internal:vault-playlist:${playlist.id}')
            .url('context://spotify:internal:vault-playlist:${playlist.id}')
            .metadata({
              ContextTrackMetadata.keyTitle: contextTitle,
              'is_vault_context': 'true',
              'vault_playlist_id': playlist.id,
            })
            .pages([page])
            .build();

    final playOptions = PreparePlayOptions.builder()
        .skipTo(
          SkipToTrack.builder()
              .trackUid(tappedTrack.uid)
              .trackUri(tappedTrack.uri)
              .build(),
        )
        .build();

    final playOrigin = PlayOrigin(
      featureIdentifier: 'vault_playlist',
      viewUri: 'spotify:internal:vault-playlist:${playlist.id}',
    );

    await _mobiusController.playContext(
      contextModel,
      options: playOptions,
      playOrigin: playOrigin,
    );

    if (_privacyProxy case final proxy?) {
      proxy.notifyVaultTrackActivated(
        vaultTrackId: tappedTrackRef.id,
        track: tappedTrack,
      );
    }
  }

  Future<Map<String, String>> _resolvePlaylistSandboxPaths({
    required List<PrivateTrackRef> tracks,
    required List<String>? resolvedFilePaths,
  }) async {
    if (resolvedFilePaths != null) {
      return const <String, String>{};
    }

    final resolved = <String, String>{};
    final missingIds = <String>[];
    final sessionCache = _sessionCache;
    final int? cacheGen = switch (sessionCache) {
      final cache? => cache.generation,
      null => null,
    };

    for (final track in tracks) {
      if (track.sourceType != TrackSourceTypeEnum.localSandbox) {
        continue;
      }
      final cachedPath = sessionCache?.getSandboxFilePath(track.id);
      if (cachedPath != null) {
        resolved[track.id] = cachedPath;
      } else {
        missingIds.add(track.id);
      }
    }

    if (missingIds.isEmpty) {
      return resolved;
    }

    final isoManager = _isolationManager;
    if (isoManager == null) {
      throw StateError(
        'Cannot resolve file paths for playlist: neither resolvedFilePaths nor isolationManager was provided.',
      );
    }

    final newlyResolved = <String, String>{};
    if (isoManager is VaultMediaIsolationManager) {
      final batchFiles = await isoManager.getIsolatedTrackFilesBatch(missingIds);
      for (final id in missingIds) {
        final file = batchFiles[id];
        if (file == null) {
          throw FileSystemException(
            'Isolated track file not found for trackId: "$id"',
            id,
          );
        }
        newlyResolved[id] = file.path;
      }
    } else {
      final entries = await Future.wait(
        missingIds.map((id) async {
          final file = await isoManager.getIsolatedTrackFile(id);
          return MapEntry<String, String>(id, file.path);
        }),
      );
      for (final entry in entries) {
        newlyResolved[entry.key] = entry.value;
      }
    }

    if (sessionCache != null && cacheGen != null) {
      sessionCache.putSandboxFilePathsIfGeneration(cacheGen, newlyResolved);
    }
    resolved.addAll(newlyResolved);
    return resolved;
  }
}
