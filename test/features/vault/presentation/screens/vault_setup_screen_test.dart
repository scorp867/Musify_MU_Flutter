import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/lockout_cooldown_info.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_setup_screen.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';

class _FakeMonotonicClock implements IMonotonicClock {
  int timeMs = 10000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class _FakeVaultStorageRepository implements IVaultStorageRepository {
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

class _FakeSetupAuthService implements IVaultAuthService {
  String? enrolledPin;
  GestureTemplate? enrolledTemplate;
  bool shouldFailEnroll = false;

  @override
  Future<VaultResult<void>> enrollInitialCredentials({
    required String pin,
    required GestureTemplate template,
  }) async {
    if (shouldFailEnroll) {
      return const VaultResult.failure(
        VaultStorageFailure('Simulated provisioning failure'),
      );
    }
    enrolledPin = pin;
    enrolledTemplate = template;
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<AuthSession>> authenticateWithPin({
    required String pin,
  }) async {
    if (enrolledPin != null && pin == enrolledPin) {
      return VaultResult.success(
        AuthSession(
          sessionToken: 'setup_session',
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
  Future<LockoutCooldownInfo> getLockoutStatus() async {
    return LockoutCooldownInfo(
      tier: LockoutCooldownTierEnum.none,
      remainingCooldownSeconds: 0,
      deadlineMonotonicMs: 0,
      consecutiveFailedAttempts: 0,
    );
  }

  @override
  Future<void> recordFailedAttempt() async {}

  @override
  Future<void> resetFailedAttempts() async {}

  @override
  void clearSessionKeysFromRam() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('VaultSetupScreen Widget Tests', () {
    late _FakeSetupAuthService fakeAuthService;
    late _FakeMonotonicClock fakeClock;
    late _FakeVaultStorageRepository fakeStorage;
    late UnlockVaultUseCase unlockVaultUseCase;
    late VerifySessionCoolOffUseCase verifyCoolOffUseCase;
    late VaultSessionBloc vaultSessionBloc;

    setUp(() {
      fakeAuthService = _FakeSetupAuthService();
      fakeClock = _FakeMonotonicClock();
      fakeStorage = _FakeVaultStorageRepository();
      unlockVaultUseCase = UnlockVaultUseCase(authService: fakeAuthService);
      verifyCoolOffUseCase = VerifySessionCoolOffUseCase(clock: fakeClock);

      vaultSessionBloc = VaultSessionBloc(
        authService: fakeAuthService,
        storageRepository: fakeStorage,
        monotonicClock: fakeClock,
        verifyCoolOffUseCase: verifyCoolOffUseCase,
      );
    });

    tearDown(() async {
      await vaultSessionBloc.close();
    });

    Widget buildHarness({
      ValueChanged<bool>? onSetupComplete,
      VaultThemePalettePolicyEnum palette =
          VaultThemePalettePolicyEnum.warmEspresso,
    }) {
      return MaterialApp(
        home: VaultTheme(
          data: VaultThemeData.fromPalette(palette),
          child: BlocProvider<VaultSessionBloc>.value(
            value: vaultSessionBloc,
            child: VaultSetupScreen(
              authService: fakeAuthService,
              monotonicClock: fakeClock,
              unlockVaultUseCase: unlockVaultUseCase,
              onSetupComplete: onSetupComplete,
            ),
          ),
        ),
      );
    }

    Future<void> enterDigits(WidgetTester tester, String digits) async {
      for (final char in digits.split('')) {
        await tester.tap(find.text(char));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    testWidgets('Phase 1 renders STEP 1 OF 2, Create PIN, 6 dots, and keypad', (
      tester,
    ) async {
      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      expect(find.text('STEP 1 OF 2'), findsOneWidget);
      expect(find.text('Create PIN'), findsOneWidget);
      expect(
        find.text('Choose a 6-digit PIN to protect your vault'),
        findsOneWidget,
      );

      for (var i = 0; i < 6; i++) {
        expect(find.byKey(ValueKey('setup_pin_dot_slot_$i')), findsOneWidget);
      }
      for (var i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets(
      'Entering 6 digits advances to STEP 2 OF 2 and Back returns to STEP 1 OF 2',
      (tester) async {
        bool? canceledResult;
        await tester.pumpWidget(
          buildHarness(onSetupComplete: (ok) => canceledResult = ok),
        );
        await tester.pumpAndSettle();

        await enterDigits(tester, '123456');

        expect(find.text('STEP 2 OF 2'), findsOneWidget);
        expect(find.text('Confirm PIN'), findsOneWidget);
        expect(
          find.text('Re-enter your 6-digit PIN to confirm'),
          findsOneWidget,
        );
        expect(canceledResult, isNull);

        // Back button on Confirm PIN steps back to Create PIN cleanly
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        expect(find.text('STEP 1 OF 2'), findsOneWidget);
        expect(find.text('Create PIN'), findsOneWidget);
        expect(canceledResult, isNull);

        // Back button on Create PIN cancels setup
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pump();

        expect(canceledResult, isFalse);
      },
    );

    testWidgets(
      'Mismatch on confirmation PIN shows calm error banner and resets to Step 1',
      (tester) async {
        await tester.pumpWidget(buildHarness());
        await tester.pumpAndSettle();

        // Phase 1: enter 123456
        await enterDigits(tester, '123456');
        expect(find.text('STEP 2 OF 2'), findsOneWidget);

        // Phase 2: enter mismatched 654321 and inspect mid-shake banner before reset
        for (final char in ['6', '5', '4', '3', '2']) {
          await tester.tap(find.text(char));
          await tester.pump();
        }
        await tester.tap(find.text('1'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('PINs do not match. Start over.'), findsOneWidget);

        await tester.pumpAndSettle();

        expect(find.text('STEP 1 OF 2'), findsOneWidget);
        expect(find.text('Create PIN'), findsOneWidget);
        expect(fakeAuthService.enrolledPin, isNull);
      },
    );

    testWidgets(
      'Matching confirmation PIN enrolls credentials, updates session, and invokes onSetupComplete(true)',
      (tester) async {
        bool? setupSucceeded;
        await tester.pumpWidget(
          buildHarness(onSetupComplete: (ok) => setupSucceeded = ok),
        );
        await tester.pumpAndSettle();

        await enterDigits(tester, '246810');
        expect(find.text('STEP 2 OF 2'), findsOneWidget);

        await enterDigits(tester, '246810');

        expect(fakeAuthService.enrolledPin, equals('246810'));
        expect(fakeAuthService.enrolledTemplate, isNotNull);
        expect(find.text('Vault Ready'), findsOneWidget);
        expect(setupSucceeded, isTrue);
        expect(vaultSessionBloc.state, isA<VaultUnlockedState>());
      },
    );

    testWidgets(
      'Design system compliance across warmEspresso & forestNoir: zero purple, zero pills, 8dp geometric radii, zero emojis/em dashes',
      (tester) async {
        for (final palette in [
          VaultThemePalettePolicyEnum.warmEspresso,
          VaultThemePalettePolicyEnum.forestNoir,
        ]) {
          await tester.pumpWidget(buildHarness(palette: palette));
          await tester.pumpAndSettle();

          final textWidgets = tester.widgetList<Text>(find.byType(Text));
          for (final text in textWidgets) {
            final content = text.data ?? text.textSpan?.toPlainText() ?? '';
            expect(
              content.contains('\u2014'),
              isFalse,
              reason: 'Em dash found in: "$content"',
            );
            final hasEmoji = RegExp(
              r'[\u{1F300}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
              unicode: true,
            ).hasMatch(content);
            expect(
              hasEmoji,
              isFalse,
              reason: 'Emoji found in: "$content"',
            );
          }

          expect(find.byType(StadiumBorder), findsNothing);

          final inkWells = tester.widgetList<InkWell>(find.byType(InkWell));
          for (final inkWell in inkWells) {
            if (inkWell.borderRadius case final radius?) {
              expect(
                radius,
                BorderRadius.circular(8.0),
                reason: 'Keypad tile must use 8px geometric radius',
              );
            }
          }

          // Verify rendered colored containers do not use purple hues [260, 310]
          final containers = tester.widgetList<Container>(find.byType(Container));
          for (final container in containers) {
            if (container.decoration case final BoxDecoration box) {
              if (box.color case final color?) {
                if (color.a > 0) {
                  final hsv = HSVColor.fromColor(color);
                  if (hsv.saturation > 0.25 && hsv.value > 0.2) {
                    expect(
                      hsv.hue >= 260 && hsv.hue <= 310,
                      isFalse,
                      reason: 'Purple hue forbidden: $color',
                    );
                  }
                }
              }
            }
          }
        }
      },
    );
  });
}
