import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/cover_image.dart';
import 'package:musify_mu/features/playlist/application/mobius/playlist_mobius_loop.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_entity.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_item.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_metadata.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_screen_state.dart';
import 'package:musify_mu/features/playlist/domain/models/sort_order.dart';
import 'package:musify_mu/features/playlist/domain/models/track_item_metadata.dart';
import 'package:musify_mu/features/playlist/presentation/playlist_screen.dart';
import 'package:musify_mu/features/vault/application/playlists/vault_playlists_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/data/services/vault_audio_playback_service.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_screen_privacy_controller.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';
import 'package:musify_mu/features/vault/presentation/screens/private_playlist_detail_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/private_vault_dashboard_screen.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';

class FakeMonotonicClock implements IMonotonicClock {
  int timeMs = 10000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class FakeScreenPrivacyController implements IScreenPrivacyController {
  ScreenPrivacyStateEnum _state = ScreenPrivacyStateEnum.publicUnrestricted;
  final StreamController<ScreenPrivacyStateEnum> _streamController =
      StreamController<ScreenPrivacyStateEnum>.broadcast();

  @override
  ScreenPrivacyStateEnum get currentState => _state;

  @override
  Stream<ScreenPrivacyStateEnum> get stateStream => _streamController.stream;

  @override
  Future<void> enableSecureFlag() async {
    _state = ScreenPrivacyStateEnum.secureFlagEngaged;
    _streamController.add(_state);
  }

  @override
  Future<void> disableSecureFlag() async {
    _state = ScreenPrivacyStateEnum.publicUnrestricted;
    _streamController.add(_state);
  }
}

class FakeVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> controller =
      StreamController<VaultSessionState>.broadcast();

  Stream<VaultSessionState> get sessionStateStream => controller.stream;

  @override
  void clearSessionKeysFromRam() {}

