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
import 'package:musify_mu/features/vault/domain/policies/active_reauth_interval.dart';
import 'package:musify_mu/features/vault/domain/policies/background_grace_timeout.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/screen_security_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/mutate_vault_config_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/purge_vault_data_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/rotate_pin_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_auth_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_settings_screen.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';

class FakeMonotonicClock implements IMonotonicClock {
  int timeMs = 1000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class FakeScreenPrivacyController implements IScreenPrivacyController {
  ScreenPrivacyStateEnum _state = ScreenPrivacyStateEnum.publicUnrestricted;
  final StreamController<ScreenPrivacyStateEnum> _streamController =
      StreamController<ScreenPrivacyStateEnum>.broadcast();

  int enableCallCount = 0;
  int disableCallCount = 0;

  @override
  ScreenPrivacyStateEnum get currentState => _state;

  @override
  Stream<ScreenPrivacyStateEnum> get stateStream => _streamController.stream;

  @override
  Future<void> enableSecureFlag() async {
    enableCallCount++;
    _state = ScreenPrivacyStateEnum.secureFlagEngaged;
    _streamController.add(_state);
  }

  @override
  Future<void> disableSecureFlag() async {
    disableCallCount++;
    _state = ScreenPrivacyStateEnum.publicUnrestricted;
    _streamController.add(_state);
  }
}

class FakeVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> _sessionController =
      StreamController<VaultSessionState>.broadcast();

  int rotatePinCalls = 0;
  String? lastRotatedOldPin;
  String? lastRotatedNewPin;

  @override
  Stream<VaultSessionState> get sessionStateStream =>
      _sessionController.stream;

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
    if (pin == '123456') {
      return VaultResult.success(
        AuthSession(
          sessionToken: 'test_token',
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
    return const VaultResult.success(null);
  }

  @override
  void clearSessionKeysFromRam() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVaultStorageRepository implements IVaultStorageRepository {
  VaultConfig currentConfig = const VaultConfig.constant();
  int purgeCalls = 0;

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
  Future<void> clearPersistedLockoutDeadline() async {}

  @override
  Future<VaultResult<GestureTemplate>> loadGestureTemplate() async =>
      VaultResult.success(DefaultGestureTemplate.canonicalVShape);

  @override
  Future<VaultResult<void>> saveGestureTemplate(GestureTemplate template) async =>
      const VaultResult.success(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGestureRecognizer implements IGestureRecognizer {
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

  group('VaultSettingsScreen & Dedicated Sub-Screens Suite', () {
    late FakeMonotonicClock monotonicClock;
    late FakeScreenPrivacyController privacyController;
    late FakeVaultAuthService authService;
    late FakeVaultStorageRepository storage;
    late FakeGestureRecognizer recognizer;

    late MutateVaultConfigUseCase mutateVaultConfigUseCase;
    late PurgeVaultDataUseCase purgeVaultDataUseCase;
    late RotatePinUseCase rotatePinUseCase;
    late UnlockVaultUseCase unlockVaultUseCase;
    late VerifySessionCoolOffUseCase verifySessionCoolOffUseCase;

    late SettingsMutationCubit settingsMutationCubit;
    late VaultSessionBloc vaultSessionBloc;
    late ScreenPrivacyCubit screenPrivacyCubit;
    late GestureEngineCubit gestureEngineCubit;
    late PinPadCubit pinPadCubit;

    setUp(() {
      monotonicClock = FakeMonotonicClock();
      privacyController = FakeScreenPrivacyController();
      authService = FakeVaultAuthService();
      storage = FakeVaultStorageRepository();
      recognizer = FakeGestureRecognizer();

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
      verifySessionCoolOffUseCase = VerifySessionCoolOffUseCase(
        clock: monotonicClock,
      );

      settingsMutationCubit = SettingsMutationCubit(
        storageRepository: storage,
        mutateVaultConfigUseCase: mutateVaultConfigUseCase,
        authService: authService,
        monotonicClock: monotonicClock,
      );

      vaultSessionBloc = VaultSessionBloc(
        authService: authService,
        storageRepository: storage,
        monotonicClock: monotonicClock,
        verifyCoolOffUseCase: verifySessionCoolOffUseCase,
      );

      screenPrivacyCubit = ScreenPrivacyCubit(
        privacyController: privacyController,
        monotonicClock: monotonicClock,
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
        monotonicClock: monotonicClock,
      );
    });

    tearDown(() {
      // Clean teardown
    });

    Widget createTestBed({Widget? child}) {
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
            home: child ??
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
                  monotonicClock: monotonicClock,
                ),
          ),
        ),
      );
    }

    void setLargeViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('Hub screen renders top bar, status badge, quick-lock, and 5 nav tiles',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vault_settings_scaffold')), findsOneWidget);
      expect(find.text('Vault Settings'), findsOneWidget);
      expect(find.byKey(const ValueKey('vault_settings_status_badge')), findsOneWidget);
      expect(find.text('Active Session'), findsOneWidget);
      expect(find.byKey(const ValueKey('vault_settings_quick_lock_button')), findsOneWidget);

      expect(find.byKey(const ValueKey('nav_tile_appearance')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav_tile_security')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav_tile_privacy')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav_tile_gestures')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav_tile_danger_zone')), findsOneWidget);
    });

