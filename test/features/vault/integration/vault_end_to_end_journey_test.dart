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
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
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

  Widget buildRootApp() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: FakeAuthBloc()),
        BlocProvider<VaultSessionBloc>.value(value: harness.sessionBloc),
        BlocProvider<SettingsMutationCubit>.value(
            value: harness.settingsMutationCubit),
        BlocProvider<ScreenPrivacyCubit>.value(value: harness.screenPrivacyCubit),
        BlocProvider<GestureEngineCubit>.value(value: harness.gestureEngineCubit),
        BlocProvider<PinPadCubit>.value(value: harness.pinPadCubit),
      ],
      child: RepositoryProvider<IVaultStorageRepository>.value(
        value: harness.storageRepository,
        child: MaterialApp(
          navigatorObservers: [harness.routeObserver],
          onGenerateRoute: VaultRoutes.onGenerateRoute,
          home: Scaffold(
            body: DrawerMenu(
              gestureRecognizer: harness.recognizer,
            ),
          ),
        ),
      ),
    );
  }

  group('Vault End-to-End User Journey Tests', () {
    testWidgets(
        'Complete lifecycle: drawer stealth trigger -> full-screen auth -> dashboard -> settings mutation -> quick lock',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildRootApp());
      await tester.pump();

      // 1. Initially at drawer menu with locked session
      expect(find.byType(DrawerMenu), findsOneWidget);
      expect(harness.sessionBloc.state, isA<VaultLockedState>());

      // 2. Draw "V" gesture on StealthGesturePad spacer
      final padFinder = find.byType(StealthGesturePad);
      expect(padFinder, findsOneWidget);
      final center = tester.getCenter(padFinder);
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(30, 60));
      await gesture.moveBy(const Offset(30, -60));
      await gesture.up();
      await tester.pumpAndSettle();

      // 3. VaultAuthScreen opens full-screen (Zero dialogs / Zero bottom sheets)
      expect(find.byType(VaultAuthScreen), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);

      // 4. Enter valid 6-digit Master PIN
      for (final digit in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(digit));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // 5. Auth succeeds -> enters PrivateVaultDashboardScreen
      expect(find.byType(VaultAuthScreen), findsNothing);
      expect(find.byType(PrivateVaultDashboardScreen), findsOneWidget);
      expect(harness.sessionBloc.state, isA<VaultUnlockedState>());

      // 6. Navigate to Settings via VaultRoutes
      final nav = Navigator.of(tester.element(find.byType(PrivateVaultDashboardScreen)));
      nav.pushNamed('/vault/settings');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(VaultSettingsScreen), findsOneWidget);

      // 7. Verify dynamic theme switching
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

      // 8. Trigger manual Quick Lock
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.detached);
      await tester.pump(const Duration(milliseconds: 300));

      // 9. Session is locked, RAM keys are cleared
      expect(harness.sessionBloc.state, isA<VaultLockedState>());
      expect(harness.authService.keysCleared, isTrue);
    });
  });
}
