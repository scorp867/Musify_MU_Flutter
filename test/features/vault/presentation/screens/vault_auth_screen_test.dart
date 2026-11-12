import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/lockout_cooldown_info.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/keypad_layout_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/pin_pad_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_auth_screen.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';

class FakeMonotonicClock implements IMonotonicClock {
  int timeMs = 10000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> sessionController =
      StreamController<VaultSessionState>.broadcast();

  int consecutiveFailedAttempts = 0;
  LockoutCooldownTierEnum activeTier = LockoutCooldownTierEnum.none;
  int lockoutDeadlineMs = 0;
  bool keysClearedFromRam = false;

  Stream<VaultSessionState> get sessionStateStream => sessionController.stream;

  @override
  Future<LockoutCooldownInfo> getLockoutStatus() async {
    final remainingSec = activeTier == LockoutCooldownTierEnum.none
        ? 0
        : max(0, (lockoutDeadlineMs - 10000) ~/ 1000);
    return LockoutCooldownInfo(
      tier: activeTier,
      remainingCooldownSeconds: remainingSec,
      deadlineMonotonicMs: lockoutDeadlineMs,
      consecutiveFailedAttempts: consecutiveFailedAttempts,
    );
  }

  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({required String pin}) async {
    if (activeTier != LockoutCooldownTierEnum.none) {
      return VaultResult.failure(
        VaultLockoutFailure(
          'Locked out',
          remainingCooldownSeconds: 30,
          deadlineMonotonicMs: lockoutDeadlineMs,
        ),
      );
    }

    if (pin == '123456') {
      return VaultResult.success(
        AuthSession(
          sessionToken: 'valid_session',
          sessionStartedEpochMs: 1000,
          lastActiveEpochMs: 1000,
          authMethod: AuthMethodEnum.pin,
        ),
      );
    }

    return const VaultResult.failure(
      VaultAuthFailure('Invalid PIN', remainingAttempts: 4),
    );
  }

  @override
  Future<VaultResult<AuthSession>> authenticateWithBiometrics() async {
    return VaultResult.success(
      AuthSession(
        sessionToken: 'valid_bio_session',
        sessionStartedEpochMs: 1000,
        lastActiveEpochMs: 1000,
        authMethod: AuthMethodEnum.biometric,
      ),
    );
  }

  @override
  Future<void> recordFailedAttempt() async {
    consecutiveFailedAttempts++;
    if (consecutiveFailedAttempts >= 5) {
      activeTier = LockoutCooldownTierEnum.tier1ThirtySeconds;
      lockoutDeadlineMs = 40000;
    }
  }

  @override
  Future<void> resetFailedAttempts() async {
    consecutiveFailedAttempts = 0;
    activeTier = LockoutCooldownTierEnum.none;
    lockoutDeadlineMs = 0;
  }

