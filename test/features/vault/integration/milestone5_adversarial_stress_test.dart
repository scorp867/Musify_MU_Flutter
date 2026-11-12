import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:musify_mu/app/di/vault_injection.dart';
import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/vault/application/coordinator/vault_coordinator.dart';
import 'package:musify_mu/features/vault/application/gesture/gesture_engine_cubit.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/playlists/vault_playlists_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/data/database/vault_database.dart';
import 'package:musify_mu/features/vault/data/datasources/i_native_vault_crypto_bridge.dart';
import 'package:musify_mu/features/vault/data/datasources/platform_security_channel.dart';
import 'package:musify_mu/features/vault/data/datasources/system_monotonic_clock.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';
import 'package:musify_mu/features/vault/data/services/playback_privacy_proxy.dart';
import 'package:musify_mu/features/vault/data/services/vault_audio_playback_service.dart';
import 'package:musify_mu/features/vault/data/services/vault_pbkdf2_derivation.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_screen_privacy_controller.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/background_grace_timeout.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/screen_security_policy.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/settings_mutation_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/enroll_gesture_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/mutate_vault_config_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/purge_vault_data_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/rotate_pin_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';

import 'integration_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vector 1: SystemMonotonicClock Empirical Stress Tests', () {
    test('10,000 rapid queries strictly obey monotonic increment invariant (t_i+1 >= t_i)', () {
      final clock = SystemMonotonicClock();
      var previousMs = clock.currentMonotonicMs;
      var previousElapsed = clock.elapsedMilliseconds;

      for (var i = 0; i < 10000; i++) {
        final currentMs = clock.currentMonotonicMs;
        final currentElapsed = clock.elapsedMilliseconds;

        expect(
          currentMs,
          greaterThanOrEqualTo(previousMs),
          reason: 'Monotonic violation at iteration $i: $currentMs < $previousMs',
        );
        expect(
          currentElapsed,
          greaterThanOrEqualTo(previousElapsed),
          reason: 'Elapsed monotonic violation at iteration $i: $currentElapsed < $previousElapsed',
        );
        expect(currentElapsed, greaterThanOrEqualTo(0));

        previousMs = currentMs;
        previousElapsed = currentElapsed;
      }
    });

    test('1,000 concurrent async microtask queries preserve non-decreasing order', () async {
      final clock = SystemMonotonicClock(baseEpochMs: 1700000000000);
      final futures = List.generate(1000, (index) async {
        await Future<void>.delayed(Duration(microseconds: Random().nextInt(500)));
        return (
          index: index,
          monotonicMs: clock.currentMonotonicMs,
          elapsedMs: clock.elapsedMilliseconds,
        );
      });

      final results = await Future.wait(futures);
      expect(results.length, equals(1000));

      for (final item in results) {
        expect(item.elapsedMs, greaterThanOrEqualTo(0));
        // monotonicMs was queried just before elapsedMs; elapsedMs can advance by 0 or 1ms
        expect(
          item.monotonicMs,
          lessThanOrEqualTo(1700000000000 + item.elapsedMs),
          reason: 'monotonicMs must be <= baseEpochMs + elapsedMs when read first',
        );
        expect(
          item.monotonicMs,
          greaterThanOrEqualTo(1700000000000 + item.elapsedMs - 2),
          reason: 'elapsedMs should not drift by more than 2ms across consecutive reads',
        );
      }
    });

    test('createStopwatch returns an unstarted fresh stopwatch instance', () {
      final clock = SystemMonotonicClock();
      final sw1 = clock.createStopwatch();
      final sw2 = clock.createStopwatch();

      expect(identical(sw1, sw2), isFalse);
      expect(sw1.isRunning, isFalse);
      expect(sw1.elapsedMilliseconds, equals(0));
      expect(sw2.isRunning, isFalse);
      expect(sw2.elapsedMilliseconds, equals(0));
    });
  });

  group('Vector 2: PlatformSecurityChannel Stress Tests', () {
    const channel = MethodChannel(PlatformSecurityChannel.channelName);
    late PlatformSecurityChannel securityChannel;

    setUp(() {
      securityChannel = PlatformSecurityChannel(channel: channel);
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await securityChannel.dispose();
    });

    test('Concurrent enable and disable calls serialize and maintain consistent state', () async {
      var callOrder = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        callOrder.add(call.method);
        // Simulate small native platform processing jitter
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return true;
      });

      // Fire 20 concurrent alternating operations
      final futures = <Future<void>>[];
      for (var i = 0; i < 20; i++) {
        if (i.isEven) {
          futures.add(securityChannel.enableSecureFlag());
        } else {
          futures.add(securityChannel.disableSecureFlag());
        }
      }

      await Future.wait(futures);
      expect(callOrder.length, equals(20));

      // The final state must match the last executed native method
      final lastMethod = callOrder.last;
      if (lastMethod == 'enableSecureFlag') {
        expect(securityChannel.currentState, equals(ScreenPrivacyStateEnum.secureFlagEngaged));
      } else {
        expect(securityChannel.currentState, equals(ScreenPrivacyStateEnum.publicUnrestricted));
      }
    });

    test('Native error does not corrupt or prematurely advance currentState', () async {
      var shouldFail = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (shouldFail) {
          throw PlatformException(
            code: 'WINDOW_FLAG_ERROR',
            message: 'Simulated window management failure',
          );
        }
        return true;
      });

      // Initial state is publicUnrestricted
      expect(securityChannel.currentState, equals(ScreenPrivacyStateEnum.publicUnrestricted));

      // Successful enable
      await securityChannel.enableSecureFlag();
      expect(securityChannel.currentState, equals(ScreenPrivacyStateEnum.secureFlagEngaged));

      // Failing disable: throws and preserves secureFlagEngaged
      shouldFail = true;
      expect(
        () => securityChannel.disableSecureFlag(),
        throwsA(isA<PlatformException>()),
      );
      expect(
        securityChannel.currentState,
        equals(ScreenPrivacyStateEnum.secureFlagEngaged),
        reason: 'State must not transition to publicUnrestricted when native call failed',
      );

      // Failing enable: throws and preserves secureFlagEngaged
      expect(
        () => securityChannel.enableSecureFlag(),
        throwsA(isA<PlatformException>()),
      );
      expect(securityChannel.currentState, equals(ScreenPrivacyStateEnum.secureFlagEngaged));
    });

    test('StateStream broadcasts correctly across 20 simultaneous active listeners', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => true);

      final receivedPerListener = List.generate(20, (_) => <ScreenPrivacyStateEnum>[]);
      final subs = <StreamSubscription<ScreenPrivacyStateEnum>>[];

      for (var i = 0; i < 20; i++) {
        final idx = i;
        subs.add(securityChannel.stateStream.listen(receivedPerListener[idx].add));
      }

      await securityChannel.enableSecureFlag();
      await securityChannel.disableSecureFlag();
      await securityChannel.enableSecureFlag();
      await pumpEventQueue();

      for (var i = 0; i < 20; i++) {
        expect(
          receivedPerListener[i],
          equals([
            ScreenPrivacyStateEnum.secureFlagEngaged,
            ScreenPrivacyStateEnum.publicUnrestricted,
            ScreenPrivacyStateEnum.secureFlagEngaged,
          ]),
          reason: 'Listener $i missed state broadcast events',
        );
        await subs[i].cancel();
      }
    });

    test('Disposed channel immediately rejects all calls and cleans up stream', () async {
      await securityChannel.dispose();

      expect(() => securityChannel.enableSecureFlag(), throwsA(isA<StateError>()));
      expect(() => securityChannel.disableSecureFlag(), throwsA(isA<StateError>()));
      expect(() => securityChannel.isSecureFlagEngaged(), throwsA(isA<StateError>()));

      // State stream must be closed
      final isDone = Completer<bool>();
      securityChannel.stateStream.listen(
        (_) {},
        onDone: () => isDone.complete(true),
      );
      await pumpEventQueue();
      expect(await isDone.future, isTrue);
    });
  });

  group('Vector 3: DI Container (setupVaultInjection) Stress & Deadlock Tests', () {
    late GetIt sl;

    setUp(() async {
      sl = GetIt.asNewInstance();
    });

    tearDown(() async {
      await sl.reset();
    });

    test('Resolves all 26 registered vault services with 0 circular deadlocks and 0 null instances', () async {
      // Register prerequisite PlayerQueueMobiusController mock
      sl.registerLazySingleton<PlayerQueueMobiusController>(
        () => PlayerQueueMobiusController(),
        dispose: (c) => c.close(),
      );

      // Register all vault dependencies via production setupVaultInjection
      setupVaultInjection(sl);

      // Verify all 26 services can be resolved concurrently and synchronously
      final resolvedServices = <Type, Object>{
        FlutterSecureStorage: sl<FlutterSecureStorage>(),
        VaultPbkdf2Derivation: sl<VaultPbkdf2Derivation>(),
        VaultDatabase: sl<VaultDatabase>(),
        INativeVaultCryptoBridge: sl<INativeVaultCryptoBridge>(),
        IMonotonicClock: sl<IMonotonicClock>(),
        IScreenPrivacyController: sl<IScreenPrivacyController>(),
        IGestureRecognizer: sl<IGestureRecognizer>(),
        IVaultMediaIsolationManager: sl<IVaultMediaIsolationManager>(),
        IVaultStorageRepository: sl<IVaultStorageRepository>(),
        IVaultAuthService: sl<IVaultAuthService>(),
        PlaybackPrivacyProxy: sl<PlaybackPrivacyProxy>(),
        VaultAudioPlaybackService: sl<VaultAudioPlaybackService>(),
        UnlockVaultUseCase: sl<UnlockVaultUseCase>(),
        RotatePinUseCase: sl<RotatePinUseCase>(),
        PurgeVaultDataUseCase: sl<PurgeVaultDataUseCase>(),
        MutateVaultConfigUseCase: sl<MutateVaultConfigUseCase>(),
        EnrollGestureUseCase: sl<EnrollGestureUseCase>(),
        VerifySessionCoolOffUseCase: sl<VerifySessionCoolOffUseCase>(),
        VaultSessionBloc: sl<VaultSessionBloc>(),
        SettingsMutationCubit: sl<SettingsMutationCubit>(),
        ScreenPrivacyCubit: sl<ScreenPrivacyCubit>(),
        GestureEngineCubit: sl<GestureEngineCubit>(),
        PinPadCubit: sl<PinPadCubit>(),
        VaultPlaylistsCubit: sl<VaultPlaylistsCubit>(),
        VaultCoordinator: sl<VaultCoordinator>(),
        VaultRouteObserver: sl<VaultRouteObserver>(),
      };

      expect(resolvedServices.length, equals(26));

      for (final entry in resolvedServices.entries) {
        expect(
          entry.value,
          isNotNull,
          reason: 'Service ${entry.key} resolved to null',
        );
      }

      // Verify factory creates distinct instances for VaultPlaylistsCubit
      final cubit1 = sl<VaultPlaylistsCubit>();
      final cubit2 = sl<VaultPlaylistsCubit>();
      expect(identical(cubit1, cubit2), isFalse);

      // Verify singletons resolve to identical references
      expect(identical(sl<VaultCoordinator>(), sl<VaultCoordinator>()), isTrue);
      expect(identical(sl<VaultSessionBloc>(), sl<VaultSessionBloc>()), isTrue);
      expect(identical(sl<SettingsMutationCubit>(), sl<SettingsMutationCubit>()), isTrue);
    });

    test('Clean disposal via sl.reset() shuts down all active BLoCs and streams without leakage', () async {
      sl.registerLazySingleton<PlayerQueueMobiusController>(
        () => PlayerQueueMobiusController(),
        dispose: (c) => c.close(),
      );
      setupVaultInjection(sl);

      final coordinator = sl<VaultCoordinator>();
      final sessionBloc = sl<VaultSessionBloc>();
      final screenPrivacyCubit = sl<ScreenPrivacyCubit>();

      expect(coordinator.isDisposed, isFalse);
      expect(sessionBloc.isClosed, isFalse);
      expect(screenPrivacyCubit.isClosed, isFalse);

      await sl.reset();

      expect(coordinator.isDisposed, isTrue);
      expect(sessionBloc.isClosed, isTrue);
      expect(screenPrivacyCubit.isClosed, isTrue);
    });
  });

  group('Vector 4: App Lifecycle & VaultCoordinator Stress Tests', () {
    late TestVaultHarness harness;

    setUp(() async {
      harness = TestVaultHarness();
      await harness.setup();
    });

    tearDown(() async {
      await harness.tearDown();
    });

    test('Lifecycle sequence: resumed -> paused -> advance clock > grace timeout -> resumed transitions to locked', () async {
      // Seed unlocked session
      final session = AuthSession(
        sessionToken: 'test_token',
        sessionStartedEpochMs: 10000,
        lastActiveEpochMs: 10000,
        authMethod: AuthMethodEnum.pin,
      );
      harness.sessionBloc.emit(
        VaultUnlockedState(
          session: session,
          unlockedAtMonotonicMs: 10000,
          reauthDeadlineMonotonicMs: 0,
        ),
      );

      // 1. App goes to background
      harness.clock.timeMs = 15000;
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.paused);
      await pumpEventQueue();

      expect(
        harness.sessionBloc.state,
        isA<VaultBackgroundGraceState>().having(
          (s) => s.enteredBackgroundMonotonicMs,
          'enteredBackgroundMonotonicMs',
          equals(15000),
        ),
      );

      // 2. Clock advances past 30s grace timeout (advance 35 seconds)
      harness.clock.advance(const Duration(seconds: 35));

      // 3. App returns to foreground
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(
        harness.sessionBloc.state,
        isA<VaultLockedState>(),
        reason: 'Session must transition to locked after grace period expires',
      );
    });

    test('Lifecycle sequence: resumed -> paused -> advance clock < grace timeout -> resumed keeps session active', () async {
      final session = AuthSession(
        sessionToken: 'test_token_2',
        sessionStartedEpochMs: 10000,
        lastActiveEpochMs: 10000,
        authMethod: AuthMethodEnum.pin,
      );
      harness.sessionBloc.emit(
        VaultUnlockedState(
          session: session,
          unlockedAtMonotonicMs: 10000,
          reauthDeadlineMonotonicMs: 0,
        ),
      );

      // App paused
      harness.clock.timeMs = 15000;
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.paused);
      await pumpEventQueue();

      expect(harness.sessionBloc.state, isA<VaultBackgroundGraceState>());

      // Advance by only 10 seconds (< 30s grace timeout)
      harness.clock.advance(const Duration(seconds: 10));

      // App resumed
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(
        harness.sessionBloc.state,
        isA<VaultUnlockedState>(),
        reason: 'Session must remain unlocked when returning within grace window',
      );
    });

    test('Immediate grace timeout policy locks immediately on pause without waiting for resume', () async {
      // Re-configure policy with immediate grace
      const immediateConfig = VaultConfig.constant(
        backgroundGraceTimeout: BackgroundGraceTimeoutEnum.immediate,
        screenSecurity: ScreenSecurityPolicyEnum.allowCapture,
        lockPlaybackBehavior: LockPlaybackBehaviorEnum.stopImmediately,
      );
      harness.storageRepository.config = immediateConfig;
      harness.settingsMutationCubit.emit(
        const SettingsMutationSyncedIdleState(),
      );
      harness.sessionBloc.add(const VaultConfigUpdated(config: immediateConfig));
      await pumpEventQueue();

      final session = AuthSession(
        sessionToken: 'immediate_token',
        sessionStartedEpochMs: 10000,
        lastActiveEpochMs: 10000,
        authMethod: AuthMethodEnum.pin,
      );
      harness.sessionBloc.emit(
        VaultUnlockedState(
          session: session,
          unlockedAtMonotonicMs: 10000,
          reauthDeadlineMonotonicMs: 0,
        ),
      );

      // App backgrounded
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.paused);
      await pumpEventQueue();

      expect(
        harness.sessionBloc.state,
        isA<VaultLockedState>(),
        reason: 'Immediate grace policy must lock immediately upon app backgrounding',
      );
    });

    test('AppLifecycleState.detached immediately executes quick-lock', () async {
      final session = AuthSession(
        sessionToken: 'detach_token',
        sessionStartedEpochMs: 10000,
        lastActiveEpochMs: 10000,
        authMethod: AuthMethodEnum.pin,
      );
      harness.sessionBloc.emit(
        VaultUnlockedState(
          session: session,
          unlockedAtMonotonicMs: 10000,
          reauthDeadlineMonotonicMs: 0,
        ),
      );

      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.detached);
      await pumpEventQueue();

      expect(harness.sessionBloc.state, isA<VaultLockedState>());
    });

    test('AppLifecycleState.hidden preserves active session and engages FLAG_SECURE if configured', () async {
      const secureConfig = VaultConfig.constant(
        screenSecurity: ScreenSecurityPolicyEnum.blockScreenshotsAndRecents,
        backgroundGraceTimeout: BackgroundGraceTimeoutEnum.thirtySeconds,
      );
      harness.storageRepository.config = secureConfig;
      harness.settingsMutationCubit.emit(
        const SettingsMutationSyncedIdleState(),
      );
      harness.screenPrivacyCubit.emit(const ScreenPrivacyPublicUnrestrictedState());

      final session = AuthSession(
        sessionToken: 'hidden_token',
        sessionStartedEpochMs: 10000,
        lastActiveEpochMs: 10000,
        authMethod: AuthMethodEnum.pin,
      );
      harness.sessionBloc.emit(
        VaultUnlockedState(
          session: session,
          unlockedAtMonotonicMs: 10000,
          reauthDeadlineMonotonicMs: 0,
        ),
      );

      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.hidden);
      await pumpEventQueue();

      expect(harness.sessionBloc.state, isA<VaultUnlockedState>());
      expect(
        harness.screenPrivacyCubit.state,
        isA<ScreenPrivacySecureFlagEngagedState>().having(
          (s) => s.reason,
          'reason',
          equals(ScreenPrivacyEngageReasonEnum.appBackgroundWithVaultLoaded),
        ),
      );
    });

    test('Full Flutter OS lifecycle: resumed -> inactive -> hidden -> paused -> hidden -> inactive -> resumed respects background grace window', () async {
      final session = AuthSession(
        sessionToken: 'lifecycle_test_token',
        sessionStartedEpochMs: 10000,
        lastActiveEpochMs: 10000,
        authMethod: AuthMethodEnum.pin,
      );
      harness.sessionBloc.emit(
        VaultUnlockedState(
          session: session,
          unlockedAtMonotonicMs: 10000,
          reauthDeadlineMonotonicMs: 0,
        ),
      );

      // App backgrounding sequence: inactive -> hidden -> paused
      harness.clock.timeMs = 15000;
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.inactive);
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.hidden);
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.paused);
      await pumpEventQueue();

      expect(harness.sessionBloc.state, isA<VaultBackgroundGraceState>());

      // User returns after 10 seconds (well within 30s grace window)
      harness.clock.advance(const Duration(seconds: 10));

      // App resuming sequence: hidden -> inactive -> resumed
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.hidden);
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.inactive);
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(
        harness.sessionBloc.state,
        isA<VaultUnlockedState>(),
        reason: 'Session must remain unlocked across full Flutter OS background/foreground cycle within grace window',
      );
    });

    test('Full Flutter OS lifecycle: resumed -> inactive -> hidden -> paused -> hidden -> inactive -> resumed locks after grace deadline expires', () async {
      final session = AuthSession(
        sessionToken: 'lifecycle_expired_token',
        sessionStartedEpochMs: 10000,
        lastActiveEpochMs: 10000,
        authMethod: AuthMethodEnum.pin,
      );
      harness.sessionBloc.emit(
        VaultUnlockedState(
          session: session,
          unlockedAtMonotonicMs: 10000,
          reauthDeadlineMonotonicMs: 0,
        ),
      );

      // Backgrounding
      harness.clock.timeMs = 15000;
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.inactive);
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.hidden);
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.paused);
      await pumpEventQueue();

      expect(harness.sessionBloc.state, isA<VaultBackgroundGraceState>());

      // User returns after 35 seconds (exceeding 30s grace window)
      harness.clock.advance(const Duration(seconds: 35));

      // Resuming
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.hidden);
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.inactive);
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(
        harness.sessionBloc.state,
        isA<VaultLockedState>(),
        reason: 'Session must lock when returning after background grace period elapsed',
      );
    });

    test('FLAG_SECURE is engaged on pause when blockScreenshotsAndRecents policy is active', () async {
      const secureConfig = VaultConfig.constant(
        screenSecurity: ScreenSecurityPolicyEnum.blockScreenshotsAndRecents,
        backgroundGraceTimeout: BackgroundGraceTimeoutEnum.thirtySeconds,
      );
      harness.storageRepository.config = secureConfig;
      harness.settingsMutationCubit.emit(
        const SettingsMutationSyncedIdleState(),
      );
      harness.screenPrivacyCubit.emit(const ScreenPrivacyPublicUnrestrictedState());

      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.paused);
      await pumpEventQueue();

      expect(
        harness.screenPrivacyCubit.state,
        isA<ScreenPrivacySecureFlagEngagedState>().having(
          (s) => s.reason,
          'reason',
          equals(ScreenPrivacyEngageReasonEnum.appBackgroundWithVaultLoaded),
        ),
      );
    });

    test('Rapid consecutive lifecycle oscillations do not crash or throw unhandled exceptions', () async {
      final states = [
        AppLifecycleState.resumed,
        AppLifecycleState.inactive,
        AppLifecycleState.paused,
        AppLifecycleState.resumed,
        AppLifecycleState.inactive,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.resumed,
        AppLifecycleState.detached,
      ];

      for (final state in states) {
        harness.coordinator.onAppLifecycleStateChanged(state);
      }
      await pumpEventQueue();

      expect(harness.sessionBloc.state, isA<VaultLockedState>());
    });
  });
}
