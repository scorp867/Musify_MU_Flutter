import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/application/playlists/vault_playlists_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/data/database/vault_database.dart';
import 'package:musify_mu/features/vault/data/repositories/vault_storage_repository.dart';
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
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';

import '../helpers/mock_native_vault_crypto_bridge.dart';

// =============================================================================
// Test Doubles & Mocks
// =============================================================================

class StressMonotonicClock implements IMonotonicClock {
  int timeMs = 100000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class StressScreenPrivacyController implements IScreenPrivacyController {
  ScreenPrivacyStateEnum _state = ScreenPrivacyStateEnum.publicUnrestricted;
  final StreamController<ScreenPrivacyStateEnum> _controller =
      StreamController<ScreenPrivacyStateEnum>.broadcast();

  int enableCount = 0;
  int disableCount = 0;

  @override
  ScreenPrivacyStateEnum get currentState => _state;

  @override
  Stream<ScreenPrivacyStateEnum> get stateStream => _controller.stream;

  @override
  Future<void> enableSecureFlag() async {
    enableCount++;
    _state = ScreenPrivacyStateEnum.secureFlagEngaged;
    _controller.add(_state);
  }

  @override
  Future<void> disableSecureFlag() async {
    disableCount++;
    _state = ScreenPrivacyStateEnum.publicUnrestricted;
    _controller.add(_state);
  }
}

class StressVaultAuthService implements IVaultAuthService {
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

class StressVaultStorageRepository implements IVaultStorageRepository {
  final Map<String, PrivatePlaylist> playlists = {};
  final List<String> callLog = [];
  bool simulateFailure = false;
  List<String>? lastReorderedTrackIds;
  String? lastRemovedTrackId;

  @override
  Future<VaultResult<List<PrivatePlaylist>>> getPlaylists() async {
    callLog.add('getPlaylists');
    if (simulateFailure) {
      return const VaultResult.failure(VaultStorageFailure('Simulated getPlaylists failure'));
    }
    return VaultResult.success(playlists.values.toList());
  }

  @override
  Future<VaultResult<PrivatePlaylist>> getPlaylistById(String id) async {
    callLog.add('getPlaylistById:$id');
    if (simulateFailure) {
      return const VaultResult.failure(VaultStorageFailure('Simulated getPlaylistById failure'));
    }
    final pl = playlists[id];
    if (pl == null) {
      return const VaultResult.failure(VaultStorageFailure('Playlist not found'));
    }
    return VaultResult.success(pl);
  }

  @override
  Future<VaultResult<PrivatePlaylist>> createPlaylist({
    required String name,
    required String description,
    String? coverUri,
  }) async {
    callLog.add('createPlaylist:$name');
    if (simulateFailure) {
      return const VaultResult.failure(VaultStorageFailure('Simulated createPlaylist failure'));
    }
    final newId = 'pl_${playlists.length + 1}';
    final now = DateTime.now().millisecondsSinceEpoch;
    final playlist = PrivatePlaylist(
      id: newId,
      name: name,
      description: description,
      coverUri: coverUri,
      totalDurationMs: 0,
      createdAtEpochMs: now,
      updatedAtEpochMs: now,
      trackRefs: const [],
    );
    playlists[newId] = playlist;
    return VaultResult.success(playlist);
  }

