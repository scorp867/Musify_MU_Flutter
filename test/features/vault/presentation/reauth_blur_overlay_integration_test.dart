import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';
import 'package:musify_mu/features/vault/presentation/widgets/reauth_blur_overlay.dart';

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
  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      VaultResult.success(const VaultConfig.constant());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> controller =
      StreamController<VaultSessionState>.broadcast();
  @override
  Stream<VaultSessionState> get sessionStateStream => controller.stream;
  @override
  void clearSessionKeysFromRam() {}
  @override
  Future<void> resetFailedAttempts() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  group('ReauthBlurOverlay Integration Tests', () {
    late FakeVaultAuthService fakeAuthService;
    late FakeMonotonicClock fakeClock;
    late FakeVaultStorageRepository fakeStorage;
    late VerifySessionCoolOffUseCase verifyCoolOff;
    late TestVaultSessionBloc sessionBloc;

    final testSession = AuthSession(
      sessionToken: 'test_token',
      sessionStartedEpochMs: 1000,
      lastActiveEpochMs: 1000,
      authMethod: AuthMethodEnum.pin,
    );

    final unlockedState = VaultUnlockedState(
      session: testSession,
      unlockedAtMonotonicMs: 1000,
      reauthDeadlineMonotonicMs: 60000,
    );

    final pendingReauthState = VaultPendingReauthState(
      session: testSession,
      reauthTriggeredAtMonotonicMs: 5000,
      remainingAttempts: 3,
    );

    setUp(() {
      fakeAuthService = FakeVaultAuthService();
      fakeClock = FakeMonotonicClock();
      fakeStorage = FakeVaultStorageRepository();
      verifyCoolOff = VerifySessionCoolOffUseCase(clock: fakeClock);
      sessionBloc = TestVaultSessionBloc(
        authService: fakeAuthService,
        storageRepository: fakeStorage,
        monotonicClock: fakeClock,
        verifyCoolOffUseCase: verifyCoolOff,
        initialState: unlockedState,
      );
    });

    tearDown(() {
      sessionBloc.close();
      fakeAuthService.controller.close();
    });

    testWidgets(
      'Invariant 1: Scroll Offset Persistence across blur engage and release',
      (WidgetTester tester) async {
        final scrollController = ScrollController();
        int reauthCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<VaultSessionBloc>.value(
              value: sessionBloc,
              child: Scaffold(
                body: ReauthBlurOverlay(
                  onReauthRequested: () => reauthCount++,
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 100,
                    itemBuilder: (context, index) => SizedBox(
                      height: 50.0,
                      child: Text('Playlist Item $index'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Scroll down to 350px
        scrollController.jumpTo(350.0);
        await tester.pumpAndSettle();
        expect(scrollController.offset, 350.0);

        // Transition session to VaultPendingReauthState (blur engages)
        sessionBloc.emitState(pendingReauthState);
        await tester.pumpAndSettle();

        // Verify frosted blur mounted
        expect(find.byType(BackdropFilter), findsOneWidget);
        expect(find.text('Session Timed Out'), findsOneWidget);

        // Invariant: underlying scroll offset remains strictly 350.0
        expect(scrollController.offset, 350.0);

        // Transition back to VaultUnlockedState (blur releases)
        sessionBloc.emitState(unlockedState);
        await tester.pumpAndSettle();

        // Verify frosted blur unmounted
        expect(find.byType(BackdropFilter), findsNothing);
        expect(find.text('Session Timed Out'), findsNothing);

        // Invariant: scroll offset is still 350.0
        expect(scrollController.offset, 350.0);
        expect(reauthCount, 0);

        scrollController.dispose();
      },
    );

    testWidgets(
      'Invariant 2: TextEditingController persistence across blur engage and release',
      (WidgetTester tester) async {
        final textController = TextEditingController(text: 'secret midnight beats');
        int reauthCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<VaultSessionBloc>.value(
              value: sessionBloc,
              child: Scaffold(
                body: ReauthBlurOverlay(
                  onReauthRequested: () => reauthCount++,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: textController,
                      decoration: const InputDecoration(hintText: 'Search tracks'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('secret midnight beats'), findsOneWidget);

        // Transition to VaultPendingReauthState
        sessionBloc.emitState(pendingReauthState);
        await tester.pumpAndSettle();

        // Verify blur mounted
        expect(find.text('Session Timed Out'), findsOneWidget);

        // Invariant: text controller still contains exact input
        expect(textController.text, 'secret midnight beats');

        // Transition back to VaultUnlockedState
        sessionBloc.emitState(unlockedState);
        await tester.pumpAndSettle();

        expect(find.text('Session Timed Out'), findsNothing);
        expect(textController.text, 'secret midnight beats');

        textController.dispose();
      },
    );

    testWidgets(
      'Invariant 3: Pointer event shielding prevents touches reaching child during blur',
      (WidgetTester tester) async {
        int underlyingButtonTaps = 0;
        int reauthCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<VaultSessionBloc>.value(
              value: sessionBloc,
              child: Scaffold(
                body: ReauthBlurOverlay(
                  onReauthRequested: () => reauthCount++,
                  child: Center(
                    child: ElevatedButton(
                      key: const ValueKey('underlying_action_button'),
                      onPressed: () => underlyingButtonTaps++,
                      child: const Text('Play Track'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. When Unlocked: button is interactive
        await tester.tap(find.byKey(const ValueKey('underlying_action_button')));
        await tester.pumpAndSettle();
        expect(underlyingButtonTaps, 1);

        // 2. Transition to VaultPendingReauthState (blur engages)
        sessionBloc.emitState(pendingReauthState);
        await tester.pumpAndSettle();

        final absorbPointer = tester.widget<AbsorbPointer>(
          find.byKey(const ValueKey('reauth_absorb_pointer')),
        );
        expect(absorbPointer.absorbing, isTrue);

        // Tap the area of the underlying button through the blur
        await tester.tap(
          find.byKey(const ValueKey('underlying_action_button')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Invariant: underlying button was shielded; tap count did NOT increment
        expect(underlyingButtonTaps, 1);

        // 3. Transition back to Unlocked
        sessionBloc.emitState(unlockedState);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('underlying_action_button')));
        await tester.pumpAndSettle();
        expect(underlyingButtonTaps, 2);
      },
    );

    testWidgets(
      'Invariant 4: Tapping Re-authenticate triggers onReauthRequested callback',
      (WidgetTester tester) async {
        int reauthRequestedCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<VaultSessionBloc>.value(
              value: sessionBloc,
              child: Scaffold(
                body: ReauthBlurOverlay(
                  onReauthRequested: () => reauthRequestedCount++,
                  child: const Center(child: Text('Underlying Vault Content')),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        sessionBloc.emitState(pendingReauthState);
        await tester.pumpAndSettle();

        final reauthButton = find.text('Re-authenticate');
        expect(reauthButton, findsOneWidget);

        await tester.tap(reauthButton);
        await tester.pumpAndSettle();

        expect(reauthRequestedCount, 1);
      },
    );

    testWidgets(
      'Invariant 5: Design tokens adhere to 8px geometric radius, 1px borders, zero purple hues',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<VaultSessionBloc>.value(
              value: sessionBloc,
              child: Scaffold(
                body: ReauthBlurOverlay(
                  paletteOverride: VaultThemePalettePolicyEnum.warmEspresso,
                  onReauthRequested: () {},
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        sessionBloc.emitState(pendingReauthState);
        await tester.pumpAndSettle();

        // 1. Verify Card shape has 8px geometric radius and 1px border
        final card = tester.widget<Card>(find.byType(Card));
        final shape = card.shape! as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(8.0));
        expect(shape.side.width, VaultTheme.borderWidth);

        // 2. Verify warm espresso palette surface and border
        final theme = VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.warmEspresso);
        expect(card.color, theme.surface);
        expect(shape.side.color, theme.border);

        // 3. Strict guardrail: zero purple/violet hues (HSV hue between 260 and 310)
        final surfaceHsl = HSLColor.fromColor(card.color!);
        final borderHsl = HSLColor.fromColor(shape.side.color);
        expect(surfaceHsl.hue < 260 || surfaceHsl.hue > 310, isTrue);
        expect(borderHsl.hue < 260 || borderHsl.hue > 310, isTrue);

        // 4. Verify no pill buttons (no StadiumBorder)
        expect(find.byType(StadiumBorder), findsNothing);
      },
    );
  });
}
