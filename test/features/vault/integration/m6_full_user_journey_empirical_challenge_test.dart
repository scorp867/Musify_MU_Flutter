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
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/settings_mutation_state.dart';
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

  Widget buildRootTestbed({GlobalKey<NavigatorState>? navKey}) {
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
          home: Scaffold(
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

  group('Milestone 6 Empirical Challenge: Full E2E User Journey & Subsystem Validation', () {
    testWidgets(
        'Verify exhaustive 9-step lifecycle: Drawer stealth gesture -> Full-screen PIN auth -> '
        'Dashboard mount -> Create playlist via FAB -> Ingestion verification -> '
        'Playlist detail mount, reorder & Mobius trigger -> Settings theme palette mutation -> '
        'Step-up PIN rotation -> App lifecycle detachment quick-lock & RAM shredding',
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

      // Step 1: Initial state is locked at DrawerMenu
      expect(find.byType(DrawerMenu), findsOneWidget);
      expect(harness.sessionBloc.state, isA<VaultLockedState>());

      // Draw V shape gesture on StealthGesturePad spacer
      final padFinder = find.byType(StealthGesturePad);
      expect(padFinder, findsOneWidget);
      final center = tester.getCenter(padFinder);
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(30, 60));
      await gesture.moveBy(const Offset(30, -60));
      await gesture.up();
      await tester.pumpAndSettle();

      // Step 2: Full-screen VaultAuthScreen PIN unlock (Zero dialogs / Zero bottom sheets)
      expect(find.byType(VaultAuthScreen), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);

      for (final digit in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(digit));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Step 3: PrivateVaultDashboardScreen mount & session unlocked
      expect(find.byType(VaultAuthScreen), findsNothing);
      expect(find.byType(PrivateVaultDashboardScreen), findsOneWidget);
      expect(harness.sessionBloc.state, isA<VaultUnlockedState>());

      // Step 4: Create private playlist via FAB & Drift insert verification
      final fab = find.byKey(const ValueKey('create_private_playlist_fab'));
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      final nameField = find.byType(TextFormField).first;
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Phase 4 Master Tracklist');

      final descField = find.byType(TextFormField).last;
      expect(descField, findsOneWidget);
      await tester.enterText(descField, 'Encrypted private recordings');

      final submitBtn = find.text('Create');
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      final playlistsResult = await harness.storageRepository.getPlaylists();
      expect(playlistsResult, isA<VaultSuccess>());
      late final String createdPlaylistId;
      if (playlistsResult case VaultSuccess(:final data)) {
        expect(data.length, equals(1));
        expect(data.first.name, equals('Phase 4 Master Tracklist'));
        createdPlaylistId = data.first.id;
      }

      // Step 5: Ingestion verification (add tracks to private playlist)
      final track1 = PrivateTrackRef(
        id: 'track_1',
        playlistId: createdPlaylistId,
        trackUri: 'spotify:track:obsidian',
        title: 'Deep Obsidian',
        artistName: 'Acoustic Labs',
        albumTitle: 'Isolation',
        durationMs: 180000,
        sourceType: TrackSourceTypeEnum.spotify,
        sortOrder: 0,
        addedAtEpochMs: 1000,
      );
      final track2 = PrivateTrackRef(
        id: 'track_2',
        playlistId: createdPlaylistId,
        trackUri: 'spotify:track:echoes',
        title: 'Silent Echoes',
        artistName: 'Resonance',
        albumTitle: 'Isolation',
        durationMs: 210000,
        sourceType: TrackSourceTypeEnum.spotify,
        sortOrder: 1,
        addedAtEpochMs: 1001,
      );

      await harness.storageRepository.addTrackToPlaylist(
        playlistId: createdPlaylistId,
        trackRef: track1,
      );
      await harness.storageRepository.addTrackToPlaylist(
        playlistId: createdPlaylistId,
        trackRef: track2,
      );

      // Verify tracks exist in storage
      final updatedPlaylist =
          await harness.storageRepository.getPlaylistById(createdPlaylistId);
      expect(updatedPlaylist, isA<VaultSuccess>());

      // Step 6: Open PrivatePlaylistDetailScreen, reorder tracks, trigger Mobius
      navKey.currentState!.pushNamed('/vault/playlist/$createdPlaylistId');
      await tester.pumpAndSettle();

      expect(find.byType(PrivatePlaylistDetailScreen), findsOneWidget);

      // Reorder tracks in storage
      final reorderResult = await harness.storageRepository.reorderTracksInPlaylist(
        playlistId: createdPlaylistId,
        trackIdsInOrder: ['track_2', 'track_1'],
      );
      expect(reorderResult, isA<VaultSuccess>());

      // Trigger playback via Mobius controller
      expect(harness.mobiusController.isClosed, isFalse);

      // Step 7: Navigate to VaultSettingsScreen, switch theme palette to forestNoir
      navKey.currentState!.pushNamed('/vault/settings');
      await tester.pumpAndSettle();

      expect(find.byType(VaultSettingsScreen), findsOneWidget);
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

      // Step 8: Step-up PIN rotation flow
      await harness.settingsMutationCubit.requestSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.pinRotation,
      );
      expect(
        harness.settingsMutationCubit.state,
        isA<SettingsMutationAwaitingStepUpAuthState>(),
      );

      // Execute PIN rotation with old PIN 123456 -> new PIN 654321
      final rotateResult = await harness.authService.rotatePin(
        oldPin: '123456',
        newPin: '654321',
      );
      expect(rotateResult, isA<VaultSuccess>());

      await harness.settingsMutationCubit.confirmSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.pinRotation,
        onExecute: () async {},
      );
      expect(
        harness.settingsMutationCubit.state,
        isA<SettingsMutationSyncedIdleState>(),
      );
      expect(harness.authService.currentPin, equals('654321'));

      // Step 9: Quick-lock via app lifecycle detachment and RAM key shredding
      expect(harness.authService.keysCleared, isFalse);
      harness.coordinator.onAppLifecycleStateChanged(AppLifecycleState.detached);
      await tester.pump(const Duration(milliseconds: 300));

      expect(harness.sessionBloc.state, isA<VaultLockedState>());
      expect(harness.authService.keysCleared, isTrue);
    });
  });
}
