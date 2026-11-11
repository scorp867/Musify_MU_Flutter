import 'dart:async';
import 'package:flutter/material.dart';
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
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';

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
  final List<PrivatePlaylist> playlists = [];
  final List<PrivateTrackRef> addedTracks = [];

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      VaultResult.success(const VaultConfig.constant());

  @override
  Future<VaultResult<List<PrivatePlaylist>>> getPlaylists() async =>
      VaultResult.success(List.unmodifiable(playlists));

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
  Future<VaultResult<void>> addTrackToPlaylist({
    required String playlistId,
    required PrivateTrackRef trackRef,
  }) async {
    addedTracks.add(trackRef);
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final existing = playlists[index];
      playlists[index] = existing.copyWith(
        trackRefs: [...existing.trackRefs, trackRef],
        totalDurationMs: existing.totalDurationMs + trackRef.durationMs,
      );
    }
    return const VaultResult.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> controller =
      StreamController<VaultSessionState>.broadcast();
  @override
  Stream<VaultSessionState> get sessionStateStream => controller.stream;
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

class FakePlaylistMobiusLoop implements PlaylistMobiusLoop {
  final StreamController<PlaylistScreenState> _controller =
      StreamController<PlaylistScreenState>.broadcast();
  PlaylistScreenState _state;

  FakePlaylistMobiusLoop(this._state);

  @override
  String get playlistUri => 'spotify:playlist:test_public';

  @override
  Stream<PlaylistScreenState> get stateStream => _controller.stream;

  @override
  PlaylistScreenState get currentState => _state;

