import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_control_client.dart';
import 'package:musify_mu/features/player/domain/commands/options/prepare_play_options.dart';
import 'package:musify_mu/features/player/domain/models/context.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/play_origin.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';
import 'package:musify_mu/features/vault/data/services/playback_privacy_proxy.dart';
import 'package:musify_mu/features/vault/data/services/vault_audio_playback_service.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
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

// =============================================================================
// Test Doubles
// =============================================================================

class FakeMobiusPlayerController extends ChangeNotifier
    implements PlayerQueueMobiusController {
  Context? lastPlayedContext;
  PreparePlayOptions? lastPlayOptions;
  PlayOrigin? lastPlayOrigin;
  int playContextCallCount = 0;

  final StreamController<QueueModel> _modelController =
      StreamController<QueueModel>.broadcast();
  final QueueModel _model = const QueueModel();
  bool _closed = false;

  @override
  QueueModel get model => _model;

  @override
  QueueModel get state => _model;

  @override
  QueueModel get value => _model;

  @override
  Stream<QueueModel> get stream => _modelController.stream;

  @override
  bool get isClosed => _closed;

  @override
  ContextPlayerControlClient? get controlClient => null;

  @override
  void dispatch(QueueEvent event) {}

  @override
  Future<void> playContext(
    Context context, {
    PreparePlayOptions? options,
    PlayOrigin? playOrigin,
  }) async {
    playContextCallCount++;
    lastPlayedContext = context;
    lastPlayOptions = options;
    lastPlayOrigin = playOrigin;
  }

  @override
  void dispose() {
    _closed = true;
    _modelController.close();
    super.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeIsolationManager implements IVaultMediaIsolationManager {
  final Map<String, File> files = {};

  @override
  Future<File> getIsolatedTrackFile(String trackId) async {
    return files[trackId] ?? File('/mock/storage/vault_media/.nomedia/$trackId.mp3');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePlaybackPrivacyProxy implements PlaybackPrivacyProxy {
  String? lastActivatedTrackId;
  ContextTrack? lastActivatedTrack;

  @override
  void notifyVaultTrackActivated({
    required String vaultTrackId,
    required ContextTrack track,
  }) {
    lastActivatedTrackId = vaultTrackId;
    lastActivatedTrack = track;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SimpleStorageRepo implements IVaultStorageRepository {
  final Map<String, PrivatePlaylist> playlists = {};

  @override
  Future<VaultResult<PrivatePlaylist>> getPlaylistById(String id) async {
    final p = playlists[id];
    if (p != null) return VaultResult.success(p);
    return const VaultResult.failure(VaultStorageFailure('Not found'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SimpleClock implements IMonotonicClock {
  @override
  int get currentMonotonicMs => 50000;
  @override
  int get elapsedMilliseconds => 50000;
  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class SimpleScreenPrivacyController implements IScreenPrivacyController {
  @override
  ScreenPrivacyStateEnum get currentState => ScreenPrivacyStateEnum.publicUnrestricted;
  @override
  Stream<ScreenPrivacyStateEnum> get stateStream => const Stream.empty();
  @override
  Future<void> enableSecureFlag() async {}
  @override
  Future<void> disableSecureFlag() async {}
}

class SimpleAuthService implements IVaultAuthService {
  @override
  Stream<VaultSessionState> get sessionStateStream => const Stream.empty();
  @override
  void clearSessionKeysFromRam() {}
  @override
  Future<void> resetFailedAttempts() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CRITERION 4: Real VaultAudioPlaybackService & Mobius Audio Pipeline Communication', () {
    late FakeMobiusPlayerController mobiusController;
    late FakeIsolationManager isolationManager;
    late FakePlaybackPrivacyProxy privacyProxy;
    late VaultAudioPlaybackService realPlaybackService;
    late SimpleStorageRepo storageRepo;
    late SimpleClock clock;
    late ScreenPrivacyCubit privacyCubit;
    late VaultSessionBloc sessionBloc;
    late PrivatePlaylist testPlaylist;

    setUp(() {
      mobiusController = FakeMobiusPlayerController();
      isolationManager = FakeIsolationManager();
      privacyProxy = FakePlaybackPrivacyProxy();
      realPlaybackService = VaultAudioPlaybackService(
        mobiusController: mobiusController,
        isolationManager: isolationManager,
        privacyProxy: privacyProxy,
      );
      storageRepo = SimpleStorageRepo();
      clock = SimpleClock();
      privacyCubit = ScreenPrivacyCubit(
        privacyController: SimpleScreenPrivacyController(),
        monotonicClock: clock,
      );
      sessionBloc = VaultSessionBloc(
        authService: SimpleAuthService(),
        storageRepository: storageRepo,
        monotonicClock: clock,
        verifyCoolOffUseCase: VerifySessionCoolOffUseCase(clock: clock),
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

      final now = DateTime.now().millisecondsSinceEpoch;
      final tracks = List.generate(
        4,
        (i) => PrivateTrackRef(
          id: 'audio_track_$i',
          playlistId: 'pl_audio_mobius',
          trackUri: 'spotify:track:uri_$i',
          title: 'Acoustic Melody $i',
          artistName: 'Musify Artist $i',
          albumTitle: 'Vault Sessions Vol $i',
          durationMs: 210000 + i * 5000,
          sourceType: TrackSourceTypeEnum.spotify,
          sortOrder: i,
          addedAtEpochMs: now,
        ),
      );

      testPlaylist = PrivatePlaylist(
        id: 'pl_audio_mobius',
        name: 'Private Studio Masters',
        description: 'Unreleased encrypted studio tracks',
        coverUri: null,
        totalDurationMs: 840000,
        createdAtEpochMs: now,
        updatedAtEpochMs: now,
        trackRefs: tracks,
      );
      storageRepo.playlists[testPlaylist.id] = testPlaylist;
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
              playlistId: testPlaylist.id,
              storageRepository: storageRepo,
              audioPlaybackService: realPlaybackService,
              playbackPrivacyProxy: privacyProxy,
              sessionBloc: sessionBloc,
              screenPrivacyCubit: privacyCubit,
            ),
          ),
        ),
      );
    }

    testWidgets('Play All dispatches canonical Context and PreparePlayOptions to Mobius controller', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      final playAllBtn = find.byKey(const ValueKey('playlist_detail_play_all_button'));
      expect(playAllBtn, findsOneWidget);

      await tester.tap(playAllBtn);
      await tester.pumpAndSettle();

      // Verify Mobius playContext was triggered
      expect(mobiusController.playContextCallCount, equals(1));
      final context = mobiusController.lastPlayedContext;
      expect(context, isNotNull);
      expect(context!.uri, equals('spotify:internal:vault-playlist:${testPlaylist.id}'));
      expect(context.metadata[ContextTrackMetadata.keyTitle], equals('Private Studio Masters'));
      expect(context.metadata['is_vault_context'], equals('true'));

      // Verify tracks in context
      final pages = context.pages;
      expect(pages, isNotNull);
      final page = pages!.first;
      final tracks = page.tracks;
      expect(tracks, isNotNull);
      expect(tracks!.length, equals(4));
      for (var i = 0; i < 4; i++) {
        final track = tracks[i];
        expect(track.uid, equals('vault_audio_track_$i'));
        expect(track.uri, equals('spotify:track:uri_$i'));
        expect(track.provider, equals('musify_vault'));
        expect(track.metadata['is_vault_track'], equals('true'));
        expect(track.metadata['vault_track_id'], equals('audio_track_$i'));
        expect(track.metadata['vault_playlist_id'], equals(testPlaylist.id));
      }

      // Verify play options skipped to first track (startIndex 0)
      final options = mobiusController.lastPlayOptions;
      expect(options, isNotNull);
      expect(options!.skipTo?.trackUid, equals('vault_audio_track_0'));
      expect(options.skipTo?.trackUri, equals('spotify:track:uri_0'));

      // Verify PlayOrigin telemetry
      final origin = mobiusController.lastPlayOrigin;
      expect(origin, isNotNull);
      expect(origin!.featureIdentifier, equals('vault_playlist'));
      expect(origin.viewUri, equals('spotify:internal:vault-playlist:${testPlaylist.id}'));

      // Verify privacy proxy notified
      expect(privacyProxy.lastActivatedTrackId, equals('audio_track_0'));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('Shuffle Play dispatches valid skipTo options to Mobius', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      final shuffleBtn = find.byKey(const ValueKey('playlist_detail_shuffle_button'));
      expect(shuffleBtn, findsOneWidget);

      await tester.tap(shuffleBtn);
      await tester.pumpAndSettle();

      expect(mobiusController.playContextCallCount, equals(1));
      final options = mobiusController.lastPlayOptions;
      expect(options, isNotNull);
      expect(options!.skipTo, isNotNull);
      final skippedUid = options.skipTo!.trackUid!;
      expect(skippedUid.startsWith('vault_audio_track_'), isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping 3rd track starts playback specifically at that track index in Mobius', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Tap index 2 (audio_track_2)
      final targetWidget = find.byKey(const ValueKey('vault_track_audio_track_2'));
      expect(targetWidget, findsOneWidget);

      await tester.tap(targetWidget);
      await tester.pumpAndSettle();

      expect(mobiusController.playContextCallCount, equals(1));
      final options = mobiusController.lastPlayOptions;
      expect(options?.skipTo?.trackUid, equals('vault_audio_track_2'));
      expect(options?.skipTo?.trackUri, equals('spotify:track:uri_2'));
      expect(privacyProxy.lastActivatedTrackId, equals('audio_track_2'));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  });
}
