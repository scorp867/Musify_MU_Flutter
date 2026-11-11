import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:musify_mu/app/di/mode_persistence.dart';
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/network/status/bloc/network_status_bloc.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/application/auth_event.dart';
import 'package:musify_mu/features/auth/domain/entities/auth_state.dart';
import 'package:musify_mu/features/browse/application/browse_bloc.dart';
import 'package:musify_mu/features/home_feed/application/home_feed_bloc.dart';
import 'package:musify_mu/features/library/application/library_bloc.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_bloc.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_state.dart';
import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/application/queue/player_queue_bloc.dart';
import 'package:musify_mu/features/vault/application/coordinator/vault_coordinator.dart';
import 'package:musify_mu/features/vault/application/gesture/gesture_engine_cubit.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/playlists/vault_playlists_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
import 'package:musify_mu/features/vault/data/gesture/kinematic_sanity_gate.dart';
import 'package:musify_mu/features/vault/data/services/playback_privacy_proxy.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/lockout_cooldown_info.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_screen_privacy_controller.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/mutate_vault_config_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';

final class FakeMonotonicClock implements IMonotonicClock {
  int timeMs;

  FakeMonotonicClock({this.timeMs = 10000});

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();

  void advance(Duration duration) {
    timeMs += duration.inMilliseconds;
  }
}

final class FakeScreenPrivacyController implements IScreenPrivacyController {
  ScreenPrivacyStateEnum _state = ScreenPrivacyStateEnum.publicUnrestricted;
  final StreamController<ScreenPrivacyStateEnum> _streamController =
      StreamController<ScreenPrivacyStateEnum>.broadcast();

  int enableCount = 0;
  int disableCount = 0;

  @override
  ScreenPrivacyStateEnum get currentState => _state;

  @override
  Stream<ScreenPrivacyStateEnum> get stateStream => _streamController.stream;

  @override
  Future<void> enableSecureFlag() async {
    enableCount++;
    _state = ScreenPrivacyStateEnum.secureFlagEngaged;
    _streamController.add(_state);
  }

  @override
  Future<void> disableSecureFlag() async {
    disableCount++;
    _state = ScreenPrivacyStateEnum.publicUnrestricted;
    _streamController.add(_state);
  }

  Future<void> dispose() async {
    await _streamController.close();
  }
}

final class FakeGestureRecognizer implements IGestureRecognizer {
  bool shouldMatch = true;
  final KinematicSanityGate _gate = KinematicSanityGate.standard;

