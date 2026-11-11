import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/domain/commands/options/prepare_play_options.dart';
import 'package:musify_mu/features/player/domain/commands/options/skip_to_track.dart';
import 'package:musify_mu/features/player/domain/models/context.dart';
import 'package:musify_mu/features/player/domain/models/context_page.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/play_origin.dart';
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
  final IMediaMaskingStrategy _decoyStrategy;
  final IMediaMaskingStrategy _passthroughStrategy;

  /// Pure constructor injection. Zero Service Locator calls.
  VaultAudioPlaybackService({
    required PlayerQueueMobiusController mobiusController,
    PlaybackPrivacyProxy? privacyProxy,
    IVaultMediaIsolationManager? isolationManager,
    IMediaMaskingStrategy? decoyStrategy,
    IMediaMaskingStrategy? passthroughStrategy,
  })  : _mobiusController = mobiusController,
        _privacyProxy = privacyProxy,
        _isolationManager = isolationManager,
        _decoyStrategy = switch (decoyStrategy) {
          final d? => d,
          null => const DecoyMediaMaskingStrategy(),
        },
        _passthroughStrategy = switch (passthroughStrategy) {
          final p? => p,
          null => const PassthroughMediaMaskingStrategy(),
        };

  /// Packages a [PrivateTrackRef] into a canonical [ContextTrack] configured
  /// with isolated local file paths and masked or unmasked metadata.
  ContextTrack packagePrivateTrack({
    required PrivateTrackRef trackRef,
    required String isolatedFilePath,
    VaultConfig? config,
  }) {
    final effectiveConfig = switch (config) {
      final c? => c,
      null => const VaultConfig.constant(),
    };

    final rawMetadata = <String, String>{
      ContextTrackMetadata.keyIsLocal: 'true',
      ContextTrackMetadata.keyLocalFilePath: isolatedFilePath,
      ContextTrackMetadata.keyDuration: trackRef.durationMs.toString(),
      ContextTrackMetadata.keyIsQueued: 'false',
      'is_vault_track': 'true',
      'vault_track_id': trackRef.id,
      'vault_playlist_id': trackRef.playlistId,
      ContextTrackMetadata.keyTitle: trackRef.title,
      ContextTrackMetadata.keyArtistName: trackRef.artistName,
      ContextTrackMetadata.keyAlbumArtistName: trackRef.artistName,
      ContextTrackMetadata.keyAlbumTitle: trackRef.albumTitle,
    };

    final strategy = switch (effectiveConfig.metadataVisibility) {
      MetadataVisibilityPolicyEnum.maskWithPlaceholder => _decoyStrategy,
      MetadataVisibilityPolicyEnum.showActualMetadata => _passthroughStrategy,
    };

    final maskedMetadata = strategy.maskMetadata(
      originalMetadata: rawMetadata,
      config: effectiveConfig,
    );

    final resolvedUri = trackRef.trackUri.trim().isNotEmpty
        ? trackRef.trackUri
        : 'file://$isolatedFilePath';

    return ContextTrack(
      uri: resolvedUri,
      uid: 'vault_${trackRef.id}',
      metadata: maskedMetadata,
      provider: 'musify_vault',
    );
  }

  /// Plays a single private vault track through [PlayerQueueMobiusController.playContext].
  Future<void> playPrivateTrack({
    required PrivateTrackRef trackRef,
    required String isolatedFilePath,
    VaultConfig? config,
  }) async {
    final contextTrack = packagePrivateTrack(
      trackRef: trackRef,
      isolatedFilePath: isolatedFilePath,
      config: config,
    );

    final effectiveTitle =
        switch (contextTrack.metadata[ContextTrackMetadata.keyTitle]) {
      final t? when t.isNotEmpty => t,
      _ => trackRef.title,
    };

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

    final contextTracks = <ContextTrack>[];
    for (var i = 0; i < playlist.trackRefs.length; i++) {
      final trackRef = playlist.trackRefs[i];
      final String filePath;

      if (resolvedFilePaths case final paths?) {
        if (i >= paths.length) {
          throw RangeError.index(i, paths, 'resolvedFilePaths');
        }
        filePath = paths[i];
      } else if (_isolationManager case final isoManager?) {
        final isolatedFile = await isoManager.getIsolatedTrackFile(trackRef.id);
        filePath = isolatedFile.path;
      } else {
        throw StateError(
          'Cannot resolve file paths for playlist: neither resolvedFilePaths nor isolationManager was provided.',
        );
      }

      final packaged = packagePrivateTrack(
        trackRef: trackRef,
        isolatedFilePath: filePath,
        config: config,
      );
      contextTracks.add(packaged);
    }

    final tappedTrack = contextTracks[startIndex];
    final tappedTrackRef = playlist.trackRefs[startIndex];

    final page = ContextPage.builder().tracks(contextTracks).build();
    final contextModel =
        Context.builder('spotify:internal:vault-playlist:${playlist.id}')
            .url('context://spotify:internal:vault-playlist:${playlist.id}')
            .metadata({
              ContextTrackMetadata.keyTitle: playlist.name,
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
}
