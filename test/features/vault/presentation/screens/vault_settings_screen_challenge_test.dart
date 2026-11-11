import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/application/gesture/gesture_engine_cubit.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/lockout_cooldown_info.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_screen_privacy_controller.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/biometric_auth_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/policies/screen_security_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/pin_pad_state.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/settings_mutation_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/mutate_vault_config_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/purge_vault_data_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/rotate_pin_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_auth_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_settings_screen.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';

class ChallengeMonotonicClock implements IMonotonicClock {
  int timeMs = 1000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class ChallengeScreenPrivacyController implements IScreenPrivacyController {
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
    _streamController.add(_state);
  }

  @override
  Future<void> disableSecureFlag() async {
    disableCount++;
    _state = ScreenPrivacyStateEnum.publicUnrestricted;
    _streamController.add(_state);
  }
}

class ChallengeVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> _sessionController =
      StreamController<VaultSessionState>.broadcast();

  String currentPin = '123456';
  int rotatePinCalls = 0;
  String? lastRotatedOldPin;
  String? lastRotatedNewPin;
  int clearRamCalls = 0;

  @override
  Stream<VaultSessionState> get sessionStateStream => _sessionController.stream;

  @override
  Future<LockoutCooldownInfo> getLockoutStatus() async =>
      LockoutCooldownInfo(
        tier: LockoutCooldownTierEnum.none,
        remainingCooldownSeconds: 0,
        deadlineMonotonicMs: 0,
        consecutiveFailedAttempts: 0,
      );

  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({
    required String pin,
  }) async {
    if (pin == currentPin) {
      return VaultResult.success(
        AuthSession(
          sessionToken: 'valid_token',
          sessionStartedEpochMs: 1000,
          lastActiveEpochMs: 1000,
          authMethod: AuthMethodEnum.pin,
        ),
      );
    }
    return const VaultResult.failure(
      VaultAuthFailure('Incorrect PIN entered.'),
    );
  }

  @override
  Future<VaultResult<void>> rotatePin({
    required String oldPin,
    required String newPin,
  }) async {
    rotatePinCalls++;
    lastRotatedOldPin = oldPin;
    lastRotatedNewPin = newPin;
    currentPin = newPin;
    return const VaultResult.success(null);
  }

  @override
  void clearSessionKeysFromRam() {
    clearRamCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ChallengeVaultStorageRepository implements IVaultStorageRepository {
  VaultConfig currentConfig = const VaultConfig.constant();
  int purgeCalls = 0;
  int clearLockoutCalls = 0;

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      VaultResult.success(currentConfig);

  @override
  Future<VaultResult<void>> saveVaultConfig(VaultConfig config) async {
    currentConfig = config;
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> purgeAllVaultData() async {
    purgeCalls++;
    return const VaultResult.success(null);
  }

  @override
  Future<int?> getPersistedLockoutDeadlineMs() async => null;

  @override
  Future<void> clearPersistedLockoutDeadline() async {
    clearLockoutCalls++;
  }

  @override
  Future<VaultResult<GestureTemplate>> loadGestureTemplate() async =>
      VaultResult.success(DefaultGestureTemplate.canonicalVShape);

  @override
  Future<VaultResult<void>> saveGestureTemplate(GestureTemplate template) async =>
      const VaultResult.success(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ChallengeGestureRecognizer implements IGestureRecognizer {
  @override
  Future<VaultResult<RecognitionScore>> evaluateStroke({
    required GestureSample liveStroke,
    required GestureTemplate template,
    required GestureSensitivityTierEnum sensitivityTier,
  }) async {
    return VaultResult.success(
      RecognitionScore(
        dollarOneScore: 0.95,
        dtwScore: 0.92,
        featureScore: 0.90,
        ensembleScore: 0.932,
        decision: GestureMatchDecisionEnum.matched,
      ),
    );
  }

  @override
  Future<VaultResult<GestureTemplate>> synthesizeMasterTemplate({
    required List<GestureSample> samples,
  }) async =>
      VaultResult.success(DefaultGestureTemplate.canonicalVShape);

  @override
  Future<VaultResult<void>> validateSampleConsistency({
    required List<GestureSample> samples,
  }) async =>
      const VaultResult.success(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Empirical Challenge: Vault Settings & Security Flows', () {
    late ChallengeMonotonicClock clock;
    late ChallengeScreenPrivacyController privacyController;
    late ChallengeVaultAuthService authService;
    late ChallengeVaultStorageRepository storage;
    late ChallengeGestureRecognizer recognizer;

    late MutateVaultConfigUseCase mutateVaultConfigUseCase;
    late PurgeVaultDataUseCase purgeVaultDataUseCase;
    late RotatePinUseCase rotatePinUseCase;
    late UnlockVaultUseCase unlockVaultUseCase;
    late VerifySessionCoolOffUseCase verifyCoolOffUseCase;

    late SettingsMutationCubit settingsMutationCubit;
    late VaultSessionBloc vaultSessionBloc;
    late ScreenPrivacyCubit screenPrivacyCubit;
    late GestureEngineCubit gestureEngineCubit;
    late PinPadCubit pinPadCubit;

    setUp(() {
      clock = ChallengeMonotonicClock();
      privacyController = ChallengeScreenPrivacyController();
      authService = ChallengeVaultAuthService();
      storage = ChallengeVaultStorageRepository();
      recognizer = ChallengeGestureRecognizer();

      mutateVaultConfigUseCase = MutateVaultConfigUseCase(
        storageRepository: storage,
        authService: authService,
      );
      purgeVaultDataUseCase = PurgeVaultDataUseCase(
        authService: authService,
        storageRepository: storage,
      );
      rotatePinUseCase = RotatePinUseCase(authService: authService);
      unlockVaultUseCase = UnlockVaultUseCase(authService: authService);
      verifyCoolOffUseCase = VerifySessionCoolOffUseCase(clock: clock);

      settingsMutationCubit = SettingsMutationCubit(
        storageRepository: storage,
        mutateVaultConfigUseCase: mutateVaultConfigUseCase,
        authService: authService,
        monotonicClock: clock,
      );

      vaultSessionBloc = VaultSessionBloc(
        authService: authService,
        storageRepository: storage,
        monotonicClock: clock,
        verifyCoolOffUseCase: verifyCoolOffUseCase,
      );

      screenPrivacyCubit = ScreenPrivacyCubit(
        privacyController: privacyController,
        monotonicClock: clock,
        initialPolicy: ScreenSecurityPolicyEnum.blockScreenshotsAndRecents,
      );

      gestureEngineCubit = GestureEngineCubit(
        recognizer: recognizer,
        storageRepository: storage,
        vaultAuthService: authService,
      );

      pinPadCubit = PinPadCubit(
        unlockVaultUseCase: unlockVaultUseCase,
        authService: authService,
        monotonicClock: clock,
      );
    });

    void setLargeViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    Widget createTestApp({Widget? home}) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<SettingsMutationCubit>.value(value: settingsMutationCubit),
          BlocProvider<VaultSessionBloc>.value(value: vaultSessionBloc),
          BlocProvider<ScreenPrivacyCubit>.value(value: screenPrivacyCubit),
          BlocProvider<GestureEngineCubit>.value(value: gestureEngineCubit),
          BlocProvider<PinPadCubit>.value(value: pinPadCubit),
        ],
        child: VaultTheme(
          data: VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.warmEspresso),
          child: MaterialApp(
            home: home ??
                VaultSettingsScreen(
                  settingsMutationCubit: settingsMutationCubit,
                  sessionBloc: vaultSessionBloc,
                  screenPrivacyCubit: screenPrivacyCubit,
                  gestureEngineCubit: gestureEngineCubit,
                  storageRepository: storage,
                  authService: authService,
                  rotatePinUseCase: rotatePinUseCase,
                  purgeVaultDataUseCase: purgeVaultDataUseCase,
                  unlockVaultUseCase: unlockVaultUseCase,
                  monotonicClock: clock,
                ),
          ),
        ),
      );
    }

    Future<void> enterPinDigits(WidgetTester tester, String digits) async {
      for (final char in digits.split('')) {
        final digitButton = find.widgetWithText(InkWell, char);
        expect(digitButton, findsOneWidget, reason: 'Keypad digit button "$char" must exist');
        await tester.tap(digitButton);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
    }

    Finder findAuthScreenBackButton() {
      return find.descendant(
        of: find.byType(AppBar),
        matching: find.widgetWithIcon(IconButton, Icons.arrow_back),
      );
    }

    // -------------------------------------------------------------------------
    // Challenge 1: Full-Screen Navigation & Back Navigation for all 5 screens
    // -------------------------------------------------------------------------
    testWidgets('Full-screen navigation to and back from all 5 section screens (zero dialogs/sheets)',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final sections = [
        ('nav_tile_appearance', 'vault_appearance_screen', 'vault_appearance_back_button'),
        ('nav_tile_security', 'vault_security_screen', 'vault_security_back_button'),
        ('nav_tile_privacy', 'vault_privacy_screen', 'vault_privacy_back_button'),
        ('nav_tile_gestures', 'vault_gesture_screen', 'vault_gesture_back_button'),
        ('nav_tile_danger_zone', 'vault_danger_zone_screen', 'vault_danger_zone_back_button'),
      ];

      for (final (navKey, screenKey, backKey) in sections) {
        // Navigate forward
        await tester.tap(find.byKey(ValueKey(navKey)));
        await tester.pumpAndSettle();

        // Screen is pushed full-screen
        expect(find.byKey(ValueKey(screenKey)), findsOneWidget);
        // Verify no modal bottom sheets or alert dialogs exist
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.byType(Dialog), findsNothing);

        // Navigate back
        await tester.tap(find.byKey(ValueKey(backKey)));
        await tester.pumpAndSettle();

        // Returned to hub
        expect(find.byKey(const ValueKey('vault_settings_scaffold')), findsOneWidget);
      }
    });

    // -------------------------------------------------------------------------
    // Challenge 2: Master PIN Rotation Flow (Happy Path)
    // -------------------------------------------------------------------------
    testWidgets('Master PIN Rotation: Full multi-step flow: old PIN check -> new PIN -> confirm PIN -> re-wrapping',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(
        createTestApp(
          home: VaultSecuritySettingsScreen(
            settingsMutationCubit: settingsMutationCubit,
            sessionBloc: vaultSessionBloc,
            screenPrivacyCubit: screenPrivacyCubit,
            authService: authService,
            rotatePinUseCase: rotatePinUseCase,
            unlockVaultUseCase: unlockVaultUseCase,
            monotonicClock: clock,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap PIN rotation tile
      await tester.tap(find.byKey(const ValueKey('tile_pin_rotation')));
      await tester.pumpAndSettle();

      // Step 1: Verify Current PIN screen
      expect(find.byType(VaultAuthScreen), findsOneWidget);
      expect(find.text('Verify Current PIN'), findsOneWidget);
      expect(settingsMutationCubit.state, isA<SettingsMutationAwaitingStepUpAuthState>());

      // Enter correct current PIN (123456)
      await enterPinDigits(tester, '123456');

      // Step 2: Enter New PIN screen
      expect(find.byType(VaultAuthScreen), findsOneWidget);
      expect(find.text('Enter New PIN'), findsOneWidget);

      // Enter valid distinct new PIN: 654321
      await enterPinDigits(tester, '654321');

      // Step 3: Confirm New PIN screen
      expect(find.byType(VaultAuthScreen), findsOneWidget);
      expect(find.text('Confirm New PIN'), findsOneWidget);

      // Enter matching PIN: 654321
      await enterPinDigits(tester, '654321');

      // Step 4: Execution completes
      expect(authService.rotatePinCalls, equals(1));
      expect(authService.lastRotatedOldPin, equals('123456'));
      expect(authService.lastRotatedNewPin, equals('654321'));
      expect(authService.currentPin, equals('654321'));

      // Successfully back on security screen
      expect(find.byKey(const ValueKey('vault_security_screen')), findsOneWidget);
      expect(find.text('Master PIN updated successfully'), findsOneWidget);
      expect(settingsMutationCubit.state, isA<SettingsMutationSyncedIdleState>());
    });

    // -------------------------------------------------------------------------
    // Challenge 2B: Master PIN Rotation Rejection & Post-Failure State Analysis
    // -------------------------------------------------------------------------
    testWidgets('Master PIN Rotation: Identical PIN rejection causes shake and prevents rotation',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(
        createTestApp(
          home: VaultSecuritySettingsScreen(
            settingsMutationCubit: settingsMutationCubit,
            sessionBloc: vaultSessionBloc,
            screenPrivacyCubit: screenPrivacyCubit,
            authService: authService,
            rotatePinUseCase: rotatePinUseCase,
            unlockVaultUseCase: unlockVaultUseCase,
            monotonicClock: clock,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tile_pin_rotation')));
      await tester.pumpAndSettle();

      // Enter correct current PIN (123456)
      await enterPinDigits(tester, '123456');

      // Step 2: Enter identical PIN (123456)
      expect(find.text('Enter New PIN'), findsOneWidget);
      await enterPinDigits(tester, '123456');

      // Identical PIN was rejected! Shaken, rotation not called, stays on Step 2
      expect(find.text('Enter New PIN'), findsOneWidget);
      expect(find.byKey(const ValueKey('pin_shake_container')), findsOneWidget);
      expect(authService.rotatePinCalls, equals(0));

      // Empirical Check: Digits automatically reset to idle after shake
      final scopedCubit = tester.element(find.byType(Scaffold).last).read<PinPadCubit>();
      expect(scopedCubit.state, isA<PinPadIdleInputState>());
      expect((scopedCubit.state as PinPadIdleInputState).enteredDigitsCount, equals(0));

      // Canceling returns cleanly to security screen
      final backButton = findAuthScreenBackButton();
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(authService.rotatePinCalls, equals(0));
      expect(settingsMutationCubit.state, isA<SettingsMutationSyncedIdleState>());
      expect(find.byKey(const ValueKey('vault_security_screen')), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Challenge 3: Step-Up Auth Cancellation Clean Abort & No State Drift
    // -------------------------------------------------------------------------
    testWidgets('Step-Up Auth Guard: Canceling PIN rotation at Step 1 aborts cleanly without state drift',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(
        createTestApp(
          home: VaultSecuritySettingsScreen(
            settingsMutationCubit: settingsMutationCubit,
            sessionBloc: vaultSessionBloc,
            screenPrivacyCubit: screenPrivacyCubit,
            authService: authService,
            rotatePinUseCase: rotatePinUseCase,
            unlockVaultUseCase: unlockVaultUseCase,
            monotonicClock: clock,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tile_pin_rotation')));
      await tester.pumpAndSettle();

      expect(settingsMutationCubit.state, isA<SettingsMutationAwaitingStepUpAuthState>());

      // Cancel at step 1 via back button in VaultAuthScreen
      final backButton = findAuthScreenBackButton();
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Mutation is cancelled, no rotation occurred
      expect(authService.rotatePinCalls, equals(0));
      expect(settingsMutationCubit.state, isA<SettingsMutationSyncedIdleState>());
      expect(find.byKey(const ValueKey('vault_security_screen')), findsOneWidget);
    });

    testWidgets('Step-Up Auth Guard: Canceling Biometrics step-up returns to syncedIdle without modifying policy',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(
        createTestApp(
          home: VaultSecuritySettingsScreen(
            settingsMutationCubit: settingsMutationCubit,
            sessionBloc: vaultSessionBloc,
            screenPrivacyCubit: screenPrivacyCubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialPolicy = settingsMutationCubit.currentConfig.biometricAuth;
      expect(initialPolicy, equals(BiometricAuthPolicyEnum.pinOnly));

      // Tap biometrics switch
      await tester.tap(find.byKey(const ValueKey('biometric_auth_switch')));
      await tester.pumpAndSettle();

      expect(find.byType(VaultAuthScreen), findsOneWidget);
      expect(settingsMutationCubit.state, isA<SettingsMutationAwaitingStepUpAuthState>());

      // Press Back to cancel
      final backButton = findAuthScreenBackButton();
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Policy was not modified
      expect(settingsMutationCubit.currentConfig.biometricAuth, equals(BiometricAuthPolicyEnum.pinOnly));
      expect(settingsMutationCubit.state, isA<SettingsMutationSyncedIdleState>());
    });

    // -------------------------------------------------------------------------
    // Challenge 4: Danger Zone Destructive Purge Flow
    // -------------------------------------------------------------------------
    testWidgets('Destructive Purge: Warning card, step-up PIN verification, isolate purge, VaultPurged event, pop to root',
        (tester) async {
      setLargeViewport(tester);

      // Put session in unlocked state
      vaultSessionBloc.emit(
        VaultUnlockedState(
          session: AuthSession(
            sessionToken: 'test_token',
            sessionStartedEpochMs: 1000,
            lastActiveEpochMs: 1000,
            authMethod: AuthMethodEnum.pin,
          ),
          unlockedAtMonotonicMs: 1000,
          reauthDeadlineMonotonicMs: 0,
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          home: VaultDangerZoneScreen(
            settingsMutationCubit: settingsMutationCubit,
            sessionBloc: vaultSessionBloc,
            screenPrivacyCubit: screenPrivacyCubit,
            purgeVaultDataUseCase: purgeVaultDataUseCase,
            unlockVaultUseCase: unlockVaultUseCase,
            authService: authService,
            monotonicClock: clock,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 5 consequences in warning card
      expect(find.textContaining('Cryptographic Shredding'), findsOneWidget);
      expect(find.textContaining('Database Wipe'), findsOneWidget);
      expect(find.textContaining('64KB Zero-Overwriting'), findsOneWidget);
      expect(find.textContaining('RAM Zeroization'), findsOneWidget);
      expect(find.textContaining('Irreversible Action'), findsOneWidget);

      // Trigger Purge
      await tester.tap(find.byKey(const ValueKey('purge_vault_button')));
      await tester.pumpAndSettle();

      // In purge confirmation screen
      expect(find.byType(VaultAuthScreen), findsOneWidget);
      expect(find.text('Confirm Vault Purge'), findsOneWidget);
      expect(settingsMutationCubit.state, isA<SettingsMutationAwaitingStepUpAuthState>());

      // Enter valid confirmation PIN
      await enterPinDigits(tester, '123456');

      // Verify Purge use case executed
      expect(storage.purgeCalls, equals(1));
      expect(storage.clearLockoutCalls, equals(1));
      expect(authService.clearRamCalls, equals(1));

      // Verify VaultPurged event dispatched
      expect(vaultSessionBloc.state, isA<VaultUninitializedState>());
      expect(settingsMutationCubit.state, isA<SettingsMutationSyncedIdleState>());
    });

    testWidgets('Destructive Purge: Canceling purge PIN prompt cleanly aborts without shredding',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(
        createTestApp(
          home: VaultDangerZoneScreen(
            settingsMutationCubit: settingsMutationCubit,
            sessionBloc: vaultSessionBloc,
            screenPrivacyCubit: screenPrivacyCubit,
            purgeVaultDataUseCase: purgeVaultDataUseCase,
            unlockVaultUseCase: unlockVaultUseCase,
            authService: authService,
            monotonicClock: clock,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('purge_vault_button')));
      await tester.pumpAndSettle();

      expect(settingsMutationCubit.state, isA<SettingsMutationAwaitingStepUpAuthState>());

      // Cancel
      final backButton = findAuthScreenBackButton();
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Zero purge calls
      expect(storage.purgeCalls, equals(0));
      expect(authService.clearRamCalls, equals(0));
      expect(settingsMutationCubit.state, isA<SettingsMutationSyncedIdleState>());
      expect(find.byKey(const ValueKey('vault_danger_zone_screen')), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Challenge 5: Screen Privacy FLAG_SECURE Lifecycle
    // -------------------------------------------------------------------------
    testWidgets('Screen Privacy: FLAG_SECURE engaged on entry and released on exit across screen lifecycle',
        (tester) async {
      setLargeViewport(tester);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SettingsMutationCubit>.value(value: settingsMutationCubit),
            BlocProvider<VaultSessionBloc>.value(value: vaultSessionBloc),
            BlocProvider<ScreenPrivacyCubit>.value(value: screenPrivacyCubit),
            BlocProvider<GestureEngineCubit>.value(value: gestureEngineCubit),
            BlocProvider<PinPadCubit>.value(value: pinPadCubit),
          ],
          child: VaultTheme(
            data: VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.warmEspresso),
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    key: const ValueKey('open_settings_btn'),
                    onPressed: () {
                      Navigator.push(
                        ctx,
                        MaterialPageRoute<void>(
                          builder: (_) => VaultSettingsScreen(
                            settingsMutationCubit: settingsMutationCubit,
                            sessionBloc: vaultSessionBloc,
                            screenPrivacyCubit: screenPrivacyCubit,
                            gestureEngineCubit: gestureEngineCubit,
                            storageRepository: storage,
                            authService: authService,
                            rotatePinUseCase: rotatePinUseCase,
                            purgeVaultDataUseCase: purgeVaultDataUseCase,
                            unlockVaultUseCase: unlockVaultUseCase,
                            monotonicClock: clock,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially no vault route open
      expect(privacyController.enableCount, equals(0));
      expect(screenPrivacyCubit.isSecureFlagEngaged, isFalse);

      // Open Vault Settings Screen
      await tester.tap(find.byKey(const ValueKey('open_settings_btn')));
      await tester.pumpAndSettle();

      expect(privacyController.enableCount, equals(1));
      expect(screenPrivacyCubit.isSecureFlagEngaged, isTrue);

      // Back navigation pops VaultSettingsScreen
      await tester.tap(find.byKey(const ValueKey('vault_settings_back_button')));
      await tester.pumpAndSettle();

      expect(privacyController.disableCount, equals(1));
      expect(screenPrivacyCubit.isSecureFlagEngaged, isFalse);
    });
  });
}