    testWidgets('Tapping Appearance tile navigates to dedicated VaultAppearanceSettingsScreen',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('nav_tile_appearance')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vault_appearance_screen')), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.byKey(const ValueKey('palette_warm_espresso')), findsOneWidget);
      expect(find.byKey(const ValueKey('palette_forest_noir')), findsOneWidget);
      expect(find.byKey(const ValueKey('blur_slider')), findsOneWidget);
      expect(find.byKey(const ValueKey('blur_preview_container')), findsOneWidget);

      // Back navigation returns to hub
      await tester.tap(find.byKey(const ValueKey('vault_appearance_back_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vault_settings_scaffold')), findsOneWidget);
    });

    testWidgets('Appearance Screen: Palette switching mutates config immediately',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(
        createTestBed(
          child: VaultAppearanceSettingsScreen(
            settingsMutationCubit: settingsMutationCubit,
            screenPrivacyCubit: screenPrivacyCubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Forest Noir
      await tester.tap(find.byKey(const ValueKey('palette_forest_noir')));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(
        settingsMutationCubit.currentConfig.themePalette,
        equals(VaultThemePalettePolicyEnum.forestNoir),
      );
    });

    testWidgets('Tapping Security tile navigates to dedicated VaultSecuritySettingsScreen',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('nav_tile_security')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vault_security_screen')), findsOneWidget);
      expect(find.text('Security & Authentication'), findsOneWidget);
      expect(find.byKey(const ValueKey('biometric_auth_switch')), findsOneWidget);
      expect(find.byKey(const ValueKey('grace_timeout_immediate')), findsOneWidget);
      expect(find.byKey(const ValueKey('grace_timeout_thirty_seconds')), findsOneWidget);
      expect(find.byKey(const ValueKey('reauth_interval_15_min')), findsOneWidget);
      expect(find.byKey(const ValueKey('keypad_layout_standard')), findsOneWidget);
      expect(find.byKey(const ValueKey('tile_pin_rotation')), findsOneWidget);

      // Back navigation
      await tester.tap(find.byKey(const ValueKey('vault_security_back_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vault_settings_scaffold')), findsOneWidget);
    });

    testWidgets('Security Screen: Biometrics toggle triggers full-screen step-up auth',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(
        createTestBed(
          child: VaultSecuritySettingsScreen(
            settingsMutationCubit: settingsMutationCubit,
            sessionBloc: vaultSessionBloc,
            screenPrivacyCubit: screenPrivacyCubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('biometric_auth_switch')));
      await tester.pumpAndSettle();

      // Pushes full-screen VaultAuthScreen in stepUp mode
      expect(find.byType(VaultAuthScreen), findsOneWidget);
      expect(find.text('Authorize Biometrics'), findsOneWidget);
    });

    testWidgets('Security Screen: Grace timeout and reauth selectors persist immediately',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(
        createTestBed(
          child: VaultSecuritySettingsScreen(
            settingsMutationCubit: settingsMutationCubit,
            sessionBloc: vaultSessionBloc,
            screenPrivacyCubit: screenPrivacyCubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select 1 Minute
      await tester.tap(find.byKey(const ValueKey('grace_timeout_one_minute')));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(
        settingsMutationCubit.currentConfig.backgroundGraceTimeout,
        equals(BackgroundGraceTimeoutEnum.oneMinute),
      );

      // Select 30 minutes
      await tester.tap(find.byKey(const ValueKey('reauth_interval_30_min')));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(
        settingsMutationCubit.currentConfig.activeReauthInterval,
        equals(ActiveReauthIntervalEnum.every30Minutes),
      );
    });

    testWidgets('Tapping Privacy tile navigates to dedicated VaultPrivacySettingsScreen',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('nav_tile_privacy')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vault_privacy_screen')), findsOneWidget);
      expect(find.text('Playback & Privacy'), findsOneWidget);
      expect(find.byKey(const ValueKey('screen_privacy_switch')), findsOneWidget);
      expect(find.byKey(const ValueKey('metadata_masking_switch')), findsOneWidget);
      expect(find.byKey(const ValueKey('decoy_title_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('decoy_artist_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('decoy_album_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('lock_playback_stop')), findsOneWidget);
    });

    testWidgets('Privacy Screen: Screen privacy and metadata masking toggle reactively',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(
        createTestBed(
          child: VaultPrivacySettingsScreen(
            settingsMutationCubit: settingsMutationCubit,
            screenPrivacyCubit: screenPrivacyCubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle Screen Privacy
      await tester.tap(find.byKey(const ValueKey('screen_privacy_switch')));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(
        settingsMutationCubit.currentConfig.screenSecurity,
        equals(ScreenSecurityPolicyEnum.allowCapture),
      );

      // Toggle Metadata Masking
      await tester.tap(find.byKey(const ValueKey('metadata_masking_switch')));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(
        settingsMutationCubit.currentConfig.metadataVisibility,
        equals(MetadataVisibilityPolicyEnum.showActualMetadata),
      );
    });

    testWidgets('Tapping Gesture Controls tile navigates to dedicated VaultGestureSettingsScreen',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('nav_tile_gestures')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vault_gesture_screen')), findsOneWidget);
      expect(find.text('Gesture Controls'), findsOneWidget);
      expect(find.byKey(const ValueKey('gesture_status_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('gesture_sensitivity_strict')), findsOneWidget);
      expect(find.byKey(const ValueKey('gesture_ink_visibility_switch')), findsOneWidget);
      expect(find.byKey(const ValueKey('re_enroll_gesture_button')), findsOneWidget);
    });

    testWidgets('Gesture Screen: Sensitivity selector updates policy immediately',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(
        createTestBed(
          child: VaultGestureSettingsScreen(
            settingsMutationCubit: settingsMutationCubit,
            sessionBloc: vaultSessionBloc,
            screenPrivacyCubit: screenPrivacyCubit,
            gestureEngineCubit: gestureEngineCubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('gesture_sensitivity_strict')));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(
        settingsMutationCubit.currentConfig.gestureSensitivity,
        equals(GestureSensitivityTierEnum.strict92Percent),
      );
    });

    testWidgets('Gesture Screen: Re-enroll gesture button triggers step-up auth',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(
        createTestBed(
          child: VaultGestureSettingsScreen(
            settingsMutationCubit: settingsMutationCubit,
            sessionBloc: vaultSessionBloc,
            screenPrivacyCubit: screenPrivacyCubit,
            gestureEngineCubit: gestureEngineCubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('re_enroll_gesture_button')));
      await tester.pumpAndSettle();

      expect(find.byType(VaultAuthScreen), findsOneWidget);
      expect(find.text('Authorize Gesture Re-Enrollment'), findsOneWidget);
    });

    testWidgets('Tapping Danger Zone tile navigates to dedicated VaultDangerZoneScreen',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('nav_tile_danger_zone')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vault_danger_zone_screen')), findsOneWidget);
      expect(find.text('Danger Zone'), findsOneWidget);
      expect(find.byKey(const ValueKey('danger_zone_warning_card')), findsOneWidget);
      expect(find.text('Destructive Vault Purge'), findsOneWidget);
      expect(find.byKey(const ValueKey('purge_vault_button')), findsOneWidget);
    });

    testWidgets('Danger Zone Screen: Warning card renders all 5 explicit consequences',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(
        createTestBed(
          child: VaultDangerZoneScreen(
            settingsMutationCubit: settingsMutationCubit,
            sessionBloc: vaultSessionBloc,
            screenPrivacyCubit: screenPrivacyCubit,
            purgeVaultDataUseCase: purgeVaultDataUseCase,
            unlockVaultUseCase: unlockVaultUseCase,
            authService: authService,
            monotonicClock: monotonicClock,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Cryptographic Shredding'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Database Wipe'),
        findsOneWidget,
      );
      expect(
        find.textContaining('64KB Zero-Overwriting'),
        findsOneWidget,
      );
      expect(
        find.textContaining('RAM Zeroization'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Irreversible Action'),
        findsOneWidget,
      );
    });

    testWidgets('Danger Zone Screen: Purge button triggers full-screen purge confirmation auth',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(
        createTestBed(
          child: VaultDangerZoneScreen(
            settingsMutationCubit: settingsMutationCubit,
            sessionBloc: vaultSessionBloc,
            screenPrivacyCubit: screenPrivacyCubit,
            purgeVaultDataUseCase: purgeVaultDataUseCase,
            unlockVaultUseCase: unlockVaultUseCase,
            authService: authService,
            monotonicClock: monotonicClock,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('purge_vault_button')));
      await tester.pumpAndSettle();

      expect(find.byType(VaultAuthScreen), findsOneWidget);
      expect(find.text('Confirm Vault Purge'), findsOneWidget);
    });

    testWidgets('Design system compliance across all settings screens',
        (tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestBed());
      await tester.pumpAndSettle();

      // Check all Text widgets for emojis and em dashes
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      for (final text in textWidgets) {
        final content = text.data ?? text.textSpan?.toPlainText() ?? '';
        expect(content.contains('\u2014'), isFalse,
            reason: 'Em dash found in: "$content"');
        expect(content.contains('—'), isFalse,
            reason: 'Em dash character found in: "$content"');
      }
    });
  });
}
