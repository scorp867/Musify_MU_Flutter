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

  @override
  Stream<VaultSessionState> get sessionStateStream => sessionController.stream;

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
  group('ReauthBlurOverlay Widget Tests', () {
    late FakeVaultAuthService fakeAuthService;
    late FakeMonotonicClock fakeClock;
    late FakeVaultStorageRepository fakeStorage;
    late VerifySessionCoolOffUseCase verifyCoolOffUseCase;
    late TestVaultSessionBloc vaultSessionBloc;

    final testSession = AuthSession(
      sessionToken: 'test_token',
      sessionStartedEpochMs: 1000,
      lastActiveEpochMs: 1000,
      authMethod: AuthMethodEnum.pin,
    );

    setUp(() {
      fakeAuthService = FakeVaultAuthService();
      fakeClock = FakeMonotonicClock();
      fakeStorage = FakeVaultStorageRepository();
      verifyCoolOffUseCase = VerifySessionCoolOffUseCase(
        clock: fakeClock,
      );

      vaultSessionBloc = TestVaultSessionBloc(
        authService: fakeAuthService,
        storageRepository: fakeStorage,
        monotonicClock: fakeClock,
        verifyCoolOffUseCase: verifyCoolOffUseCase,
        initialState: VaultUnlockedState(
          session: testSession,
          unlockedAtMonotonicMs: 1000,
          reauthDeadlineMonotonicMs: 60000,
        ),
      );
    });

    tearDown(() async {
      await vaultSessionBloc.close();
    });

    Widget buildTestHarness({
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
            value: vaultSessionBloc,
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

    testWidgets('When session is unlocked, blur is NOT mounted and child is interactive', (tester) async {
      var childTapped = false;
      await tester.pumpWidget(buildTestHarness(
        child: ElevatedButton(
          onPressed: () => childTapped = true,
          child: const Text('Play Track'),
        ),
        onReauthRequested: () {},
      ));

      expect(find.byType(BackdropFilter), findsNothing);
      await tester.tap(find.text('Play Track'));
      await tester.pump();
      expect(childTapped, isTrue);
    });

    testWidgets('When session is pendingReauth, sigma 12 BackdropFilter is mounted', (tester) async {
      vaultSessionBloc.emitState(VaultPendingReauthState(
        session: testSession,
        reauthTriggeredAtMonotonicMs: 5000,
        remainingAttempts: 3,
      ));

      await tester.pumpWidget(buildTestHarness(
        child: const Text('Private Vault Dashboard'),
        onReauthRequested: () {},
      ));
      await tester.pump();

      expect(find.byType(BackdropFilter), findsOneWidget);
      final backdrop = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
      final filter = backdrop.filter;
      expect(filter.toString(), contains('12.0'));
      expect(find.text('Session Timed Out'), findsOneWidget);
      expect(find.textContaining('—'), findsNothing);
    });

    testWidgets('Touch event shielding: child touches are absorbed when blurred', (tester) async {
      var childTapped = false;
      vaultSessionBloc.emitState(VaultPendingReauthState(
        session: testSession,
        reauthTriggeredAtMonotonicMs: 5000,
        remainingAttempts: 3,
      ));

      await tester.pumpWidget(buildTestHarness(
        child: ElevatedButton(
          onPressed: () => childTapped = true,
          child: const Text('Private Track'),
        ),
        onReauthRequested: () {},
      ));
      await tester.pump();

      final absorbPointer = tester.widget<AbsorbPointer>(
        find.byKey(const ValueKey('reauth_absorb_pointer')),
      );
      expect(absorbPointer.absorbing, isTrue, reason: 'Touches must be absorbed by AbsorbPointer');

      await tester.tap(find.text('Private Track'), warnIfMissed: false);
      await tester.pump();
      expect(childTapped, isFalse);
    });

    testWidgets('Re-auth action button triggers onReauthRequested callback', (tester) async {
      var reauthTriggered = false;
      vaultSessionBloc.emitState(VaultPendingReauthState(
        session: testSession,
        reauthTriggeredAtMonotonicMs: 5000,
        remainingAttempts: 3,
      ));

      await tester.pumpWidget(buildTestHarness(
        child: const Text('Dashboard'),
        onReauthRequested: () => reauthTriggered = true,
      ));
      await tester.pump();

      await tester.tap(find.text('Re-authenticate'));
      await tester.pump();
      expect(reauthTriggered, isTrue);
    });

    testWidgets('Non-destruction of underlying widget state across re-auth lifecycle', (tester) async {
      final scrollController = ScrollController();
      final textController = TextEditingController(text: 'Initial Note');

      final testChild = Material(
        child: ListView(
          controller: scrollController,
          children: [
            SizedBox(
              height: 600,
              child: TextField(controller: textController),
            ),
            const SizedBox(height: 600, child: Text('Bottom Item')),
          ],
        ),
      );

      await tester.pumpWidget(buildTestHarness(
        child: testChild,
        onReauthRequested: () {},
      ));

      scrollController.jumpTo(250.0);
      textController.text = 'Modified Secret Note';
      await tester.pump();
      expect(scrollController.offset, 250.0);

      // Transition to pendingReauth (Overlay shown)
      vaultSessionBloc.emitState(VaultPendingReauthState(
        session: testSession,
        reauthTriggeredAtMonotonicMs: 5000,
        remainingAttempts: 3,
      ));
      await tester.pump();
      await tester.pump();
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(scrollController.offset, 250.0,
          reason: 'Scroll offset must be preserved without jumping to top');
      expect(textController.text, 'Modified Secret Note',
          reason: 'Form inputs must not be wiped');

      // Transition back to unlocked (Overlay dismissed)
      vaultSessionBloc.emitState(VaultUnlockedState(
        session: testSession,
        unlockedAtMonotonicMs: 2000,
        reauthDeadlineMonotonicMs: 300000,
      ));
      await tester.pump();
      await tester.pump();
      expect(find.byType(BackdropFilter), findsNothing);
      expect(scrollController.offset, 250.0,
          reason: 'Scroll offset must be preserved after returning to unlocked');
      expect(textController.text, 'Modified Secret Note',
          reason: 'Form inputs must remain preserved after re-auth');
    });

    testWidgets('Design system invariants: 8px radius, 1px border, zero emojis/em dashes', (tester) async {
      vaultSessionBloc.emitState(VaultPendingReauthState(
        session: testSession,
        reauthTriggeredAtMonotonicMs: 5000,
        remainingAttempts: 3,
      ));

      await tester.pumpWidget(buildTestHarness(
        child: const Text('Content'),
        onReauthRequested: () {},
      ));
      await tester.pump();

      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(8.0));
      expect(shape.side.width, 1.0);
      expect(find.textContaining('—'), findsNothing);
    });

    testWidgets('Explicit isBlurActive: true mounts BackdropFilter directly', (tester) async {
      await tester.pumpWidget(buildTestHarness(
        isBlurActive: true,
        child: const Text('Direct Blur Child'),
        onReauthRequested: () {},
      ));

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('Explicit isBlurActive: false hides BackdropFilter directly', (tester) async {
      await tester.pumpWidget(buildTestHarness(
        isBlurActive: false,
        child: const Text('Direct Unblur Child'),
        onReauthRequested: () {},
      ));

      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('Palette switching to forestNoir renders forest palette colors', (tester) async {
      await tester.pumpWidget(buildTestHarness(
        isBlurActive: true,
        paletteOverride: VaultThemePalettePolicyEnum.forestNoir,
        child: const Text('Forest Content'),
        onReauthRequested: () {},
      ));

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, const Color(0xFF3E5A3F));
    });
  });
}
