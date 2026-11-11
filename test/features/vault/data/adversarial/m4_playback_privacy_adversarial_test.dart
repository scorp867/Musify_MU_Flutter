import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_control_client.dart';
import 'package:musify_mu/features/player/domain/commands/options/prepare_play_options.dart';
import 'package:musify_mu/features/player/domain/commands/pause_command.dart';
import 'package:musify_mu/features/player/domain/commands/resume_command.dart';
import 'package:musify_mu/features/player/domain/commands/skip_to_next_track_command.dart';
import 'package:musify_mu/features/player/domain/commands/stop_command.dart';
import 'package:musify_mu/features/player/domain/models/context.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/play_origin.dart';
import 'package:musify_mu/features/player/domain/models/player_response.dart';
import 'package:musify_mu/features/vault/data/services/playback_privacy_proxy.dart';
import 'package:musify_mu/features/vault/data/services/vault_audio_playback_service.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/lockout_cooldown_info.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/states/playback_privacy_mode.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';

class AdversarialFakeControlClient implements ContextPlayerControlClient {
  int stopCalls = 0;
  StopCommand? lastStopCommand;

  @override
  Future<PlayerResponse> stop(StopCommand command) async {
    stopCalls++;
    lastStopCommand = command;
    return PlayerResponse.success;
  }

  @override
  Future<PlayerResponse> pause(PauseCommand command) async =>
      PlayerResponse.success;

  @override
  Future<PlayerResponse> resume(ResumeCommand command) async =>
      PlayerResponse.success;

