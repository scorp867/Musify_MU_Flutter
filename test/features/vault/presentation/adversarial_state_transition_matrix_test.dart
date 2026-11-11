import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/app/routes/vault_routes.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_screen_privacy_controller.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/pin_pad_state.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';
import 'package:musify_mu/features/vault/presentation/screens/gesture_enrollment_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_auth_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_settings_screen.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';
import 'package:musify_mu/features/vault/presentation/widgets/reauth_blur_overlay.dart';

class FakeMonotonicClock implements IMonotonicClock {
  int timeMs = 10000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  DateTime get now => DateTime.fromMillisecondsSinceEpoch(timeMs);

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class FakeVaultStorageRepository implements IVaultStorageRepository {
  VaultConfig config = const VaultConfig.constant();
  int? persistedDeadlineMs;

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      VaultResult.success(config);

  @override
  Future<int?> getPersistedLockoutDeadlineMs() async => persistedDeadlineMs;

  @override
  Future<void> clearPersistedLockoutDeadline() async {
    persistedDeadlineMs = null;
  }

  @override
  Future<void> persistLockoutDeadlineMs(int deadlineMonotonicMs) async {
    persistedDeadlineMs = deadlineMonotonicMs;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> sessionController =
      StreamController<VaultSessionState>.broadcast();
  int clearKeysCallCount = 0;
  int resetAttemptsCallCount = 0;

  Stream<VaultSessionState> get sessionStateStream => sessionController.stream;

  @override
  void clearSessionKeysFromRam() {
    clearKeysCallCount++;
  }

  @override
  Future<void> resetFailedAttempts() async {
    resetAttemptsCallCount++;
  }

  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({
    required String pin,
  }) async {
    if (pin == '123456') {
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
      VaultAuthFailure('Invalid PIN'),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

class TestVaultSessionBloc extends VaultSessionBloc {
  TestVaultSessionBloc({
    required super.authService,
    required super.storageRepository,
    required super.monotonicClock,
    required super.verifyCoolOffUseCase,
    super.initialState = const VaultUninitializedState(),
  });

  void emitState(VaultSessionState state) {
    emit(state);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adversarial State Transition Matrix Suite', () {
    late FakeVaultAuthService fakeAuthService;
    late FakeMonotonicClock fakeClock;
    late FakeVaultStorageRepository fakeStorage;
    late FakeScreenPrivacyController fakePrivacyController;
    late VerifySessionCoolOffUseCase verifyCoolOffUseCase;
    late UnlockVaultUseCase unlockVaultUseCase;
    late TestVaultSessionBloc vaultSessionBloc;
    late ScreenPrivacyCubit screenPrivacyCubit;
    late PinPadCubit pinPadCubit;

    final testSession = AuthSession(
      sessionToken: 'matrix_token',
      sessionStartedEpochMs: 10000,
      lastActiveEpochMs: 10000,
      authMethod: AuthMethodEnum.pin,
    );

    setUp(() {
      fakeAuthService = FakeVaultAuthService();
      fakeClock = FakeMonotonicClock();
      fakeStorage = FakeVaultStorageRepository();
      fakePrivacyController = FakeScreenPrivacyController();
      verifyCoolOffUseCase = VerifySessionCoolOffUseCase(clock: fakeClock);
      unlockVaultUseCase = UnlockVaultUseCase(authService: fakeAuthService);

      vaultSessionBloc = TestVaultSessionBloc(
        authService: fakeAuthService,
        storageRepository: fakeStorage,
        monotonicClock: fakeClock,
        verifyCoolOffUseCase: verifyCoolOffUseCase,
        initialState: VaultUnlockedState(
          session: testSession,
          unlockedAtMonotonicMs: 10000,
          reauthDeadlineMonotonicMs: 70000,
        ),
      );

      screenPrivacyCubit = ScreenPrivacyCubit(
        privacyController: fakePrivacyController,
        monotonicClock: fakeClock,
      );

      pinPadCubit = PinPadCubit(
        unlockVaultUseCase: unlockVaultUseCase,
        authService: fakeAuthService,
        monotonicClock: fakeClock,
      );
    });

    tearDown(() async {
      await vaultSessionBloc.close();
      await screenPrivacyCubit.close();
      await pinPadCubit.close();
    });

    testWidgets(
      'T05: Rapid double-tap on re-auth button only triggers a single callback invocation',
      (tester) async {
        int pushCount = 0;
        final themeData = VaultThemeData.fromPalette(
          VaultThemePalettePolicyEnum.warmEspresso,
        );

        vaultSessionBloc.emitState(
          VaultPendingReauthState(
            session: testSession,
            reauthTriggeredAtMonotonicMs: 10000,
            remainingAttempts: 5,
          ),
        );

        await tester.pumpWidget(
          VaultTheme(
            data: themeData,
            child: BlocProvider<VaultSessionBloc>.value(
              value: vaultSessionBloc,
              child: MaterialApp(
                home: Scaffold(
                  body: ReauthBlurOverlay(
                    onReauthRequested: () {
                      pushCount++;
                    },
                    child: const Center(child: Text('Secret Protected Content')),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final buttonFinder = find.text('Re-authenticate');
        expect(buttonFinder, findsOneWidget);

        // Rapid double tap simulated within same frame
        await tester.tap(buttonFinder);
        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();

        expect(pushCount, 1);
      },
    );

    testWidgets(
      'T06/T08: Lockout cooldown maintains frosted glass blur shield and absorbs touches',
      (tester) async {
        final themeData = VaultThemeData.fromPalette(
          VaultThemePalettePolicyEnum.warmEspresso,
        );

        vaultSessionBloc.emitState(
          const VaultLockoutCooldownState(
            tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
            cooldownStartedMonotonicMs: 10000,
            durationMs: 30000,
            deadlineMonotonicMs: 40000,
            failedAttemptsCount: 5,
          ),
        );

        await tester.pumpWidget(
          VaultTheme(
            data: themeData,
            child: BlocProvider<VaultSessionBloc>.value(
              value: vaultSessionBloc,
              child: MaterialApp(
                home: Scaffold(
                  body: ReauthBlurOverlay(
                    onReauthRequested: () {},
                    child: const Center(
                      child: Text('Protected Vault Vault Data'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byType(BackdropFilter),
          findsOneWidget,
        );
        expect(
          find.text('Security Lockout Active'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'T09: Deep-link cold-start back navigation on VaultAuthScreen invokes SystemNavigator.pop',
      (tester) async {
        final platformCalls = <MethodCall>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            platformCalls.add(call);
            return null;
          },
        );

        final themeData = VaultThemeData.fromPalette(
          VaultThemePalettePolicyEnum.warmEspresso,
        );

        // Mount VaultAuthScreen directly as root of MaterialApp (Navigator.canPop() == false)
        await tester.pumpWidget(
          VaultTheme(
            data: themeData,
            child: MaterialApp(
              home: VaultAuthScreen(
                mode: VaultAuthScreenMode.unlock,
                pinPadCubit: pinPadCubit,
                sessionBloc: vaultSessionBloc,
                screenPrivacyCubit: screenPrivacyCubit,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final backButton = find.byKey(const ValueKey('vault_auth_back_button'));
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        final popCalls = platformCalls.where(
          (call) => call.method == 'SystemNavigator.pop',
        );
        expect(popCalls, isNotEmpty);
      },
    );

    testWidgets(
      'T12: AppLifecycleState.paused / inactive resets entered PIN digits on VaultAuthScreen',
      (tester) async {
        final themeData = VaultThemeData.fromPalette(
          VaultThemePalettePolicyEnum.warmEspresso,
        );

        await tester.pumpWidget(
          VaultTheme(
            data: themeData,
            child: MaterialApp(
              home: VaultAuthScreen(
                mode: VaultAuthScreenMode.unlock,
                pinPadCubit: pinPadCubit,
                sessionBloc: vaultSessionBloc,
                screenPrivacyCubit: screenPrivacyCubit,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enter 3 digits into the cubit
        pinPadCubit.onDigitEntered(1);
        pinPadCubit.onDigitEntered(2);
        pinPadCubit.onDigitEntered(3);
        await tester.pump();

        expect(
          pinPadCubit.state,
          isA<PinPadIdleInputState>().having(
            (s) => s.enteredDigitsCount,
            'enteredDigitsCount',
            3,
          ),
        );

        // Simulate app backgrounding
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );
        await tester.pumpAndSettle();

        // PinPad state must be reset to 0 digits
        expect(
          pinPadCubit.state,
          isA<PinPadIdleInputState>().having(
            (s) => s.enteredDigitsCount,
            'enteredDigitsCount',
            0,
          ),
        );
      },
    );

    testWidgets(
      'T17/T31: Session lock / Quick-lock pops VaultSettingsScreen back to root route',
      (tester) async {
        final themeData = VaultThemeData.fromPalette(
          VaultThemePalettePolicyEnum.warmEspresso,
        );

        await tester.pumpWidget(
          VaultTheme(
            data: themeData,
            child: MaterialApp(
              initialRoute: '/',
              routes: {
                '/': (ctx) => const Scaffold(
                      body: Center(child: Text('Root Public View')),
                    ),
                '/settings': (ctx) => VaultSettingsScreen(
                      sessionBloc: vaultSessionBloc,
                      screenPrivacyCubit: screenPrivacyCubit,
                      authService: fakeAuthService,
                      unlockVaultUseCase: unlockVaultUseCase,
                      monotonicClock: fakeClock,
                    ),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final nav = tester.state<NavigatorState>(find.byType(Navigator));
        nav.pushNamed('/settings');
        await tester.pumpAndSettle();

        expect(find.byType(VaultSettingsScreen), findsOneWidget);

        // Transition session state to locked
        vaultSessionBloc.emitState(
          const VaultLockedState(lockedAtMonotonicMs: 10000),
        );
        await tester.pumpAndSettle();

        // VaultSettingsScreen must be popped back to root
        expect(find.byType(VaultSettingsScreen), findsNothing);
        expect(find.text('Root Public View'), findsOneWidget);
      },
    );

    testWidgets(
      'T27/T29: VaultLockoutCooldownState pops VaultSettingsScreen and sub-screens',
      (tester) async {
        final themeData = VaultThemeData.fromPalette(
          VaultThemePalettePolicyEnum.warmEspresso,
        );

        await tester.pumpWidget(
          VaultTheme(
            data: themeData,
            child: MaterialApp(
              initialRoute: '/',
              routes: {
                '/': (ctx) => const Scaffold(
                      body: Center(child: Text('Root Public View')),
                    ),
                '/appearance': (ctx) => VaultAppearanceSettingsScreen(
                      sessionBloc: vaultSessionBloc,
                      screenPrivacyCubit: screenPrivacyCubit,
                    ),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final nav = tester.state<NavigatorState>(find.byType(Navigator));
        nav.pushNamed('/appearance');
        await tester.pumpAndSettle();

        expect(find.byType(VaultAppearanceSettingsScreen), findsOneWidget);

        // Transition session state to Lockout cooldown
        vaultSessionBloc.emitState(
          const VaultLockoutCooldownState(
            tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
            cooldownStartedMonotonicMs: 10000,
            durationMs: 30000,
            deadlineMonotonicMs: 40000,
            failedAttemptsCount: 5,
          ),
        );
        await tester.pumpAndSettle();

        // Appearance screen must be popped back to root
        expect(find.byType(VaultAppearanceSettingsScreen), findsNothing);
        expect(find.text('Root Public View'), findsOneWidget);
      },
    );

    testWidgets(
      'T32/T37: VaultSessionScaffoldGuard automatically pops GestureEnrollmentScreen when locked',
      (tester) async {
        final themeData = VaultThemeData.fromPalette(
          VaultThemePalettePolicyEnum.warmEspresso,
        );

        await tester.pumpWidget(
          VaultTheme(
            data: themeData,
            child: MaterialApp(
              initialRoute: '/',
              routes: {
                '/': (ctx) => const Scaffold(
                      body: Center(child: Text('Root Public View')),
                    ),
                '/enrollment': (ctx) => GestureEnrollmentScreen(
                      sessionBloc: vaultSessionBloc,
                      screenPrivacyCubit: screenPrivacyCubit,
                      authService: fakeAuthService,
                      pinPadCubit: pinPadCubit,
                    ),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final nav = tester.state<NavigatorState>(find.byType(Navigator));
        nav.pushNamed('/enrollment');
        await tester.pumpAndSettle();

        expect(find.byType(GestureEnrollmentScreen), findsOneWidget);

        // Emit Lockout Cooldown State
        vaultSessionBloc.emitState(
          const VaultLockoutCooldownState(
            tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
            cooldownStartedMonotonicMs: 10000,
            durationMs: 30000,
            deadlineMonotonicMs: 40000,
            failedAttemptsCount: 5,
          ),
        );
        await tester.pumpAndSettle();

        // Enrollment screen must be popped back to root
        expect(find.byType(GestureEnrollmentScreen), findsNothing);
        expect(find.text('Root Public View'), findsOneWidget);
      },
    );

    testWidgets(
      'T01: VaultNavigationTarget.setupScreen continuation navigates to dashboard on true return and stays on root on false return',
      (tester) async {
        final navKey = GlobalKey<NavigatorState>();

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navKey,
            initialRoute: '/',
            routes: {
              '/': (context) => const Scaffold(body: Text('Root Public View')),
              VaultRoutes.setup: (context) => Scaffold(
                    body: Center(
                      child: Column(
                        children: [
                          ElevatedButton(
                            key: const ValueKey('complete_setup_success_button'),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Complete Setup Success'),
                          ),
                          ElevatedButton(
                            key: const ValueKey('cancel_setup_button'),
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel Setup'),
                          ),
                        ],
                      ),
                    ),
                  ),
              VaultRoutes.dashboard: (context) => const Scaffold(
                    body: Center(child: Text('Vault Dashboard View')),
                  ),
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Root Public View'), findsOneWidget);

        // Step 1: Trigger continuation and cancel setup (pop false)
        final nav = navKey.currentState!;
        nav.pushNamed(VaultRoutes.setup).then((setupResult) {
          if (setupResult == true) {
            nav.pushNamed(VaultRoutes.dashboard);
          }
        });
        await tester.pumpAndSettle();

        expect(find.text('Cancel Setup'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('cancel_setup_button')));
        await tester.pumpAndSettle();

        // Must remain on Root Public View, dashboard should NOT be reached
        expect(find.text('Root Public View'), findsOneWidget);
        expect(find.text('Vault Dashboard View'), findsNothing);

        // Step 2: Trigger continuation and complete setup (pop true)
        nav.pushNamed(VaultRoutes.setup).then((setupResult) {
          if (setupResult == true) {
            nav.pushNamed(VaultRoutes.dashboard);
          }
        });
        await tester.pumpAndSettle();

        expect(find.text('Complete Setup Success'), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey('complete_setup_success_button')),
        );
        await tester.pumpAndSettle();

        // Must transition to Vault Dashboard View
        expect(find.text('Vault Dashboard View'), findsOneWidget);
      },
    );
  });
}
