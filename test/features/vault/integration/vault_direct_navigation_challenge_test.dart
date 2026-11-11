import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/app/routes/vault_routes.dart';
import 'package:musify_mu/features/vault/application/gesture/gesture_engine_cubit.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/presentation/screens/private_playlist_detail_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/private_vault_dashboard_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_auth_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_settings_screen.dart';

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

  group('Challenge Routing Invariants: Direct Navigation to /vault routes', () {
    testWidgets(
        'FAIL: Direct navigation to /vault/dashboard when session is locked does NOT redirect to /vault/auth',
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

      (harness.sessionBloc as TestVaultSessionBloc)
          .emitState(const VaultLockedState(lockedAtMonotonicMs: 0));
      expect(harness.sessionBloc.state, isA<VaultLockedState>());

      navKey.currentState!.pushNamed('/vault/dashboard');
      await tester.pumpAndSettle();

      // Expected by challenge specification: Automatic redirection to /vault/auth
      final authCount = find.byType(VaultAuthScreen).evaluate().length;
      final dashboardCount = find.byType(PrivateVaultDashboardScreen).evaluate().length;

      expect(authCount, equals(1),
          reason: 'Direct navigation to /vault/dashboard when locked must redirect to /vault/auth');
      expect(dashboardCount, equals(0),
          reason: 'PrivateVaultDashboardScreen must not be mounted when session is locked');
    });

    testWidgets(
        'FAIL: Direct navigation to /vault/dashboard when session is uninitialized does NOT redirect to /vault/auth',
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

      (harness.sessionBloc as TestVaultSessionBloc)
          .emitState(const VaultUninitializedState());
      expect(harness.sessionBloc.state, isA<VaultUninitializedState>());

      navKey.currentState!.pushNamed('/vault/dashboard');
      await tester.pumpAndSettle();

      final authCount = find.byType(VaultAuthScreen).evaluate().length;
      final dashboardCount = find.byType(PrivateVaultDashboardScreen).evaluate().length;

      expect(authCount, equals(1),
          reason: 'Direct navigation to /vault/dashboard when uninitialized must redirect to /vault/auth');
      expect(dashboardCount, equals(0),
          reason: 'PrivateVaultDashboardScreen must not be mounted when session is uninitialized');
    });

    testWidgets(
        'Direct navigation to /vault/settings when session is locked does NOT redirect to /vault/auth',
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

      (harness.sessionBloc as TestVaultSessionBloc)
          .emitState(const VaultLockedState(lockedAtMonotonicMs: 0));
      expect(harness.sessionBloc.state, isA<VaultLockedState>());

      navKey.currentState!.pushNamed('/vault/settings');
      await tester.pumpAndSettle();

      final authCount = find.byType(VaultAuthScreen).evaluate().length;
      final settingsCount = find.byType(VaultSettingsScreen).evaluate().length;

      expect(authCount, equals(1),
          reason: 'Direct navigation to /vault/settings when locked must redirect to /vault/auth');
      expect(settingsCount, equals(0));
    });

    testWidgets(
        'Direct navigation to /vault/playlist/p1 when session is locked does NOT redirect to /vault/auth',
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

      (harness.sessionBloc as TestVaultSessionBloc)
          .emitState(const VaultLockedState(lockedAtMonotonicMs: 0));
      expect(harness.sessionBloc.state, isA<VaultLockedState>());

      navKey.currentState!.pushNamed('/vault/playlist/p1');
      await tester.pumpAndSettle();

      final authCount = find.byType(VaultAuthScreen).evaluate().length;
      final detailCount = find.byType(PrivatePlaylistDetailScreen).evaluate().length;

      expect(authCount, equals(1),
          reason: 'Direct navigation to /vault/playlist when locked must redirect to /vault/auth');
      expect(detailCount, equals(0));
    });
  });
}
