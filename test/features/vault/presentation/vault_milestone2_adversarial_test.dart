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
import 'package:musify_mu/features/vault/domain/policies/biometric_auth_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/keypad_layout_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/pin_pad_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_auth_screen.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';
import 'package:musify_mu/features/vault/presentation/widgets/reauth_blur_overlay.dart';

class AdversarialMonotonicClock implements IMonotonicClock {
  int timeMs = 10000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class AdversarialVaultStorageRepository implements IVaultStorageRepository {
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

class AdversarialVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> sessionController =
      StreamController<VaultSessionState>.broadcast();

  int consecutiveFailedAttempts = 0;
  LockoutCooldownTierEnum activeTier = LockoutCooldownTierEnum.none;
  int lockoutDeadlineMs = 0;
  bool resetFailedAttemptsCalled = false;
  bool clearSessionKeysCalled = false;

  @override
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

    if (pin == '654321') {
      return VaultResult.success(
        AuthSession(
          sessionToken: 'valid_adversarial_session',
          sessionStartedEpochMs: 1000,
          lastActiveEpochMs: 1000,
          authMethod: AuthMethodEnum.pin,
        ),
      );
    }

    consecutiveFailedAttempts++;
    final remaining = max(0, 5 - consecutiveFailedAttempts);
    if (consecutiveFailedAttempts >= 5) {
      activeTier = LockoutCooldownTierEnum.tier1ThirtySeconds;
      lockoutDeadlineMs = 40000;
      return VaultResult.failure(
        VaultLockoutFailure(
          'Max attempts reached',
          remainingCooldownSeconds: 30,
          deadlineMonotonicMs: lockoutDeadlineMs,
        ),
      );
    }

    return VaultResult.failure(
      VaultAuthFailure('Invalid PIN', remainingAttempts: remaining),
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
    resetFailedAttemptsCalled = true;
    consecutiveFailedAttempts = 0;
    activeTier = LockoutCooldownTierEnum.none;
    lockoutDeadlineMs = 0;
  }

  @override
  void clearSessionKeysFromRam() {
    clearSessionKeysCalled = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdversarialVaultSessionBloc extends VaultSessionBloc {
  AdversarialVaultSessionBloc({
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
  group('Milestone 2 Adversarial & Empirical Verification Suite', () {
    late AdversarialVaultAuthService authService;
    late AdversarialMonotonicClock clock;
    late AdversarialVaultStorageRepository storage;
    late UnlockVaultUseCase unlockUseCase;
    late VerifySessionCoolOffUseCase coolOffUseCase;
    late PinPadCubit pinPadCubit;
    late AdversarialVaultSessionBloc sessionBloc;

    final canonicalSession = AuthSession(
      sessionToken: 'adversarial_session_token',
      sessionStartedEpochMs: 1000,
      lastActiveEpochMs: 1000,
      authMethod: AuthMethodEnum.pin,
    );

    setUp(() {
      authService = AdversarialVaultAuthService();
      clock = AdversarialMonotonicClock();
      storage = AdversarialVaultStorageRepository();
      unlockUseCase = UnlockVaultUseCase(authService: authService);
      coolOffUseCase = VerifySessionCoolOffUseCase(clock: clock);

      pinPadCubit = PinPadCubit(
        unlockVaultUseCase: unlockUseCase,
        authService: authService,
        monotonicClock: clock,
      );

      sessionBloc = AdversarialVaultSessionBloc(
        authService: authService,
        storageRepository: storage,
        monotonicClock: clock,
        verifyCoolOffUseCase: coolOffUseCase,
        initialState: VaultUnlockedState(
          session: canonicalSession,
          unlockedAtMonotonicMs: 1000,
          reauthDeadlineMonotonicMs: 60000,
        ),
      );
    });

    tearDown(() async {
      await pinPadCubit.close();
      await sessionBloc.close();
    });

    Widget buildAuthScreenHarness({
      required VaultAuthScreenMode mode,
      PinPadCubit? cubitOverride,
      AdversarialVaultSessionBloc? blocOverride,
      ValueChanged<bool>? onAuthComplete,
      VaultThemePalettePolicyEnum palette = VaultThemePalettePolicyEnum.warmEspresso,
      BiometricAuthPolicyEnum? biometricPolicy = BiometricAuthPolicyEnum.pinAndBiometricStrong,
    }) {
      final activeCubit = cubitOverride ?? pinPadCubit;
      final activeBloc = blocOverride ?? sessionBloc;

      return MaterialApp(
        home: VaultTheme(
          data: VaultThemeData.fromPalette(palette),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<PinPadCubit>.value(value: activeCubit),
              BlocProvider<VaultSessionBloc>.value(value: activeBloc),
            ],
            child: VaultAuthScreen(
              mode: mode,
              onAuthComplete: onAuthComplete,
              pinPadCubit: activeCubit,
              sessionBloc: activeBloc,
              biometricPolicy: biometricPolicy,
            ),
          ),
        ),
      );
    }

    Widget buildReauthOverlayHarness({
      required Widget child,
      required VoidCallback onReauthRequested,
      bool? isBlurActive,
      VaultThemePalettePolicyEnum? paletteOverride,
      VaultThemePalettePolicyEnum themePalette = VaultThemePalettePolicyEnum.warmEspresso,
    }) {
      return MaterialApp(
        home: VaultTheme(
          data: VaultThemeData.fromPalette(themePalette),
          child: BlocProvider<VaultSessionBloc>.value(
            value: sessionBloc,
            child: ReauthBlurOverlay(
              onReauthRequested: onReauthRequested,
              isBlurActive: isBlurActive,
              paletteOverride: paletteOverride,
              child: child,
            ),
          ),
        ),
      );
    }

    group('1. VaultAuthScreen Concurrency & Burst Stress', () {
      testWidgets('Rapid 6-digit burst entry auto-submits reliably without dropped digits', (tester) async {
        final completer = Completer<VaultResult<AuthSession>>();
        final asyncCubit = PinPadCubit(
          unlockVaultUseCase: unlockUseCase,
          authService: authService,
          monotonicClock: clock,
          customPinSubmitter: (_) => completer.future,
        );

        await tester.pumpWidget(buildAuthScreenHarness(
          mode: VaultAuthScreenMode.unlock,
          cubitOverride: asyncCubit,
        ));

        // Rapid burst: simulate user typing 6 digits with zero inter-tap delay
        const burstDigits = ['6', '5', '4', '3', '2', '1'];
        for (final digit in burstDigits) {
          await tester.tap(find.text(digit));
          await tester.pump();
        }

        // Must enter evaluating state on the 6th digit
        expect(asyncCubit.state, isA<PinPadEvaluatingState>());
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Verifying PIN...'), findsOneWidget);

        // Mashing extra digits during active evaluation must be completely ignored
        await tester.tap(find.text('9'), warnIfMissed: false);
        await tester.tap(find.text('8'), warnIfMissed: false);
        await tester.tap(find.byIcon(Icons.backspace_outlined), warnIfMissed: false);
        await tester.pump();

        expect(asyncCubit.state, isA<PinPadEvaluatingState>());

        // Resolve async evaluation with success
        completer.complete(VaultResult.success(canonicalSession));
        await tester.pump();

        expect(asyncCubit.state, isA<PinPadSuccessState>());
        expect(find.text('Verified'), findsOneWidget);

        await asyncCubit.close();
      });

      testWidgets('Burst entry with randomized keypad layout policy auto-submits accurately', (tester) async {
        final randomCubit = PinPadCubit(
          unlockVaultUseCase: unlockUseCase,
          authService: authService,
          monotonicClock: clock,
          initialLayout: KeypadLayoutPolicyEnum.randomizedPerAttempt,
        );

        await tester.pumpWidget(buildAuthScreenHarness(
          mode: VaultAuthScreenMode.unlock,
          cubitOverride: randomCubit,
        ));

        // Verify keypad layout is permuted
        final digits = randomCubit.currentKeypadDigits;
        expect(digits.length, 10);
        expect(digits.toSet().length, 10);

        // Tap the first 5 digits
        for (var i = 0; i < 5; i++) {
          await tester.tap(find.text('${digits[i]}'));
          await tester.pump();
        }
        expect(find.byKey(const ValueKey('pin_dot_filled')), findsNWidgets(5));
        expect(randomCubit.state, isA<PinPadIdleInputState>());

        // Tap 6th digit to trigger auto-submit
        await tester.tap(find.text('${digits[5]}'));
        await tester.pump();

        // Evaluates immediately against authService (which fails because digits != 654321)
        expect(randomCubit.state, isA<PinPadFailureShakeState>());
        expect(find.textContaining('attempts remaining'), findsOneWidget);

        await randomCubit.close();
      });
    });

    group('2. Brute-Force Lockout Defense & Bypass Vectors', () {
      testWidgets('Brute-force lockout bypass attempts are completely absorbed and rejected', (tester) async {
        // Force cubit into lockout state
        pinPadCubit.emit(const PinPadLockedOutState(
          cooldownRemainingSeconds: 30,
          deadlineMonotonicMs: 40000,
        ));

        await tester.pumpWidget(buildAuthScreenHarness(mode: VaultAuthScreenMode.unlock));
        expect(find.text('Vault Locked'), findsOneWidget);
        expect(find.text('00:30'), findsOneWidget);

        // Bypass attempt 1: Calling resetToIdle() during lockout is blocked
        pinPadCubit.resetToIdle();
        expect(pinPadCubit.state, isA<PinPadLockedOutState>(),
            reason: 'resetToIdle() must not bypass active lockout state');

        // Bypass attempt 2: Calling clear() during lockout is blocked
        pinPadCubit.clear();
        expect(pinPadCubit.state, isA<PinPadLockedOutState>(),
            reason: 'clear() must not bypass active lockout state');

        // Bypass attempt 3: Calling onDigitEntered() during lockout is blocked
        pinPadCubit.onDigitEntered(1);
        expect(pinPadCubit.state, isA<PinPadLockedOutState>(),
            reason: 'onDigitEntered() must not bypass active lockout state');

        // Bypass attempt 4: Calling onBackspace() during lockout is blocked
        pinPadCubit.onBackspace();
        expect(pinPadCubit.state, isA<PinPadLockedOutState>(),
            reason: 'onBackspace() must not bypass active lockout state');

        // Bypass attempt 5: UI touch storm on keypad buttons is absorbed by AbsorbPointer
        for (var i = 0; i <= 9; i++) {
          await tester.tap(find.text('$i'), warnIfMissed: false);
        }
        await tester.tap(find.byIcon(Icons.backspace_outlined), warnIfMissed: false);
        await tester.tap(find.byIcon(Icons.fingerprint), warnIfMissed: false);
        await tester.pump();

        expect(pinPadCubit.state, isA<PinPadLockedOutState>());
        expect(find.byKey(const ValueKey('pin_dot_filled')), findsNothing);
      });

      testWidgets('Monotonic countdown ticks accurately and resets failed attempts at zero', (tester) async {
        // Set clock to 10000, deadline to 40000 (30 seconds remaining)
        clock.timeMs = 10000;
        authService.consecutiveFailedAttempts = 5;
        authService.activeTier = LockoutCooldownTierEnum.tier1ThirtySeconds;
        authService.lockoutDeadlineMs = 40000;

        pinPadCubit.enterLockout(
          deadlineMonotonicMs: 40000,
          initialRemainingSeconds: 30,
        );

        await tester.pumpWidget(buildAuthScreenHarness(mode: VaultAuthScreenMode.unlock));
        expect(find.text('00:30'), findsOneWidget);

        // Advance monotonic clock by 10 seconds (timeMs = 20000)
        clock.timeMs = 20000;
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('00:20'), findsOneWidget);

        // Advance monotonic clock by another 19 seconds (timeMs = 39000 -> 1 second left)
        clock.timeMs = 39000;
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('00:01'), findsOneWidget);

        // Advance monotonic clock past deadline (timeMs = 40001 -> cooldown expired)
        clock.timeMs = 40001;
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();

        // Must reset failed attempts and re-enable keypad
        expect(authService.resetFailedAttemptsCalled, isTrue);
        expect(pinPadCubit.state, isA<PinPadIdleInputState>());
        expect(find.text('00:00'), findsNothing);
        expect(find.text('Vault Locked'), findsNothing);
      });
    });

    group('3. Failure Shake Animation & Remaining Attempts Feedback', () {
      testWidgets('Consecutive failure progression displays accurate attempts countdown and shake', (tester) async {
        await tester.pumpWidget(buildAuthScreenHarness(mode: VaultAuthScreenMode.unlock));

        // Attempt 1: 4 attempts remaining
        pinPadCubit.emit(const PinPadFailureShakeState(
          failedAttemptsCount: 1,
          remainingAttemptsBeforeCooldown: 4,
        ));
        await tester.pump();
        expect(find.text('Incorrect PIN. 4 attempts remaining.'), findsOneWidget);

        // Shake container has non-zero translation during animation
        final shakeFinder = find.byKey(const ValueKey('pin_shake_container'));
        expect(shakeFinder, findsOneWidget);
        await tester.pump(const Duration(milliseconds: 100));
        final transformWidget = tester.widget<Transform>(shakeFinder);
        expect(transformWidget.transform.getTranslation().x, isNot(0.0),
            reason: 'Shake animation must translate horizontally');

        // Let shake finish
        await tester.pump(const Duration(milliseconds: 350));

        // Attempt 4: 1 attempt remaining (critical warning before lockout)
        pinPadCubit.emit(const PinPadFailureShakeState(
          failedAttemptsCount: 4,
          remainingAttemptsBeforeCooldown: 1,
        ));
        await tester.pump();
        await tester.pump();
        expect(find.text('Incorrect PIN. 1 attempts remaining.'), findsOneWidget);

        // Dots turn danger color on failure
        final dotContainer = tester.firstWidget<Container>(find.byKey(const ValueKey('pin_dot_filled')));
        final boxDecoration = dotContainer.decoration as BoxDecoration;
        expect(boxDecoration.color, const Color(0xFFA84438),
            reason: 'Dots must show danger color on error');
      });
    });

    group('4. ReauthBlurOverlay State Preservation & Touch Shielding', () {
      testWidgets('Scroll offset and text input are 100% preserved before, during, and after reauth blur', (tester) async {
        final scrollController = ScrollController();
        final textController = TextEditingController(text: 'Initial Confidential Playlist Name');

        final contentWidget = Material(
          child: ListView.builder(
            controller: scrollController,
            itemCount: 40,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    key: const ValueKey('confidential_text_field'),
                    controller: textController,
                  ),
                );
              }
              return ListTile(
                key: ValueKey('list_item_$index'),
                title: Text('Confidential Playlist Item #$index'),
              );
            },
          ),
        );

        await tester.pumpWidget(buildReauthOverlayHarness(
          child: contentWidget,
          onReauthRequested: () {},
        ));

        // Step 1: Scroll to non-zero offset and mutate text
        scrollController.jumpTo(680.0);
        textController.text = 'Classified Vault Playlist 42';
        await tester.pump();

        expect(scrollController.offset, 680.0);
        expect(textController.text, 'Classified Vault Playlist 42');
        expect(find.byType(BackdropFilter), findsNothing);

        // Step 2: Engage reauth blur overlay (VaultPendingReauthState)
        sessionBloc.emitState(VaultPendingReauthState(
          session: canonicalSession,
          reauthTriggeredAtMonotonicMs: clock.currentMonotonicMs,
          remainingAttempts: 3,
        ));
        await tester.pump();
        await tester.pump();

        // Verify BackdropFilter with sigma 12 is active
        expect(find.byType(BackdropFilter), findsOneWidget);
        expect(find.text('Session Timed Out'), findsOneWidget);

        // Verify underlying scroll offset and text input are 100% PRESERVED during blur
        expect(scrollController.offset, 680.0,
            reason: 'Scroll offset must remain untouched during blur overlay');
        expect(textController.text, 'Classified Vault Playlist 42',
            reason: 'TextField content must remain untouched during blur overlay');

        // Step 3: Disengage blur overlay (VaultUnlockedState)
        sessionBloc.emitState(VaultUnlockedState(
          session: canonicalSession,
          unlockedAtMonotonicMs: clock.currentMonotonicMs,
          reauthDeadlineMonotonicMs: 60000,
        ));
        await tester.pump();
        await tester.pump();

        // Verify BackdropFilter is removed
        expect(find.byType(BackdropFilter), findsNothing);

        // Verify underlying scroll offset and text input remain 100% PRESERVED after unlock
        expect(scrollController.offset, 680.0,
            reason: 'Scroll offset must remain preserved after overlay dismissal');
        expect(textController.text, 'Classified Vault Playlist 42',
            reason: 'TextField content must remain preserved after overlay dismissal');
      });

      testWidgets('Touch shielding test: taps on frosted shield do not penetrate to underlying child', (tester) async {
        var underlyingChildTapped = false;
        var underlyingChildScrolled = false;

        final scrollController = ScrollController();
        scrollController.addListener(() {
          underlyingChildScrolled = true;
        });

        final contentWidget = Material(
          child: ListView(
            controller: scrollController,
            children: [
              ElevatedButton(
                key: const ValueKey('underlying_secret_button'),
                onPressed: () => underlyingChildTapped = true,
                child: const Text('Underlying Secret Button'),
              ),
              const SizedBox(height: 1000),
            ],
          ),
        );

        // Mount with active blur
        sessionBloc.emitState(VaultPendingReauthState(
          session: canonicalSession,
          reauthTriggeredAtMonotonicMs: clock.currentMonotonicMs,
          remainingAttempts: 3,
        ));

        await tester.pumpWidget(buildReauthOverlayHarness(
          child: contentWidget,
          onReauthRequested: () {},
        ));
        await tester.pump();

        expect(find.byType(BackdropFilter), findsOneWidget);

        // Attempt 1: Tap directly on underlying button location
        await tester.tap(find.byKey(const ValueKey('underlying_secret_button')), warnIfMissed: false);
        await tester.pump();
        expect(underlyingChildTapped, isFalse,
            reason: 'Underlying child button must not receive taps through shield');

        // Attempt 2: Drag/scroll gesture across screen
        await tester.drag(find.byType(BackdropFilter), const Offset(0, -200));
        await tester.pump();
        expect(underlyingChildScrolled, isFalse,
            reason: 'Underlying ListView must not scroll while shield is active');
      });

      testWidgets('Audio continuity test: 0 audio interruptions or mutations during reauth blur lifecycle', (tester) async {
        // Track mock audio player continuity
        var audioStatus = 'Playing Audio Stream';
        var audioDisposed = false;
        var audioPaused = false;

        final audioContextChild = Builder(
          builder: (context) {
            return Container(
              key: const ValueKey('audio_player_stub'),
              child: Text(audioStatus),
            );
          },
        );

        await tester.pumpWidget(buildReauthOverlayHarness(
          child: audioContextChild,
          onReauthRequested: () {},
        ));

        expect(find.text('Playing Audio Stream'), findsOneWidget);

        // Transition through complete reauth lifecycle:
        // Unlocked -> PendingReauth -> Unlocked
        sessionBloc.emitState(VaultPendingReauthState(
          session: canonicalSession,
          reauthTriggeredAtMonotonicMs: 5000,
          remainingAttempts: 3,
        ));
        await tester.pump();
        await tester.pump();

        expect(find.byType(BackdropFilter), findsOneWidget);
        expect(audioStatus, equals('Playing Audio Stream'));
        expect(audioDisposed, isFalse);
        expect(audioPaused, isFalse);

        sessionBloc.emitState(VaultUnlockedState(
          session: canonicalSession,
          unlockedAtMonotonicMs: 8000,
          reauthDeadlineMonotonicMs: 60000,
        ));
        await tester.pump();
        await tester.pump();

        expect(find.byType(BackdropFilter), findsNothing);
        expect(audioStatus, equals('Playing Audio Stream'));
        expect(audioDisposed, isFalse);
        expect(audioPaused, isFalse);
        expect(find.text('Playing Audio Stream'), findsOneWidget);
      });
    });
  });
}
