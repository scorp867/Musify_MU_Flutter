import 'dart:async';

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
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/lockout_cooldown_info.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/states/playback_privacy_mode.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';

class FakeControlClient implements ContextPlayerControlClient {
  int stopCallCount = 0;
  int pauseCallCount = 0;
  int resumeCallCount = 0;
  int skipToNextCallCount = 0;

  @override
  Future<PlayerResponse> stop(StopCommand command) async {
    stopCallCount++;
    return PlayerResponse.success;
  }

  @override
  Future<PlayerResponse> pause(PauseCommand command) async {
    pauseCallCount++;
    return PlayerResponse.success;
  }

  @override
  Future<PlayerResponse> resume(ResumeCommand command) async {
    resumeCallCount++;
    return PlayerResponse.success;
  }

  @override
  Future<PlayerResponse> skipToNext(SkipToNextTrackCommand command) async {
    skipToNextCallCount++;
    return PlayerResponse.success;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMobiusController extends ChangeNotifier
    implements PlayerQueueMobiusController {
  final List<QueueEvent> dispatchedEvents = <QueueEvent>[];
  final StreamController<QueueModel> _modelController =
      StreamController<QueueModel>.broadcast();
  QueueModel _model = const QueueModel();
  bool _closed = false;

  final FakeControlClient fakeControlClient = FakeControlClient();

  @override
  ContextPlayerControlClient get controlClient => fakeControlClient;

  @override
  QueueModel get model => _model;

  @override
  QueueModel get state => _model;

  @override
  QueueModel get value => _model;

  @override
  Stream<QueueModel> get stream => _modelController.stream;

  @override
  bool get isClosed => _closed;

  void emitModel(QueueModel newModel) {
    _model = newModel;
    if (!_closed) {
      _modelController.add(newModel);
    }
  }

  @override
  void dispatch(QueueEvent event) {
    dispatchedEvents.add(event);
  }

  @override
  void add(QueueEvent event) {
    dispatch(event);
  }

  @override
  Future<void> playContext(
    Context context, {
    PreparePlayOptions? options,
    PlayOrigin? playOrigin,
  }) async {}

  @override
  Future<void> close() async {
    _closed = true;
    await _modelController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> sessionController =
      StreamController<VaultSessionState>.broadcast();

  @override
  Stream<VaultSessionState> get sessionStateStream =>
      sessionController.stream;

  void emitSessionState(VaultSessionState state) {
    if (!sessionController.isClosed) {
      sessionController.add(state);
    }
  }

  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({
    required String pin,
  }) async =>
      VaultResult.success(
        AuthSession(
          sessionToken: 'test',
          sessionStartedEpochMs: 1,
          lastActiveEpochMs: 1,
          authMethod: AuthMethodEnum.pin,
        ),
      );

  @override
  Future<VaultResult<AuthSession>> authenticateWithBiometrics() async =>
      VaultResult.success(
        AuthSession(
          sessionToken: 'bio',
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

class MockVaultStorageRepository implements IVaultStorageRepository {
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
  group('PlaybackPrivacyProxy Unit Tests', () {
    late FakeMobiusController mobiusController;
    late MockVaultAuthService authService;
    late MockVaultStorageRepository storageRepository;
    late PlaybackPrivacyProxy proxy;

    setUp(() {
      mobiusController = FakeMobiusController();
      authService = MockVaultAuthService();
      storageRepository = MockVaultStorageRepository();

      proxy = PlaybackPrivacyProxy(
        vaultAuthService: authService,
        mobiusController: mobiusController,
        storageRepository: storageRepository,
      );
    });

    tearDown(() async {
      await proxy.dispose();
      await mobiusController.close();
      await authService.sessionController.close();
    });

    const publicTrack = ContextTrack(
      uri: 'spotify:track:public_1',
      uid: 'pub_1',
      provider: 'spotify',
      metadata: {
        ContextTrackMetadata.keyTitle: 'Public Pop Song',
        ContextTrackMetadata.keyArtistName: 'Public Artist',
      },
    );

    const vaultTrack = ContextTrack(
      uri: 'file:///data/vault_media/.nomedia/vtrack_1.mp3',
      uid: 'vault_vtrack_1',
      provider: 'musify_vault',
      metadata: {
        ContextTrackMetadata.keyIsLocal: 'true',
        ContextTrackMetadata.keyLocalFilePath:
            '/data/vault_media/.nomedia/vtrack_1.mp3',
        ContextTrackMetadata.keyTitle: 'Secret Vault Song',
        ContextTrackMetadata.keyArtistName: 'Secret Artist',
        ContextTrackMetadata.keyAlbumTitle: 'Confidential Album',
        ContextTrackMetadata.keyImageUrl: 'https://example.com/vault_art.jpg',
        'is_vault_track': 'true',
        'vault_track_id': 'vtrack_1',
      },
    );

    final standardSession = AuthSession(
      sessionToken: 'test_token',
      sessionStartedEpochMs: 1000,
      lastActiveEpochMs: 1000,
      authMethod: AuthMethodEnum.pin,
    );

    test('T01: Initial state is PublicPassthrough and isIdle is true', () {
      expect(proxy.currentState, isA<PlaybackPrivacyPublicPassthroughState>());
      expect(proxy.isIdle, isTrue);
      expect(proxy.isVaultTrackActive, isFalse);
      expect(proxy.isExecutingLockStrategy, isFalse);
      expect(proxy.isDecoyActive, isFalse);
    });

    test('T02: Public track playback leaves proxy in PublicPassthrough state', () async {
      await proxy.initialize();

      mobiusController.emitModel(
        const QueueModel(currentTrack: publicTrack),
      );

      await Future<void>.delayed(Duration.zero);

      expect(proxy.currentState, isA<PlaybackPrivacyPublicPassthroughState>());
      expect(proxy.isIdle, isTrue);
    });

    test('T03: Vault track playback under maskWithPlaceholder transitions to VaultTrackActive with decoyPersonaProjected', () async {
      storageRepository.config = VaultConfig(
        metadataVisibility: MetadataVisibilityPolicyEnum.maskWithPlaceholder,
        decoyTitle: 'Ghost Decoy',
      );
      await proxy.initialize();

      mobiusController.emitModel(
        const QueueModel(currentTrack: vaultTrack),
      );

      await Future<void>.delayed(Duration.zero);

      expect(proxy.currentState, isA<PlaybackPrivacyVaultTrackActiveState>());
      final active = proxy.currentState as PlaybackPrivacyVaultTrackActiveState;
      expect(active.vaultTrackId, 'vtrack_1');
      expect(active.maskingStatus, PlaybackMaskingStatusEnum.decoyPersonaProjected);
      expect(active.visibilityPolicy, MetadataVisibilityPolicyEnum.maskWithPlaceholder);
      expect(proxy.isVaultTrackActive, isTrue);
      expect(proxy.isDecoyActive, isTrue);
    });

    test('T04: Vault track playback under showActualMetadata transitions to VaultTrackActive with unmasked', () async {
      storageRepository.config = VaultConfig(
        metadataVisibility: MetadataVisibilityPolicyEnum.showActualMetadata,
      );
      await proxy.initialize();

      mobiusController.emitModel(
        const QueueModel(currentTrack: vaultTrack),
      );

      await Future<void>.delayed(Duration.zero);

      expect(proxy.currentState, isA<PlaybackPrivacyVaultTrackActiveState>());
      final active = proxy.currentState as PlaybackPrivacyVaultTrackActiveState;
      expect(active.vaultTrackId, 'vtrack_1');
      expect(active.maskingStatus, PlaybackMaskingStatusEnum.unmasked);
      expect(active.visibilityPolicy, MetadataVisibilityPolicyEnum.showActualMetadata);
      expect(proxy.isDecoyActive, isFalse);
    });

    test('T05: Vault track completion reverts proxy to PublicPassthrough', () async {
      await proxy.initialize();

      mobiusController.emitModel(
        const QueueModel(currentTrack: vaultTrack),
      );
      await Future<void>.delayed(Duration.zero);
      expect(proxy.isVaultTrackActive, isTrue);

      mobiusController.emitModel(
        const QueueModel(currentTrack: null),
      );
      await Future<void>.delayed(Duration.zero);

      expect(proxy.currentState, isA<PlaybackPrivacyPublicPassthroughState>());
      expect(proxy.isIdle, isTrue);
    });

    test('T06: Changing to another vault track updates vaultTrackId', () async {
      await proxy.initialize();

      mobiusController.emitModel(
        const QueueModel(currentTrack: vaultTrack),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        (proxy.currentState as PlaybackPrivacyVaultTrackActiveState).vaultTrackId,
        'vtrack_1',
      );

      const vaultTrack2 = ContextTrack(
        uri: 'file:///data/vault_media/.nomedia/vtrack_2.mp3',
        uid: 'vault_vtrack_2',
        metadata: {
          'is_vault_track': 'true',
          'vault_track_id': 'vtrack_2',
        },
      );

      mobiusController.emitModel(
        const QueueModel(currentTrack: vaultTrack2),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        (proxy.currentState as PlaybackPrivacyVaultTrackActiveState).vaultTrackId,
        'vtrack_2',
      );
    });

    test('T07: notifyVaultTrackActivated triggers immediate transition to VaultTrackActive', () {
      proxy.notifyVaultTrackActivated(
        vaultTrackId: 'vtrack_manual',
        track: vaultTrack,
      );

      expect(proxy.currentState, isA<PlaybackPrivacyVaultTrackActiveState>());
      final active = proxy.currentState as PlaybackPrivacyVaultTrackActiveState;
      expect(active.vaultTrackId, 'vtrack_manual');
    });

    test('T08: projectTrack handles public, masked, unmasked, and locked states', () {
      final unmaskedConfig = VaultConfig(
        metadataVisibility: MetadataVisibilityPolicyEnum.showActualMetadata,
      );
      final maskedConfig = VaultConfig(
        metadataVisibility: MetadataVisibilityPolicyEnum.maskWithPlaceholder,
        decoyTitle: 'Persona Title',
      );

      final projPub = proxy.projectTrack(publicTrack);
      expect(identical(projPub, publicTrack), isTrue);

      proxy.updateConfig(unmaskedConfig);
      proxy.notifyVaultTrackActivated(vaultTrackId: 'vtrack_1', track: vaultTrack);
      final projUnmasked = proxy.projectTrack(vaultTrack);
      expect(projUnmasked.metadata[ContextTrackMetadata.keyTitle], 'Secret Vault Song');

      proxy.updateConfig(maskedConfig);
      final projMasked = proxy.projectTrack(vaultTrack);
      expect(projMasked.metadata[ContextTrackMetadata.keyTitle], 'Persona Title');
      expect(projMasked.metadata.containsKey(ContextTrackMetadata.keyImageUrl), isFalse);
    });

    test('T09: Lock transition under stopImmediately halts playback and evicts queue', () async {
      storageRepository.config = VaultConfig(
        lockPlaybackBehavior: LockPlaybackBehaviorEnum.stopImmediately,
      );
      await proxy.initialize();

      mobiusController.emitModel(
        const QueueModel(currentTrack: vaultTrack),
      );
      await Future<void>.delayed(Duration.zero);
      expect(proxy.isVaultTrackActive, isTrue);

      authService.emitSessionState(
        const VaultLockedState(lockedAtMonotonicMs: 1000),
      );
      await Future<void>.delayed(Duration.zero);

      expect(mobiusController.fakeControlClient.stopCallCount, 1);
      expect(mobiusController.dispatchedEvents, contains(isA<ClearQueueEvent>()));
      expect(proxy.currentState, isA<PlaybackPrivacyPublicPassthroughState>());
    });

    test('T10: Lock transition under finishCurrentTrack clears upcoming tracks and stops on finish', () async {
      storageRepository.config = VaultConfig(
        lockPlaybackBehavior: LockPlaybackBehaviorEnum.finishCurrentTrack,
      );
      await proxy.initialize();

      mobiusController.emitModel(
        const QueueModel(currentTrack: vaultTrack),
      );
      await Future<void>.delayed(Duration.zero);

      authService.emitSessionState(
        const VaultLockedState(lockedAtMonotonicMs: 1000),
      );
      await Future<void>.delayed(Duration.zero);

      expect(mobiusController.fakeControlClient.stopCallCount, 0);
      expect(mobiusController.dispatchedEvents, contains(isA<ClearQueueEvent>()));
      expect(proxy.currentState, isA<PlaybackPrivacyExecutingLockStrategyState>());

      final lockState =
          proxy.currentState as PlaybackPrivacyExecutingLockStrategyState;
      expect(lockState.executingBehavior, LockPlaybackBehaviorEnum.finishCurrentTrack);
      expect(lockState.activeVaultTrackId, 'vtrack_1');

      mobiusController.emitModel(
        const QueueModel(currentTrack: null),
      );
      await Future<void>.delayed(Duration.zero);

      expect(proxy.currentState, isA<PlaybackPrivacyPublicPassthroughState>());
    });

    test('T11: Lock transition under continueMaskedInBackground continues playback with decoy metadata', () async {
      storageRepository.config = VaultConfig(
        lockPlaybackBehavior: LockPlaybackBehaviorEnum.continueMaskedInBackground,
        metadataVisibility: MetadataVisibilityPolicyEnum.showActualMetadata,
        decoyTitle: 'Background Decoy',
      );
      await proxy.initialize();

      mobiusController.emitModel(
        const QueueModel(currentTrack: vaultTrack),
      );
      await Future<void>.delayed(Duration.zero);

      authService.emitSessionState(
        const VaultLockedState(lockedAtMonotonicMs: 1000),
      );
      await Future<void>.delayed(Duration.zero);

      expect(mobiusController.fakeControlClient.stopCallCount, 0);
      expect(proxy.currentState, isA<PlaybackPrivacyExecutingLockStrategyState>());
      expect(proxy.isDecoyActive, isTrue);

      final projected = proxy.projectTrack(vaultTrack);
      expect(projected.metadata[ContextTrackMetadata.keyTitle], 'Background Decoy');
    });

    test('T12: VaultLockoutCooldownState triggers lock strategy execution', () async {
      storageRepository.config = VaultConfig(
        lockPlaybackBehavior: LockPlaybackBehaviorEnum.stopImmediately,
      );
      await proxy.initialize();

      mobiusController.emitModel(
        const QueueModel(currentTrack: vaultTrack),
      );
      await Future<void>.delayed(Duration.zero);

      authService.emitSessionState(
        const VaultLockoutCooldownState(
          tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
          cooldownStartedMonotonicMs: 1000,
          durationMs: 30000,
          deadlineMonotonicMs: 31000,
          failedAttemptsCount: 5,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(mobiusController.fakeControlClient.stopCallCount, 1);
      expect(proxy.currentState, isA<PlaybackPrivacyPublicPassthroughState>());
    });

    test('T13: Background grace and pending re-auth do NOT trigger lock', () async {
      await proxy.initialize();

      mobiusController.emitModel(
        const QueueModel(currentTrack: vaultTrack),
      );
      await Future<void>.delayed(Duration.zero);

      authService.emitSessionState(
        VaultBackgroundGraceState(
          session: standardSession,
          enteredBackgroundMonotonicMs: 1000,
          graceTimeoutMs: 30000,
          graceDeadlineMonotonicMs: 31000,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(proxy.isVaultTrackActive, isTrue);

      authService.emitSessionState(
        VaultPendingReauthState(
          session: standardSession,
          reauthTriggeredAtMonotonicMs: 1000,
          remainingAttempts: 3,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(proxy.isVaultTrackActive, isTrue);
    });

    test('T14: Re-Unlock Recovery restores unmasked VaultTrackActive when vault track still playing', () async {
      storageRepository.config = VaultConfig(
        lockPlaybackBehavior: LockPlaybackBehaviorEnum.continueMaskedInBackground,
        metadataVisibility: MetadataVisibilityPolicyEnum.showActualMetadata,
      );
      await proxy.initialize();

      mobiusController.emitModel(
        const QueueModel(currentTrack: vaultTrack),
      );
      await Future<void>.delayed(Duration.zero);

      authService.emitSessionState(
        const VaultLockedState(lockedAtMonotonicMs: 1000),
      );
      await Future<void>.delayed(Duration.zero);
      expect(proxy.currentState, isA<PlaybackPrivacyExecutingLockStrategyState>());

      authService.emitSessionState(
        VaultUnlockedState(
          session: standardSession,
          unlockedAtMonotonicMs: 2000,
          reauthDeadlineMonotonicMs: 0,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(proxy.currentState, isA<PlaybackPrivacyVaultTrackActiveState>());
      final active = proxy.currentState as PlaybackPrivacyVaultTrackActiveState;
      expect(active.vaultTrackId, 'vtrack_1');
      expect(active.maskingStatus, PlaybackMaskingStatusEnum.unmasked);
      expect(active.visibilityPolicy, MetadataVisibilityPolicyEnum.showActualMetadata);
    });

    test('T15: Re-Unlock Recovery transitions to PublicPassthrough if audio was stopped while locked', () async {
      storageRepository.config = VaultConfig(
        lockPlaybackBehavior: LockPlaybackBehaviorEnum.continueMaskedInBackground,
      );
      await proxy.initialize();

      mobiusController.emitModel(
        const QueueModel(currentTrack: vaultTrack),
      );
      await Future<void>.delayed(Duration.zero);

      authService.emitSessionState(
        const VaultLockedState(lockedAtMonotonicMs: 1000),
      );
      await Future<void>.delayed(Duration.zero);

      mobiusController.emitModel(const QueueModel(currentTrack: null));

      authService.emitSessionState(
        VaultUnlockedState(
          session: standardSession,
          unlockedAtMonotonicMs: 2000,
          reauthDeadlineMonotonicMs: 0,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(proxy.currentState, isA<PlaybackPrivacyPublicPassthroughState>());
    });

    test('T16: updateConfig dynamically updates projection status and persona', () {
      final initialConfig = VaultConfig(
        metadataVisibility: MetadataVisibilityPolicyEnum.showActualMetadata,
      );
      proxy.updateConfig(initialConfig);
      proxy.notifyVaultTrackActivated(vaultTrackId: 'vtrack_1', track: vaultTrack);

      expect(
        (proxy.currentState as PlaybackPrivacyVaultTrackActiveState).maskingStatus,
        PlaybackMaskingStatusEnum.unmasked,
      );

      final newConfig = VaultConfig(
        metadataVisibility: MetadataVisibilityPolicyEnum.maskWithPlaceholder,
        decoyTitle: 'Custom Dynamic Title',
      );
      proxy.updateConfig(newConfig);

      expect(
        (proxy.currentState as PlaybackPrivacyVaultTrackActiveState).maskingStatus,
        PlaybackMaskingStatusEnum.decoyPersonaProjected,
      );

      final projected = proxy.projectTrack(vaultTrack);
      expect(projected.metadata[ContextTrackMetadata.keyTitle], 'Custom Dynamic Title');
    });

    test('T17: stateStream emits sequential state transitions', () async {
      final emittedStates = <PlaybackPrivacyState>[];
      final subscription = proxy.stateStream.listen(emittedStates.add);

      proxy.notifyVaultTrackActivated(vaultTrackId: 'v1', track: vaultTrack);
      proxy.notifyVaultTrackActivated(vaultTrackId: 'v2', track: vaultTrack);

      await Future<void>.delayed(Duration.zero);

      expect(emittedStates.length, 2);
      expect(emittedStates[0], isA<PlaybackPrivacyVaultTrackActiveState>());
      expect(emittedStates[1], isA<PlaybackPrivacyVaultTrackActiveState>());

      await subscription.cancel();
    });

    test('T18: dispose cleans up subscriptions and closes state stream', () async {
      await proxy.initialize();
      expect(proxy.isDisposed, isFalse);

      await proxy.dispose();
      expect(proxy.isDisposed, isTrue);

      proxy.updateConfig(VaultConfig.constant());
      proxy.notifyVaultTrackActivated(vaultTrackId: 'v1', track: vaultTrack);
    });
  });
}
