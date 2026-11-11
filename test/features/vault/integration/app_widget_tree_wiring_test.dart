import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/app/app.dart';
import 'package:musify_mu/app/routes/vault_routes.dart';
import 'package:musify_mu/features/vault/application/gesture/gesture_engine_cubit.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';

import 'integration_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestVaultHarness harness;

  setUp(() async {
    harness = TestVaultHarness();
    await harness.setup();
  });

  tearDown(() async {
    await harness.tearDown();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MusifyApp(
        createAuthBloc: () => FakeAuthBloc(),
        createLocalMusicBloc: () => FakeLocalMusicBloc(),
      ),
    );
    await tester.pump();
  }

  void triggerLifecycle(WidgetTester tester, AppLifecycleState state) {
    final observer =
        tester.state(find.byType(MusifyApp)) as WidgetsBindingObserver;
    observer.didChangeAppLifecycleState(state);
  }

  group('MusifyApp Root Widget Tree Wiring Tests', () {
    testWidgets(
        'MusifyApp provides all 4 Harel FSM region BLoCs and Sub-Services to ancestor context',
        (tester) async {
      await pumpApp(tester);

      // Find an element inside MaterialApp
      final materialAppFinder = find.byType(MaterialApp);
      expect(materialAppFinder, findsOneWidget);
      final element = tester.element(materialAppFinder);

      // Verify all 4 orthogonal regions and sub-services resolve cleanly
      expect(element.read<VaultSessionBloc>(), isNotNull);
      expect(element.read<SettingsMutationCubit>(), isNotNull);
      expect(element.read<ScreenPrivacyCubit>(), isNotNull);
      expect(element.read<GestureEngineCubit>(), isNotNull);
      expect(element.read<PinPadCubit>(), isNotNull);
      expect(element.read<IVaultStorageRepository>(), isNotNull);

      // Verify MaterialApp configuration
      final materialApp = tester.widget<MaterialApp>(materialAppFinder);
      final hasObserver = materialApp.navigatorObservers
              ?.any((obs) => obs is VaultRouteObserver) ??
          false;
      expect(hasObserver, isTrue);
      expect(materialApp.onGenerateRoute, equals(VaultRoutes.onGenerateRoute));
    });

    testWidgets(
        'AppLifecycleState.paused engages FLAG_SECURE when blockScreenshotsAndRecents policy is active',
        (tester) async {
      await pumpApp(tester);

      expect(
        harness.screenPrivacyCubit.state,
        isA<ScreenPrivacyPublicUnrestrictedState>(),
      );

      // Transition to paused (OS background)
      triggerLifecycle(tester, AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        harness.screenPrivacyCubit.state,
        isA<ScreenPrivacySecureFlagEngagedState>().having(
          (s) => s.reason,
          'reason',
          equals(ScreenPrivacyEngageReasonEnum.appBackgroundWithVaultLoaded),
        ),
      );
    });

    testWidgets(
        'AppLifecycleState.paused records monotonic timestamp and transitions session to backgroundGrace',
        (tester) async {
      await pumpApp(tester);

      // Seed session as unlocked
      final session = AuthSession(
        sessionToken: 'active_token',
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
      await tester.pump();

      // Background the app
      harness.clock.timeMs = 12000;
      triggerLifecycle(tester, AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        harness.sessionBloc.state,
        isA<VaultBackgroundGraceState>().having(
          (s) => s.enteredBackgroundMonotonicMs,
          'enteredBackgroundMonotonicMs',
          equals(12000),
        ),
      );
    });

    testWidgets(
        'Background grace timeout expiration transitions session to locked on resume',
        (tester) async {
      await pumpApp(tester);

      // Seed session as unlocked at 10000ms
      final session = AuthSession(
        sessionToken: 'active_token',
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
      await tester.pump();

      // Pause at 12000ms
      harness.clock.timeMs = 12000;
      triggerLifecycle(tester, AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 50));

      expect(harness.sessionBloc.state, isA<VaultBackgroundGraceState>());

      // Advance clock by 35 seconds (exceeding 30s grace timeout)
      harness.clock.advance(const Duration(seconds: 35));

      // Resume app
      triggerLifecycle(tester, AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 50));

      expect(harness.sessionBloc.state, isA<VaultLockedState>());
    });

    testWidgets(
        'AppLifecycleState.detached or hidden immediately triggers VaultQuickLockRequested',
        (tester) async {
      await pumpApp(tester);

      // Seed session as unlocked
      final session = AuthSession(
        sessionToken: 'active_token',
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
      await tester.pump();

      // Detach app
      triggerLifecycle(tester, AppLifecycleState.detached);
      await tester.pump(const Duration(milliseconds: 50));

      expect(harness.sessionBloc.state, isA<VaultLockedState>());
    });
  });
}
