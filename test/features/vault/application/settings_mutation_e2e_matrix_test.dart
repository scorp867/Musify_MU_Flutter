import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_control_client.dart';
import 'package:musify_mu/features/player/domain/commands/pause_command.dart';
import 'package:musify_mu/features/player/domain/commands/resume_command.dart';
import 'package:musify_mu/features/player/domain/commands/skip_to_next_track_command.dart';
import 'package:musify_mu/features/player/domain/commands/stop_command.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';
import 'package:musify_mu/features/player/domain/models/player_response.dart';
import 'package:musify_mu/features/vault/application/gesture/gesture_engine_cubit.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/data/database/vault_database.dart';
import 'package:musify_mu/features/vault/data/datasources/platform_security_channel.dart';
import 'package:musify_mu/features/vault/data/repositories/vault_storage_repository.dart';
import 'package:musify_mu/features/vault/data/services/playback_privacy_proxy.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_screen_privacy_controller.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/policies/active_reauth_interval.dart';
import 'package:musify_mu/features/vault/domain/policies/background_grace_timeout.dart';
import 'package:musify_mu/features/vault/domain/policies/biometric_auth_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/keypad_layout_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/screen_security_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/settings_mutation_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/mutate_vault_config_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';

import '../helpers/mock_native_vault_crypto_bridge.dart';

/// Test implementation of [IMonotonicClock] enabling discrete time-travel control.
class FakeMonotonicClock implements IMonotonicClock {
  int timeMs = 1000;

  FakeMonotonicClock([this.timeMs = 1000]);

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();

  void advance(int milliseconds) {
    timeMs += milliseconds;
  }

  void setTime(int milliseconds) {
    timeMs = milliseconds;
  }
}

/// Fake implementation of [IVaultAuthService] for testing auth handoffs and key wipes.
class FakeVaultAuthService implements IVaultAuthService {
  int failedAttempts = 0;
  bool keysClearedFromRam = false;
  int recordFailedAttemptCallCount = 0;
  int resetFailedAttemptsCallCount = 0;

  @override
  Future<void> recordFailedAttempt() async {
    failedAttempts++;
    recordFailedAttemptCallCount++;
  }

  @override
  Future<void> resetFailedAttempts() async {
    failedAttempts = 0;
    resetFailedAttemptsCallCount++;
  }

