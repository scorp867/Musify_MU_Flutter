import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/app/routes/vault_routes.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/shell/presentation/widgets/drawer_menu.dart';
import 'package:musify_mu/features/vault/application/gesture/gesture_engine_cubit.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/presentation/screens/private_vault_dashboard_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_auth_screen.dart';
import 'package:musify_mu/features/vault/presentation/widgets/stealth_gesture_pad.dart';

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

  Widget buildTestbed({Widget? child}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: FakeAuthBloc()),
        BlocProvider<VaultSessionBloc>.value(value: harness.sessionBloc),
        BlocProvider<SettingsMutationCubit>.value(
            value: harness.settingsMutationCubit),
        BlocProvider<ScreenPrivacyCubit>.value(
            value: harness.screenPrivacyCubit),
        BlocProvider<GestureEngineCubit>.value(
            value: harness.gestureEngineCubit),
        BlocProvider<PinPadCubit>.value(value: harness.pinPadCubit),
      ],
      child: RepositoryProvider<IVaultStorageRepository>.value(
        value: harness.storageRepository,
        child: MaterialApp(
          navigatorObservers: [harness.routeObserver],
          onGenerateRoute: VaultRoutes.onGenerateRoute,
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 700,
              child: child ?? const DrawerMenu(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> performStroke(WidgetTester tester) async {
    final padFinder = find.byType(StealthGesturePad);
    expect(padFinder, findsOneWidget);

    final padCenter = tester.getCenter(padFinder);
    final gesture = await tester.startGesture(padCenter);
    await gesture.moveBy(const Offset(30, 60));
    await gesture.moveBy(const Offset(30, -60));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  group('DrawerMenu Stealth Gateway Integration Tests', () {
    testWidgets(
        'StealthGesturePad in DrawerMenu captures gestures and triggers onVaultGestureMatched',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var matchedCount = 0;

      await tester.pumpWidget(
        buildTestbed(
          child: DrawerMenu(
            onVaultGestureMatched: () => matchedCount++,
            gestureRecognizer: harness.recognizer,
          ),
        ),
      );
      await tester.pump();

      await performStroke(tester);

      expect(matchedCount, equals(1));
    });

    testWidgets(
        'Stealth gateway in DrawerMenu navigates to VaultAuthScreen(mode: unlock) on root navigator',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestbed(
          child: DrawerMenu(
            gestureRecognizer: harness.recognizer,
          ),
        ),
      );
      await tester.pump();

      await performStroke(tester);

      // Verify full-screen VaultAuthScreen is mounted on top
      expect(find.byType(VaultAuthScreen), findsOneWidget);
      expect(find.text('Enter Master PIN'), findsOneWidget);
    });

    testWidgets(
        'Successful PIN entry in VaultAuthScreen pops and transitions to PrivateVaultDashboardScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestbed(
          child: DrawerMenu(
            gestureRecognizer: harness.recognizer,
          ),
        ),
      );
      await tester.pump();

      // Trigger stealth gateway
      await performStroke(tester);

      expect(find.byType(VaultAuthScreen), findsOneWidget);

      // Enter correct PIN: 1, 2, 3, 4, 5, 6
      for (final digit in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(digit));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();

      // VaultAuthScreen popped and PrivateVaultDashboardScreen is now active
      expect(find.byType(VaultAuthScreen), findsNothing);
      expect(find.byType(PrivateVaultDashboardScreen), findsOneWidget);
    });

    testWidgets(
        'Stealth gesture when session is already active navigates directly to PrivateVaultDashboardScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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

      await tester.pumpWidget(
        buildTestbed(
          child: DrawerMenu(
            gestureRecognizer: harness.recognizer,
          ),
        ),
      );
      await tester.pump();

      await performStroke(tester);

      // Directly on dashboard without auth screen
      expect(find.byType(VaultAuthScreen), findsNothing);
      expect(find.byType(PrivateVaultDashboardScreen), findsOneWidget);
    });

    testWidgets(
        'Non-matching gesture rejects silently with zero UI leakage',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      harness.recognizer.shouldMatch = false;

      await tester.pumpWidget(
        buildTestbed(
          child: DrawerMenu(
            gestureRecognizer: harness.recognizer,
          ),
        ),
      );
      await tester.pump();

      final padFinder = find.byType(StealthGesturePad);
      final center = tester.getCenter(padFinder);
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(30, 60));
      await gesture.moveBy(const Offset(30, -60));
      await gesture.up();
      await tester.pumpAndSettle();

      // No auth screen, no dashboard, no dialog, no snackbar
      expect(find.byType(VaultAuthScreen), findsNothing);
      expect(find.byType(PrivateVaultDashboardScreen), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(DrawerMenu), findsOneWidget);
    });
  });
}
