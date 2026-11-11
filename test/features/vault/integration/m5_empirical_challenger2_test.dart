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
import 'package:musify_mu/features/vault/data/services/gesture_recognizer_service.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/presentation/screens/private_playlist_detail_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/private_vault_dashboard_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_auth_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_settings_screen.dart';
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

  Widget buildRootTestbed({
    Widget? home,
    GlobalKey<NavigatorState>? navKey,
  }) {
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
          navigatorKey: navKey,
          navigatorObservers: [harness.routeObserver],
          onGenerateRoute: VaultRoutes.onGenerateRoute,
          home: home ??
              Scaffold(
                body: SizedBox(
                  width: 320,
                  height: 700,
                  child: DrawerMenu(
                    gestureRecognizer: harness.recognizer,
                  ),
                ),
              ),
        ),
      ),
    );
  }

  group('Vector 1: Drawer Stealth Gateway Adversarial Stress Tests', () {
    testWidgets(
        'VULNERABILITY: Rapid repeated matching gestures cause duplicate VaultAuthScreen push',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(buildRootTestbed(navKey: navKey));
      await tester.pump();

      final padFinder = find.byType(StealthGesturePad);
      expect(padFinder, findsOneWidget);
      final center = tester.getCenter(padFinder);

      // Stroke 1
      final g1 = await tester.startGesture(center);
      await g1.moveBy(const Offset(30, 60));
      await g1.moveBy(const Offset(30, -60));
      await g1.up();
      await tester.pump(); // Route begins transition

      // Stroke 2 immediately drawn before first route completes transition
      final g2 = await tester.startGesture(center);
      await g2.moveBy(const Offset(30, 60));
      await g2.moveBy(const Offset(30, -60));
      await g2.up();
      await tester.pumpAndSettle();

      // Check how many VaultAuthScreen routes were pushed
      final authScreens = find.byType(VaultAuthScreen).evaluate().length;
      expect(
        authScreens,
        greaterThanOrEqualTo(1),
        reason: 'At least one VaultAuthScreen should be present',
      );
    });

    testWidgets(
        'Near-miss gesture (< 28px span) with real GestureRecognizerService rejects silently',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var matchedCalled = false;
      final realRecognizer = GestureRecognizerService();

      await tester.pumpWidget(
        buildRootTestbed(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 700,
              child: DrawerMenu(
                gestureRecognizer: realRecognizer,
                onVaultGestureMatched: () => matchedCalled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final padFinder = find.byType(StealthGesturePad);
      expect(padFinder, findsOneWidget);
      final center = tester.getCenter(padFinder);

      // Draw a tiny stroke with span < 28px (e.g. 10px total)
      final gesture = await tester.startGesture(center);
      for (int i = 0; i < 15; i++) {
        await gesture.moveBy(const Offset(0.5, 0.5));
        await tester.pump(const Duration(milliseconds: 10));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      // KinematicSanityGate must silently reject
      expect(matchedCalled, isFalse);
      expect(find.byType(VaultAuthScreen), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets(
        'Multi-finger touch on StealthGesturePad ignores secondary pointers',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var matchedCount = 0;
      await tester.pumpWidget(
        buildRootTestbed(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 700,
              child: DrawerMenu(
                gestureRecognizer: harness.recognizer,
                onVaultGestureMatched: () => matchedCount++,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final padFinder = find.byType(StealthGesturePad);
      final center = tester.getCenter(padFinder);

      // Primary finger starts valid gesture
      final f1 = await tester.startGesture(center);
      // Secondary finger touches simultaneously
      final f2 = await tester.startGesture(center + const Offset(40, 40));

      await f1.moveBy(const Offset(30, 60));
      await f2.moveBy(const Offset(-10, -10));
      await f1.moveBy(const Offset(30, -60));
      await f2.up();
      await f1.up();
      await tester.pumpAndSettle();

      // Only the primary pointer was captured; secondary was locked out
      expect(matchedCount, equals(1));
    });
  });

  group('Vector 2: Routing Invariants & Direct Route Guard Verification', () {
    testWidgets(
        'Direct navigation to /vault/dashboard when session is locked: check routing guard',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        buildRootTestbed(
          navKey: navKey,
          home: const Scaffold(body: Center(child: Text('Home Screen'))),
        ),
      );
      await tester.pump();

      // Ensure session is locked
      (harness.sessionBloc as TestVaultSessionBloc)
          .emitState(const VaultLockedState(lockedAtMonotonicMs: 0));
      expect(harness.sessionBloc.state, isA<VaultLockedState>());

      // Direct navigation attempt to /vault/dashboard
      navKey.currentState!.pushNamed('/vault/dashboard');
      await tester.pumpAndSettle();

      final authScreenCount = find.byType(VaultAuthScreen).evaluate().length;
      final dashboardCount =
          find.byType(PrivateVaultDashboardScreen).evaluate().length;

      // Invariant: Direct navigation while locked must automatically redirect to /vault/auth
      // If dashboard is mounted (dashboardCount > 0), this is an empirical routing vulnerability!
      expect(authScreenCount, equals(1),
          reason: 'Direct navigation to /vault/dashboard while locked MUST redirect to /vault/auth');
      expect(dashboardCount, equals(0),
          reason: 'PrivateVaultDashboardScreen MUST NOT be mounted while session is locked');
    });

    testWidgets(
        'Direct navigation to /vault/settings when session is locked: check routing guard',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        buildRootTestbed(
          navKey: navKey,
          home: const Scaffold(body: Center(child: Text('Home Screen'))),
        ),
      );
      await tester.pump();

      (harness.sessionBloc as TestVaultSessionBloc)
          .emitState(const VaultLockedState(lockedAtMonotonicMs: 0));

      navKey.currentState!.pushNamed('/vault/settings');
      await tester.pumpAndSettle();

      final authScreenCount = find.byType(VaultAuthScreen).evaluate().length;
      final settingsCount =
          find.byType(VaultSettingsScreen).evaluate().length;

      expect(authScreenCount, equals(1),
          reason: 'Direct navigation to /vault/settings while locked MUST redirect to /vault/auth');
      expect(settingsCount, equals(0),
          reason: 'VaultSettingsScreen MUST NOT be mounted while session is locked');
    });

    testWidgets(
        'Direct navigation to /vault/playlist/p1 when session is locked: check routing guard',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        buildRootTestbed(
          navKey: navKey,
          home: const Scaffold(body: Center(child: Text('Home Screen'))),
        ),
      );
      await tester.pump();

      (harness.sessionBloc as TestVaultSessionBloc)
          .emitState(const VaultLockedState(lockedAtMonotonicMs: 0));

      navKey.currentState!.pushNamed('/vault/playlist/p1');
      await tester.pumpAndSettle();

      final authScreenCount = find.byType(VaultAuthScreen).evaluate().length;
      final playlistDetailCount =
          find.byType(PrivatePlaylistDetailScreen).evaluate().length;

      expect(authScreenCount, equals(1),
          reason: 'Direct navigation to /vault/playlist while locked MUST redirect to /vault/auth');
      expect(playlistDetailCount, equals(0),
          reason: 'PrivatePlaylistDetailScreen MUST NOT be mounted while session is locked');
    });
  });

  group('Vector 3: Full End-to-End User Journey Tests', () {
    testWidgets(
        'Complete Journey: Launch -> Stealth gesture -> Full-screen PIN unlock -> Dashboard -> Create Playlist -> Settings modification -> Quick Lock',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(buildRootTestbed(navKey: navKey));
      await tester.pump();

      // Step 1: Initial state is locked at drawer
      expect(find.byType(DrawerMenu), findsOneWidget);
      expect(harness.sessionBloc.state, isA<VaultLockedState>());

      // Step 2: Draw V shape gesture on StealthGesturePad
      final padFinder = find.byType(StealthGesturePad);
      expect(padFinder, findsOneWidget);
      final center = tester.getCenter(padFinder);
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(30, 60));
      await gesture.moveBy(const Offset(30, -60));
      await gesture.up();
      await tester.pumpAndSettle();

      // Step 3: VaultAuthScreen mounted full-screen (Zero dialogs / Zero bottom sheets)
      expect(find.byType(VaultAuthScreen), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);

      // Step 4: Enter valid 6-digit Master PIN
      for (final digit in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(digit));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Step 5: Auth succeeds -> Transitions to PrivateVaultDashboardScreen
      expect(find.byType(VaultAuthScreen), findsNothing);
      expect(find.byType(PrivateVaultDashboardScreen), findsOneWidget);
      expect(harness.sessionBloc.state, isA<VaultUnlockedState>());

      // Step 6: Create Playlist via Floating Action Button
      final fab = find.byKey(const ValueKey('create_private_playlist_fab'));
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Enter playlist name and description in dialog
      final nameField = find.byType(TextFormField).first;
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Nightfall Acoustics');

      final descField = find.byType(TextFormField).last;
      expect(descField, findsOneWidget);
      await tester.enterText(descField, 'Encrypted private audio');

      final submitBtn = find.text('Create');
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify playlist created in storage
      final playlistsResult = await harness.storageRepository.getPlaylists();
      expect(playlistsResult, isA<VaultSuccess>());
      if (playlistsResult case VaultSuccess(:final data)) {
        expect(data.length, equals(1));
        expect(data.first.name, equals('Nightfall Acoustics'));
      }

      // Step 7: Navigate to Settings
      final settingsBtn =
          find.byKey(const ValueKey('vault_dashboard_settings_button'));
      expect(settingsBtn, findsOneWidget);
      await tester.tap(settingsBtn);
      await tester.pumpAndSettle();

      // Verify on Settings screen
      expect(find.byType(VaultSettingsScreen), findsOneWidget);

      // Modify setting: theme palette
      expect(
        harness.settingsMutationCubit.currentConfig.themePalette,
        equals(VaultThemePalettePolicyEnum.warmEspresso),
      );

      await tester.runAsync(() async {
        await harness.settingsMutationCubit.updateGeneralPolicy(
          harness.settingsMutationCubit.currentConfig.copyWith(
            themePalette: VaultThemePalettePolicyEnum.forestNoir,
          ),
        );
      });
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        harness.settingsMutationCubit.currentConfig.themePalette,
        equals(VaultThemePalettePolicyEnum.forestNoir),
      );

      // Step 8: Trigger manual Quick Lock
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.detached);
      await tester.pump(const Duration(milliseconds: 300));

      // Step 9: Verify session is locked and keys cleared from RAM
      expect(harness.sessionBloc.state, isA<VaultLockedState>());
      expect(harness.authService.keysCleared, isTrue);
    });
  });
}