  void emitState(PlaylistScreenState newState) {
    _state = newState;
    _controller.add(newState);
  }

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
  group('Public Menu Stealth Ingestion Gating Tests', () {
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

    final unlockedState = VaultUnlockedState(
      session: testSession,
      unlockedAtMonotonicMs: 1000,
      reauthDeadlineMonotonicMs: 60000,
    );

    final backgroundGraceState = VaultBackgroundGraceState(
      session: testSession,
      enteredBackgroundMonotonicMs: 1000,
      graceTimeoutMs: 30000,
      graceDeadlineMonotonicMs: 31000,
    );

    final track1 = PlaylistItem(
      uri: 'spotify:track:track_1',
      uid: 'uid_1',
      rowPosition: 0,
      trackMetadata: const TrackItemMetadata(
        title: 'Track One',
        uri: 'spotify:track:track_1',
        albumName: 'Album Alpha',
        durationMs: 180000,
        artists: ['Artist A'],
        coverImage: CoverImage(defaultUrl: 'https://example.com/cover1.jpg'),
      ),
    );

    final track2 = PlaylistItem(
      uri: 'spotify:track:track_2',
      uid: 'uid_2',
      rowPosition: 1,
      trackMetadata: const TrackItemMetadata(
        title: 'Track Two',
        uri: 'spotify:track:track_2',
        albumName: 'Album Beta',
        durationMs: 240000,
        artists: ['Artist B'],
        coverImage: CoverImage(defaultUrl: 'https://example.com/cover2.jpg'),
      ),
    );

    final testPlaylist = PlaylistEntity(
      metadata: const PlaylistMetadata(
        uri: 'spotify:playlist:test_public',
        name: 'Public Test Playlist',
        description: 'Original public playlist description',
        ownerName: 'Musify User',
        picture: 'https://example.com/playlist_cover.jpg',
        canEdit: true,
      ),
      items: [track1, track2],
      totalLength: 2,
    );

    final loadedState = PlaylistLoadedState(
      playlist: testPlaylist,
      displayItems: [track1, track2],
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

    Widget createTestHarness({
      required WidgetTester tester,
      required GlobalKey<PlaylistScreenWidgetState> screenKey,
      VaultSessionBloc? blocOverride,
      IVaultStorageRepository? storageOverride,
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
            vaultSessionBlocOverride: blocOverride,
            vaultStorageRepositoryOverride: storageOverride,
            loopOverride: fakeLoop,
          ),
        ),
      );
    }

    testWidgets(
      'Scenario 1: When Vault is Unlocked: Clone to Vault and Add to Private Playlists ARE rendered',
      (WidgetTester tester) async {
        sessionBloc.emitState(unlockedState);
        final screenKey = GlobalKey<PlaylistScreenWidgetState>();

        await tester.pumpWidget(createTestHarness(
          tester: tester,
          screenKey: screenKey,
          blocOverride: sessionBloc,
          storageOverride: fakeStorage,
        ));
        await tester.pumpAndSettle();

        // 1. Verify Playlist More Menu
        screenKey.currentState!.showPlaylistMoreMenu(loadedState);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('menu_clone_to_private_vault')),
          findsOneWidget,
        );
        expect(find.text('Clone to Private Vault'), findsOneWidget);

        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();

        // 2. Verify Track Options Menu
        screenKey.currentState!.showTrackOptionsMenu(track1);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('menu_add_to_private_playlists')),
          findsOneWidget,
        );
        expect(find.text('Add to Private Playlists'), findsOneWidget);

        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Scenario 2: When Vault is in Background Grace: Both ingestion options ARE rendered',
      (WidgetTester tester) async {
        sessionBloc.emitState(backgroundGraceState);
        final screenKey = GlobalKey<PlaylistScreenWidgetState>();

        await tester.pumpWidget(createTestHarness(
          tester: tester,
          screenKey: screenKey,
          blocOverride: sessionBloc,
          storageOverride: fakeStorage,
        ));
        await tester.pumpAndSettle();

        // 1. Playlist More Menu
        screenKey.currentState!.showPlaylistMoreMenu(loadedState);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('menu_clone_to_private_vault')),
          findsOneWidget,
        );

        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();

        // 2. Track Options Menu
        screenKey.currentState!.showTrackOptionsMenu(track1);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('menu_add_to_private_playlists')),
          findsOneWidget,
        );

        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Scenario 3: When Vault is Locked: 100% Invisible with zero UI leakage',
      (WidgetTester tester) async {
        sessionBloc.emitState(const VaultLockedState(lockedAtMonotonicMs: 1000));
        final screenKey = GlobalKey<PlaylistScreenWidgetState>();

        await tester.pumpWidget(createTestHarness(
          tester: tester,
          screenKey: screenKey,
          blocOverride: sessionBloc,
          storageOverride: fakeStorage,
        ));
        await tester.pumpAndSettle();

        // 1. Playlist More Menu
        screenKey.currentState!.showPlaylistMoreMenu(loadedState);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('menu_clone_to_private_vault')),
          findsNothing,
        );
        expect(find.text('Clone to Private Vault'), findsNothing);

        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();

        // 2. Track Options Menu
        screenKey.currentState!.showTrackOptionsMenu(track1);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('menu_add_to_private_playlists')),
          findsNothing,
        );
        expect(find.text('Add to Private Playlists'), findsNothing);

        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Scenario 4: When Vault is Uninitialized: 100% Invisible with zero UI leakage',
      (WidgetTester tester) async {
        sessionBloc.emitState(const VaultUninitializedState());
        final screenKey = GlobalKey<PlaylistScreenWidgetState>();

        await tester.pumpWidget(createTestHarness(
          tester: tester,
          screenKey: screenKey,
          blocOverride: sessionBloc,
          storageOverride: fakeStorage,
        ));
        await tester.pumpAndSettle();

        screenKey.currentState!.showPlaylistMoreMenu(loadedState);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('menu_clone_to_private_vault')),
          findsNothing,
        );
        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();

        screenKey.currentState!.showTrackOptionsMenu(track1);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('menu_add_to_private_playlists')),
          findsNothing,
        );
        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Scenario 5: When Vault is in Lockout Cooldown: 100% Invisible with zero UI leakage',
      (WidgetTester tester) async {
        sessionBloc.emitState(const VaultLockoutCooldownState(
          tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
          cooldownStartedMonotonicMs: 1000,
          durationMs: 30000,
          deadlineMonotonicMs: 31000,
          failedAttemptsCount: 5,
        ));
        final screenKey = GlobalKey<PlaylistScreenWidgetState>();

        await tester.pumpWidget(createTestHarness(
          tester: tester,
          screenKey: screenKey,
          blocOverride: sessionBloc,
          storageOverride: fakeStorage,
        ));
        await tester.pumpAndSettle();

        screenKey.currentState!.showPlaylistMoreMenu(loadedState);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('menu_clone_to_private_vault')),
          findsNothing,
        );
        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();

        screenKey.currentState!.showTrackOptionsMenu(track1);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('menu_add_to_private_playlists')),
          findsNothing,
        );
        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Scenario 6: When Vault is Authenticating: 100% Invisible with zero UI leakage',
      (WidgetTester tester) async {
        sessionBloc.emitState(const VaultAuthenticatingState(
          authSessionId: 'sess_1',
          attemptNumber: 1,
          remainingAttemptsBeforeCooldown: 5,
        ));
        final screenKey = GlobalKey<PlaylistScreenWidgetState>();

        await tester.pumpWidget(createTestHarness(
          tester: tester,
          screenKey: screenKey,
          blocOverride: sessionBloc,
          storageOverride: fakeStorage,
        ));
        await tester.pumpAndSettle();

        screenKey.currentState!.showPlaylistMoreMenu(loadedState);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('menu_clone_to_private_vault')),
          findsNothing,
        );
        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();

        screenKey.currentState!.showTrackOptionsMenu(track1);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('menu_add_to_private_playlists')),
          findsNothing,
        );
        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Scenario 7: When Vault is in Pending Reauth: 100% Invisible with zero UI leakage',
      (WidgetTester tester) async {
        sessionBloc.emitState(VaultPendingReauthState(
          session: testSession,
          reauthTriggeredAtMonotonicMs: 5000,
          remainingAttempts: 3,
        ));
        final screenKey = GlobalKey<PlaylistScreenWidgetState>();

        await tester.pumpWidget(createTestHarness(
          tester: tester,
          screenKey: screenKey,
          blocOverride: sessionBloc,
          storageOverride: fakeStorage,
        ));
        await tester.pumpAndSettle();

        screenKey.currentState!.showPlaylistMoreMenu(loadedState);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('menu_clone_to_private_vault')),
          findsNothing,
        );
        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();

        screenKey.currentState!.showTrackOptionsMenu(track1);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('menu_add_to_private_playlists')),
          findsNothing,
        );
        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Scenario 8: When VaultSessionBloc is unregistered / null: 100% Invisible with zero crash',
      (WidgetTester tester) async {
        final screenKey = GlobalKey<PlaylistScreenWidgetState>();

        await tester.pumpWidget(createTestHarness(
          tester: tester,
          screenKey: screenKey,
          blocOverride: null,
          storageOverride: fakeStorage,
        ));
        await tester.pumpAndSettle();

        screenKey.currentState!.showPlaylistMoreMenu(loadedState);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('menu_clone_to_private_vault')),
          findsNothing,
        );
        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();

        screenKey.currentState!.showTrackOptionsMenu(track1);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('menu_add_to_private_playlists')),
          findsNothing,
        );
        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Scenario 9: Executing Clone to Vault clones playlist metadata and all tracks into storage',
      (WidgetTester tester) async {
        sessionBloc.emitState(unlockedState);
        final screenKey = GlobalKey<PlaylistScreenWidgetState>();

        await tester.pumpWidget(createTestHarness(
          tester: tester,
          screenKey: screenKey,
          blocOverride: sessionBloc,
          storageOverride: fakeStorage,
        ));
        await tester.pumpAndSettle();

        screenKey.currentState!.showPlaylistMoreMenu(loadedState);
        await tester.pumpAndSettle();

        final cloneTile = find.byKey(const ValueKey('menu_clone_to_private_vault'));
        expect(cloneTile, findsOneWidget);

        await tester.tap(cloneTile);
        await tester.pumpAndSettle();

        // Verify storage mutations
        expect(fakeStorage.playlists.length, 1);
        final cloned = fakeStorage.playlists.first;
        expect(cloned.name, 'Public Test Playlist');
        expect(cloned.description, 'Original public playlist description');
        expect(cloned.coverUri, 'https://example.com/playlist_cover.jpg');

        expect(fakeStorage.addedTracks.length, 2);
        expect(fakeStorage.addedTracks[0].title, 'Track One');
        expect(fakeStorage.addedTracks[0].artistName, 'Artist A');
        expect(fakeStorage.addedTracks[0].albumTitle, 'Album Alpha');
        expect(fakeStorage.addedTracks[1].title, 'Track Two');
        expect(fakeStorage.addedTracks[1].artistName, 'Artist B');

        // Verify user-facing snackbar
        expect(
          find.text('Cloned "Public Test Playlist" to Private Vault'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Scenario 10: Executing Add to Private Playlists adds track to selected private playlist',
      (WidgetTester tester) async {
        sessionBloc.emitState(unlockedState);
        await fakeStorage.createPlaylist(
          name: 'Late Night Chill',
          description: 'Secret beats',
        );

        final screenKey = GlobalKey<PlaylistScreenWidgetState>();

        await tester.pumpWidget(createTestHarness(
          tester: tester,
          screenKey: screenKey,
          blocOverride: sessionBloc,
          storageOverride: fakeStorage,
        ));
        await tester.pumpAndSettle();

        screenKey.currentState!.showTrackOptionsMenu(track1);
        await tester.pumpAndSettle();

        final addTile = find.byKey(const ValueKey('menu_add_to_private_playlists'));
        expect(addTile, findsOneWidget);

        await tester.tap(addTile);
        await tester.pumpAndSettle();

        // Verify playlist picker modal appeared
        expect(find.text('Select Private Playlist'), findsOneWidget);
        expect(find.byKey(const ValueKey('picker_playlist_pl_1')), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('picker_playlist_pl_1')));
        await tester.pumpAndSettle();

        // Verify track added
        expect(fakeStorage.addedTracks.length, 1);
        expect(fakeStorage.addedTracks.first.title, 'Track One');
        expect(fakeStorage.addedTracks.first.playlistId, 'pl_1');

        // Verify user-facing snackbar
        expect(
          find.text('Added "Track One" to "Late Night Chill"'),
          findsOneWidget,
        );
      },
    );
  });
}