  @override
  Future<VaultResult<RecognitionScore>> evaluateStroke({
    required GestureSample liveStroke,
    required GestureTemplate template,
    required GestureSensitivityTierEnum sensitivityTier,
  }) async {
    List<GesturePoint> evalPoints = liveStroke.points;
    if (evalPoints.length >= 3 && evalPoints.length < 10) {
      final interpolated = <GesturePoint>[];
      for (int i = 0; i < evalPoints.length - 1; i++) {
        final p1 = evalPoints[i];
        final p2 = evalPoints[i + 1];
        const int steps = 5;
        for (int s = 0; s < steps; s++) {
          final t = s / steps;
          interpolated.add(
            GesturePoint(
              x: p1.x + (p2.x - p1.x) * t,
              y: p1.y + (p2.y - p1.y) * t,
              timestampMs: (p1.timestampMs + (p2.timestampMs - p1.timestampMs) * t).round(),
            ),
          );
        }
      }
      interpolated.add(evalPoints.last);
      evalPoints = interpolated;
    }

    final gateDecision = _gate.evaluate(evalPoints);
    if (gateDecision is! KinematicGatePassed) {
      return VaultResult.success(
        RecognitionScore(
          dollarOneScore: 0.0,
          dtwScore: 0.0,
          featureScore: 0.0,
          ensembleScore: 0.0,
          decision: GestureMatchDecisionEnum.rejectedAntiScribble,
        ),
      );
    }

    if (shouldMatch) {
      return VaultResult.success(
        RecognitionScore(
          dollarOneScore: 0.95,
          dtwScore: 0.90,
          featureScore: 0.88,
          ensembleScore: 0.92,
          decision: GestureMatchDecisionEnum.matched,
        ),
      );
    }
    return VaultResult.success(
      RecognitionScore(
        dollarOneScore: 0.40,
        dtwScore: 0.35,
        featureScore: 0.30,
        ensembleScore: 0.35,
        decision: GestureMatchDecisionEnum.rejectedAntiScribble,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class FakeVaultStorageRepository implements IVaultStorageRepository {
  VaultConfig config;
  GestureTemplate? template;
  final Map<String, PrivatePlaylist> playlists = {};
  final Map<String, List<PrivateTrackRef>> tracks = {};
  int? persistedLockoutDeadlineMs;

  FakeVaultStorageRepository({
    VaultConfig? initialConfig,
    GestureTemplate? initialTemplate,
  })  : config = initialConfig ?? const VaultConfig.constant(),
        template = initialTemplate ?? DefaultGestureTemplate.canonicalVShape;

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() =>
      SynchronousFuture(VaultResult.success(config));

  @override
  Future<VaultResult<void>> saveVaultConfig(VaultConfig newConfig) {
    config = newConfig;
    return SynchronousFuture(const VaultResult.success(null));
  }

  @override
  Future<VaultResult<GestureTemplate>> loadGestureTemplate() =>
      SynchronousFuture(VaultResult.success(
          template ?? DefaultGestureTemplate.canonicalVShape));

  @override
  Future<VaultResult<void>> saveGestureTemplate(
      GestureTemplate newTemplate) {
    template = newTemplate;
    return SynchronousFuture(const VaultResult.success(null));
  }

  @override
  Future<VaultResult<List<PrivatePlaylist>>> getPlaylists() =>
      SynchronousFuture(VaultResult.success(playlists.values.toList()));

  @override
  Future<VaultResult<PrivatePlaylist>> getPlaylistById(String id) {
    final p = playlists[id];
    if (p != null) return SynchronousFuture(VaultResult.success(p));
    return SynchronousFuture(
        const VaultResult.failure(VaultStorageFailure('Not found')));
  }

  @override
  Future<VaultResult<PrivatePlaylist>> createPlaylist({
    required String name,
    required String description,
    String? coverUri,
  }) {
    final id = 'playlist_${playlists.length + 1}';
    final playlist = PrivatePlaylist(
      id: id,
      name: name,
      description: description,
      coverUri: coverUri,
      createdAtEpochMs: 1000,
      updatedAtEpochMs: 1000,
      totalDurationMs: 0,
      trackRefs: const [],
    );
    playlists[id] = playlist;
    return SynchronousFuture(VaultResult.success(playlist));
  }

  @override
  Future<VaultResult<void>> updatePlaylist(PrivatePlaylist playlist) {
    playlists[playlist.id] = playlist;
    return SynchronousFuture(const VaultResult.success(null));
  }

  @override
  Future<VaultResult<void>> deletePlaylist(String playlistId) {
    playlists.remove(playlistId);
    tracks.remove(playlistId);
    return SynchronousFuture(const VaultResult.success(null));
  }

  @override
  Future<VaultResult<void>> addTrackToPlaylist({
    required String playlistId,
    required PrivateTrackRef trackRef,
  }) {
    final list = tracks.putIfAbsent(playlistId, () => []);
    list.add(trackRef);
    return SynchronousFuture(const VaultResult.success(null));
  }

  @override
  Future<VaultResult<void>> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) {
    tracks[playlistId]?.removeWhere((t) => t.id == trackId);
    return SynchronousFuture(const VaultResult.success(null));
  }

  @override
  Future<VaultResult<void>> reorderTracksInPlaylist({
    required String playlistId,
    required List<String> trackIdsInOrder,
  }) {
    return SynchronousFuture(const VaultResult.success(null));
  }

  @override
  Future<int?> getPersistedLockoutDeadlineMs() =>
      SynchronousFuture(persistedLockoutDeadlineMs);

  @override
  Future<void> persistLockoutDeadlineMs(int deadlineMonotonicMs) {
    persistedLockoutDeadlineMs = deadlineMonotonicMs;
    return SynchronousFuture(null);
  }

  @override
  Future<void> clearPersistedLockoutDeadline() {
    persistedLockoutDeadlineMs = null;
    return SynchronousFuture(null);
  }

  @override
  Future<VaultResult<void>> purgeAllVaultData() {
    playlists.clear();
    tracks.clear();
    config = const VaultConfig.constant();
    template = null;
    persistedLockoutDeadlineMs = null;
    return SynchronousFuture(const VaultResult.success(null));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestVaultSessionBloc extends VaultSessionBloc {
  TestVaultSessionBloc({
    required super.authService,
    required super.storageRepository,
    required super.monotonicClock,
    required super.verifyCoolOffUseCase,
    super.initialConfig = const VaultConfig.constant(),
    super.initialState = const VaultUninitializedState(),
  });

  void emitState(VaultSessionState state) {
    emit(state);
  }
}

final class FakeVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> _sessionController =
      StreamController<VaultSessionState>.broadcast();
  TestVaultSessionBloc? sessionBloc;
  bool keysCleared = false;
  String currentPin;
  int failedAttempts = 0;

  FakeVaultAuthService({this.currentPin = '123456'});

  @override
  Stream<VaultSessionState> get sessionStateStream => _sessionController.stream;

  @override
  Future<LockoutCooldownInfo> getLockoutStatus() async =>
      LockoutCooldownInfo(
        tier: LockoutCooldownTierEnum.none,
        remainingCooldownSeconds: 0,
        deadlineMonotonicMs: 0,
        consecutiveFailedAttempts: failedAttempts,
      );

  @override
  Future<VaultResult<AuthSession>> authenticateWithPin(
      {required String pin}) async {
    if (pin == currentPin) {
      failedAttempts = 0;
      final session = AuthSession(
        sessionToken: 'test_token',
        sessionStartedEpochMs: 10000,
        lastActiveEpochMs: 10000,
        authMethod: AuthMethodEnum.pin,
      );
      final unlocked = VaultUnlockedState(
        session: session,
        unlockedAtMonotonicMs: 10000,
        reauthDeadlineMonotonicMs: 0,
      );
      _sessionController.add(unlocked);
      sessionBloc?.emitState(unlocked);
      return VaultResult.success(session);
    }
    failedAttempts++;
    return const VaultResult.failure(VaultAuthFailure('Invalid PIN'));
  }

  @override
  Future<VaultResult<void>> rotatePin({
    required String oldPin,
    required String newPin,
  }) async {
    if (oldPin != currentPin) {
      return const VaultResult.failure(VaultAuthFailure('Old PIN mismatch'));
    }
    currentPin = newPin;
    return const VaultResult.success(null);
  }

  @override
  Future<void> recordFailedAttempt() async {
    failedAttempts++;
  }

  @override
  Future<void> resetFailedAttempts() async {
    failedAttempts = 0;
  }

  @override
  void clearSessionKeysFromRam() {
    keysCleared = true;
    sessionBloc?.emitState(const VaultLockedState(lockedAtMonotonicMs: 0));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class FakeDataPool extends Fake implements DataPool {}

final class FakeColorExtractionService extends Fake
    implements ColorExtractionService {}

final class FakeNetworkMonitorService implements NetworkMonitorService {
  final StreamController<NetworkStatus> _controller =
      StreamController<NetworkStatus>.broadcast();

  @override
  Stream<NetworkStatus> get statusStream => _controller.stream;

  @override
  NetworkStatus get currentStatus => NetworkStatus.online;

  @override
  void dispose() {
    _controller.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class FakeAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  FakeAuthBloc([super.initial = const Unauthenticated()]);
}

final class FakeHomeFeedBloc extends Fake implements HomeFeedBloc {
  @override
  Stream<HomeFeedState> get stream => const Stream.empty();
  @override
  HomeFeedState get state => const HomeFeedLoading();
}

final class FakeBrowseBloc extends Fake implements BrowseBloc {
  @override
  Stream<BrowseState> get stream => const Stream.empty();
  @override
  BrowseState get state => const BrowseLoading();
}

final class FakeLibraryBloc extends Fake implements LibraryBloc {
  @override
  Stream<LibraryState> get stream => const Stream.empty();
  @override
  LibraryState get state => const LibraryLoading();
}

final class FakeLocalMusicBloc extends Fake implements LocalMusicBloc {
  @override
  Stream<LocalMusicState> get stream => const Stream.empty();
  @override
  LocalMusicState get state => const LocalMusicInitial();
}

final class FakeModePersistence extends Fake implements ModePersistence {
  bool isOnline = true;
  @override
  Future<bool?> loadMode() async => isOnline;
  @override
  Future<void> saveMode(bool online) async {
    isOnline = online;
  }
}

/// Helper harness configuring GetIt with real or fake vault components for integration tests.
class TestVaultHarness {
  GetIt get sl => GetIt.instance;

  final FakeMonotonicClock clock;
  final FakeScreenPrivacyController screenPrivacyController;
  final FakeVaultStorageRepository storageRepository;
  final FakeVaultAuthService authService;
  final FakeGestureRecognizer recognizer;

  late final VaultSessionBloc sessionBloc;
  late final SettingsMutationCubit settingsMutationCubit;
  late final ScreenPrivacyCubit screenPrivacyCubit;
  late final GestureEngineCubit gestureEngineCubit;
  late final PinPadCubit pinPadCubit;
  late final PlaybackPrivacyProxy playbackPrivacyProxy;
  late final VaultCoordinator coordinator;
  late final VaultRouteObserver routeObserver;
  late final PlayerQueueMobiusController mobiusController;

  TestVaultHarness({
    FakeMonotonicClock? clock,
    FakeScreenPrivacyController? screenPrivacyController,
    FakeVaultStorageRepository? storageRepository,
    FakeVaultAuthService? authService,
    FakeGestureRecognizer? recognizer,
    VaultConfig? initialConfig,
  })  : clock = clock ?? FakeMonotonicClock(),
        screenPrivacyController =
            screenPrivacyController ?? FakeScreenPrivacyController(),
        storageRepository = storageRepository ??
            FakeVaultStorageRepository(initialConfig: initialConfig),
        authService = authService ?? FakeVaultAuthService(),
        recognizer = recognizer ?? FakeGestureRecognizer();

  Future<void> setup() async {
    final sl = GetIt.instance;
    await sl.reset();

    sl.registerSingleton<IMonotonicClock>(clock);
    sl.registerSingleton<IScreenPrivacyController>(screenPrivacyController);
    sl.registerSingleton<IVaultStorageRepository>(storageRepository);
    sl.registerSingleton<IVaultAuthService>(authService);
    sl.registerSingleton<IGestureRecognizer>(recognizer);

    mobiusController = PlayerQueueMobiusController();
    sl.registerSingleton<PlayerQueueMobiusController>(mobiusController);

    final unlockUseCase = UnlockVaultUseCase(authService: authService);
    final mutateConfigUseCase = MutateVaultConfigUseCase(
      authService: authService,
      storageRepository: storageRepository,
    );
    final verifyCoolOffUseCase = VerifySessionCoolOffUseCase(clock: clock);

    final testSessionBloc = TestVaultSessionBloc(
      authService: authService,
      storageRepository: storageRepository,
      monotonicClock: clock,
      verifyCoolOffUseCase: verifyCoolOffUseCase,
      initialConfig: storageRepository.config,
      initialState: const VaultLockedState(lockedAtMonotonicMs: 0),
    );
    sessionBloc = testSessionBloc;
    authService.sessionBloc = testSessionBloc;
    sl.registerSingleton<VaultSessionBloc>(sessionBloc);

    settingsMutationCubit = SettingsMutationCubit(
      storageRepository: storageRepository,
      mutateVaultConfigUseCase: mutateConfigUseCase,
      authService: authService,
      monotonicClock: clock,
      initialConfig: storageRepository.config,
    );
    sl.registerSingleton<SettingsMutationCubit>(settingsMutationCubit);

    screenPrivacyCubit = ScreenPrivacyCubit(
      privacyController: screenPrivacyController,
      monotonicClock: clock,
      initialPolicy: storageRepository.config.screenSecurity,
    );
    sl.registerSingleton<ScreenPrivacyCubit>(screenPrivacyCubit);

    gestureEngineCubit = GestureEngineCubit(
      recognizer: recognizer,
      storageRepository: storageRepository,
      vaultAuthService: authService,
    );
    sl.registerSingleton<GestureEngineCubit>(gestureEngineCubit);

    pinPadCubit = PinPadCubit(
      unlockVaultUseCase: unlockUseCase,
      authService: authService,
      monotonicClock: clock,
    );
    sl.registerSingleton<PinPadCubit>(pinPadCubit);

    playbackPrivacyProxy = PlaybackPrivacyProxy(
      vaultAuthService: authService,
      mobiusController: mobiusController,
      storageRepository: storageRepository,
    );
    sl.registerSingleton<PlaybackPrivacyProxy>(playbackPrivacyProxy);

    coordinator = VaultCoordinator(
      sessionBloc: sessionBloc,
      playbackPrivacyProxy: playbackPrivacyProxy,
      screenPrivacyCubit: screenPrivacyCubit,
      gestureEngineCubit: gestureEngineCubit,
      settingsMutationCubit: settingsMutationCubit,
      pinPadCubit: pinPadCubit,
      monotonicClock: clock,
    )..initialize();
    sl.registerSingleton<VaultCoordinator>(coordinator);

    routeObserver = VaultRouteObserver(privacyCubit: screenPrivacyCubit);
    sl.registerSingleton<VaultRouteObserver>(routeObserver);

    sl.registerFactory<VaultPlaylistsCubit>(
      () => VaultPlaylistsCubit(storageRepository: storageRepository),
    );

    // App core mocks
    sl.registerSingleton<DataPool>(FakeDataPool());
    sl.registerSingleton<ColorExtractionService>(FakeColorExtractionService());
    sl.registerSingleton<NetworkStatusBloc>(
      NetworkStatusBloc(monitorService: FakeNetworkMonitorService()),
    );
    sl.registerSingleton<ModePersistence>(FakeModePersistence());
    sl.registerFactory<HomeFeedBloc>(() => FakeHomeFeedBloc());
    sl.registerFactory<BrowseBloc>(() => FakeBrowseBloc());
    sl.registerFactory<LibraryBloc>(() => FakeLibraryBloc());
  }

  Future<void> tearDown() async {
    try {
      sessionBloc.close();
      settingsMutationCubit.close();
      screenPrivacyCubit.close();
      gestureEngineCubit.close();
      pinPadCubit.close();
      playbackPrivacyProxy.dispose();
      coordinator.dispose();
      mobiusController.close();
      await screenPrivacyController.dispose();
    } catch (_) {}
    await GetIt.instance.reset();
  }
}
