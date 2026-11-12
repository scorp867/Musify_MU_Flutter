import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/library/domain/models/library_item.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file_metadata.dart';
import 'package:musify_mu/features/player/presentation/models/more_options_entity.dart';
import 'package:musify_mu/features/player/presentation/widgets/more_options_bottom_sheet.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_entity.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_item.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_metadata.dart';
import 'package:musify_mu/features/playlist/domain/models/sort_order.dart';
import 'package:musify_mu/features/playlist/domain/models/track_item_metadata.dart';
import 'package:musify_mu/features/playlist/domain/repositories/playlist_repository.dart';
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
  @override
  int get currentMonotonicMs => 10000;
  @override
  int get elapsedMilliseconds => 10000;
  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class FakeVaultAuthService implements IVaultAuthService {
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

class FakeVaultStorageRepository implements IVaultStorageRepository {
  final Map<String, PrivatePlaylist> playlists = {};
  final List<PrivateTrackRef> addedTracks = [];

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      VaultResult.success(const VaultConfig.constant());

  @override
  Future<VaultResult<List<PrivatePlaylist>>> getPlaylists() async =>
      VaultResult.success(playlists.values.toList());

  @override
  Future<VaultResult<PrivatePlaylist>> createPlaylist({
    required String name,
    required String description,
    String? coverUri,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = 'pl_${playlists.length + 1}';
    final playlist = PrivatePlaylist(
      id: id,
      name: name,
      description: description,
      coverUri: coverUri,
      totalDurationMs: 0,
      createdAtEpochMs: now,
      updatedAtEpochMs: now,
      trackRefs: const [],
    );
    playlists[id] = playlist;
    return VaultResult.success(playlist);
  }

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

class FakePlaylistRepository implements PlaylistRepository {
  final Map<String, PlaylistEntity> mockPlaylists = {};

  @override
  Future<PlaylistEntity> getPlaylist(
    String playlistUri, {
    ProvidedSortOrder sortOrder = ProvidedSortOrder.custom,
  }) async {
    final pl = mockPlaylists[playlistUri];
    if (pl != null) return pl;
    throw Exception('Playlist not found: $playlistUri');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MoreOptionsBottomSheet Comprehensive Tests', () {
    late FakeVaultAuthService authService;
    late FakeMonotonicClock clock;
    late FakeVaultStorageRepository storageRepo;
    late FakePlaylistRepository playlistRepo;
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
      authService = FakeVaultAuthService();
      clock = FakeMonotonicClock();
      storageRepo = FakeVaultStorageRepository();
      playlistRepo = FakePlaylistRepository();
      verifyCoolOff = VerifySessionCoolOffUseCase(clock: clock);
      sessionBloc = TestVaultSessionBloc(
        authService: authService,
        storageRepository: storageRepo,
        monotonicClock: clock,
        verifyCoolOffUseCase: verifyCoolOff,
      );
    });

    tearDown(() {
      sessionBloc.close();
    });

    testWidgets('LocalTrackOptionsEntity renders Copy to Vault and Move to Vault when session unlocked', (tester) async {
      sessionBloc.emitState(unlockedState);
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const localFile = LocalFile(
        path: '/storage/emulated/0/Music/song.mp3',
        metadata: LocalFileMetadata(
          title: 'Night Sky',
          artist: 'Ambient Artist',
          album: 'Cosmos',
          duration: 180,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => MoreOptionsBottomSheet.show(
                  ctx,
                  entity: const LocalTrackOptionsEntity(localFile),
                  sessionBlocOverride: sessionBloc,
                  storageRepositoryOverride: storageRepo,
                ),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Night Sky'), findsOneWidget);
      expect(find.text('Ambient Artist'), findsOneWidget);
      expect(find.byKey(const ValueKey('menu_copy_local_to_vault')), findsOneWidget);
      expect(find.byKey(const ValueKey('menu_move_local_to_vault')), findsOneWidget);
      expect(find.text('Copy to Vault'), findsOneWidget);
      expect(find.text('Move to Vault'), findsOneWidget);
    });

    testWidgets('LocalPlaylistOptionsEntity renders Copy to Vault and Move to Vault options', (tester) async {
      sessionBloc.emitState(unlockedState);
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const file1 = LocalFile(
        path: '/music/t1.mp3',
        metadata: LocalFileMetadata(title: 'Track One', artist: 'Artist 1'),
      );
      const file2 = LocalFile(
        path: '/music/t2.mp3',
        metadata: LocalFileMetadata(title: 'Track Two', artist: 'Artist 2'),
      );

      final localPlaylistEntity = LocalPlaylistOptionsEntity(
        playlistName: 'Roadtrip Mixtape',
        files: const [file1, file2],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => MoreOptionsBottomSheet.show(
                  ctx,
                  entity: localPlaylistEntity,
                  sessionBlocOverride: sessionBloc,
                  storageRepositoryOverride: storageRepo,
                ),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Roadtrip Mixtape'), findsOneWidget);
      expect(find.text('2 local tracks'), findsOneWidget);
      expect(find.byKey(const ValueKey('menu_copy_local_playlist_to_vault')), findsOneWidget);
      expect(find.byKey(const ValueKey('menu_move_local_playlist_to_vault')), findsOneWidget);

      // Execute Copy to Vault
      await tester.tap(find.byKey(const ValueKey('menu_copy_local_playlist_to_vault')));
      await tester.pumpAndSettle();

      // Verify playlist created and tracks added
      expect(storageRepo.playlists.length, 1);
      final pl = storageRepo.playlists.values.first;
      expect(pl.name, 'Roadtrip Mixtape');
      expect(storageRepo.addedTracks.length, 2);
      expect(storageRepo.addedTracks.first.sourceType, TrackSourceTypeEnum.localReference);
    });

    testWidgets('LibraryItemOptionsEntity executes real playlist cloning via PlaylistRepository', (tester) async {
      sessionBloc.emitState(unlockedState);
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const item = LibraryItem(
        uri: 'spotify:playlist:library_chill',
        type: 'playlist',
        name: 'Chill Evening',
        trackCount: 1,
      );

      final spotifyItem = PlaylistItem(
        uri: 'spotify:track:chill_1',
        uid: 'uid_chill_1',
        rowPosition: 0,
        trackMetadata: const TrackItemMetadata(
          title: 'Evening Calm',
          uri: 'spotify:track:chill_1',
          albumName: 'Calm Album',
          artists: ['Calm Artist'],
          durationMs: 120000,
        ),
      );

      playlistRepo.mockPlaylists['spotify:playlist:library_chill'] = PlaylistEntity(
        metadata: const PlaylistMetadata(
          uri: 'spotify:playlist:library_chill',
          name: 'Chill Evening',
          description: 'Relaxing tunes',
        ),
        items: [spotifyItem],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => MoreOptionsBottomSheet.show(
                  ctx,
                  entity: const LibraryItemOptionsEntity(item),
                  sessionBlocOverride: sessionBloc,
                  storageRepositoryOverride: storageRepo,
                  playlistRepositoryOverride: playlistRepo,
                ),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final cloneTile = find.byKey(const ValueKey('menu_clone_library_to_private_vault'));
      expect(cloneTile, findsOneWidget);

      await tester.tap(cloneTile);
      await tester.pumpAndSettle();

      // Invariant: REAL playlist cloning (not fake snackbar only)
      expect(storageRepo.playlists.length, 1);
      final clonedPlaylist = storageRepo.playlists.values.first;
      expect(clonedPlaylist.name, 'Chill Evening');
      expect(storageRepo.addedTracks.length, 1);
      expect(storageRepo.addedTracks.first.title, 'Evening Calm');
      expect(storageRepo.addedTracks.first.sourceType, TrackSourceTypeEnum.spotify);
    });

    testWidgets('Locked session completely omits vault options (True Stealth)', (tester) async {
      sessionBloc.emitState(const VaultLockedState(lockedAtMonotonicMs: 1000));
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const localFile = LocalFile(
        path: '/storage/music/song.mp3',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => MoreOptionsBottomSheet.show(
                  ctx,
                  entity: const LocalTrackOptionsEntity(localFile),
                  sessionBlocOverride: sessionBloc,
                  storageRepositoryOverride: storageRepo,
                ),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('menu_copy_local_to_vault')), findsNothing);
      expect(find.byKey(const ValueKey('menu_move_local_to_vault')), findsNothing);
      expect(find.text('Copy to Vault'), findsNothing);
      expect(find.text('Move to Vault'), findsNothing);
    });
  });
}