  @override
  Future<PlayerResponse> skipToNext(SkipToNextTrackCommand command) async =>
      PlayerResponse.success;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdversarialFakeMobiusController extends ChangeNotifier
    implements PlayerQueueMobiusController {
  final List<QueueEvent> dispatchedQueueEvents = <QueueEvent>[];
  final StreamController<QueueModel> _modelStream =
      StreamController<QueueModel>.broadcast();
  QueueModel _currentQueueModel = const QueueModel();
  bool _closed = false;

  final AdversarialFakeControlClient client = AdversarialFakeControlClient();

  @override
  ContextPlayerControlClient get controlClient => client;

  @override
  QueueModel get model => _currentQueueModel;

  @override
  QueueModel get state => _currentQueueModel;

  @override
  QueueModel get value => _currentQueueModel;

  @override
  Stream<QueueModel> get stream => _modelStream.stream;

  @override
  bool get isClosed => _closed;

  void emit(QueueModel model) {
    _currentQueueModel = model;
    if (!_closed) {
      _modelStream.add(model);
    }
  }

  @override
  void dispatch(QueueEvent event) {
    dispatchedQueueEvents.add(event);
  }

  @override
  void add(QueueEvent event) => dispatch(event);

  @override
  Future<void> playContext(
    Context context, {
    PreparePlayOptions? options,
    PlayOrigin? playOrigin,
  }) async {}

  @override
  Future<void> close() async {
    _closed = true;
    await _modelStream.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdversarialMockAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> stateStreamController =
      StreamController<VaultSessionState>.broadcast();

  @override
  Stream<VaultSessionState> get sessionStateStream =>
      stateStreamController.stream;

  void emit(VaultSessionState state) {
    if (!stateStreamController.isClosed) {
      stateStreamController.add(state);
    }
  }

  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({
    required String pin,
  }) async =>
      VaultResult.success(
        AuthSession(
          sessionToken: 'adv_tok',
          sessionStartedEpochMs: 1,
          lastActiveEpochMs: 1,
          authMethod: AuthMethodEnum.pin,
        ),
      );

  @override
  Future<VaultResult<AuthSession>> authenticateWithBiometrics() async =>
      VaultResult.success(
        AuthSession(
          sessionToken: 'adv_bio',
          sessionStartedEpochMs: 1,
          lastActiveEpochMs: 1,
          authMethod: AuthMethodEnum.biometric,
        ),
      );

  @override
  Future<void> recordFailedAttempt() async {}

  @override
  Future<void> resetFailedAttempts() async {}

  @override
  Future<LockoutCooldownInfo> getLockoutStatus() async =>
      LockoutCooldownInfo.none();

  @override
  Future<VaultResult<void>> rotatePin({
    required String oldPin,
    required String newPin,
  }) async =>
      const VaultResult.success(null);

  @override
  Future<void> clearSessionKeysFromRam() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdversarialMockStorageRepository implements IVaultStorageRepository {
  VaultConfig config = VaultConfig.constant();

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      VaultResult.success(config);

  @override
  Future<VaultResult<void>> saveVaultConfig(VaultConfig newConfig) async {
    config = newConfig;
    return const VaultResult.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('M4 Playback Privacy Adversarial Stress Suite', () {
    late AdversarialFakeMobiusController mobiusController;
    late AdversarialMockAuthService authService;
    late AdversarialMockStorageRepository storageRepository;
    late PlaybackPrivacyProxy proxy;
    late VaultAudioPlaybackService playbackService;

    setUp(() {
      mobiusController = AdversarialFakeMobiusController();
      authService = AdversarialMockAuthService();
      storageRepository = AdversarialMockStorageRepository();

      proxy = PlaybackPrivacyProxy(
        vaultAuthService: authService,
        mobiusController: mobiusController,
        storageRepository: storageRepository,
      );

      playbackService = VaultAudioPlaybackService(
        mobiusController: mobiusController,
        privacyProxy: proxy,
      );
    });

    tearDown(() async {
      await proxy.dispose();
      await mobiusController.close();
      await authService.stateStreamController.close();
    });

    const highEntropySecretTitle = 'CONFIDENTIAL_BANKING_TELEMETRY_0x892B';
    const highEntropySecretArtist = 'CLASSIFIED_SOURCE_WHISPER_0x77A';
    const highEntropySecretAlbum = 'TOP_SECRET_DOSSIER_2026';
    const highEntropyArtworkUrl = 'https://blackops.internal/classified_cover.png';

    final sensitiveTrack = PrivateTrackRef(
      id: 'adv_track_001',
      playlistId: 'adv_playlist_001',
      trackUri: 'spotify:track:classified_secret',
      title: highEntropySecretTitle,
      artistName: highEntropySecretArtist,
      albumTitle: highEntropySecretAlbum,
      durationMs: 312000,
      sourceType: TrackSourceTypeEnum.localSandbox,
      localRelativePath: 'vault_media/.nomedia/adv_track_001.mp3',
      sortOrder: 0,
      addedAtEpochMs: 123456789,
    );

    test('Adv-01: Zero Metadata Leakage Attack on Public Surfaces', () {
      final config = VaultConfig(
        metadataVisibility: MetadataVisibilityPolicyEnum.maskWithPlaceholder,
        decoyTitle: 'System Decoy Audio',
        decoyArtist: 'OS Audio Host',
        decoyAlbum: 'Default Media Container',
      );

      final packaged = playbackService.packagePrivateTrack(
        trackRef: sensitiveTrack,
        isolatedFilePath: '/data/user/0/app/vault_media/.nomedia/adv_track_001.mp3',
        config: config,
      );

      // Verify that zero bytes of sensitive metadata appear in values
      for (final value in packaged.metadata.values) {
        expect(value.contains(highEntropySecretTitle), isFalse);
        expect(value.contains(highEntropySecretArtist), isFalse);
        expect(value.contains(highEntropySecretAlbum), isFalse);
        expect(value.contains(highEntropyArtworkUrl), isFalse);
      }

      // Verify display strings are strictly decoy persona
      expect(packaged.metadata[ContextTrackMetadata.keyTitle], 'System Decoy Audio');
      expect(packaged.metadata[ContextTrackMetadata.keyArtistName], 'OS Audio Host');
      expect(packaged.metadata[ContextTrackMetadata.keyAlbumTitle], 'Default Media Container');

      // Verify artwork keys are completely stripped
      expect(packaged.metadata.containsKey(ContextTrackMetadata.keyImageUrl), isFalse);
      expect(packaged.metadata.containsKey(ContextTrackMetadata.keyThumbnailImageUrl), isFalse);

      // Verify internal local playback file path is intact for C++ engine
      expect(
        packaged.metadata[ContextTrackMetadata.keyLocalFilePath],
        '/data/user/0/app/vault_media/.nomedia/adv_track_001.mp3',
      );
      expect(packaged.metadata[ContextTrackMetadata.keyIsLocal], 'true');
    });

    test('Adv-02: Rapid Re-Unlock Bouncing & Concurrency Stress (100 Iterations)', () async {
      storageRepository.config = VaultConfig(
        lockPlaybackBehavior: LockPlaybackBehaviorEnum.continueMaskedInBackground,
        metadataVisibility: MetadataVisibilityPolicyEnum.showActualMetadata,
      );
      await proxy.initialize();

      final packagedTrack = playbackService.packagePrivateTrack(
        trackRef: sensitiveTrack,
        isolatedFilePath: '/data/vault_media/.nomedia/adv_track_001.mp3',
        config: storageRepository.config,
      );

      mobiusController.emit(QueueModel(currentTrack: packagedTrack));
      await Future<void>.delayed(Duration.zero);
      expect(proxy.isVaultTrackActive, isTrue);

      final session = AuthSession(
        sessionToken: 'stress_token',
        sessionStartedEpochMs: 1000,
        lastActiveEpochMs: 1000,
        authMethod: AuthMethodEnum.pin,
      );

      // Rapidly alternate lock and unlock states 100 times
      for (var i = 0; i < 100; i++) {
        authService.emit(
          VaultLockedState(lockedAtMonotonicMs: 1000 + i * 10),
        );
        authService.emit(
          VaultUnlockedState(
            session: session,
            unlockedAtMonotonicMs: 1000 + i * 10 + 5,
            reauthDeadlineMonotonicMs: 0,
          ),
        );
      }

      await Future<void>.delayed(Duration.zero);

      // Final state must remain deterministic and healthy
      expect(proxy.currentState, isA<PlaybackPrivacyVaultTrackActiveState>());
      expect(proxy.isVaultTrackActive, isTrue);
      expect(mobiusController.client.stopCalls, 0);
    });

    test('Adv-03: Lookahead Queue Snooping Prevention Under FinishCurrentTrack', () async {
      storageRepository.config = VaultConfig(
        lockPlaybackBehavior: LockPlaybackBehaviorEnum.finishCurrentTrack,
      );
      await proxy.initialize();

      final current = playbackService.packagePrivateTrack(
        trackRef: sensitiveTrack,
        isolatedFilePath: '/data/vault_media/.nomedia/adv_track_001.mp3',
        config: storageRepository.config,
      );

      mobiusController.emit(QueueModel(currentTrack: current));
      await Future<void>.delayed(Duration.zero);

      // Lock triggered
      authService.emit(const VaultLockedState(lockedAtMonotonicMs: 2000));
      await Future<void>.delayed(Duration.zero);

      // Must have cleared upcoming queue to prevent lookahead track snooping
      expect(mobiusController.dispatchedQueueEvents, contains(isA<ClearQueueEvent>()));
      expect(proxy.currentState, isA<PlaybackPrivacyExecutingLockStrategyState>());

      // Subsequent track arrives after track finished
      final nextSneakyTrack = ContextTrack(
        uri: 'file:///data/vault_media/.nomedia/sneaky.mp3',
        uid: 'vault_sneaky',
        metadata: {
          'is_vault_track': 'true',
          'vault_track_id': 'sneaky_002',
        },
      );

      mobiusController.emit(QueueModel(currentTrack: nextSneakyTrack));
      await Future<void>.delayed(Duration.zero);

      // Must have halted playback and reverted to public passthrough
      expect(mobiusController.client.stopCalls, 1);
      expect(proxy.currentState, isA<PlaybackPrivacyPublicPassthroughState>());
    });

    test('Adv-04: Unicode Edge Cases & Extreme Decoy Persona Strings', () {
      const extremeUnicodeTitle = 'عنوان وهمي 🎵 \u200E\u200F 測試 100% 🔊';
      const extremeUnicodeArtist = 'Исполнитель Призрак ⚡ 999';
      const extremeUnicodeAlbum = 'อัลบั้มลับ 🛡️ Top Confidential';

      final extremeConfig = VaultConfig(
        metadataVisibility: MetadataVisibilityPolicyEnum.maskWithPlaceholder,
        decoyTitle: extremeUnicodeTitle,
        decoyArtist: extremeUnicodeArtist,
        decoyAlbum: extremeUnicodeAlbum,
      );

      final track = playbackService.packagePrivateTrack(
        trackRef: sensitiveTrack,
        isolatedFilePath: '/data/vault_media/.nomedia/adv.mp3',
        config: extremeConfig,
      );

      expect(track.metadata[ContextTrackMetadata.keyTitle], extremeUnicodeTitle);
      expect(track.metadata[ContextTrackMetadata.keyArtistName], extremeUnicodeArtist);
      expect(track.metadata[ContextTrackMetadata.keyAlbumTitle], extremeUnicodeAlbum);
    });

    test('Adv-05: Source Code Audit Verifying ZERO Forbidden Audio Libraries', () {
      final strategiesDir = Directory('lib/features/vault/data/strategies');
      final servicesDir = Directory('lib/features/vault/data/services');

      final allFiles = <File>[
        ...strategiesDir.listSync().whereType<File>(),
        ...servicesDir.listSync().whereType<File>(),
      ];

      expect(allFiles.isNotEmpty, isTrue);

      final bannedTokens = [
        'just_audio',
        'audio_service',
        'exoplayer',
        'ExoPlayer',
        'package:just_audio',
        'package:audio_service',
      ];

      for (final file in allFiles) {
        final content = file.readAsStringSync();
        for (final token in bannedTokens) {
          expect(
            content.contains(token),
            isFalse,
            reason: 'Found banned token "$token" in ${file.path}',
          );
        }
      }
    });

    test('Adv-06: Pre-Commit Invariant Gate AST Scan (Zero ??, Zero !, Zero dynamic in code)', () {
      final m4Files = [
        File('lib/features/vault/data/strategies/decoy_media_masking_strategy.dart'),
        File('lib/features/vault/data/strategies/passthrough_media_masking_strategy.dart'),
        File('lib/features/vault/data/strategies/stop_immediately_lock_strategy.dart'),
        File('lib/features/vault/data/strategies/finish_current_track_lock_strategy.dart'),
        File('lib/features/vault/data/strategies/continue_masked_lock_strategy.dart'),
        File('lib/features/vault/data/services/vault_audio_playback_service.dart'),
        File('lib/features/vault/data/services/playback_privacy_proxy.dart'),
      ];

      for (final file in m4Files) {
        expect(file.existsSync(), isTrue);
        final lines = file.readAsLinesSync();

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final lineNum = i + 1;

          // Ignore comments
          final trimmed = line.trim();
          if (trimmed.startsWith('//') || trimmed.startsWith('///') || trimmed.startsWith('*')) {
            continue;
          }

          // Check for forbidden ??
          expect(
            line.contains('??'),
            isFalse,
            reason: 'Line $lineNum in ${file.path} contains forbidden fallback "??": "$line"',
          );

          // Check for forbidden dynamic keyword in code
          expect(
            RegExp(r'\bdynamic\b').hasMatch(line),
            isFalse,
            reason: 'Line $lineNum in ${file.path} contains forbidden "dynamic": "$line"',
          );

          // Check for non-null assertion ! (exclude !=, !_, is!, !is)
          final stripped = line
              .replaceAll('!=', '')
              .replaceAll('!is', '')
              .replaceAll('is!', '');
          final hasBang = RegExp(r'[\w\)\]]\s*!\s*[\.\,\;\)\]\}]').hasMatch(stripped);
          expect(
            hasBang,
            isFalse,
            reason: 'Line $lineNum in ${file.path} contains forbidden non-null assertion "!": "$line"',
          );
        }
      }
    });
  });
}