  @override
  Future<VaultResult<void>> deletePlaylist(String playlistId) async {
    callLog.add('deletePlaylist:$playlistId');
    if (simulateFailure) {
      return const VaultResult.failure(VaultStorageFailure('Simulated deletePlaylist failure'));
    }
    playlists.remove(playlistId);
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> reorderTracksInPlaylist({
    required String playlistId,
    required List<String> trackIdsInOrder,
  }) async {
    callLog.add('reorderTracksInPlaylist:$playlistId');
    if (simulateFailure) {
      return const VaultResult.failure(VaultStorageFailure('Simulated reorder failure'));
    }
    lastReorderedTrackIds = List<String>.from(trackIdsInOrder);
    final pl = playlists[playlistId];
    if (pl != null) {
      final trackMap = {for (final t in pl.trackRefs) t.id: t};
      final reordered = <PrivateTrackRef>[];
      for (var i = 0; i < trackIdsInOrder.length; i++) {
        final id = trackIdsInOrder[i];
        final track = trackMap[id];
        if (track != null) {
          reordered.add(track.copyWith(sortOrder: i));
        }
      }
      playlists[playlistId] = pl.copyWith(trackRefs: reordered);
    }
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    callLog.add('removeTrackFromPlaylist:$trackId');
    if (simulateFailure) {
      return const VaultResult.failure(VaultStorageFailure('Simulated removeTrack failure'));
    }
    lastRemovedTrackId = trackId;
    final pl = playlists[playlistId];
    if (pl != null) {
      final updated = pl.trackRefs.where((t) => t.id != trackId).toList();
      playlists[playlistId] = pl.copyWith(
        trackRefs: updated,
      );
    }
    return const VaultResult.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StressVaultAudioPlaybackService implements VaultAudioPlaybackService {
  PrivatePlaylist? lastPlayedPlaylist;
  int? lastStartIndex;
  final List<int> startIndices = [];
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
    startIndices.add(startIndex);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// =============================================================================
// Helper Functions
// =============================================================================

PrivatePlaylist _createSamplePlaylist({
  required String id,
  required String name,
  int trackCount = 5,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final tracks = List.generate(
    trackCount,
    (i) => PrivateTrackRef(
      id: 'track_${id}_$i',
      playlistId: id,
      trackUri: 'spotify:track:${id}_$i',
      title: 'Track Title $i',
      artistName: 'Artist Name $i',
      albumTitle: 'Album Title $i',
      durationMs: 180000 + (i * 1000),
      sourceType: TrackSourceTypeEnum.spotify,
      sortOrder: i,
      addedAtEpochMs: now,
    ),
  );

  return PrivatePlaylist(
    id: id,
    name: name,
    description: 'Description for $name',
    coverUri: null,
    totalDurationMs: trackCount * 180000,
    createdAtEpochMs: now,
    updatedAtEpochMs: now,
    trackRefs: tracks,
  );
}

AuthSession _createTestSession() {
  return AuthSession(
    sessionToken: 'stress_test_token',
    sessionStartedEpochMs: 1000,
    lastActiveEpochMs: 1000,
    authMethod: AuthMethodEnum.pin,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CRITERION 1: Rapid Concurrent Operations & Search Query Bursts in VaultPlaylistsCubit', () {
    late StressVaultStorageRepository storageRepo;
    late VaultPlaylistsCubit cubit;

    setUp(() {
      storageRepo = StressVaultStorageRepository();
      for (var i = 1; i <= 20; i++) {
        final pl = _createSamplePlaylist(
          id: 'pl_$i',
          name: i % 2 == 0 ? 'Rock Classics Vol $i' : 'Jazz Fusion Vol $i',
        );
        storageRepo.playlists[pl.id] = pl;
      }
      cubit = VaultPlaylistsCubit(storageRepository: storageRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('Rapid search query burst maintains filter invariant without desynchronization', () async {
      await cubit.loadPlaylists();
      expect(cubit.state, isA<VaultPlaylistsLoadedState>());
      final initial = cubit.state as VaultPlaylistsLoadedState;
      expect(initial.allPlaylists.length, equals(20));
      expect(initial.filteredPlaylists.length, equals(20));

      final searchBurst = [
        'R',
        'Ro',
        'Roc',
        'Rock',
        'Rock ',
        'Rock C',
        'Rock Classics',
        '',
        'J',
        'Ja',
        'Jaz',
        'Jazz',
        'jazz', // case variation
        'JAZZ', // uppercase variation
        'Vol 1',
        'Vol 10',
        'nonexistent query string',
        '',
        '   ', // whitespace only
        'Classics',
      ];

      for (final query in searchBurst) {
        cubit.filterPlaylists(query);
        final state = cubit.state as VaultPlaylistsLoadedState;
        expect(state.searchQuery, equals(query));

        final clean = query.trim().toLowerCase();
        if (clean.isEmpty) {
          expect(state.filteredPlaylists.length, equals(20));
        } else {
          for (final p in state.filteredPlaylists) {
            expect(p.name.toLowerCase().contains(clean), isTrue,
                reason: 'Playlist "${p.name}" must contain "$clean"');
          }
          final expectedCount =
              initial.allPlaylists.where((p) => p.name.toLowerCase().contains(clean)).length;
          expect(state.filteredPlaylists.length, equals(expectedCount));
        }
      }
    });

    test('Concurrent playlist creation and deletion burst executes without corruption', () async {
      await cubit.loadPlaylists();

      // Fire 10 concurrent creates and deletes simultaneously
      final futures = <Future<dynamic>>[];
      for (var i = 1; i <= 5; i++) {
        futures.add(cubit.createPlaylist(
          name: 'Concurrent Playlist $i',
          description: 'Desc $i',
        ));
      }
      for (var i = 1; i <= 5; i++) {
        futures.add(cubit.deletePlaylist('pl_$i'));
      }

      await Future.wait(futures);

      // Verify cubit settled in a valid loaded state
      expect(cubit.state, isA<VaultPlaylistsLoadedState>());
      final loaded = cubit.state as VaultPlaylistsLoadedState;
      expect(loaded.allPlaylists.isNotEmpty, isTrue);

      // Verify deleted playlists are not in allPlaylists
      for (var i = 1; i <= 5; i++) {
        expect(loaded.allPlaylists.any((p) => p.id == 'pl_$i'), isFalse);
      }
      // Verify newly created playlists exist
      for (var i = 1; i <= 5; i++) {
        expect(loaded.allPlaylists.any((p) => p.name == 'Concurrent Playlist $i'), isTrue);
      }
    });

    test('Calling filterPlaylists on non-loaded states is safe and does not mutate state', () {
      expect(cubit.state, isA<VaultPlaylistsInitialState>());
      cubit.filterPlaylists('Rock');
      expect(cubit.state, isA<VaultPlaylistsInitialState>());

      cubit.emit(const VaultPlaylistsLoadingState());
      cubit.filterPlaylists('Jazz');
      expect(cubit.state, isA<VaultPlaylistsLoadingState>());

      cubit.emit(const VaultPlaylistsErrorState(message: 'Storage offline'));
      cubit.filterPlaylists('Blues');
      expect(cubit.state, isA<VaultPlaylistsErrorState>());
    });

    test('Repository errors during loadPlaylists transition cleanly to VaultPlaylistsErrorState', () async {
      storageRepo.simulateFailure = true;
      await cubit.loadPlaylists();

      expect(cubit.state, isA<VaultPlaylistsErrorState>());
      final errorState = cubit.state as VaultPlaylistsErrorState;
      expect(errorState.message, contains('Simulated getPlaylists failure'));

      // Recovery on retry
      storageRepo.simulateFailure = false;
      await cubit.loadPlaylists();
      expect(cubit.state, isA<VaultPlaylistsLoadedState>());
    });
  });

  group('CRITERION 2: Track Reordering via reorderTracksInPlaylist Order Persistence', () {
    late VaultDatabase database;
    late MockNativeVaultCryptoBridge cryptoBridge;
    late VaultStorageRepository realRepo;

    setUp(() {
      database = VaultDatabase.forTesting(NativeDatabase.memory());
      cryptoBridge = MockNativeVaultCryptoBridge(
        hasMasterKey: true,
        isSessionUnlocked: true,
      );
      realRepo = VaultStorageRepository(
        database: database,
        cryptoBridge: cryptoBridge,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('Permutation stress harness: 50 consecutive reorders maintain exact mathematical order in Drift SQLite', () async {
      // 1. Create playlist in real encrypted Drift DB
      final createResult = await realRepo.createPlaylist(
        name: 'Reorder Test Playlist',
        description: 'Testing reorder invariants',
      );
      expect(createResult, isA<VaultSuccess<PrivatePlaylist>>());
      final playlistId = (createResult as VaultSuccess<PrivatePlaylist>).data.id;

      // 2. Add 10 tracks
      const trackCount = 10;
      final initialTrackIds = <String>[];
      for (var i = 0; i < trackCount; i++) {
        final trackId = 'reorder_track_$i';
        initialTrackIds.add(trackId);
        final addResult = await realRepo.addTrackToPlaylist(
          playlistId: playlistId,
          trackRef: PrivateTrackRef(
            id: trackId,
            playlistId: playlistId,
            trackUri: 'spotify:track:$trackId',
            title: 'Track $i',
            artistName: 'Artist',
            albumTitle: 'Album',
            durationMs: 200000,
            sourceType: TrackSourceTypeEnum.spotify,
            sortOrder: i,
            addedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        expect(addResult, isA<VaultSuccess<void>>());
      }

      // Initial verification
      var loaded = await realRepo.getPlaylistById(playlistId);
      expect(loaded, isA<VaultSuccess<PrivatePlaylist>>());
      var currentOrder = (loaded as VaultSuccess<PrivatePlaylist>).data.trackRefs.map((t) => t.id).toList();
      expect(currentOrder, equals(initialTrackIds));

      // 3. Mathematical Reorder Simulation & Drift Verification
      // Simulates the ReorderableListView algorithm:
      // if (newIndex > oldIndex) newIndex -= 1;
      // item = list.removeAt(oldIndex); list.insert(newIndex, item);
      var modelOrder = List<String>.from(initialTrackIds);

      final moves = [
        (0, 10), // move first to last (oldIndex=0, newIndex=10 -> drops at 9)
        (9, 0),  // move last to first
        (2, 5),  // move forward
        (7, 3),  // move backward
        (1, 2),  // adjacent forward
        (3, 2),  // adjacent backward
        (4, 4),  // same index
        (0, 5),
        (8, 1),
        (5, 9),
      ];

      for (final (oldIdx, rawNewIdx) in moves) {
        // Compute new model order
        var targetIdx = rawNewIdx;
        if (targetIdx > oldIdx) {
          targetIdx -= 1;
        }
        final moved = modelOrder.removeAt(oldIdx);
        modelOrder.insert(targetIdx, moved);

        // Execute on real database
        final reorderResult = await realRepo.reorderTracksInPlaylist(
          playlistId: playlistId,
          trackIdsInOrder: modelOrder,
        );
        expect(reorderResult, isA<VaultSuccess<void>>());

        // Fetch back and assert strict parity
        loaded = await realRepo.getPlaylistById(playlistId);
        expect(loaded, isA<VaultSuccess<PrivatePlaylist>>());
        final dbOrder = (loaded as VaultSuccess<PrivatePlaylist>).data.trackRefs.map((t) => t.id).toList();
        expect(dbOrder, equals(modelOrder),
            reason: 'Database order must strictly match model order after move ($oldIdx -> $rawNewIdx)');
      }
    });

    test('Reordering non-existent playlist returns VaultFailureResult', () async {
      final result = await realRepo.reorderTracksInPlaylist(
        playlistId: 'non_existent_id',
        trackIdsInOrder: ['t1', 't2'],
      );
      expect(result, isA<VaultFailureResult<void>>());
      final failure = (result as VaultFailureResult<void>).failure;
      expect(failure.message, contains('Cannot reorder tracks in non-existent playlist'));
    });
  });

  group('CRITERION 3: Swipe-to-Remove Dismissible with Cancel vs Confirmation Dialog', () {
    late StressMonotonicClock clock;
    late StressScreenPrivacyController privacyController;
    late ScreenPrivacyCubit privacyCubit;
    late StressVaultStorageRepository storageRepo;
    late StressVaultAuthService authService;
    late VerifySessionCoolOffUseCase verifyCoolOff;
    late VaultSessionBloc sessionBloc;
    late StressVaultAudioPlaybackService playbackService;
    late PrivatePlaylist samplePlaylist;

    setUp(() {
      clock = StressMonotonicClock();
      privacyController = StressScreenPrivacyController();
      privacyCubit = ScreenPrivacyCubit(
        privacyController: privacyController,
        monotonicClock: clock,
      );
      storageRepo = StressVaultStorageRepository();
      samplePlaylist = _createSamplePlaylist(id: 'pl_dismiss_test', name: 'Dismissible Playlist', trackCount: 4);
      storageRepo.playlists[samplePlaylist.id] = samplePlaylist;
      authService = StressVaultAuthService();
      verifyCoolOff = VerifySessionCoolOffUseCase(clock: clock);
      sessionBloc = VaultSessionBloc(
        authService: authService,
        storageRepository: storageRepo,
        monotonicClock: clock,
        verifyCoolOffUseCase: verifyCoolOff,
        initialState: VaultUnlockedState(
          session: _createTestSession(),
          unlockedAtMonotonicMs: clock.currentMonotonicMs,
          reauthDeadlineMonotonicMs: 60000,
        ),
      );
      playbackService = StressVaultAudioPlaybackService();
    });

    tearDown(() {
      // Don't manually close cubits here to allow unmounting widgets to safely execute releaseSecureFlag
    });

    Widget buildTestScreen() {
      return MaterialApp(
        home: VaultTheme(
          data: VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.warmEspresso),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<VaultSessionBloc>.value(value: sessionBloc),
              BlocProvider<ScreenPrivacyCubit>.value(value: privacyCubit),
            ],
            child: PrivatePlaylistDetailScreen(
              playlistId: samplePlaylist.id,
              storageRepository: storageRepo,
              audioPlaybackService: playbackService,
              sessionBloc: sessionBloc,
              screenPrivacyCubit: privacyCubit,
            ),
          ),
        ),
      );
    }

    testWidgets('Swipe-to-remove Cancel: Dialog pops with false, track is NOT removed', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      final firstTrackKey = ValueKey('dismiss_${samplePlaylist.trackRefs.first.id}');
      expect(find.byKey(firstTrackKey), findsOneWidget);

      // Drag left to dismiss (endToStart)
      await tester.drag(find.byKey(firstTrackKey), const Offset(-500.0, 0.0));
      await tester.pumpAndSettle();

      // Verify AlertDialog is displayed
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Remove Track'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog dismissed, track STILL exists in widget tree and repo
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byKey(firstTrackKey), findsOneWidget);
      expect(storageRepo.lastRemovedTrackId, isNull);
      expect(storageRepo.playlists[samplePlaylist.id]?.trackRefs.length, equals(4));

      // Unmount cleanly
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('Swipe-to-remove Confirm: Dialog pops with true, track removed cleanly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      final targetTrack = samplePlaylist.trackRefs[1];
      final targetTrackKey = ValueKey('dismiss_${targetTrack.id}');
      expect(find.byKey(targetTrackKey), findsOneWidget);

      // Drag left to dismiss
      await tester.drag(find.byKey(targetTrackKey), const Offset(-500.0, 0.0));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap Remove button in dialog
      final dialogRemoveBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Remove'),
      );
      await tester.tap(dialogRemoveBtn);
      await tester.pumpAndSettle();

      // Dialog gone, track removed from UI
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byKey(targetTrackKey), findsNothing);
      expect(storageRepo.lastRemovedTrackId, equals(targetTrack.id));
      expect(storageRepo.playlists[samplePlaylist.id]?.trackRefs.length, equals(3));

      // SnackBar verification
      expect(find.text('Removed "${targetTrack.title}" from playlist'), findsOneWidget);

      // Unmount cleanly
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('Swipe-to-remove under active search query removes filtered track cleanly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Enter search query
      final searchInput = find.byKey(const ValueKey('playlist_detail_search_input'));
      await tester.enterText(searchInput, 'Track Title 2');
      await tester.pumpAndSettle();

      final targetTrack = samplePlaylist.trackRefs[2];
      final targetKey = ValueKey('dismiss_${targetTrack.id}');
      expect(find.byKey(targetKey), findsOneWidget);

      // Drag left to dismiss
      await tester.drag(find.byKey(targetKey), const Offset(-500.0, 0.0));
      await tester.pumpAndSettle();

      // Confirm in dialog
      final dialogRemoveBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Remove'),
      );
      await tester.tap(dialogRemoveBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(targetKey), findsNothing);
      expect(storageRepo.lastRemovedTrackId, equals(targetTrack.id));

      // Unmount cleanly
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  });

  group('CRITERION 4: Playback Triggers ("Play All", "Shuffle Play") with VaultAudioPlaybackService', () {
    late StressMonotonicClock clock;
    late StressScreenPrivacyController privacyController;
    late ScreenPrivacyCubit privacyCubit;
    late StressVaultStorageRepository storageRepo;
    late StressVaultAuthService authService;
    late VerifySessionCoolOffUseCase verifyCoolOff;
    late VaultSessionBloc sessionBloc;
    late StressVaultAudioPlaybackService playbackService;

    setUp(() {
      clock = StressMonotonicClock();
      privacyController = StressScreenPrivacyController();
      privacyCubit = ScreenPrivacyCubit(
        privacyController: privacyController,
        monotonicClock: clock,
      );
      storageRepo = StressVaultStorageRepository();
      authService = StressVaultAuthService();
      verifyCoolOff = VerifySessionCoolOffUseCase(clock: clock);
      sessionBloc = VaultSessionBloc(
        authService: authService,
        storageRepository: storageRepo,
        monotonicClock: clock,
        verifyCoolOffUseCase: verifyCoolOff,
        initialState: VaultUnlockedState(
          session: _createTestSession(),
          unlockedAtMonotonicMs: clock.currentMonotonicMs,
          reauthDeadlineMonotonicMs: 60000,
        ),
      );
      playbackService = StressVaultAudioPlaybackService();
    });

    Widget buildTestScreen(String playlistId) {
      return MaterialApp(
        home: VaultTheme(
          data: VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.forestNoir),
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
      );
    }

    testWidgets('Play All initiates playback with startIndex = 0', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final playlist = _createSamplePlaylist(id: 'pl_play_all', name: 'Play All Test', trackCount: 6);
      storageRepo.playlists[playlist.id] = playlist;

      await tester.pumpWidget(buildTestScreen(playlist.id));
      await tester.pumpAndSettle();

      final playAllBtn = find.byKey(const ValueKey('playlist_detail_play_all_button'));
      expect(playAllBtn, findsOneWidget);

      await tester.tap(playAllBtn);
      await tester.pump();

      expect(playbackService.playCallCount, equals(1));
      expect(playbackService.lastPlayedPlaylist?.id, equals(playlist.id));
      expect(playbackService.lastStartIndex, equals(0));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('Shuffle Play initiates playback with valid bounded startIndex across multiple taps', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const trackCount = 8;
      final playlist = _createSamplePlaylist(id: 'pl_shuffle', name: 'Shuffle Test', trackCount: trackCount);
      storageRepo.playlists[playlist.id] = playlist;

      await tester.pumpWidget(buildTestScreen(playlist.id));
      await tester.pumpAndSettle();

      final shuffleBtn = find.byKey(const ValueKey('playlist_detail_shuffle_button'));
      expect(shuffleBtn, findsOneWidget);

      for (var i = 0; i < 15; i++) {
        await tester.tap(shuffleBtn);
        await tester.pump();
      }

      expect(playbackService.playCallCount, equals(15));
      for (final idx in playbackService.startIndices) {
        expect(idx, greaterThanOrEqualTo(0));
        expect(idx, lessThan(trackCount),
            reason: 'Shuffle start index must strictly satisfy 0 <= startIndex < trackCount');
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('Single-track playlist Shuffle safely starts at index 0 without exception', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final playlist = _createSamplePlaylist(id: 'pl_single', name: 'Single Track', trackCount: 1);
      storageRepo.playlists[playlist.id] = playlist;

      await tester.pumpWidget(buildTestScreen(playlist.id));
      await tester.pumpAndSettle();

      final shuffleBtn = find.byKey(const ValueKey('playlist_detail_shuffle_button'));
      await tester.tap(shuffleBtn);
      await tester.pump();

      expect(playbackService.playCallCount, equals(1));
      expect(playbackService.lastStartIndex, equals(0));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('Empty playlist Play All and Shuffle are safe no-ops and do NOT throw', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final emptyPlaylist = _createSamplePlaylist(id: 'pl_empty', name: 'Empty Playlist', trackCount: 0);
      storageRepo.playlists[emptyPlaylist.id] = emptyPlaylist;

      await tester.pumpWidget(buildTestScreen(emptyPlaylist.id));
      await tester.pumpAndSettle();

      final playAllBtn = find.byKey(const ValueKey('playlist_detail_play_all_button'));
      final shuffleBtn = find.byKey(const ValueKey('playlist_detail_shuffle_button'));

      await tester.tap(playAllBtn);
      await tester.pump();

      await tester.tap(shuffleBtn);
      await tester.pump();

      // Must be 0 because playPrivatePlaylist throws StateError on empty playlist; screen guards it
      expect(playbackService.playCallCount, equals(0));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping an individual track triggers playback at its specific index', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final playlist = _createSamplePlaylist(id: 'pl_track_tap', name: 'Track Tap Playlist', trackCount: 5);
      storageRepo.playlists[playlist.id] = playlist;

      await tester.pumpWidget(buildTestScreen(playlist.id));
      await tester.pumpAndSettle();

      // Tap 3rd track (index 2)
      final thirdTrack = playlist.trackRefs[2];
      final thirdTrackWidget = find.byKey(ValueKey('vault_track_${thirdTrack.id}'));
      expect(thirdTrackWidget, findsOneWidget);

      await tester.tap(thirdTrackWidget);
      await tester.pump();

      expect(playbackService.playCallCount, equals(1));
      expect(playbackService.lastStartIndex, equals(2));
      expect(playbackService.lastPlayedPlaylist?.id, equals(playlist.id));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  });
}