  @override
  void clearSessionKeysFromRam() {
    keysClearedFromRam = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('VaultAuthScreen Widget Tests', () {
    late FakeVaultAuthService fakeAuthService;
    late FakeMonotonicClock fakeClock;
    late FakeVaultStorageRepository fakeStorage;
    late UnlockVaultUseCase unlockVaultUseCase;
    late VerifySessionCoolOffUseCase verifyCoolOffUseCase;
    late PinPadCubit pinPadCubit;
    late VaultSessionBloc vaultSessionBloc;

    setUp(() {
      fakeAuthService = FakeVaultAuthService();
      fakeClock = FakeMonotonicClock();
      fakeStorage = FakeVaultStorageRepository();
      unlockVaultUseCase = UnlockVaultUseCase(authService: fakeAuthService);
      verifyCoolOffUseCase = VerifySessionCoolOffUseCase(
        clock: fakeClock,
      );

      pinPadCubit = PinPadCubit(
        unlockVaultUseCase: unlockVaultUseCase,
        authService: fakeAuthService,
        monotonicClock: fakeClock,
      );

      vaultSessionBloc = VaultSessionBloc(
        authService: fakeAuthService,
        storageRepository: fakeStorage,
        monotonicClock: fakeClock,
        verifyCoolOffUseCase: verifyCoolOffUseCase,
      );
    });

    tearDown(() async {
      await pinPadCubit.close();
      await vaultSessionBloc.close();
    });

    Widget buildTestHarness({
      required VaultAuthScreenMode mode,
      String? titleOverride,
      ValueChanged<bool>? onAuthComplete,
      VaultThemePalettePolicyEnum palette = VaultThemePalettePolicyEnum.warmEspresso,
    }) {
      return MaterialApp(
        home: VaultTheme(
          data: VaultThemeData.fromPalette(palette),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<PinPadCubit>.value(value: pinPadCubit),
              BlocProvider<VaultSessionBloc>.value(value: vaultSessionBloc),
            ],
            child: VaultAuthScreen(
              mode: mode,
              titleOverride: titleOverride,
              onAuthComplete: onAuthComplete,
              pinPadCubit: pinPadCubit,
              sessionBloc: vaultSessionBloc,
            ),
          ),
        ),
      );
    }

    testWidgets('unlock mode renders "Enter Master PIN" and vector lock icon', (tester) async {
      await tester.pumpWidget(buildTestHarness(mode: VaultAuthScreenMode.unlock));
      expect(find.text('Enter Master PIN'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.textContaining('—'), findsNothing);
    });

    testWidgets('stepUp mode renders "Step-Up Verification"', (tester) async {
      await tester.pumpWidget(buildTestHarness(mode: VaultAuthScreenMode.stepUp));
      expect(find.text('Step-Up Verification'), findsOneWidget);
    });

    testWidgets('verifyOldPin mode renders "Verify Current PIN"', (tester) async {
      await tester.pumpWidget(buildTestHarness(mode: VaultAuthScreenMode.verifyOldPin));
      expect(find.text('Verify Current PIN'), findsOneWidget);
    });

    testWidgets('rotatePin mode renders "Enter New PIN" and lock reset icon', (tester) async {
      await tester.pumpWidget(buildTestHarness(mode: VaultAuthScreenMode.rotatePin));
      expect(find.text('Enter New PIN'), findsOneWidget);
      expect(find.byIcon(Icons.lock_reset_outlined), findsOneWidget);
    });

    testWidgets('purgeConfirmation mode renders "Confirm Vault Purge" and warning icon', (tester) async {
      await tester.pumpWidget(buildTestHarness(mode: VaultAuthScreenMode.purgeConfirmation));
      expect(find.text('Confirm Vault Purge'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('titleOverride replaces default mode title', (tester) async {
      await tester.pumpWidget(buildTestHarness(
        mode: VaultAuthScreenMode.unlock,
        titleOverride: 'Custom Security Check',
      ));
      expect(find.text('Custom Security Check'), findsOneWidget);
    });

    testWidgets('standardOrdered renders keys 1..9, 0 in sequence', (tester) async {
      pinPadCubit.updateKeypadLayout(KeypadLayoutPolicyEnum.standardOrdered);
      await tester.pumpWidget(buildTestHarness(mode: VaultAuthScreenMode.unlock));
      for (var i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
    });

    testWidgets('randomizedPerAttempt renders all 10 digits permuted', (tester) async {
      pinPadCubit.updateKeypadLayout(KeypadLayoutPolicyEnum.randomizedPerAttempt);
      await tester.pumpWidget(buildTestHarness(mode: VaultAuthScreenMode.unlock));
      for (var i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
      expect(pinPadCubit.currentKeypadDigits.length, 10);
    });

    testWidgets('Tapping digits increments PIN dot indicators', (tester) async {
      await tester.pumpWidget(buildTestHarness(mode: VaultAuthScreenMode.unlock));
      expect(find.byKey(const ValueKey('pin_dot_filled')), findsNothing);

      await tester.tap(find.text('1'));
      await tester.pump();
      expect(find.byKey(const ValueKey('pin_dot_filled')), findsNWidgets(1));

      await tester.tap(find.text('2'));
      await tester.pump();
      expect(find.byKey(const ValueKey('pin_dot_filled')), findsNWidgets(2));
    });

    testWidgets('Backspace button removes the last entered digit', (tester) async {
      await tester.pumpWidget(buildTestHarness(mode: VaultAuthScreenMode.unlock));
      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.pump();
      expect(find.byKey(const ValueKey('pin_dot_filled')), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
      expect(find.byKey(const ValueKey('pin_dot_filled')), findsNWidgets(1));
    });

    testWidgets('Auto-submit on 6th digit enters evaluatingAndDeriving state', (tester) async {
      final completer = Completer<VaultResult<AuthSession>>();
      final evaluatingCubit = PinPadCubit(
        unlockVaultUseCase: unlockVaultUseCase,
        authService: fakeAuthService,
        monotonicClock: fakeClock,
        customPinSubmitter: (_) => completer.future,
      );

      await tester.pumpWidget(MaterialApp(
        home: VaultTheme(
          data: VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.warmEspresso),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<PinPadCubit>.value(value: evaluatingCubit),
              BlocProvider<VaultSessionBloc>.value(value: vaultSessionBloc),
            ],
            child: VaultAuthScreen(
              mode: VaultAuthScreenMode.unlock,
              pinPadCubit: evaluatingCubit,
              sessionBloc: vaultSessionBloc,
            ),
          ),
        ),
      ));

      for (var i = 1; i <= 5; i++) {
        await tester.tap(find.text('$i'));
        await tester.pump();
      }
      expect(evaluatingCubit.state, isA<PinPadIdleInputState>());

      // 6th digit auto-submits while async derivation is in-flight
      await tester.tap(find.text('6'));
      await tester.pump();
      expect(evaluatingCubit.state, isA<PinPadEvaluatingState>());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(VaultResult.success(AuthSession(
        sessionToken: 'valid_session',
        sessionStartedEpochMs: 1000,
        lastActiveEpochMs: 1000,
        authMethod: AuthMethodEnum.pin,
      )));
      await tester.pump();
      expect(evaluatingCubit.state, isA<PinPadSuccessState>());

      await evaluatingCubit.close();
    });

    testWidgets('Incorrect PIN triggers failure shake and remaining attempts text', (tester) async {
      fakeAuthService.consecutiveFailedAttempts = 1;
      await tester.pumpWidget(buildTestHarness(mode: VaultAuthScreenMode.unlock));

      pinPadCubit.emit(const PinPadFailureShakeState(
        failedAttemptsCount: 1,
        remainingAttemptsBeforeCooldown: 4,
      ));
      await tester.pump();
      expect(find.textContaining('4 attempts remaining'), findsOneWidget);
      expect(find.byKey(const ValueKey('pin_shake_container')), findsOneWidget);
    });

    testWidgets('Lockout state disables keypad and renders monotonic countdown timer', (tester) async {
      pinPadCubit.emit(const PinPadLockedOutState(
        cooldownRemainingSeconds: 30,
        deadlineMonotonicMs: 40000,
      ));
      await tester.pumpWidget(buildTestHarness(mode: VaultAuthScreenMode.unlock));

      expect(find.text('Vault Locked'), findsOneWidget);
      expect(find.text('00:30'), findsOneWidget);

      // Digits are absorbed and not interactive
      await tester.tap(find.text('1'), warnIfMissed: false);
      await tester.pump();
      expect(pinPadCubit.state, isA<PinPadLockedOutState>());
    });

    testWidgets('Zero pill buttons & 8px geometric radius verification', (tester) async {
      await tester.pumpWidget(buildTestHarness(mode: VaultAuthScreenMode.unlock));
      final buttons = tester.widgetList<InkWell>(find.byType(InkWell));
      for (final button in buttons) {
        if (button.borderRadius case final radius?) {
          expect(radius, BorderRadius.circular(8.0),
              reason: 'Keypad button must have exact 8px radius');
        }
      }
      expect(find.byType(StadiumBorder), findsNothing);
    });

    testWidgets('Success triggers onAuthComplete callback with true', (tester) async {
      bool? authResult;
      await tester.pumpWidget(buildTestHarness(
        mode: VaultAuthScreenMode.unlock,
        onAuthComplete: (result) => authResult = result,
      ));

      pinPadCubit.emit(const PinPadSuccessState());
      await tester.pump();
      expect(authResult, isTrue);
    });

    testWidgets('Back button triggers onAuthComplete callback with false', (tester) async {
      bool? authResult;
      await tester.pumpWidget(buildTestHarness(
        mode: VaultAuthScreenMode.unlock,
        onAuthComplete: (result) => authResult = result,
      ));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      expect(authResult, isFalse);
    });
  });
}