  @override
  void clearSessionKeysFromRam() {
    keysClearedFromRam = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Test double simulating [ContextPlayerControlClient] without native FFI transport.
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

class FakeGestureRecognizer implements IGestureRecognizer {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeScreenPrivacyController implements IScreenPrivacyController {
  ScreenPrivacyStateEnum _state = ScreenPrivacyStateEnum.publicUnrestricted;
  final StreamController<ScreenPrivacyStateEnum> _streamController =
      StreamController<ScreenPrivacyStateEnum>.broadcast();

  int enableCount = 0;
  int disableCount = 0;

  @override
  ScreenPrivacyStateEnum get currentState => _state;

  @override
  Stream<ScreenPrivacyStateEnum> get stateStream => _streamController.stream;

  @override
  Future<void> enableSecureFlag() async {
    enableCount++;
    _state = ScreenPrivacyStateEnum.secureFlagEngaged;
  }

  @override
  Future<void> disableSecureFlag() async {
    disableCount++;
    _state = ScreenPrivacyStateEnum.publicUnrestricted;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VaultDatabase database;
  late MockNativeVaultCryptoBridge mockCryptoBridge;
  late VaultStorageRepository storageRepository;
  late MutateVaultConfigUseCase mutateUseCase;
  late FakeVaultAuthService authService;
  late FakeMonotonicClock monotonicClock;
  late SettingsMutationCubit mutationCubit;

  setUp(() async {
    database = VaultDatabase.forTesting(NativeDatabase.memory());
    mockCryptoBridge = MockNativeVaultCryptoBridge(
      hasMasterKey: true,
      isSessionUnlocked: false,
    );
    storageRepository = VaultStorageRepository(
      database: database,
      cryptoBridge: mockCryptoBridge,
    );
    authService = FakeVaultAuthService();
    mutateUseCase = MutateVaultConfigUseCase(
      authService: authService,
      storageRepository: storageRepository,
    );
    monotonicClock = FakeMonotonicClock(1000);

    mutationCubit = SettingsMutationCubit(
      storageRepository: storageRepository,
      mutateVaultConfigUseCase: mutateUseCase,
      authService: authService,
      monotonicClock: monotonicClock,
    );
  });

  tearDown(() async {
    await mutationCubit.close();
    await database.close();
  });

  group('Enterprise Matrix 1: All 16 Mutation Dimensions & Cold-Start Rehydration', () {
    test('All VaultConfig dimensions mutate and persist across authentic cold-boot restart', () async {
      // 1. Define custom, non-default configuration covering all user policy dimensions
      const mutatedConfig = VaultConfig.constant(
        themePalette: VaultThemePalettePolicyEnum.forestNoir,
        biometricAuth: BiometricAuthPolicyEnum.pinAndBiometricStrong,
        backgroundGraceTimeout: BackgroundGraceTimeoutEnum.thirtySeconds,
        activeReauthInterval: ActiveReauthIntervalEnum.every5Minutes,
        keypadLayout: KeypadLayoutPolicyEnum.randomizedPerAttempt,
        screenSecurity: ScreenSecurityPolicyEnum.allowCapture,
        metadataVisibility: MetadataVisibilityPolicyEnum.showActualMetadata,
        lockPlaybackBehavior: LockPlaybackBehaviorEnum.stopImmediately,
        gestureSensitivity: GestureSensitivityTierEnum.relaxed76Percent,
        gestureVisibility: GestureVisibilityPolicyEnum.faintDissipatingHairline,
        decoyTitle: 'Cold Boot Masked Title',
        decoyArtist: 'Cold Boot Host',
        decoyAlbum: 'Cold Boot Season 2',
      );

      // Save mutated configuration via repository
      final saveResult = await storageRepository.saveVaultConfig(mutatedConfig);
      expect(saveResult, isA<VaultSuccess<void>>());

      // Also persist a golden master gesture template (64 points, 7 rubine features)
      final points = List.generate(
        64,
        (i) => GesturePoint(x: i.toDouble(), y: (i * 2).toDouble(), timestampMs: i * 10),
      );
      final template = GestureTemplate(
        id: 'master_gesture',
        normalizedPoints: points,
        rubineFeatureVector: const [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7],
        createdAtEpochMs: 12345,
      );
      final saveGestureResult = await storageRepository.saveGestureTemplate(template);
      expect(saveGestureResult, isA<VaultSuccess<void>>());

      // -----------------------------------------------------------------------
      // SIMULATE COLD-BOOT APP RESTART
      // -----------------------------------------------------------------------
      // 1. Session is strictly locked (user hasn't entered PIN)
      mockCryptoBridge.setSessionUnlocked(false);

      // 2. Sensitive media encryption throws on access (confirming locked hardware barrier)
      final dummyMediaBytes = Uint8List.fromList(utf8.encode('private media secret'));
      expect(
        () => mockCryptoBridge.encryptPayload(dummyMediaBytes),
        throwsA(isA<VaultCryptoFailure>()),
      );

      // 3. New repository and cubit instances are spun up on Frame 0
      final coldBootRepository = VaultStorageRepository(
        database: database,
        cryptoBridge: mockCryptoBridge,
      );

      // 4. Config MUST load successfully on Frame 0 via dual-tier KeyStore without session unlock
      final loadResult = await coldBootRepository.loadVaultConfig();
      expect(loadResult, isA<VaultSuccess<VaultConfig>>());

      final rehydrated = (loadResult as VaultSuccess<VaultConfig>).data;

      // Verify every single dimension survived cold-boot restart bit-for-bit:
      expect(rehydrated.themePalette, equals(VaultThemePalettePolicyEnum.forestNoir));
      expect(rehydrated.biometricAuth, equals(BiometricAuthPolicyEnum.pinAndBiometricStrong));
      expect(rehydrated.backgroundGraceTimeout, equals(BackgroundGraceTimeoutEnum.thirtySeconds));
      expect(rehydrated.activeReauthInterval, equals(ActiveReauthIntervalEnum.every5Minutes));
      expect(rehydrated.keypadLayout, equals(KeypadLayoutPolicyEnum.randomizedPerAttempt));
      expect(rehydrated.screenSecurity, equals(ScreenSecurityPolicyEnum.allowCapture));
      expect(rehydrated.metadataVisibility, equals(MetadataVisibilityPolicyEnum.showActualMetadata));
      expect(rehydrated.lockPlaybackBehavior, equals(LockPlaybackBehaviorEnum.stopImmediately));
      expect(rehydrated.gestureSensitivity, equals(GestureSensitivityTierEnum.relaxed76Percent));
      expect(rehydrated.gestureVisibility, equals(GestureVisibilityPolicyEnum.faintDissipatingHairline));
      expect(rehydrated.decoyTitle, equals('Cold Boot Masked Title'));
      expect(rehydrated.decoyArtist, equals('Cold Boot Host'));
      expect(rehydrated.decoyAlbum, equals('Cold Boot Season 2'));

      // 5. Verify gesture template can also rehydrate at Frame 0 for pre-unlock drawer detection
      final gestureResult = await coldBootRepository.loadGestureTemplate();
      expect(gestureResult, isA<VaultSuccess<GestureTemplate>>());
      final loadedGesture = (gestureResult as VaultSuccess<GestureTemplate>).data;
      expect(loadedGesture.id, equals('master_gesture'));
      expect(loadedGesture.normalizedPoints.length, equals(64));

      // 6. Verify pre-unlock subsystems arm with mutated settings before unlock
      final coldPinPad = PinPadCubit(
        unlockVaultUseCase: UnlockVaultUseCase(authService: authService),
        authService: authService,
        monotonicClock: monotonicClock,
        initialLayout: rehydrated.keypadLayout,
      );
      expect(coldPinPad.keypadLayout, equals(KeypadLayoutPolicyEnum.randomizedPerAttempt));

      final coldGestureEngine = GestureEngineCubit(
        recognizer: FakeGestureRecognizer(),
        storageRepository: coldBootRepository,
        vaultAuthService: authService,
        initialSensitivityTier: rehydrated.gestureSensitivity,
      );
      expect(coldGestureEngine.sensitivityTier, equals(GestureSensitivityTierEnum.relaxed76Percent));
      expect(coldGestureEngine.state, isA<GestureEngineIdleState>());

      await coldPinPad.close();
      await coldGestureEngine.close();
    });
  });

  group('Enterprise Matrix 2: Immediate Subsystem Behavioral Execution', () {
    test('PlaybackPrivacyProxy immediately re-projects lockscreen metadata mid-playback upon config mutation', () async {
      final fakeControlClient = FakeControlClient();
      final mobiusController = PlayerQueueMobiusController(controlClient: fakeControlClient);

      final proxy = PlaybackPrivacyProxy(
        mobiusController: mobiusController,
        storageRepository: storageRepository,
        controlClient: fakeControlClient,
        initialConfig: const VaultConfig.constant(
          metadataVisibility: MetadataVisibilityPolicyEnum.maskWithPlaceholder,
          decoyTitle: 'Initial Decoy Title',
          decoyArtist: 'Initial Decoy Artist',
          decoyAlbum: 'Initial Decoy Album',
        ),
      );
      await proxy.initialize();

      // Simulate a private vault track actively playing
      const privateTrack = ContextTrack(
        uri: 'file:///vault_media/private_track_1.mp3',
        uid: 'vault_track_1',
        metadata: {
          'is_vault_track': 'true',
          'vault_track_id': 'track_1',
          ContextTrackMetadata.keyTitle: 'Super Sensitive Secret Track',
          ContextTrackMetadata.keyArtistName: 'Top Secret Artist',
          ContextTrackMetadata.keyAlbumTitle: 'Confidential Album',
        },
      );

      // Enqueue and play track
      mobiusController.dispatch(
        const QueueUpdatedEvent(
          PlayerQueue(
            revision: '1',
            track: privateTrack,
            nextTracks: [],
            prevTracks: [],
          ),
        ),
      );

      // Verify track initially projects masked decoy persona
      final initialProjected = proxy.projectTrack(privateTrack);
      expect(initialProjected.metadata[ContextTrackMetadata.keyTitle], equals('Initial Decoy Title'));
      expect(initialProjected.metadata[ContextTrackMetadata.keyArtistName], equals('Initial Decoy Artist'));

      // MUTATION 1: User switches metadataVisibility to showActualMetadata
      proxy.updateConfig(
        proxy.cachedConfig.copyWith(
          metadataVisibility: MetadataVisibilityPolicyEnum.showActualMetadata,
        ),
      );

      // The active track in PlayerQueueMobiusController is immediately re-projected with unmasked metadata!
      final unmaskedTrack = mobiusController.state.playerQueue.track;
      expect(unmaskedTrack, isNotNull);
      expect(unmaskedTrack?.metadata[ContextTrackMetadata.keyTitle], equals('Super Sensitive Secret Track'));
      expect(unmaskedTrack?.metadata[ContextTrackMetadata.keyArtistName], equals('Top Secret Artist'));

      // MUTATION 2: User mutates decoy persona strings while playback is active
      proxy.updateConfig(
        proxy.cachedConfig.copyWith(
          metadataVisibility: MetadataVisibilityPolicyEnum.maskWithPlaceholder,
          decoyTitle: 'Updated Live Decoy Podcast',
          decoyArtist: 'Updated Host Name',
        ),
      );

      // The active track in PlayerQueueMobiusController immediately reflects the new decoy strings!
      final remaskedTrack = mobiusController.state.playerQueue.track;
      expect(remaskedTrack, isNotNull);
      expect(remaskedTrack?.metadata[ContextTrackMetadata.keyTitle], equals('Updated Live Decoy Podcast'));
      expect(remaskedTrack?.metadata[ContextTrackMetadata.keyArtistName], equals('Updated Host Name'));

      await proxy.dispose();
      mobiusController.dispose();
    });

    test('ScreenPrivacyCubit immediately dispatches FLAG_SECURE on screenSecurity mutation', () async {
      final List<MethodCall> channelLog = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('um.musify.mu/screen_privacy'),
        (MethodCall call) async {
          channelLog.add(call);
          return true;
        },
      );

      final screenPrivacyCubit = ScreenPrivacyCubit(
        privacyController: PlatformSecurityChannel(),
        monotonicClock: monotonicClock,
        initialPolicy: ScreenSecurityPolicyEnum.blockScreenshotsAndRecents,
      );

      // Engage privacy
      await screenPrivacyCubit.engageSecureFlag(
        reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
      );
      expect(channelLog.last.method, equals('enableSecureFlag'));

      // MUTATION: User relaxes policy to allowCapture
      await screenPrivacyCubit.updateSecurityPolicy(ScreenSecurityPolicyEnum.allowCapture);
      expect(channelLog.last.method, equals('disableSecureFlag'));

      // MUTATION: User re-enables blockScreenshotsAndRecents
      await screenPrivacyCubit.updateSecurityPolicy(ScreenSecurityPolicyEnum.blockScreenshotsAndRecents);
      expect(channelLog.last.method, equals('enableSecureFlag'));

      await screenPrivacyCubit.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('um.musify.mu/screen_privacy'),
        null,
      );
    });

    test('GestureEngineCubit immediately updates sensitivity tier upon config mutation', () async {
      final gestureCubit = GestureEngineCubit(
        recognizer: FakeGestureRecognizer(),
        storageRepository: storageRepository,
        vaultAuthService: authService,
        initialSensitivityTier: GestureSensitivityTierEnum.balanced84Percent,
      );

      expect(gestureCubit.sensitivityTier, equals(GestureSensitivityTierEnum.balanced84Percent));

      gestureCubit.updateSensitivityTier(GestureSensitivityTierEnum.strict92Percent);
      expect(gestureCubit.sensitivityTier, equals(GestureSensitivityTierEnum.strict92Percent));

      gestureCubit.updateSensitivityTier(GestureSensitivityTierEnum.relaxed76Percent);
      expect(gestureCubit.sensitivityTier, equals(GestureSensitivityTierEnum.relaxed76Percent));

      await gestureCubit.close();
    });
  });

  group('Enterprise Matrix 3: Monotonic Inactivity & Background Grace Timer Prorations', () {
    test('VaultSessionBloc prorates active reauth interval on mutation without resetting elapsed idle time', () async {
      final sessionBloc = VaultSessionBloc(
        authService: authService,
        storageRepository: storageRepository,
        monotonicClock: monotonicClock,
        verifyCoolOffUseCase: VerifySessionCoolOffUseCase(clock: monotonicClock),
        initialConfig: const VaultConfig.constant(
          activeReauthInterval: ActiveReauthIntervalEnum.every15Minutes, // 900,000 ms
        ),
      );

      // Unlock vault at t = 1000
      sessionBloc.add(
        VaultAuthSucceeded(
          session: AuthSession(
            sessionToken: 'token_1',
            sessionStartedEpochMs: 1000,
            lastActiveEpochMs: 1000,
            authMethod: AuthMethodEnum.pin,
          ),
        ),
      );
      await pumpEventQueue();
      expect(sessionBloc.state, isA<VaultUnlockedState>());
      expect((sessionBloc.state as VaultUnlockedState).reauthDeadlineMonotonicMs, equals(1000 + 900000));

      // User idles for 10 minutes (600,000 ms). Time is now 601,000
      monotonicClock.advance(600000);

      // User mutates activeReauthInterval to every5Minutes (300,000 ms)
      // Because elapsed idle time (600,000 ms) > new interval (300,000 ms),
      // VaultSessionBloc MUST transition to VaultPendingReauthState immediately!
      sessionBloc.add(
        const VaultConfigUpdated(
          config: VaultConfig.constant(
            activeReauthInterval: ActiveReauthIntervalEnum.every5Minutes,
          ),
        ),
      );
      await pumpEventQueue();

      expect(sessionBloc.state, isA<VaultPendingReauthState>());

      await sessionBloc.close();
    });

    test('VaultSessionBloc prorates remaining active reauth deadline when elapsed idle time is within new interval', () async {
      final sessionBloc = VaultSessionBloc(
        authService: authService,
        storageRepository: storageRepository,
        monotonicClock: monotonicClock,
        verifyCoolOffUseCase: VerifySessionCoolOffUseCase(clock: monotonicClock),
        initialConfig: const VaultConfig.constant(
          activeReauthInterval: ActiveReauthIntervalEnum.every15Minutes, // 900,000 ms
        ),
      );

      // Unlock at t = 1000
      sessionBloc.add(
        VaultAuthSucceeded(
          session: AuthSession(
            sessionToken: 'token_2',
            sessionStartedEpochMs: 1000,
            lastActiveEpochMs: 1000,
            authMethod: AuthMethodEnum.pin,
          ),
        ),
      );
      await pumpEventQueue();

      // User idles for 2 minutes (120,000 ms). Time is now 121,000
      monotonicClock.advance(120000);

      // User mutates interval to every5Minutes (300,000 ms)
      // Elapsed idle time = 120,000 ms. Remaining = 300,000 - 120,000 = 180,000 ms.
      // New deadline MUST be nowMs (121,000) + 180,000 = 301,000 ms!
      sessionBloc.add(
        const VaultConfigUpdated(
          config: VaultConfig.constant(
            activeReauthInterval: ActiveReauthIntervalEnum.every5Minutes,
          ),
        ),
      );
      await pumpEventQueue();

      expect(sessionBloc.state, isA<VaultUnlockedState>());
      final unlockedState = sessionBloc.state as VaultUnlockedState;
      expect(unlockedState.reauthDeadlineMonotonicMs, equals(121000 + 180000));

      await sessionBloc.close();
    });

    test('VaultSessionBloc prorates background grace timeout on mutation and auto-locks immediately if exceeded', () async {
      final sessionBloc = VaultSessionBloc(
        authService: authService,
        storageRepository: storageRepository,
        monotonicClock: monotonicClock,
        verifyCoolOffUseCase: VerifySessionCoolOffUseCase(clock: monotonicClock),
        initialConfig: const VaultConfig.constant(
          backgroundGraceTimeout: BackgroundGraceTimeoutEnum.fiveMinutes, // 300,000 ms
        ),
      );

      // Unlock at t = 1000
      sessionBloc.add(
        VaultAuthSucceeded(
          session: AuthSession(
            sessionToken: 'token_3',
            sessionStartedEpochMs: 1000,
            lastActiveEpochMs: 1000,
            authMethod: AuthMethodEnum.pin,
          ),
        ),
      );
      await pumpEventQueue();

      // App backgrounded at t = 2000
      monotonicClock.setTime(2000);
      sessionBloc.add(const VaultAppBackgrounded());
      await pumpEventQueue();

      expect(sessionBloc.state, isA<VaultBackgroundGraceState>());

      // App stays in background for 45 seconds (45,000 ms). Time is now 47,000
      monotonicClock.advance(45000);

      // Config update arrives: backgroundGraceTimeout shortened to thirtySeconds (30,000 ms)
      // Because elapsed background time (45,000 ms) > new limit (30,000 ms),
      // VaultSessionBloc MUST immediately transition to VaultLockedState and clear RAM keys!
      sessionBloc.add(
        const VaultConfigUpdated(
          config: VaultConfig.constant(
            backgroundGraceTimeout: BackgroundGraceTimeoutEnum.thirtySeconds,
          ),
        ),
      );
      await pumpEventQueue();

      expect(sessionBloc.state, isA<VaultLockedState>());
      expect(authService.keysClearedFromRam, isTrue);

      await sessionBloc.close();
    });
  });

  group('Enterprise Matrix 4: Concurrency Safety & Zero Snapshot Clobbering', () {
    test('Concurrent mutatePolicy calls execute atomically via FIFO reducer without clobbering', () async {
      await mutationCubit.initialize();

      // Dispatch 5 rapid concurrent mutations mutating different fields
      final futures = [
        mutationCubit.mutatePolicy(
          (c) => c.copyWith(themePalette: VaultThemePalettePolicyEnum.warmEspresso),
        ),
        mutationCubit.mutatePolicy(
          (c) => c.copyWith(keypadLayout: KeypadLayoutPolicyEnum.randomizedPerAttempt),
        ),
        mutationCubit.mutatePolicy(
          (c) => c.copyWith(screenSecurity: ScreenSecurityPolicyEnum.allowCapture),
        ),
        mutationCubit.mutatePolicy(
          (c) => c.copyWith(activeReauthInterval: ActiveReauthIntervalEnum.every30Minutes),
        ),
        mutationCubit.mutatePolicy(
          (c) => c.copyWith(decoyTitle: 'Concurrent Safe Decoy'),
        ),
      ];

      final results = await Future.wait(futures);
      expect(results, equals([true, true, true, true, true]));

      // Verify ALL 5 mutations were applied cumulatively to the latest state without clobbering!
      final finalConfig = mutationCubit.currentConfig;
      expect(finalConfig.themePalette, equals(VaultThemePalettePolicyEnum.warmEspresso));
      expect(finalConfig.keypadLayout, equals(KeypadLayoutPolicyEnum.randomizedPerAttempt));
      expect(finalConfig.screenSecurity, equals(ScreenSecurityPolicyEnum.allowCapture));
      expect(finalConfig.activeReauthInterval, equals(ActiveReauthIntervalEnum.every30Minutes));
      expect(finalConfig.decoyTitle, equals('Concurrent Safe Decoy'));
    });

    test('SettingsMutationCubit preserves awaitingStepUp state when general mutations complete in background', () async {
      await mutationCubit.initialize();

      // User opens step-up prompt
      await mutationCubit.requestSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.pinRotation,
      );
      expect(mutationCubit.state, isA<SettingsMutationAwaitingStepUpAuthState>());

      // Background general policy update completes
      await mutationCubit.mutatePolicy(
        (c) => c.copyWith(themePalette: VaultThemePalettePolicyEnum.forestNoir),
      );

      // SettingsMutationAwaitingStepUpAuthState MUST be preserved without being clobbered to SyncedIdleState
      expect(mutationCubit.state, isA<SettingsMutationAwaitingStepUpAuthState>());
      expect(mutationCubit.currentConfig.themePalette, equals(VaultThemePalettePolicyEnum.forestNoir));
    });

    test('flushDecoyPersonaImmediately saves pending debounced keystrokes without data loss on exit', () async {
      await mutationCubit.initialize();

      mutationCubit.updateDecoyPersonaDebounced(
        title: 'Instant Flush Title',
        artist: 'Instant Flush Artist',
        album: 'Instant Flush Album',
      );

      // Immediate exit before 350ms debounce
      await mutationCubit.flushDecoyPersonaImmediately();

      expect(mutationCubit.currentConfig.decoyTitle, equals('Instant Flush Title'));
      expect(mutationCubit.currentConfig.decoyArtist, equals('Instant Flush Artist'));
      expect(mutationCubit.currentConfig.decoyAlbum, equals('Instant Flush Album'));

      // Verify persisted in SQLite
      final reloaded = await storageRepository.loadVaultConfig();
      expect(reloaded, isA<VaultSuccess<VaultConfig>>());
      final reloadedConfig = (reloaded as VaultSuccess<VaultConfig>).data;
      expect(reloadedConfig.decoyTitle, equals('Instant Flush Title'));
    });
  });
}
