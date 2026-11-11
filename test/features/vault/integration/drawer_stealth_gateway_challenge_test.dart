import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/app/routes/vault_routes.dart';
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/network/status/bloc/network_status_bloc.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/shell/presentation/hidden_drawer_scaffold.dart';
import 'package:musify_mu/features/shell/presentation/widgets/drawer_menu.dart';
import 'package:musify_mu/features/vault/application/gesture/gesture_engine_cubit.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/data/services/gesture_recognizer_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
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

  Widget buildDrawerTestbed({Widget? child, GlobalKey<NavigatorState>? navKey}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: FakeAuthBloc()),
        BlocProvider<NetworkStatusBloc>.value(value: harness.sl<NetworkStatusBloc>()),
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
          navigatorKey: navKey,
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

  group('Drawer Stealth Gateway Adversarial Challenges', () {
    testWidgets(
        'Adversarial: Near-miss gesture (span < 28px) rejects silently with zero UI leakage',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var matchedCount = 0;
      await tester.pumpWidget(
        buildDrawerTestbed(
          child: DrawerMenu(
            onVaultGestureMatched: () => matchedCount++,
            gestureRecognizer: GestureRecognizerService(),
          ),
        ),
      );
      await tester.pump();

      final padFinder = find.byType(StealthGesturePad);
      final center = tester.getCenter(padFinder);

      // Draw a tiny stroke < 28px (net span ~10px)
      final gesture = await tester.startGesture(center);
      for (int i = 0; i < 15; i++) {
        await gesture.moveBy(const Offset(0.5, 0.5));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(matchedCount, equals(0));
      expect(find.byType(VaultAuthScreen), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets(
        'Adversarial: Near-miss gesture (insufficient points < 10) rejects silently',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var matchedCount = 0;
      await tester.pumpWidget(
        buildDrawerTestbed(
          child: DrawerMenu(
            onVaultGestureMatched: () => matchedCount++,
            gestureRecognizer: GestureRecognizerService(),
          ),
        ),
      );
      await tester.pump();

      final padFinder = find.byType(StealthGesturePad);
      final center = tester.getCenter(padFinder);

      // Fast jump: only 2 points total
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(40, 40));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(matchedCount, equals(0));
      expect(find.byType(VaultAuthScreen), findsNothing);
    });

    testWidgets(
        'Adversarial: Rapid repeated matching gestures without debounce in DrawerMenu',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        buildDrawerTestbed(
          navKey: navKey,
          child: DrawerMenu(
            gestureRecognizer: harness.recognizer,
          ),
        ),
      );
      await tester.pump();

      final padFinder = find.byType(StealthGesturePad);
      final center = tester.getCenter(padFinder);

      // Perform stroke 1
      final g1 = await tester.startGesture(center);
      await g1.moveBy(const Offset(30, 60));
      await g1.moveBy(const Offset(30, -60));
      await g1.up();
      await tester.pump(); // Start navigation, but don't settle yet

      // Immediately perform stroke 2 while first navigation is starting/running
      final g2 = await tester.startGesture(center);
      await g2.moveBy(const Offset(30, 60));
      await g2.moveBy(const Offset(30, -60));
      await g2.up();
      await tester.pumpAndSettle();

      final authScreens = find.byType(VaultAuthScreen).evaluate().length;
      expect(authScreens, equals(1));
    });

    testWidgets(
        'Adversarial: Multi-pointer collision (two simultaneous touches on gesture pad)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var matchedCount = 0;
      await tester.pumpWidget(
        buildDrawerTestbed(
          child: DrawerMenu(
            onVaultGestureMatched: () => matchedCount++,
            gestureRecognizer: harness.recognizer,
          ),
        ),
      );
      await tester.pump();

      final padFinder = find.byType(StealthGesturePad);
      final center = tester.getCenter(padFinder);

      // Finger 1 down
      final finger1 = await tester.startGesture(center);
      // Finger 2 down on another spot
      final finger2 = await tester.startGesture(center + const Offset(50, 50));

      // Finger 1 moves in V shape
      await finger1.moveBy(const Offset(30, 60));
      await finger1.moveBy(const Offset(30, -60));

      // Finger 2 moves erratically
      await finger2.moveBy(const Offset(-20, -20));
      await finger2.up();

      await finger1.up();
      await tester.pumpAndSettle();

      // Finger 1 completed valid V stroke while Finger 2 was rejected by _activePointerId lock
      expect(matchedCount, equals(1));
    });

    testWidgets(
        'Adversarial: Gesture input while drawer is mid-animation in HiddenDrawerScaffold',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final scaffoldKey = GlobalKey();
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<IVaultStorageRepository>.value(
              value: harness.storageRepository,
            ),
            RepositoryProvider<ColorExtractionService>.value(
              value: harness.sl<ColorExtractionService>(),
            ),
            RepositoryProvider<DataPool>.value(
              value: harness.sl<DataPool>(),
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: FakeAuthBloc()),
              BlocProvider<NetworkStatusBloc>.value(
                  value: harness.sl<NetworkStatusBloc>()),
              BlocProvider<VaultSessionBloc>.value(value: harness.sessionBloc),
              BlocProvider<SettingsMutationCubit>.value(
                  value: harness.settingsMutationCubit),
              BlocProvider<ScreenPrivacyCubit>.value(
                  value: harness.screenPrivacyCubit),
              BlocProvider<GestureEngineCubit>.value(
                  value: harness.gestureEngineCubit),
              BlocProvider<PinPadCubit>.value(value: harness.pinPadCubit),
            ],
            child: MaterialApp(
              onGenerateRoute: VaultRoutes.onGenerateRoute,
              home: HiddenDrawerScaffold(
                key: scaffoldKey,
                modePersistence: FakeModePersistence(),
                createHomeFeedBloc: () => FakeHomeFeedBloc(),
                createBrowseBloc: () => FakeBrowseBloc(),
                createLibraryBloc: (_) => FakeLibraryBloc(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Find menu button (avatar icon) in home header to open drawer
      final menuButton = find.byIcon(Icons.person).last;
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);

      // Pump 140ms (exactly half-way through the 280ms drawer slide animation)
      await tester.pump(const Duration(milliseconds: 140));

      // Check StealthGesturePad is present in tree
      final padFinder = find.byType(StealthGesturePad);
      expect(padFinder, findsOneWidget);

      // Drawer is mid-animation (progress ~ 0.5)
      // Attempt to start a gesture on the pad while animating
      final padCenter = tester.getCenter(padFinder);
      final gesture = await tester.startGesture(padCenter);
      await gesture.moveBy(const Offset(30, 60));

      // Let animation finish
      await tester.pump(const Duration(milliseconds: 140));
      await gesture.moveBy(const Offset(30, -60));
      await gesture.up();
      await tester.pumpAndSettle();

      // Verify no crashes or unhandled state transitions occurred
      expect(tester.takeException(), isNull);
    });
  });
}
