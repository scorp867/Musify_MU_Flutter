import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/local_music/data/datasources/local_tracks_store.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/presentation/widgets/vault_local_song_picker_sheet.dart';

class FakePickerStorageRepository implements IVaultStorageRepository {
  final Map<String, PrivatePlaylist> playlists = {};
  final List<PrivateTrackRef> addedTracks = [];

  @override
  Future<VaultResult<void>> addTrackToPlaylist({
    required String playlistId,
    required PrivateTrackRef trackRef,
  }) async {
    addedTracks.add(trackRef);
    final pl = playlists[playlistId];
    if (pl != null) {
      final updated = List<PrivateTrackRef>.from(pl.trackRefs)..add(trackRef);
      playlists[playlistId] = pl.copyWith(trackRefs: updated);
    }
    return const VaultResult.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePickerIsolationManager implements IVaultMediaIsolationManager {
  final List<String> isolatedPaths = [];

  @override
  Future<IsolatedTrackResult> isolateTrackDetailed({
    required String sourceFilePath,
    required String trackId,
  }) async {
    isolatedPaths.add(sourceFilePath);
    return IsolatedTrackResult(
      isolatedFile: File('/vault_sandbox/$trackId.mp3'),
      relativePath: '$trackId.mp3',
      deletionResult: ScopedStorageDeletionSuccess(sourcePath: sourceFilePath),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocalTracksStore implements LocalTracksStore {
  final List<LocalTrack> tracks;
  final List<Set<int>> deletedSongIdSets = [];

  FakeLocalTracksStore(this.tracks);

  @override
  Future<List<LocalTrack>> getAll() async => tracks;

  @override
  Future<void> deleteBySongIds(Set<int> songIds) async {
    deletedSongIdSets.add(songIds);
    tracks.removeWhere((t) => songIds.contains(t.songId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VaultLocalSongPickerSheet Widget Tests', () {
    late FakePickerStorageRepository storageRepo;
    late FakeLocalTracksStore tracksStore;
    late FakePickerIsolationManager isolationManager;
    late PrivatePlaylist samplePlaylist;

    setUp(() {
      storageRepo = FakePickerStorageRepository();
      isolationManager = FakePickerIsolationManager();

      final track1 = LocalTrack(
        id: 1,
        songId: 101,
        title: 'Song One',
        artist: 'Artist Alpha',
        album: 'Album One',
        dataPath: '/storage/music/song_one.mp3',
        duration: 180000,
        dateModified: 1700000000,
      );

      final track2 = LocalTrack(
        id: 2,
        songId: 102,
        title: 'Song Two',
        artist: 'Artist Beta',
        album: 'Album Two',
        dataPath: '/storage/music/song_two.mp3',
        duration: 240000,
        dateModified: 1700000000,
      );

      tracksStore = FakeLocalTracksStore([track1, track2]);

      final now = DateTime.now().millisecondsSinceEpoch;
      // Playlist already contains 'Song One'
      final existingTrack = PrivateTrackRef(
        id: 'existing_1',
        playlistId: 'pl_picker_test',
        trackUri: '/storage/music/song_one.mp3',
        title: 'Song One',
        artistName: 'Artist Alpha',
        albumTitle: 'Album One',
        durationMs: 180000,
        sourceType: TrackSourceTypeEnum.localReference,
        sortOrder: 0,
        addedAtEpochMs: now,
      );

      samplePlaylist = PrivatePlaylist(
        id: 'pl_picker_test',
        name: 'Private Favorites',
        description: 'Testing song picker',
        totalDurationMs: 180000,
        createdAtEpochMs: now,
        updatedAtEpochMs: now,
        trackRefs: [existingTrack],
      );
      storageRepo.playlists[samplePlaylist.id] = samplePlaylist;
    });

    testWidgets('Renders sheet header, segmented control, and tracks with already-added badge', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VaultLocalSongPickerSheet(
              playlist: samplePlaylist,
              storageRepository: storageRepo,
              localTracksStore: tracksStore,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Add Local Songs'), findsOneWidget);
      expect(find.text('Private Favorites'), findsOneWidget);
      expect(find.text('Copy to Vault'), findsOneWidget);
      expect(find.text('Move to Vault'), findsOneWidget);

      // Both tracks visible
      expect(find.text('Song One'), findsOneWidget);
      expect(find.text('Song Two'), findsOneWidget);

      // Song One is already in playlist -> displays 'Added' badge
      expect(find.text('Added'), findsOneWidget);
    });

    testWidgets('Selecting available track updates bottom button label and toggling mode updates action verb', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VaultLocalSongPickerSheet(
              playlist: samplePlaylist,
              storageRepository: storageRepo,
              localTracksStore: tracksStore,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Tap Song Two to select it
      await tester.tap(find.text('Song Two'));
      await tester.pumpAndSettle();

      // Button shows "Add 1 Song to Playlist"
      expect(find.text('Add 1 Song to Playlist'), findsOneWidget);

      // Switch to Move to Vault mode
      await tester.tap(find.text('Move to Vault'));
      await tester.pumpAndSettle();

      // In Move mode, description updates
      expect(
        find.text(
          'Moves the audio file into the hidden .nomedia sandbox and removes it from public storage.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Instant search filters local songs by title or artist', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VaultLocalSongPickerSheet(
              playlist: samplePlaylist,
              storageRepository: storageRepo,
              localTracksStore: tracksStore,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Song One'), findsOneWidget);
      expect(find.text('Song Two'), findsOneWidget);

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Beta');
      await tester.pumpAndSettle();

      expect(find.text('Song One'), findsNothing);
      expect(find.text('Song Two'), findsOneWidget);
    });

    testWidgets('Committing in Copy mode adds track with localReference without deleting from store', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VaultLocalSongPickerSheet(
              playlist: samplePlaylist,
              storageRepository: storageRepo,
              localTracksStore: tracksStore,
              isolationManager: isolationManager,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Select Song Two
      await tester.tap(find.text('Song Two'));
      await tester.pumpAndSettle();

      // Tap commit button
      await tester.tap(find.byKey(const ValueKey('picker_commit_add_songs_button')));
      await tester.pumpAndSettle();

      // Verify track added to storage repo as localReference
      expect(storageRepo.addedTracks.length, 1);
      final added = storageRepo.addedTracks.first;
      expect(added.title, 'Song Two');
      expect(added.sourceType, TrackSourceTypeEnum.localReference);
      expect(added.trackUri, '/storage/music/song_two.mp3');

      // Not deleted from public store
      expect(tracksStore.deletedSongIdSets.isEmpty, true);
    });

    testWidgets('Committing in Move mode isolates track, adds localSandbox ref, and deletes from store', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VaultLocalSongPickerSheet(
              playlist: samplePlaylist,
              storageRepository: storageRepo,
              localTracksStore: tracksStore,
              isolationManager: isolationManager,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Switch to Move to Vault mode
      await tester.tap(find.text('Move to Vault'));
      await tester.pumpAndSettle();

      // Select Song Two
      await tester.tap(find.text('Song Two'));
      await tester.pumpAndSettle();

      // Tap commit button
      await tester.tap(find.byKey(const ValueKey('picker_commit_add_songs_button')));
      await tester.pumpAndSettle();

      // Verify track added to storage repo as localSandbox
      expect(storageRepo.addedTracks.length, 1);
      final added = storageRepo.addedTracks.first;
      expect(added.title, 'Song Two');
      expect(added.sourceType, TrackSourceTypeEnum.localSandbox);
      expect(added.trackUri, '/vault_sandbox/${added.id}.mp3');

      // Track isolated and deleted from public store
      expect(isolationManager.isolatedPaths, contains('/storage/music/song_two.mp3'));
      expect(tracksStore.deletedSongIdSets.isNotEmpty, true);
      expect(tracksStore.deletedSongIdSets.first, contains(102));
    });
  });
}