  @override
  Future<void> resetFailedAttempts() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVaultStorageRepository implements IVaultStorageRepository {
  final List<PrivatePlaylist> playlists = [];

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      VaultResult.success(const VaultConfig.constant());

  @override
  Future<VaultResult<List<PrivatePlaylist>>> getPlaylists() async {
    return VaultResult.success(List.unmodifiable(playlists));
  }

  @override
  Future<VaultResult<PrivatePlaylist>> getPlaylistById(String id) async {
    final match = playlists.where((p) => p.id == id).firstOrNull;
    if (match != null) {
      return VaultResult.success(match);
    }
    return const VaultResult.failure(VaultStorageFailure('Playlist not found'));
  }

  @override
  Future<VaultResult<PrivatePlaylist>> createPlaylist({
    required String name,
    required String description,
    String? coverUri,
  }) async {
    final playlist = PrivatePlaylist(
      id: 'pl_${playlists.length + 1}',
      name: name,
      description: description,
      coverUri: coverUri,
      totalDurationMs: 0,
      createdAtEpochMs: 1000,
      updatedAtEpochMs: 1000,
      trackRefs: const [],
    );
    playlists.add(playlist);
    return VaultResult.success(playlist);
  }

  @override
  Future<VaultResult<void>> deletePlaylist(String playlistId) async {
    playlists.removeWhere((p) => p.id == playlistId);
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final pl = playlists[index];
      playlists[index] = pl.copyWith(
        trackRefs: pl.trackRefs.where((t) => t.id != trackId).toList(),
      );
    }
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> reorderTracksInPlaylist({
    required String playlistId,
    required List<String> trackIdsInOrder,
  }) async {
    return const VaultResult.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVaultAudioPlaybackService implements VaultAudioPlaybackService {
  @override
  Future<void> playPrivatePlaylist({
    required PrivatePlaylist playlist,
    List<String>? resolvedFilePaths,
    required int startIndex,
    VaultConfig? config,
  }) async {}

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

class FakePlaylistMobiusLoop implements PlaylistMobiusLoop {
  final StreamController<PlaylistScreenState> _controller =
      StreamController<PlaylistScreenState>.broadcast();
  final PlaylistScreenState _state;

  FakePlaylistMobiusLoop(this._state);

  @override
  String get playlistUri => 'spotify:playlist:test_public';

  @override
  Stream<PlaylistScreenState> get stateStream => _controller.stream;

  @override
  PlaylistScreenState get currentState => _state;

  @override
  void onDownloadTapped() {}

  @override
  void onSearchChanged(String query) {}

  @override
  void dispose() {
    _controller.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Adversarial Challenge: Session Lock Dialog Dismissal & Pop Alignment', () {
    late FakeMonotonicClock clock;
    late FakeScreenPrivacyController privacyController;
    late ScreenPrivacyCubit privacyCubit;
    late FakeVaultStorageRepository storageRepo;
    late FakeVaultAuthService authService;
    late VerifySessionCoolOffUseCase verifyCoolOff;
    late TestVaultSessionBloc sessionBloc;
    late FakeVaultAudioPlaybackService playbackService;

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

    final sampleTrack = PrivateTrackRef(
      id: 'track_1',
      playlistId: 'pl_1',
      trackUri: 'spotify:track:sample_1',
      title: 'Midnight Echoes',
      artistName: 'Solar Flare',
      albumTitle: 'Cosmic Drift',
      durationMs: 210000,
      sourceType: TrackSourceTypeEnum.spotify,
      sortOrder: 0,
      addedAtEpochMs: 1000,
    );

    final samplePlaylist = PrivatePlaylist(
      id: 'pl_1',
      name: 'Confidential Session',
      description: 'Zero leakage playlist',
      coverUri: null,
      totalDurationMs: 210000,
      createdAtEpochMs: 1000,
      updatedAtEpochMs: 1000,
      trackRefs: [sampleTrack],
    );

    setUp(() {
      clock = FakeMonotonicClock();
      privacyController = FakeScreenPrivacyController();
      privacyCubit = ScreenPrivacyCubit(
        privacyController: privacyController,
        monotonicClock: clock,
      );
      storageRepo = FakeVaultStorageRepository();
      storageRepo.playlists.add(samplePlaylist);
      authService = FakeVaultAuthService();
      verifyCoolOff = VerifySessionCoolOffUseCase(clock: clock);
      sessionBloc = TestVaultSessionBloc(
        authService: authService,
        storageRepository: storageRepo,
        monotonicClock: clock,
        verifyCoolOffUseCase: verifyCoolOff,
        initialState: unlockedState,
      );
      playbackService = FakeVaultAudioPlaybackService();
    });

    tearDown(() {
      // Don't close privacyCubit immediately in tearDown without unmounting,
      // handled cleanly at the end of each test via pumpWidget(SizedBox.shrink()).
    });

    Widget buildDashboardHarness({
      required VaultPlaylistsCubit cubit,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (rootContext) => Column(
              children: [
                const Text('Root Public Screen'),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(rootContext).push(
                      MaterialPageRoute<void>(
                        builder: (_) => VaultTheme(
                          data: VaultThemeData.fromPalette(
                            VaultThemePalettePolicyEnum.warmEspresso,
                          ),
                          child: MultiBlocProvider(
                            providers: [
                              BlocProvider<VaultSessionBloc>.value(value: sessionBloc),
                              BlocProvider<ScreenPrivacyCubit>.value(value: privacyCubit),
                            ],
                            child: PrivateVaultDashboardScreen(
                              playlistsCubit: cubit,
                              storageRepository: storageRepo,
                              sessionBloc: sessionBloc,
                              screenPrivacyCubit: privacyCubit,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Vault Dashboard'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildDetailHarness({
      required String playlistId,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (rootContext) => Column(
              children: [
                const Text('Root Public Screen'),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(rootContext).push(
                      MaterialPageRoute<void>(
                        builder: (_) => VaultTheme(
                          data: VaultThemeData.fromPalette(
                            VaultThemePalettePolicyEnum.warmEspresso,
                          ),
                          child: MultiBlocProvider(
                            providers: [
                              BlocProvider<VaultSessionBloc>.value(value: sessionBloc),
                              BlocProvider<ScreenPrivacyCubit>.value(value: privacyCubit),
                            ],
                            child: PrivatePlaylistDetailScreen(
                              playlistId: playlistId,
                              storageRepository: storageRepo,
                              audioPlaybackService: playbackService,
                              sessionBloc: sessionBloc,
                              screenPrivacyCubit: privacyCubit,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Detail Screen'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets(
      'Challenge 1: Dashboard creation dialog open + VaultLockedState dispatches -> Pops both dialog and dashboard to root',
      (WidgetTester tester) async {
        final cubit = VaultPlaylistsCubit(storageRepository: storageRepo);
        await cubit.loadPlaylists();

        await tester.pumpWidget(buildDashboardHarness(cubit: cubit));
        await tester.pumpAndSettle();

        // 1. Navigate to Dashboard
        await tester.tap(find.text('Open Vault Dashboard'));
        await tester.pumpAndSettle();
        expect(find.text('Private Vault'), findsOneWidget);

        // 2. Open Create Playlist Dialog
        await tester.tap(find.byKey(const ValueKey('create_private_playlist_fab')));
        await tester.pumpAndSettle();
        expect(find.text('New Private Playlist'), findsOneWidget);

        // 3. Dispatch VaultLockedState
        sessionBloc.emitState(const VaultLockedState(lockedAtMonotonicMs: 15000));
        await tester.pumpAndSettle();

        // 4. Assert: Dialog is gone, Dashboard is gone, Root screen is restored
        expect(find.text('New Private Playlist'), findsNothing);
        expect(find.text('Private Vault'), findsNothing);
        expect(find.text('Root Public Screen'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await cubit.close();
      },
    );

    testWidgets(
      'Challenge 2: Dashboard creation dialog open + VaultUninitializedState dispatches -> Pops both dialog and dashboard to root',
      (WidgetTester tester) async {
        final cubit = VaultPlaylistsCubit(storageRepository: storageRepo);
        await cubit.loadPlaylists();

        await tester.pumpWidget(buildDashboardHarness(cubit: cubit));
        await tester.pumpAndSettle();

        // 1. Navigate to Dashboard
        await tester.tap(find.text('Open Vault Dashboard'));
        await tester.pumpAndSettle();
        expect(find.text('Private Vault'), findsOneWidget);

        // 2. Open Create Playlist Dialog
        await tester.tap(find.byKey(const ValueKey('create_private_playlist_fab')));
        await tester.pumpAndSettle();
        expect(find.text('New Private Playlist'), findsOneWidget);

        // 3. Dispatch VaultUninitializedState (e.g. Purge)
        sessionBloc.emitState(const VaultUninitializedState());
        await tester.pumpAndSettle();

        // 4. Assert: Dialog is gone, Dashboard is gone, Root screen is restored
        expect(find.text('New Private Playlist'), findsNothing);
        expect(find.text('Private Vault'), findsNothing);
        expect(find.text('Root Public Screen'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await cubit.close();
      },
    );

    testWidgets(
      'Challenge 3: Dashboard delete confirmation dialog open + VaultLockedState dispatches -> Pops cleanly to root',
      (WidgetTester tester) async {
        final cubit = VaultPlaylistsCubit(storageRepository: storageRepo);
        await cubit.loadPlaylists();

        await tester.pumpWidget(buildDashboardHarness(cubit: cubit));
        await tester.pumpAndSettle();

        // 1. Navigate to Dashboard
        await tester.tap(find.text('Open Vault Dashboard'));
        await tester.pumpAndSettle();
        expect(find.text('Private Vault'), findsOneWidget);

        // 2. Trigger delete confirmation dialog by swiping tile
        final tileKey = ValueKey(samplePlaylist.id);
        await tester.drag(find.byKey(tileKey), const Offset(-500.0, 0.0));
        await tester.pumpAndSettle();

        expect(find.text('Delete Playlist'), findsOneWidget);

        // 3. Dispatch VaultLockedState
        sessionBloc.emitState(const VaultLockedState(lockedAtMonotonicMs: 25000));
        await tester.pumpAndSettle();

        // 4. Assert: Dialog gone, Dashboard gone, Root restored
        expect(find.text('Delete Playlist'), findsNothing);
        expect(find.text('Private Vault'), findsNothing);
        expect(find.text('Root Public Screen'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await cubit.close();
      },
    );

    testWidgets(
      'Challenge 4: Playlist Detail Screen track removal dialog open + VaultLockedState dispatches -> Pops cleanly to root',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildDetailHarness(playlistId: samplePlaylist.id));
        await tester.pumpAndSettle();

        // 1. Navigate to Detail
        await tester.tap(find.text('Open Detail Screen'));
        await tester.pumpAndSettle();
        expect(find.byType(PrivatePlaylistDetailScreen), findsOneWidget);

        // 2. Trigger track removal confirmation dialog by swiping track tile
        final trackDismissKey = ValueKey('dismiss_${sampleTrack.id}');
        await tester.drag(find.byKey(trackDismissKey), const Offset(-500.0, 0.0));
        await tester.pumpAndSettle();

        expect(find.text('Remove Track'), findsOneWidget);

        // 3. Dispatch VaultLockedState
        sessionBloc.emitState(const VaultLockedState(lockedAtMonotonicMs: 35000));
        await tester.pumpAndSettle();

        // 4. Assert: Dialog gone, Detail screen gone, Root restored
        expect(find.text('Remove Track'), findsNothing);
        expect(find.byType(PrivatePlaylistDetailScreen), findsNothing);
        expect(find.text('Root Public Screen'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Challenge 5: Playlist Detail Screen delete playlist dialog open + VaultUninitializedState dispatches -> Pops cleanly to root',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildDetailHarness(playlistId: samplePlaylist.id));
        await tester.pumpAndSettle();

        // 1. Navigate to Detail
        await tester.tap(find.text('Open Detail Screen'));
        await tester.pumpAndSettle();
        expect(find.byType(PrivatePlaylistDetailScreen), findsOneWidget);

        // 2. Tap delete button in header
        final deleteBtn = find.widgetWithText(TextButton, 'Delete Playlist');
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        // 3. Dispatch VaultUninitializedState
        sessionBloc.emitState(const VaultUninitializedState());
        await tester.pumpAndSettle();

        // 4. Assert: Dialog gone, Detail screen gone, Root restored
        expect(find.text('Delete Playlist'), findsNothing);
        expect(find.byType(PrivatePlaylistDetailScreen), findsNothing);
        expect(find.text('Root Public Screen'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  });

  group('Adversarial Challenge: Complete 8-Session-State Stealth Ingestion Matrix', () {
    late FakeVaultAuthService fakeAuthService;
    late FakeMonotonicClock fakeClock;
    late FakeVaultStorageRepository fakeStorage;
    late VerifySessionCoolOffUseCase verifyCoolOff;
    late TestVaultSessionBloc sessionBloc;
    late FakePlaylistMobiusLoop fakeLoop;

    final testSession = AuthSession(
      sessionToken: 'test_token',
      sessionStartedEpochMs: 1000,
      lastActiveEpochMs: 1000,
      authMethod: AuthMethodEnum.pin,
    );

    final track1 = PlaylistItem(
      uri: 'spotify:track:track_1',
      uid: 'uid_1',
      rowPosition: 0,
      trackMetadata: const TrackItemMetadata(
        title: 'Adversarial Track 1',
        uri: 'spotify:track:track_1',
        albumName: 'Album Omega',
        durationMs: 180000,
        artists: ['Artist Omega'],
        coverImage: CoverImage(defaultUrl: 'https://example.com/cover1.jpg'),
      ),
    );

    final testPlaylist = PlaylistEntity(
      metadata: const PlaylistMetadata(
        uri: 'spotify:playlist:test_public',
        name: 'Matrix Public Playlist',
        description: 'Test stealth gating matrix',
        ownerName: 'Musify User',
        picture: 'https://example.com/cover.jpg',
        canEdit: true,
      ),
      items: [track1],
      totalLength: 1,
    );

    final loadedState = PlaylistLoadedState(
      playlist: testPlaylist,
      displayItems: [track1],
      sortOrder: ProvidedSortOrder.custom,
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
      );
      fakeLoop = FakePlaylistMobiusLoop(loadedState);
    });

    tearDown(() {
      fakeLoop.dispose();
      sessionBloc.close();
      fakeAuthService.controller.close();
    });

    Widget createPlaylistScreenHarness({
      required WidgetTester tester,
      required GlobalKey<PlaylistScreenWidgetState> screenKey,
    }) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      return MaterialApp(
        home: Scaffold(
          body: PlaylistScreen(
            key: screenKey,
            playlistUri: 'spotify:playlist:test_public',
            vaultSessionBlocOverride: sessionBloc,
            vaultStorageRepositoryOverride: fakeStorage,
            loopOverride: fakeLoop,
          ),
        ),
      );
    }

    testWidgets(
      'Challenge 6: Exhaustive 8-State Session Gating Matrix for Both Playlist & Track Menus',
      (WidgetTester tester) async {
        final screenKey = GlobalKey<PlaylistScreenWidgetState>();

        // Exact 8 Harel Region A session states:
        final stateMatrix = <({String name, VaultSessionState state, bool shouldRender})>[
          (
            name: 'State 1: VaultUninitializedState',
            state: const VaultUninitializedState(),
            shouldRender: false,
          ),
          (
            name: 'State 2: VaultLockedState',
            state: const VaultLockedState(lockedAtMonotonicMs: 1000),
            shouldRender: false,
          ),
          (
            name: 'State 3: VaultAuthenticatingState',
            state: const VaultAuthenticatingState(
              authSessionId: 'auth_sess_1',
              attemptNumber: 1,
              remainingAttemptsBeforeCooldown: 5,
            ),
            shouldRender: false,
          ),
          (
            name: 'State 4: VaultUnlockedState',
            state: VaultUnlockedState(
              session: testSession,
              unlockedAtMonotonicMs: 1000,
              reauthDeadlineMonotonicMs: 60000,
            ),
            shouldRender: true,
          ),
          (
            name: 'State 5: VaultBackgroundGraceState',
            state: VaultBackgroundGraceState(
              session: testSession,
              enteredBackgroundMonotonicMs: 1000,
              graceTimeoutMs: 30000,
              graceDeadlineMonotonicMs: 31000,
            ),
            shouldRender: true,
          ),
          (
            name: 'State 6: VaultPendingReauthState',
            state: VaultPendingReauthState(
              session: testSession,
              reauthTriggeredAtMonotonicMs: 5000,
              remainingAttempts: 3,
            ),
            shouldRender: false,
          ),
          (
            name: 'State 7: VaultLockoutCooldownState (Tier 1: 30s)',
            state: const VaultLockoutCooldownState(
              tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
              cooldownStartedMonotonicMs: 1000,
              durationMs: 30000,
              deadlineMonotonicMs: 31000,
              failedAttemptsCount: 5,
            ),
            shouldRender: false,
          ),
          (
            name: 'State 8: VaultLockoutCooldownState (Tier 2: 5m)',
            state: const VaultLockoutCooldownState(
              tier: LockoutCooldownTierEnum.tier2FiveMinutes,
              cooldownStartedMonotonicMs: 1000,
              durationMs: 300000,
              deadlineMonotonicMs: 301000,
              failedAttemptsCount: 10,
            ),
            shouldRender: false,
          ),
        ];

        await tester.pumpWidget(createPlaylistScreenHarness(
          tester: tester,
          screenKey: screenKey,
        ));
        await tester.pumpAndSettle();

        for (final entry in stateMatrix) {
          sessionBloc.emitState(entry.state);
          await tester.pump();

          // 1. Verify Playlist More Menu ("Clone to Private Vault")
          screenKey.currentState!.showPlaylistMoreMenu(loadedState);
          await tester.pumpAndSettle();

          final cloneTileFinder = find.byKey(const ValueKey('menu_clone_to_private_vault'));
          if (entry.shouldRender) {
            expect(
              cloneTileFinder,
              findsOneWidget,
              reason: '${entry.name} MUST render "Clone to Private Vault"',
            );
          } else {
            expect(
              cloneTileFinder,
              findsNothing,
              reason: '${entry.name} MUST NOT leak "Clone to Private Vault"',
            );
          }

          Navigator.of(tester.element(find.byType(BottomSheet))).pop();
          await tester.pumpAndSettle();

          // 2. Verify Track Options Menu ("Add to Private Playlists")
          screenKey.currentState!.showTrackOptionsMenu(track1);
          await tester.pumpAndSettle();

          final addTileFinder = find.byKey(const ValueKey('menu_add_to_private_playlists'));
          if (entry.shouldRender) {
            expect(
              addTileFinder,
              findsOneWidget,
              reason: '${entry.name} MUST render "Add to Private Playlists"',
            );
          } else {
            expect(
              addTileFinder,
              findsNothing,
              reason: '${entry.name} MUST NOT leak "Add to Private Playlists"',
            );
          }

          Navigator.of(tester.element(find.byType(BottomSheet))).pop();
          await tester.pumpAndSettle();
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  });
}
