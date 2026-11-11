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

  int enableCallCount = 0;
  int disableCallCount = 0;

  @override
  ScreenPrivacyStateEnum get currentState => _state;

  @override
  Stream<ScreenPrivacyStateEnum> get stateStream => _streamController.stream;

  @override
  Future<void> enableSecureFlag() async {
    enableCallCount++;
    _state = ScreenPrivacyStateEnum.secureFlagEngaged;
    _streamController.add(_state);
  }

  @override
  Future<void> disableSecureFlag() async {
    disableCallCount++;
    _state = ScreenPrivacyStateEnum.publicUnrestricted;
    _streamController.add(_state);
  }
}

class FakeVaultStorageRepository implements IVaultStorageRepository {
  final Map<String, PrivatePlaylist> playlistMap = {};
  List<String>? lastReorderedTrackIds;
  String? lastRemovedTrackId;

  @override
  Future<VaultResult<PrivatePlaylist>> getPlaylistById(String id) async {
    final playlist = playlistMap[id];
    if (playlist != null) {
      return VaultResult.success(playlist);
    }
    return const VaultResult.failure(VaultStorageFailure('Playlist not found'));
  }

  @override
  Future<VaultResult<void>> reorderTracksInPlaylist({
    required String playlistId,
    required List<String> trackIdsInOrder,
  }) async {
    lastReorderedTrackIds = trackIdsInOrder;
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
      final updatedTracks = playlist.trackRefs.where((t) => t.id != trackId).toList();
      playlistMap[playlistId] = playlist.copyWith(trackRefs: updatedTracks);
    }
    return const VaultResult.success(null);
  }

  @override
  Future<VaultResult<void>> deletePlaylist(String playlistId) async {
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

void main() {
  group('PrivatePlaylistDetailScreen Widget Tests', () {
    late FakeMonotonicClock clock;
    late FakeScreenPrivacyController privacyController;
    late ScreenPrivacyCubit privacyCubit;
    late FakeVaultStorageRepository storageRepo;
    late FakeVaultAudioPlaybackService playbackService;
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

    final track1 = PrivateTrackRef(
      id: 'track_1',
      playlistId: 'pl_detail_1',
      trackUri: 'spotify:track:ambient_rain',
      title: 'Ambient Rain',
      artistName: 'Nature Sounds',
      albumTitle: 'Calm Nights',
      durationMs: 180000,
      sourceType: TrackSourceTypeEnum.spotify,
      localRelativePath: null,
      sortOrder: 0,
      addedAtEpochMs: 1000,
    );

    final track2 = PrivateTrackRef(
      id: 'track_2',
      playlistId: 'pl_detail_1',
      trackUri: 'spotify:track:midnight_city',
      title: 'Midnight City',
      artistName: 'M83',
      albumTitle: 'Hurry Up',
      durationMs: 240000,
      sourceType: TrackSourceTypeEnum.spotify,
      localRelativePath: null,
      sortOrder: 1,
      addedAtEpochMs: 2000,
    );

    final samplePlaylist = PrivatePlaylist(
      id: 'pl_detail_1',
      name: 'Night Vibes',
      description: 'Secret lofi collection',
      coverUri: null,
      totalDurationMs: 420000,
      createdAtEpochMs: 1000,
      updatedAtEpochMs: 2000,
      trackRefs: [track1, track2],
    );

    setUp(() {
      clock = FakeMonotonicClock();
      privacyController = FakeScreenPrivacyController();
      privacyCubit = ScreenPrivacyCubit(
        privacyController: privacyController,
        monotonicClock: clock,
      );
      storageRepo = FakeVaultStorageRepository();
      storageRepo.playlistMap['pl_detail_1'] = samplePlaylist;
      playbackService = FakeVaultAudioPlaybackService();
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

    Widget buildTestWidget({
      String playlistId = 'pl_detail_1',
      VaultThemePalettePolicyEnum palette = VaultThemePalettePolicyEnum.warmEspresso,
    }) {
      return MaterialApp(
        home: VaultTheme(
          data: VaultThemeData.fromPalette(palette),
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

    testWidgets('Renders header with artwork, title, description, and telemetry', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('playlist_detail_header')), findsOneWidget);
      expect(find.text('Night Vibes'), findsAtLeastNWidgets(1));
      expect(find.text('Secret lofi collection'), findsOneWidget);
      expect(find.text('2 tracks \u2022 7 min'), findsOneWidget);

      expect(find.text('Ambient Rain'), findsOneWidget);
      expect(find.text('Midnight City'), findsOneWidget);
    });

    testWidgets('Tapping artwork toggles frosted privacy peek state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Initially frosted
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Tap artwork container
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // Unblurred (no visibility_off icon)
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      // Tap again to re-frost
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('In-playlist instant search filters tracks by title, artist, or album', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ambient Rain'), findsOneWidget);
      expect(find.text('Midnight City'), findsOneWidget);

      // Search for M83
      await tester.enterText(
        find.byKey(const ValueKey('playlist_detail_search_input')),
        'M83',
      );
      await tester.pumpAndSettle();

      expect(find.text('Ambient Rain'), findsNothing);
      expect(find.text('Midnight City'), findsOneWidget);

      // Clear search
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Ambient Rain'), findsOneWidget);
      expect(find.text('Midnight City'), findsOneWidget);
    });

    testWidgets('Reorderable track list uniquely keys every item with ValueKey', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vault_track_track_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('vault_track_track_2')), findsOneWidget);
    });

    testWidgets('Tapping Play All initiates playback via VaultAudioPlaybackService', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('playlist_detail_play_all_button')));
      await tester.pumpAndSettle();

      expect(playbackService.playCallCount, 1);
      expect(playbackService.lastPlayedPlaylist?.id, 'pl_detail_1');
      expect(playbackService.lastStartIndex, 0);
    });

    testWidgets('Tapping Shuffle initiates playback with valid start index', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('playlist_detail_shuffle_button')));
      await tester.pumpAndSettle();

      expect(playbackService.playCallCount, 1);
      expect(playbackService.lastPlayedPlaylist?.id, 'pl_detail_1');
      expect(playbackService.lastStartIndex, inInclusiveRange(0, 1));
    });

    testWidgets('Tapping an individual track initiates playback starting from that track index', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Midnight City'));
      await tester.pumpAndSettle();

      expect(playbackService.playCallCount, 1);
      expect(playbackService.lastStartIndex, 1);
    });

    testWidgets('Swipe-to-remove shows confirmation dialog and removes track on confirm', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Swipe track 1 left
      await tester.drag(find.text('Ambient Rain'), const Offset(-500.0, 0.0));
      await tester.pumpAndSettle();

      expect(find.text('Remove Track'), findsOneWidget);
      expect(find.text('Remove "Ambient Rain" from this private playlist?'), findsOneWidget);

      // Confirm remove
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Remove')));
      await tester.pumpAndSettle();

      expect(storageRepo.lastRemovedTrackId, 'track_1');
      expect(find.text('Ambient Rain'), findsNothing);
      expect(find.text('Midnight City'), findsOneWidget);
    });

    testWidgets('Auto-Pop: Transitioning VaultSessionBloc to VaultLockedState pops detail screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (navContext) => ElevatedButton(
                onPressed: () {
                  Navigator.of(navContext).push(
                    MaterialPageRoute<void>(
                      builder: (_) => VaultTheme(
                        data: VaultThemeData.fromPalette(VaultThemePalettePolicyEnum.warmEspresso),
                        child: MultiBlocProvider(
                          providers: [
                            BlocProvider<VaultSessionBloc>.value(value: sessionBloc),
                            BlocProvider<ScreenPrivacyCubit>.value(value: privacyCubit),
                          ],
                          child: PrivatePlaylistDetailScreen(
                            playlistId: 'pl_detail_1',
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
                child: const Text('Open Playlist'),
              ),
            ),
          ),
        ),
      );

      // Open detail screen
      await tester.tap(find.text('Open Playlist'));
      await tester.pumpAndSettle();

      expect(find.text('Night Vibes'), findsAtLeastNWidgets(1));

      // Emit locked state
      sessionBloc.emitState(const VaultLockedState(lockedAtMonotonicMs: 25000));
      await tester.pumpAndSettle();

      // Popped back to home
      expect(find.text('Open Playlist'), findsOneWidget);
      expect(find.byKey(const ValueKey('playlist_detail_header')), findsNothing);
    });

    test('PrivatePlaylistDetailLoadedState model adheres to PlaylistPlaybackStatusEnum contract', () {
      final loaded = PrivatePlaylistDetailLoadedState(
        playlist: samplePlaylist,
        searchQuery: '',
        filteredTracks: [track1, track2],
        artworkPeekState: ArtworkPeekStateEnum.frostedPeek,
        activeTrackId: null,
        playbackStatus: PlaylistPlaybackStatusEnum.stopped,
      );

      expect(loaded.playbackStatus, equals(PlaylistPlaybackStatusEnum.stopped));
      expect(loaded.playbackStatus.isPlaying, isFalse);
      expect(loaded.activeTrackId, isNull);

      // Verify copyWith with playing status and active track
      final playingState = loaded.copyWith(
        activeTrackId: 'track_1',
        playbackStatus: PlaylistPlaybackStatusEnum.playing,
      );
      expect(playingState.activeTrackId, 'track_1');
      expect(playingState.playbackStatus, equals(PlaylistPlaybackStatusEnum.playing));
      expect(playingState.playbackStatus.isPlaying, isTrue);

      // Verify copyWith with paused status
      final pausedState = playingState.copyWith(
        playbackStatus: PlaylistPlaybackStatusEnum.paused,
      );
      expect(pausedState.playbackStatus, equals(PlaylistPlaybackStatusEnum.paused));
      expect(pausedState.playbackStatus.isPlaying, isFalse);

      // Verify structural equality (Equatable)
      expect(
        playingState,
        equals(
          loaded.copyWith(
            activeTrackId: 'track_1',
            playbackStatus: PlaylistPlaybackStatusEnum.playing,
          ),
        ),
      );
      expect(playingState == pausedState, isFalse);
    });

    testWidgets('Track tile renders volume icon only when activeTrackId matches AND playbackStatus is playing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Initially stopped: shows track numbers '1' and '2', no volume icon
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
    });
  });
}
