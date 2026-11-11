import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:musify_mu/features/vault/presentation/screens/gesture_enrollment_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/private_playlist_detail_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/private_vault_dashboard_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_auth_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_settings_screen.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';

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

  Widget buildTestbed({
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return MultiBlocProvider(
      providers: [
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
          navigatorKey: navigatorKey,
          navigatorObservers: [harness.routeObserver],
          onGenerateRoute: VaultRoutes.onGenerateRoute,
          home: const Scaffold(
            body: Center(child: Text('Public Root Screen')),
          ),
        ),
      ),
    );
  }

  group('Vault Routing & Security Integration Tests', () {
    testWidgets(
        'All /vault route names resolve to their respective full-screen Scaffolds with VaultTheme',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(buildTestbed(navigatorKey: navKey));
      await tester.pump();

      // 1. /vault/auth
      navKey.currentState!.pushNamed('/vault/auth');
      await tester.pumpAndSettle();
      expect(find.byType(VaultAuthScreen), findsOneWidget);
      expect(find.byType(VaultTheme), findsWidgets);
      navKey.currentState!.pop();
      await tester.pumpAndSettle();

      // Seed unlocked session so protected routes resolve to target screens
      (harness.sessionBloc as TestVaultSessionBloc).emitState(
        VaultUnlockedState(
          session: AuthSession(
            sessionToken: 'test_token',
            sessionStartedEpochMs: 1000,
            lastActiveEpochMs: 1000,
            authMethod: AuthMethodEnum.pin,
          ),
          unlockedAtMonotonicMs: 1000,
          reauthDeadlineMonotonicMs: 0,
        ),
      );

      // 2. /vault/dashboard
      navKey.currentState!.pushNamed('/vault/dashboard');
      await tester.pumpAndSettle();
      expect(find.byType(PrivateVaultDashboardScreen), findsOneWidget);
      expect(find.byType(VaultTheme), findsWidgets);
      navKey.currentState!.pop();
      await tester.pumpAndSettle();

      // 3. /vault/settings
      navKey.currentState!.pushNamed('/vault/settings');
      await tester.pumpAndSettle();
      expect(find.byType(VaultSettingsScreen), findsOneWidget);
      expect(find.byType(VaultTheme), findsWidgets);
      navKey.currentState!.pop();
      await tester.pumpAndSettle();

      // 4. /vault/settings/appearance
      navKey.currentState!.pushNamed('/vault/settings/appearance');
      await tester.pumpAndSettle();
      expect(find.byType(VaultAppearanceSettingsScreen), findsOneWidget);
      navKey.currentState!.pop();
      await tester.pumpAndSettle();

      // 5. /vault/settings/security
      navKey.currentState!.pushNamed('/vault/settings/security');
      await tester.pumpAndSettle();
      expect(find.byType(VaultSecuritySettingsScreen), findsOneWidget);
      navKey.currentState!.pop();
      await tester.pumpAndSettle();

      // 6. /vault/settings/privacy
      navKey.currentState!.pushNamed('/vault/settings/privacy');
      await tester.pumpAndSettle();
      expect(find.byType(VaultPrivacySettingsScreen), findsOneWidget);
      navKey.currentState!.pop();
      await tester.pumpAndSettle();

      // 7. /vault/settings/gesture
      navKey.currentState!.pushNamed('/vault/settings/gesture');
      await tester.pumpAndSettle();
      expect(find.byType(VaultGestureSettingsScreen), findsOneWidget);
      navKey.currentState!.pop();
      await tester.pumpAndSettle();

      // 8. /vault/settings/danger
      navKey.currentState!.pushNamed('/vault/settings/danger');
      await tester.pumpAndSettle();
      expect(find.byType(VaultDangerZoneScreen), findsOneWidget);
      navKey.currentState!.pop();
      await tester.pumpAndSettle();

      // 9. /vault/enrollment
      navKey.currentState!.pushNamed('/vault/enrollment');
      await tester.pumpAndSettle();
      expect(find.byType(GestureEnrollmentScreen), findsOneWidget);
      navKey.currentState!.pop();
      await tester.pumpAndSettle();

      // 10. /vault/playlist/p1
      navKey.currentState!.pushNamed('/vault/playlist/p1');
      await tester.pumpAndSettle();
      expect(find.byType(PrivatePlaylistDetailScreen), findsOneWidget);
      navKey.currentState!.pop();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'VaultRouteObserver automatically engages FLAG_SECURE on push and releases on pop',
        (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(buildTestbed(navigatorKey: navKey));
      await tester.pump();

      // Seed unlocked session so protected routes resolve to target screens directly
      (harness.sessionBloc as TestVaultSessionBloc).emitState(
        VaultUnlockedState(
          session: AuthSession(
            sessionToken: 'test_token',
            sessionStartedEpochMs: 1000,
            lastActiveEpochMs: 1000,
            authMethod: AuthMethodEnum.pin,
          ),
          unlockedAtMonotonicMs: 1000,
          reauthDeadlineMonotonicMs: 0,
        ),
      );

      expect(
        harness.screenPrivacyCubit.state,
        isA<ScreenPrivacyPublicUnrestrictedState>(),
      );

      // Push vault route
      navKey.currentState!.pushNamed('/vault/dashboard');
      await tester.pumpAndSettle();

      expect(
        harness.screenPrivacyCubit.state,
        isA<ScreenPrivacySecureFlagEngagedState>().having(
          (s) => s.reason,
          'reason',
          equals(ScreenPrivacyEngageReasonEnum.vaultRouteActive),
        ),
      );

      // Pop back to public route
      navKey.currentState!.pop();
      await tester.pumpAndSettle();

      expect(
        harness.screenPrivacyCubit.state,
        isA<ScreenPrivacyPublicUnrestrictedState>(),
      );
    });

    testWidgets(
        'Strict invariant: zero ModalBottomSheet or AlertDialog used for authentication',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(buildTestbed(navigatorKey: navKey));
      await tester.pump();

      // Push unlock screen
      navKey.currentState!.pushNamed('/vault/auth');
      await tester.pumpAndSettle();

      // Verify no modal bottom sheets or alert dialogs exist
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(VaultAuthScreen), findsOneWidget);
    });
  });
}
