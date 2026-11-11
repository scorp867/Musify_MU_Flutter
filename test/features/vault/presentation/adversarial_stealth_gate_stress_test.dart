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
  group('Adversarial Stealth Gating & Dynamic Unmounting Stress Tests', () {
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

    const lockedState = VaultLockedState(lockedAtMonotonicMs: 1000);
    const uninitializedState = VaultUninitializedState();
    const lockoutState = VaultLockoutCooldownState(
      tier: LockoutCooldownTierEnum.tier1ThirtySeconds,
      cooldownStartedMonotonicMs: 1000,
      durationMs: 30000,
      deadlineMonotonicMs: 31000,
      failedAttemptsCount: 5,
    );
    const authenticatingState = VaultAuthenticatingState(
      authSessionId: 'sess_1',
      attemptNumber: 1,
      remainingAttemptsBeforeCooldown: 5,
    );
    final pendingReauthState = VaultPendingReauthState(
      session: testSession,
      reauthTriggeredAtMonotonicMs: 5000,
      remainingAttempts: 3,
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

    final testPlaylist = PlaylistEntity(
      metadata: const PlaylistMetadata(
        uri: 'spotify:playlist:test_public',
        name: 'Public Test Playlist',
        description: 'Original public playlist description',
        ownerName: 'Musify User',
        picture: 'https://example.com/playlist_cover.jpg',
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

    Widget createHarness({
      required WidgetTester tester,
      required GlobalKey<PlaylistScreenWidgetState> screenKey,
      VaultSessionBloc? blocOverride,
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
            vaultStorageRepositoryOverride: fakeStorage,
            loopOverride: fakeLoop,
          ),
        ),
      );
    }

    testWidgets(
      'Adversarial Test 1: Dynamic unmounting of "Clone to Private Vault" while Playlist More Menu is OPEN',
      (WidgetTester tester) async {
        // Start in Unlocked state
        sessionBloc.emitState(unlockedState);
        final screenKey = GlobalKey<PlaylistScreenWidgetState>();

        await tester.pumpWidget(createHarness(
          tester: tester,
          screenKey: screenKey,
          blocOverride: sessionBloc,
        ));
        await tester.pumpAndSettle();

        // Open Playlist More Menu
        screenKey.currentState!.showPlaylistMoreMenu(loadedState);
        await tester.pumpAndSettle();

        // Must be visible
        expect(find.byKey(const ValueKey('menu_clone_to_private_vault')), findsOneWidget);

        // Adversarial transition: session locks while sheet is actively displayed
        sessionBloc.emitState(lockedState);
        await tester.pumpAndSettle();

        // INVARIANT: menu item must vanish reactively without closing the bottom sheet
        expect(find.byKey(const ValueKey('menu_clone_to_private_vault')), findsNothing);
        expect(find.byType(BottomSheet), findsOneWidget);

        // Transition back to Unlocked while still open
        sessionBloc.emitState(unlockedState);
        await tester.pumpAndSettle();

        // INVARIANT: menu item reappears reactively
        expect(find.byKey(const ValueKey('menu_clone_to_private_vault')), findsOneWidget);

        // Transition to Pending Reauth
        sessionBloc.emitState(pendingReauthState);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('menu_clone_to_private_vault')), findsNothing);

        // Transition to Background Grace
        sessionBloc.emitState(backgroundGraceState);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('menu_clone_to_private_vault')), findsOneWidget);

        // Transition to Lockout Cooldown
        sessionBloc.emitState(lockoutState);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('menu_clone_to_private_vault')), findsNothing);

        // Transition to Authenticating
        sessionBloc.emitState(authenticatingState);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('menu_clone_to_private_vault')), findsNothing);

        // Transition to Uninitialized
        sessionBloc.emitState(uninitializedState);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('menu_clone_to_private_vault')), findsNothing);

        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Adversarial Test 2: Dynamic unmounting of "Add to Private Playlists" while Track Options Menu is OPEN',
      (WidgetTester tester) async {
        // Start in Unlocked state
        sessionBloc.emitState(unlockedState);
        final screenKey = GlobalKey<PlaylistScreenWidgetState>();

        await tester.pumpWidget(createHarness(
          tester: tester,
          screenKey: screenKey,
          blocOverride: sessionBloc,
        ));
        await tester.pumpAndSettle();

        // Open Track Options Menu
        screenKey.currentState!.showTrackOptionsMenu(track1);
        await tester.pumpAndSettle();

        // Must be visible initially
        expect(find.byKey(const ValueKey('menu_add_to_private_playlists')), findsOneWidget);

        // Adversarial transition: session locks while sheet is open
        sessionBloc.emitState(lockedState);
        await tester.pumpAndSettle();

        // INVARIANT: item must vanish reactively without closing the bottom sheet
        expect(find.byKey(const ValueKey('menu_add_to_private_playlists')), findsNothing);
        expect(find.byType(BottomSheet), findsOneWidget);

        // Re-unlock
        sessionBloc.emitState(unlockedState);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('menu_add_to_private_playlists')), findsOneWidget);

        // Transition to Pending Reauth
        sessionBloc.emitState(pendingReauthState);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('menu_add_to_private_playlists')), findsNothing);

        // Transition to Grace
        sessionBloc.emitState(backgroundGraceState);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('menu_add_to_private_playlists')), findsOneWidget);

        // Transition to Uninitialized
        sessionBloc.emitState(uninitializedState);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('menu_add_to_private_playlists')), findsNothing);

        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Adversarial Test 3: Rapid consecutive state flapping while menu is open does not crash or corrupt UI',
      (WidgetTester tester) async {
        sessionBloc.emitState(unlockedState);
        final screenKey = GlobalKey<PlaylistScreenWidgetState>();

        await tester.pumpWidget(createHarness(
          tester: tester,
          screenKey: screenKey,
          blocOverride: sessionBloc,
        ));
        await tester.pumpAndSettle();

        screenKey.currentState!.showPlaylistMoreMenu(loadedState);
        await tester.pumpAndSettle();

        // Rapid state flapping in quick succession
        sessionBloc.emitState(lockedState);
        sessionBloc.emitState(unlockedState);
        sessionBloc.emitState(backgroundGraceState);
        sessionBloc.emitState(pendingReauthState);
        sessionBloc.emitState(lockoutState);
        sessionBloc.emitState(authenticatingState);
        sessionBloc.emitState(unlockedState);
        sessionBloc.emitState(lockedState);

        await tester.pumpAndSettle();

        // Final state is locked -> must be invisible
        expect(find.byKey(const ValueKey('menu_clone_to_private_vault')), findsNothing);

        // Flap back to unlocked
        sessionBloc.emitState(unlockedState);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('menu_clone_to_private_vault')), findsOneWidget);

        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Adversarial Test 4: Exhaustive matrix verification for all 7 states + null on both menus',
      (WidgetTester tester) async {
        final screenKey = GlobalKey<PlaylistScreenWidgetState>();

        final allStates = <VaultSessionState, bool>{
          unlockedState: true,
          backgroundGraceState: true,
          lockedState: false,
          uninitializedState: false,
          lockoutState: false,
          authenticatingState: false,
          pendingReauthState: false,
        };

        await tester.pumpWidget(createHarness(
          tester: tester,
          screenKey: screenKey,
          blocOverride: sessionBloc,
        ));
        await tester.pumpAndSettle();

        for (final entry in allStates.entries) {
          final state = entry.key;
          final expectedVisible = entry.value;

          sessionBloc.emitState(state);
          await tester.pump();

          // 1. Check Playlist More Menu
          screenKey.currentState!.showPlaylistMoreMenu(loadedState);
          await tester.pumpAndSettle();

          if (expectedVisible) {
            expect(
              find.byKey(const ValueKey('menu_clone_to_private_vault')),
              findsOneWidget,
              reason: 'State $state MUST render Clone to Private Vault',
            );
          } else {
            expect(
              find.byKey(const ValueKey('menu_clone_to_private_vault')),
              findsNothing,
              reason: 'State $state MUST NOT render Clone to Private Vault',
            );
          }

          Navigator.of(tester.element(find.byType(BottomSheet))).pop();
          await tester.pumpAndSettle();

          // 2. Check Track Options Menu
          screenKey.currentState!.showTrackOptionsMenu(track1);
          await tester.pumpAndSettle();

          if (expectedVisible) {
            expect(
              find.byKey(const ValueKey('menu_add_to_private_playlists')),
              findsOneWidget,
              reason: 'State $state MUST render Add to Private Playlists',
            );
          } else {
            expect(
              find.byKey(const ValueKey('menu_add_to_private_playlists')),
              findsNothing,
              reason: 'State $state MUST NOT render Add to Private Playlists',
            );
          }

          Navigator.of(tester.element(find.byType(BottomSheet))).pop();
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
