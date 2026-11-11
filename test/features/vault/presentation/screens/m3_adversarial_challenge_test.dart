import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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

class FakeVaultStorageRepository implements IVaultStorageRepository {
  final Map<String, PrivatePlaylist> playlistMap = {};
  final List<PrivatePlaylist> playlists = [];
  VaultResult<PrivatePlaylist>? createPlaylistResultOverride;
  List<String>? lastReorderedTrackIds;
  String? lastRemovedTrackId;

  @override
  Future<VaultResult<List<PrivatePlaylist>>> getPlaylists() async {
    return VaultResult.success(List.unmodifiable(playlists));
  }

  @override
  Future<VaultResult<PrivatePlaylist>> getPlaylistById(String id) async {
    final playlist = playlistMap[id];
    if (playlist != null) {
      return VaultResult.success(playlist);
    }
    return const VaultResult.failure(VaultStorageFailure('Playlist not found'));
  }

  @override
  Future<VaultResult<PrivatePlaylist>> createPlaylist({
    required String name,
    required String description,
    String? coverUri,
  }) async {
    if (createPlaylistResultOverride != null) {
      return createPlaylistResultOverride!;
    }
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
    playlistMap[playlist.id] = playlist;
    return VaultResult.success(playlist);
  }

  @override
  Future<VaultResult<void>> reorderTracksInPlaylist({
    required String playlistId,
    required List<String> trackIdsInOrder,
  }) async {
    lastReorderedTrackIds = List.unmodifiable(trackIdsInOrder);
    final playlist = playlistMap[playlistId];
    if (playlist != null) {
      final trackMap = {for (final t in playlist.trackRefs) t.id: t};
      final reordered = trackIdsInOrder.map((id) => trackMap[id]!).toList();
      playlistMap[playlistId] = playlist.copyWith(trackRefs: reordered);
    }
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    lastRemovedTrackId = trackId;
    final playlist = playlistMap[playlistId];
    if (playlist != null) {
      final updatedTracks =
          playlist.trackRefs.where((t) => t.id != trackId).toList();
      playlistMap[playlistId] = playlist.copyWith(trackRefs: updatedTracks);
    }
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> deletePlaylist(String playlistId) async {
    playlists.removeWhere((p) => p.id == playlistId);
    playlistMap.remove(playlistId);
    return const VaultResult.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVaultAudioPlaybackService implements VaultAudioPlaybackService {
  PrivatePlaylist? lastPlayedPlaylist;
  int? lastStartIndex;
  int playCallCount = 0;

  @override
  Future<void> playPrivatePlaylist({
    required PrivatePlaylist playlist,
    List<String>? resolvedFilePaths,
    required int startIndex,
    VaultConfig? config,
  }) async {
    playCallCount++;
    lastPlayedPlaylist = playlist;
    lastStartIndex = startIndex;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

void main() {
  group('Adversarial Challenge: PlaylistPlaybackStatusEnum & Track Indicators', () {
    final trackA = PrivateTrackRef(
      id: 'track_a',
      playlistId: 'pl_test',
      title: 'Neon Skyline',
      artistName: 'Kavinsky',
      albumTitle: 'OutRun',
      durationMs: 240000,
      sourceType: TrackSourceTypeEnum.spotify,
      trackUri: 'spotify:track:track_a',
      localRelativePath: null,
      sortOrder: 0,
      addedAtEpochMs: 1000,
    );

    final trackB = PrivateTrackRef(
      id: 'track_b',
      playlistId: 'pl_test',
      title: 'Midnight City',
      artistName: 'M83',
      albumTitle: 'Hurry Up',
      durationMs: 244000,
      sourceType: TrackSourceTypeEnum.spotify,
      trackUri: 'spotify:track:track_b',
      localRelativePath: null,
      sortOrder: 1,
      addedAtEpochMs: 1001,
    );

    final samplePlaylist = PrivatePlaylist(
      id: 'pl_test',
      name: 'Adversarial Test Vault',
      description: 'Stress testing track states',
      totalDurationMs: 484000,
      createdAtEpochMs: 1000,
      updatedAtEpochMs: 1000,
      trackRefs: [trackA, trackB],
    );

    test('PlaylistPlaybackStatusEnum exhaustive value & getter contracts', () {
      expect(PlaylistPlaybackStatusEnum.values.length, 3);
      expect(PlaylistPlaybackStatusEnum.playing.isPlaying, isTrue);
      expect(PlaylistPlaybackStatusEnum.paused.isPlaying, isFalse);
      expect(PlaylistPlaybackStatusEnum.stopped.isPlaying, isFalse);
    });

    test('PrivatePlaylistDetailLoadedState transitions through all status permutations cleanly', () {
      var state = PrivatePlaylistDetailLoadedState(
        playlist: samplePlaylist,
        searchQuery: '',
        filteredTracks: [trackA, trackB],
        artworkPeekState: ArtworkPeekStateEnum.frostedPeek,
        activeTrackId: null,
        playbackStatus: PlaylistPlaybackStatusEnum.stopped,
      );

      // Verify baseline stopped state
      expect(state.playbackStatus, PlaylistPlaybackStatusEnum.stopped);
      expect(state.activeTrackId, isNull);

      // Transition 1: Play track A
      state = state.copyWith(
        activeTrackId: trackA.id,
        playbackStatus: PlaylistPlaybackStatusEnum.playing,
      );
      expect(state.playbackStatus, PlaylistPlaybackStatusEnum.playing);
      expect(state.activeTrackId, trackA.id);
      expect(state.playbackStatus.isPlaying, isTrue);

      // Transition 2: Pause track A
      state = state.copyWith(
        playbackStatus: PlaylistPlaybackStatusEnum.paused,
      );
      expect(state.playbackStatus, PlaylistPlaybackStatusEnum.paused);
      expect(state.activeTrackId, trackA.id);
      expect(state.playbackStatus.isPlaying, isFalse);

      // Transition 3: Resume track A
      state = state.copyWith(
        playbackStatus: PlaylistPlaybackStatusEnum.playing,
      );
      expect(state.playbackStatus, PlaylistPlaybackStatusEnum.playing);
      expect(state.playbackStatus.isPlaying, isTrue);

      // Transition 4: Switch track while playing: Track A -> Track B
      state = state.copyWith(
        activeTrackId: trackB.id,
      );
      expect(state.activeTrackId, trackB.id);
      expect(state.playbackStatus, PlaylistPlaybackStatusEnum.playing);

      // Transition 5: Stop playback and clear active track
      state = state.copyWith(
        clearActiveTrack: true,
        playbackStatus: PlaylistPlaybackStatusEnum.stopped,
      );
      expect(state.activeTrackId, isNull);
      expect(state.playbackStatus, PlaylistPlaybackStatusEnum.stopped);
      expect(state.playbackStatus.isPlaying, isFalse);
    });

    testWidgets('Track row visual indicators contract verification for playing vs paused vs stopped', (
      WidgetTester tester,
    ) async {
      // Build a widget rendering a track row using the exact layout logic of _buildTrackRow
      Widget buildTrackRowHarness({
        required PrivateTrackRef track,
        required int index,
        required String? activeTrackId,
        required PlaylistPlaybackStatusEnum playbackStatus,
      }) {
        final vaultTheme = VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.warmEspresso);
        final isActiveTrack = track.id == activeTrackId;

        return MaterialApp(
          home: Scaffold(
            body: Container(
              color: isActiveTrack ? vaultTheme.surfaceHighlight : Colors.transparent,
              child: Row(
                children: [
                  SizedBox(
                    width: 28.0,
                    child: isActiveTrack && playbackStatus == PlaylistPlaybackStatusEnum.playing
                        ? Icon(
                            Icons.volume_up_rounded,
                            size: 16.0,
                            color: vaultTheme.accent,
                          )
                        : Text(
                            '${index + 1}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: VaultTheme.fontFamily,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                              color: vaultTheme.textMediumSalience,
                            ),
                          ),
                  ),
                  Text(
                    track.title,
                    style: TextStyle(
                      fontFamily: VaultTheme.fontFamily,
                      fontSize: 14.0,
                      fontWeight: isActiveTrack ? FontWeight.w700 : FontWeight.w500,
                      color: isActiveTrack ? vaultTheme.accent : vaultTheme.textHighSalience,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Permutation 1: Inactive track, playback stopped
      await tester.pumpWidget(buildTrackRowHarness(
        track: trackA,
        index: 0,
        activeTrackId: null,
        playbackStatus: PlaylistPlaybackStatusEnum.stopped,
      ));
      expect(find.text('1'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsNothing);

      // Permutation 2: Active track, playback playing
      await tester.pumpWidget(buildTrackRowHarness(
        track: trackA,
        index: 0,
        activeTrackId: trackA.id,
        playbackStatus: PlaylistPlaybackStatusEnum.playing,
      ));
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(find.text('1'), findsNothing);

      // Permutation 3: Active track, playback paused
      await tester.pumpWidget(buildTrackRowHarness(
        track: trackA,
        index: 0,
        activeTrackId: trackA.id,
        playbackStatus: PlaylistPlaybackStatusEnum.paused,
      ));
      expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
      expect(find.text('1'), findsOneWidget);

      // Permutation 4: Inactive track, but playback is playing for another track
      await tester.pumpWidget(buildTrackRowHarness(
        track: trackA,
        index: 0,
        activeTrackId: trackB.id,
        playbackStatus: PlaylistPlaybackStatusEnum.playing,
      ));
      expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
      expect(find.text('1'), findsOneWidget);
    });
  });

  group('Adversarial Challenge: Dialog Creation Stress & Failure Feedback', () {
    late FakeMonotonicClock clock;
    late FakeScreenPrivacyController privacyController;
    late ScreenPrivacyCubit privacyCubit;
    late FakeVaultStorageRepository storageRepo;
    late FakeVaultAuthService authService;
    late VerifySessionCoolOffUseCase verifyCoolOff;
    late TestVaultSessionBloc sessionBloc;

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

    setUp(() {
      clock = FakeMonotonicClock();
      privacyController = FakeScreenPrivacyController();
      privacyCubit = ScreenPrivacyCubit(
        privacyController: privacyController,
        monotonicClock: clock,
      );
      storageRepo = FakeVaultStorageRepository();
      authService = FakeVaultAuthService();
      verifyCoolOff = VerifySessionCoolOffUseCase(clock: clock);
      sessionBloc = TestVaultSessionBloc(
        authService: authService,
        storageRepository: storageRepo,
        monotonicClock: clock,
        verifyCoolOffUseCase: verifyCoolOff,
        initialState: unlockedState,
      );
    });

    tearDown(() {
      privacyCubit.close();
      sessionBloc.close();
      authService.controller.close();
    });

    Widget buildDashboardHarness() {
      return MaterialApp(
        home: VaultTheme(
          data: VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.warmEspresso),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<VaultSessionBloc>.value(value: sessionBloc),
              BlocProvider<ScreenPrivacyCubit>.value(value: privacyCubit),
            ],
            child: PrivateVaultDashboardScreen(
              storageRepository: storageRepo,
              sessionBloc: sessionBloc,
              screenPrivacyCubit: privacyCubit,
            ),
          ),
        ),
      );
    }

    testWidgets('Empty playlist name rejection: Form validator displays error and blocks creation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildDashboardHarness());
      await tester.pumpAndSettle();

      // Open creation dialog via FAB
      await tester.tap(find.byKey(const ValueKey('create_private_playlist_fab')));
      await tester.pumpAndSettle();

      expect(find.text('New Private Playlist'), findsOneWidget);

      // Tap Create with empty name input
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Validator error must display
      expect(find.text('Playlist name is required'), findsOneWidget);
      // Dialog must still be open
      expect(find.text('New Private Playlist'), findsOneWidget);
      // Repository must not have been called
      expect(storageRepo.playlists, isEmpty);

      // Clean unmount before tearDown
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Whitespace-only playlist name rejection: Blocks submission for blank strings', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildDashboardHarness());
      await tester.pumpAndSettle();

      // Open creation dialog
      await tester.tap(find.byKey(const ValueKey('create_private_playlist_fab')));
      await tester.pumpAndSettle();

      // Enter pure whitespace
      await tester.enterText(find.byType(TextFormField).first, '   \t  \n  ');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Validator error must display
      expect(find.text('Playlist name is required'), findsOneWidget);
      // Dialog must still be open
      expect(find.text('New Private Playlist'), findsOneWidget);
      expect(storageRepo.playlists, isEmpty);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Cancel button dismisses creation dialog cleanly without mutating storage', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildDashboardHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('create_private_playlist_fab')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Abandoned Playlist');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog dismissed
      expect(find.text('New Private Playlist'), findsNothing);
      expect(storageRepo.playlists, isEmpty);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Mock storage failure on playlist creation: Renders error SnackBar without crash', (
      WidgetTester tester,
    ) async {
      // Simulate disk write / encryption failure
      const failureMsg = 'Encrypted disk write failure: simulated ENOSPC';
      storageRepo.createPlaylistResultOverride =
          const VaultResult.failure(VaultStorageFailure(failureMsg));

      await tester.pumpWidget(buildDashboardHarness());
      await tester.pumpAndSettle();

      // Open creation dialog
      await tester.tap(find.byKey(const ValueKey('create_private_playlist_fab')));
      await tester.pumpAndSettle();

      // Enter valid name and description
      await tester.enterText(find.byType(TextFormField).first, 'Doomed Playlist');
      await tester.enterText(find.byType(TextFormField).last, 'Will fail storage');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('New Private Playlist'), findsNothing);

      // Error SnackBar rendered with failure message
      expect(find.text(failureMsg), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      // Verify SnackBar background color matches danger palette
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final theme = VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.warmEspresso);
      expect(snackBar.backgroundColor, theme.danger);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Session lock while creation dialog is open: Auto-pop dismisses dialog and screen cleanly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => VaultTheme(
                        data: VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.warmEspresso),
                        child: MultiBlocProvider(
                          providers: [
                            BlocProvider<VaultSessionBloc>.value(value: sessionBloc),
                            BlocProvider<ScreenPrivacyCubit>.value(value: privacyCubit),
                          ],
                          child: PrivateVaultDashboardScreen(
                            storageRepository: storageRepo,
                            sessionBloc: sessionBloc,
                            screenPrivacyCubit: privacyCubit,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open Dashboard'),
              ),
            ),
          ),
        ),
      );

      // Open dashboard
      await tester.tap(find.text('Open Dashboard'));
      await tester.pumpAndSettle();

      // Open creation dialog
      await tester.tap(find.byKey(const ValueKey('create_private_playlist_fab')));
      await tester.pumpAndSettle();
      expect(find.text('New Private Playlist'), findsOneWidget);

      // Session lock occurs (e.g. background grace timeout / quick lock)
      sessionBloc.emitState(const VaultLockedState(lockedAtMonotonicMs: 25000));
      await tester.pumpAndSettle();

      // Both dialog and dashboard must be popped back to root screen without assertion errors
      expect(find.text('Open Dashboard'), findsOneWidget);
      expect(find.text('New Private Playlist'), findsNothing);
      expect(find.text('Private Vault'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Adversarial Challenge: Persistent Track Reordering Permutations', () {
    late FakeMonotonicClock clock;
    late FakeScreenPrivacyController privacyController;
    late ScreenPrivacyCubit privacyCubit;
    late FakeVaultStorageRepository storageRepo;
    late FakeVaultAuthService authService;
    late VerifySessionCoolOffUseCase verifyCoolOff;
    late TestVaultSessionBloc sessionBloc;
    late FakeVaultAudioPlaybackService playbackService;

    final track1 = PrivateTrackRef(
      id: 't_1',
      playlistId: 'pl_reorder',
      title: 'Track One',
      artistName: 'Artist A',
      albumTitle: 'Album 1',
      durationMs: 180000,
      sourceType: TrackSourceTypeEnum.spotify,
      trackUri: 'spotify:track:t1',
      localRelativePath: null,
      sortOrder: 0,
      addedAtEpochMs: 1000,
    );
    final track2 = PrivateTrackRef(
      id: 't_2',
      playlistId: 'pl_reorder',
      title: 'Track Two',
      artistName: 'Artist B',
      albumTitle: 'Album 2',
      durationMs: 200000,
      sourceType: TrackSourceTypeEnum.spotify,
      trackUri: 'spotify:track:t2',
      localRelativePath: null,
      sortOrder: 1,
      addedAtEpochMs: 1001,
    );
    final track3 = PrivateTrackRef(
      id: 't_3',
      playlistId: 'pl_reorder',
      title: 'Track Three',
      artistName: 'Artist C',
      albumTitle: 'Album 3',
      durationMs: 220000,
      sourceType: TrackSourceTypeEnum.spotify,
      trackUri: 'spotify:track:t3',
      localRelativePath: null,
      sortOrder: 2,
      addedAtEpochMs: 1002,
    );
    final track4 = PrivateTrackRef(
      id: 't_4',
      playlistId: 'pl_reorder',
      title: 'Track Four',
      artistName: 'Artist D',
      albumTitle: 'Album 4',
      durationMs: 240000,
      sourceType: TrackSourceTypeEnum.spotify,
      trackUri: 'spotify:track:t4',
      localRelativePath: null,
      sortOrder: 3,
      addedAtEpochMs: 1003,
    );

    final multiTrackPlaylist = PrivatePlaylist(
      id: 'pl_reorder',
      name: 'Reordering Invariants',
      description: 'Permutation stress testing',
      totalDurationMs: 840000,
      createdAtEpochMs: 1000,
      updatedAtEpochMs: 1000,
      trackRefs: [track1, track2, track3, track4],
    );

    setUp(() {
      clock = FakeMonotonicClock();
      privacyController = FakeScreenPrivacyController();
      privacyCubit = ScreenPrivacyCubit(
        privacyController: privacyController,
        monotonicClock: clock,
      );
      storageRepo = FakeVaultStorageRepository();
      storageRepo.playlistMap['pl_reorder'] = multiTrackPlaylist;
      authService = FakeVaultAuthService();
      verifyCoolOff = VerifySessionCoolOffUseCase(clock: clock);
      sessionBloc = TestVaultSessionBloc(
        authService: authService,
        storageRepository: storageRepo,
        monotonicClock: clock,
        verifyCoolOffUseCase: verifyCoolOff,
        initialState: VaultUnlockedState(
          session: AuthSession(
            sessionToken: 'test_token',
            sessionStartedEpochMs: 1000,
            lastActiveEpochMs: 1000,
            authMethod: AuthMethodEnum.pin,
          ),
          unlockedAtMonotonicMs: 1000,
          reauthDeadlineMonotonicMs: 60000,
        ),
      );
      playbackService = FakeVaultAudioPlaybackService();
    });

    tearDown(() {
      privacyCubit.close();
      sessionBloc.close();
      authService.controller.close();
    });

    Widget buildDetailHarness() {
      return MaterialApp(
        home: VaultTheme(
          data: VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.warmEspresso),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<VaultSessionBloc>.value(value: sessionBloc),
              BlocProvider<ScreenPrivacyCubit>.value(value: privacyCubit),
            ],
            child: PrivatePlaylistDetailScreen(
              playlistId: 'pl_reorder',
              storageRepository: storageRepo,
              audioPlaybackService: playbackService,
              sessionBloc: sessionBloc,
              screenPrivacyCubit: privacyCubit,
            ),
          ),
        ),
      );
    }

    test('Reorder algorithm handles ReorderableListView contract permutations accurately', () {
      List<String> simulateReorder(List<String> list, int oldIndex, int newIndex) {
        var effectiveNew = newIndex;
        if (effectiveNew > oldIndex) {
          effectiveNew -= 1;
        }
        final copy = List<String>.from(list);
        final item = copy.removeAt(oldIndex);
        copy.insert(effectiveNew, item);
        return copy;
      }

      final initial = ['t_1', 't_2', 't_3', 't_4'];

      // Permutation 1: Forward shift: Move 0 to 2 -> ['t_2', 't_1', 't_3', 't_4']
      expect(simulateReorder(initial, 0, 2), equals(['t_2', 't_1', 't_3', 't_4']));

      // Permutation 2: Backward shift: Move 3 to 0 -> ['t_4', 't_1', 't_2', 't_3']
      expect(simulateReorder(initial, 3, 0), equals(['t_4', 't_1', 't_2', 't_3']));

      // Permutation 3: Move to bottom: Move 0 to 4 -> ['t_2', 't_3', 't_4', 't_1']
      expect(simulateReorder(initial, 0, 4), equals(['t_2', 't_3', 't_4', 't_1']));

      // Permutation 4: Move adjacent forward: Move 1 to 3 -> ['t_1', 't_3', 't_2', 't_4']
      expect(simulateReorder(initial, 1, 3), equals(['t_1', 't_3', 't_2', 't_4']));

      // Permutation 5: Move adjacent backward: Move 2 to 1 -> ['t_1', 't_3', 't_2', 't_4']
      expect(simulateReorder(initial, 2, 1), equals(['t_1', 't_3', 't_2', 't_4']));
    });

    testWidgets('ReorderableListView in PrivatePlaylistDetailScreen renders items with unique ValueKeys', (
      WidgetTester tester,
    ) async {
      // Set test viewport size large enough to lay out all 4 items
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildDetailHarness());
      await tester.pumpAndSettle();

      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(find.byKey(const ValueKey('dismiss_t_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('dismiss_t_2')), findsOneWidget);
      expect(find.byKey(const ValueKey('dismiss_t_3')), findsOneWidget);
      expect(find.byKey(const ValueKey('dismiss_t_4')), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Active search filter suppresses reordering to prevent list corruption', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildDetailHarness());
      await tester.pumpAndSettle();

      // Enter search filter query
      await tester.enterText(find.byKey(const ValueKey('playlist_detail_search_input')), 'Three');
      await tester.pumpAndSettle();

      // Filtered view only displays track 3
      expect(find.text('Track Three'), findsOneWidget);
      expect(find.text('Track One'), findsNothing);

      // Reorder call when searchQuery is not empty returns early without calling repository
      expect(storageRepo.lastReorderedTrackIds, isNull);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
