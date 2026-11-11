import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_control_client.dart';
import 'package:musify_mu/features/player/domain/commands/options/prepare_play_options.dart';
import 'package:musify_mu/features/player/domain/commands/pause_command.dart';
import 'package:musify_mu/features/player/domain/commands/resume_command.dart';
import 'package:musify_mu/features/player/domain/commands/skip_to_next_track_command.dart';
import 'package:musify_mu/features/player/domain/commands/stop_command.dart';
import 'package:musify_mu/features/player/domain/models/context.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/play_origin.dart';
import 'package:musify_mu/features/player/domain/models/player_response.dart';
import 'package:musify_mu/features/vault/data/database/vault_database.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';
import 'package:musify_mu/features/vault/data/repositories/vault_storage_repository.dart';
import 'package:musify_mu/features/vault/data/services/playback_privacy_proxy.dart';
import 'package:musify_mu/features/vault/data/services/vault_audio_playback_service.dart';
import 'package:musify_mu/features/vault/data/services/vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_point.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/policies/biometric_auth_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/states/crypto_engine_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';

import '../datasources/fake_native_vault_crypto_bridge.dart';

// ---------------------------------------------------------------------------
// Test Doubles for Mobius, Player Control, Secure Storage & Monotonic Clock
// ---------------------------------------------------------------------------

class IntegrationTestControlClient implements ContextPlayerControlClient {
  int stopCallCount = 0;
  StopCommand? lastStopCommand;

  @override
  Future<PlayerResponse> stop(StopCommand command) async {
    stopCallCount++;
    lastStopCommand = command;
    return PlayerResponse.success;
  }

  @override
  Future<PlayerResponse> pause(PauseCommand command) async =>
      PlayerResponse.success;

  @override
  Future<PlayerResponse> resume(ResumeCommand command) async =>
      PlayerResponse.success;

  @override
  Future<PlayerResponse> skipToNext(SkipToNextTrackCommand command) async =>
      PlayerResponse.success;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class IntegrationTestMobiusController extends ChangeNotifier
    implements PlayerQueueMobiusController {
  final List<QueueEvent> dispatchedEvents = <QueueEvent>[];
  final StreamController<QueueModel> _modelController =
      StreamController<QueueModel>.broadcast();
  QueueModel _currentModel = const QueueModel();
  bool _isClosed = false;

  final IntegrationTestControlClient client = IntegrationTestControlClient();

  Context? lastPlayedContext;
  PreparePlayOptions? lastPlayOptions;
  PlayOrigin? lastPlayOrigin;
  int playContextCalls = 0;

  @override
  ContextPlayerControlClient get controlClient => client;

  @override
  QueueModel get model => _currentModel;

  @override
  QueueModel get state => _currentModel;

  @override
  QueueModel get value => _currentModel;

  @override
  Stream<QueueModel> get stream => _modelController.stream;

  @override
  bool get isClosed => _isClosed;

  void emit(QueueModel model) {
    _currentModel = model;
    if (!_isClosed) {
      _modelController.add(model);
    }
  }

  @override
  void dispatch(QueueEvent event) {
    dispatchedEvents.add(event);
  }

  @override
  void add(QueueEvent event) => dispatch(event);

  @override
  Future<void> playContext(
    Context context, {
    PreparePlayOptions? options,
    PlayOrigin? playOrigin,
  }) async {
    playContextCalls++;
    lastPlayedContext = context;
    lastPlayOptions = options;
    lastPlayOrigin = playOrigin;
  }

  @override
  Future<void> close() async {
    _isClosed = true;
    await _modelController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class IntegrationFakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _store = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value case final v?) {
      _store[key] = v;
    } else {
      _store.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.clear();
  }
}

class IntegrationFakeMonotonicClock implements IMonotonicClock {
  int timeMs = 1000000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();

  void advance(int deltaMs) {
    timeMs += deltaMs;
  }
}

// ---------------------------------------------------------------------------
// Test Suite Entry Point
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testTempDir;
  late VaultDatabase database;
  late FakeNativeVaultCryptoBridge cryptoBridge;
  late VaultStorageRepository storageRepository;
  late VaultMediaIsolationManager mediaIsolationManager;
  late IntegrationFakeSecureStorage secureStorage;
  late IntegrationFakeMonotonicClock monotonicClock;
  late VaultAuthService authService;
  late IntegrationTestMobiusController mobiusController;
  late PlaybackPrivacyProxy privacyProxy;
  late VaultAudioPlaybackService audioPlaybackService;

  final samplePoints = List<GesturePoint>.generate(
    64,
    (index) => GesturePoint(
      x: index.toDouble() / 64.0,
      y: (index * index).toDouble() / 4096.0,
      timestampMs: index * 16,
    ),
  );
  final sampleRubine = List<double>.generate(7, (i) => (i + 1) * 0.142);
  final sampleTemplate = GestureTemplate(
    id: 'master_gesture',
    normalizedPoints: samplePoints,
    rubineFeatureVector: sampleRubine,
    createdAtEpochMs: 1700000000000,
  );

  setUp(() async {
    testTempDir = await Directory.systemTemp.createTemp('musify_vault_integration_');
    database = VaultDatabase.forTesting(NativeDatabase.memory());
    cryptoBridge = FakeNativeVaultCryptoBridge();
    secureStorage = IntegrationFakeSecureStorage();
    monotonicClock = IntegrationFakeMonotonicClock();

    mediaIsolationManager = VaultMediaIsolationManager(
      baseDirectoryResolver: () async => testTempDir,
    );

    storageRepository = VaultStorageRepository(
      database: database,
      cryptoBridge: cryptoBridge,
      onShredMediaFiles: () async {
        await mediaIsolationManager.shredAllIsolatedMedia();
      },
    );

    authService = VaultAuthService(
      cryptoBridge: cryptoBridge,
      storageRepository: storageRepository,
      monotonicClock: monotonicClock,
      secureStorage: secureStorage,
    );

    mobiusController = IntegrationTestMobiusController();

    privacyProxy = PlaybackPrivacyProxy(
      vaultAuthService: authService,
      mobiusController: mobiusController,
      storageRepository: storageRepository,
      controlClient: mobiusController.client,
    );
    await privacyProxy.initialize();

    audioPlaybackService = VaultAudioPlaybackService(
      mobiusController: mobiusController,
      privacyProxy: privacyProxy,
      isolationManager: mediaIsolationManager,
    );
  });

  tearDown(() async {
    await privacyProxy.dispose();
    await authService.close();
    await mobiusController.close();
    await database.close();
    if (await testTempDir.exists()) {
      await testTempDir.delete(recursive: true);
    }
  });

  group('Phase 2 End-to-End Integration Verification (R1 - R7)', () {
    test('1. Android Native Target & Biometric Dependency Verification (R1)', () {
      final mainActivityFile = File('android/app/src/main/kotlin/um/musify/mu/musify_mu/MainActivity.kt');
      expect(mainActivityFile.existsSync(), isTrue);
      final mainActivitySource = mainActivityFile.readAsStringSync();
      expect(
        mainActivitySource.contains('class MainActivity : FlutterFragmentActivity()'),
        isTrue,
        reason: 'MainActivity MUST extend FlutterFragmentActivity for BiometricPrompt compatibility.',
      );
      expect(
        mainActivitySource.contains('VaultHardwareKeyStoreBridge(this)'),
        isTrue,
        reason: 'MainActivity MUST register VaultHardwareKeyStoreBridge.',
      );

      final gradleFile = File('android/app/build.gradle.kts');
      expect(gradleFile.existsSync(), isTrue);
      final gradleSource = gradleFile.readAsStringSync();
      expect(
        gradleSource.contains('androidx.biometric:biometric:1.2.0-alpha05'),
        isTrue,
        reason: 'Gradle build must declare androidx.biometric:1.2.0-alpha05 dependency.',
      );
    });

    test('2. Full Credential Enrollment & Hardware Offload KeyStore Provisioning (R2, R3)', () async {
      expect(await cryptoBridge.hasMasterKey(), isFalse);
      expect(authService.currentSessionState, isA<VaultUninitializedState>());

      final enrollResult = await authService.enrollInitialCredentials(
        pin: '849201',
        template: sampleTemplate,
      );
      expect(enrollResult, isA<VaultSuccess<void>>());

      // Hardware key generated in KeyStore
      expect(await cryptoBridge.hasMasterKey(), isTrue);

      // Transitioned to locked state
      expect(authService.currentSessionState, isA<VaultLockedState>());

      // Gesture template saved encrypted in database
      final templateResult = await storageRepository.loadGestureTemplate();
      expect(templateResult, isA<VaultSuccess<GestureTemplate>>());
      if (templateResult case VaultSuccess(:final data)) {
        expect(data.id, 'master_gesture');
        expect(data.normalizedPoints.length, 64);
        expect(data.rubineFeatureVector.length, 7);
      }
    });

    test('3. Raw Audio File Isolation, .nomedia Sentinel & Scoped Storage Fallback (R4)', () async {
      final sourceFile = File(p.join(testTempDir.path, 'original_source_track.mp3'));
      final sampleAudioBytes = Uint8List.fromList(
        List<int>.generate(2048, (i) => (i * 17 + 23) & 0xFF),
      );
      await sourceFile.writeAsBytes(sampleAudioBytes, flush: true);

      final isolationResult = await mediaIsolationManager.isolateTrackDetailed(
        sourceFilePath: sourceFile.path,
        trackId: 'track_sec_001',
      );

      expect(isolationResult.isolatedFile.existsSync(), isTrue);
      expect(isolationResult.relativePath, 'vault_media/.nomedia/track_sec_001.mp3');

      // Sentinel file exists
      final sentinelFile = File(p.join(testTempDir.path, 'vault_media', '.nomedia', '.nomedia'));
      expect(sentinelFile.existsSync(), isTrue);

      // Raw unencrypted audio verified byte-for-byte
      final isolatedBytes = await isolationResult.isolatedFile.readAsBytes();
      expect(isolatedBytes, equals(sampleAudioBytes));

      // Scoped Storage restriction fallback simulation
      final restrictedSource = File(p.join(testTempDir.path, 'restricted_source.mp3'));
      await restrictedSource.writeAsBytes(sampleAudioBytes, flush: true);

      final restrictedManager = VaultMediaIsolationManager(
        baseDirectoryResolver: () async => testTempDir,
        fileDeleter: (file) async {
          throw const FileSystemException(
            'Scoped Storage restriction on Android 10+',
            '',
            OSError('Permission denied', 13),
          );
        },
      );

      final fallbackResult = await restrictedManager.isolateTrackDetailed(
        sourceFilePath: restrictedSource.path,
        trackId: 'track_sec_002',
      );

      expect(fallbackResult.deletionResult, isA<ScopedStorageDeletionRestricted>());
      expect(fallbackResult.isolatedFile.existsSync(), isTrue);
    });

    test('4. Encrypted Metadata Storage & Direct Drift SQLite Ciphertext Inspection (R3)', () async {
      await authService.enrollInitialCredentials(
        pin: '123456',
        template: sampleTemplate,
      );

      final authResult = await authService.authenticateWithPin(pin: '123456');
      expect(authResult, isA<VaultSuccess<AuthSession>>());
      expect(authService.currentSessionState, isA<VaultUnlockedState>());

      const playlistTitle = 'Ultra Classified Album';
      const playlistDescription = 'Top Secret Vault Playlist Collection';
      const trackTitle = 'Stealth Operational Anthem';
      const trackArtist = 'Black Ops Ensemble';
      const trackAlbum = 'Dark Protocol Records';

      final playlistResult = await storageRepository.createPlaylist(
        name: playlistTitle,
        description: playlistDescription,
      );
      expect(playlistResult, isA<VaultSuccess<PrivatePlaylist>>());

      final String playlistId;
      if (playlistResult case VaultSuccess(:final data)) {
        playlistId = data.id;
      } else {
        fail('Playlist creation failed');
      }

      final trackRef = PrivateTrackRef(
        id: 'track_alpha_77',
        playlistId: playlistId,
        trackUri: 'spotify:track:classified_alpha_77',
        title: trackTitle,
        artistName: trackArtist,
        albumTitle: trackAlbum,
        durationMs: 245000,
        sourceType: TrackSourceTypeEnum.localSandbox,
        localRelativePath: 'vault_media/.nomedia/track_alpha_77.mp3',
        sortOrder: 0,
        addedAtEpochMs: 1700000000000,
      );

      final addTrackResult = await storageRepository.addTrackToPlaylist(
        playlistId: playlistId,
        trackRef: trackRef,
      );
      expect(addTrackResult, isA<VaultSuccess<void>>());

      // DIRECT SQLITE INSPECTION: Ensure raw rows contain ciphertext and ZERO plaintext
      final rawPlaylistRows = await database.customSelect('SELECT * FROM vault_playlists;').get();
      expect(rawPlaylistRows.length, 1);
      final rawRow = rawPlaylistRows.first;

      final rawTitleBytes = rawRow.read<Uint8List>('encrypted_title');
      final rawDescBytes = rawRow.read<Uint8List>('encrypted_description');
      expect(rawTitleBytes.length, greaterThanOrEqualTo(FakeNativeVaultCryptoBridge.minCiphertextEnvelopeBytes));
      expect(rawDescBytes.length, greaterThanOrEqualTo(FakeNativeVaultCryptoBridge.minCiphertextEnvelopeBytes));

      final rawTitleString = String.fromCharCodes(rawTitleBytes);
      final rawDescString = String.fromCharCodes(rawDescBytes);
      expect(rawTitleString.contains(playlistTitle), isFalse);
      expect(rawDescString.contains(playlistDescription), isFalse);

      final rawTrackRows = await database.customSelect('SELECT * FROM vault_track_refs;').get();
      expect(rawTrackRows.length, 1);
      final rawTrack = rawTrackRows.first;
      final rawTrackTitleBytes = rawTrack.read<Uint8List>('encrypted_title');
      final rawTrackTitleString = String.fromCharCodes(rawTrackTitleBytes);
      expect(rawTrackTitleString.contains(trackTitle), isFalse);
      expect(rawTrackTitleString.contains(trackArtist), isFalse);

      // Decrypted read-back via repository
      final fetchResult = await storageRepository.getPlaylistById(playlistId);
      expect(fetchResult, isA<VaultSuccess<PrivatePlaylist>>());
      if (fetchResult case VaultSuccess(:final data)) {
        expect(data.name, playlistTitle);
        expect(data.description, playlistDescription);
        expect(data.trackRefs.length, 1);
        expect(data.trackRefs.first.title, trackTitle);
        expect(data.trackRefs.first.artistName, trackArtist);
      }
    });

    test('5. Audio Playback Wiring, Mobius Dispatch & PlaybackPrivacyProxy (R6)', () async {
      await authService.enrollInitialCredentials(
        pin: '654321',
        template: sampleTemplate,
      );
      await authService.authenticateWithPin(pin: '654321');

      final trackRef = PrivateTrackRef(
        id: 'track_playback_99',
        playlistId: 'pl_001',
        trackUri: 'spotify:track:classified_99',
        title: 'Real Private Title',
        artistName: 'Real Private Artist',
        albumTitle: 'Real Private Album',
        durationMs: 180000,
        sourceType: TrackSourceTypeEnum.localSandbox,
        localRelativePath: 'vault_media/.nomedia/track_playback_99.mp3',
        sortOrder: 0,
        addedAtEpochMs: 1700000000000,
      );

      final isolatedPath = p.join(testTempDir.path, 'vault_media', '.nomedia', 'track_playback_99.mp3');

      // Save config with decoy persona
      final vaultConfig = VaultConfig(
        metadataVisibility: MetadataVisibilityPolicyEnum.maskWithPlaceholder,
        decoyTitle: 'Decoy Classical Song',
        decoyArtist: 'Decoy Symphony Orchestra',
        decoyAlbum: 'Decoy Serenade',
        lockPlaybackBehavior: LockPlaybackBehaviorEnum.stopImmediately,
      );
      await storageRepository.saveVaultConfig(vaultConfig);
      privacyProxy.updateConfig(vaultConfig);

      // Package unmasked track
      final unmaskedTrack = audioPlaybackService.packagePrivateTrack(
        trackRef: trackRef,
        isolatedFilePath: isolatedPath,
        config: vaultConfig.copyWith(
          metadataVisibility: MetadataVisibilityPolicyEnum.showActualMetadata,
        ),
      );
      expect(unmaskedTrack.metadata[ContextTrackMetadata.keyIsLocal], 'true');
      expect(unmaskedTrack.metadata[ContextTrackMetadata.keyLocalFilePath], isolatedPath);
      expect(unmaskedTrack.metadata[ContextTrackMetadata.keyTitle], 'Real Private Title');
      expect(unmaskedTrack.metadata[ContextTrackMetadata.keyArtistName], 'Real Private Artist');

      // Decoy projected track under maskWithPlaceholder
      final decoyProjected = privacyProxy.projectTrack(unmaskedTrack);
      expect(decoyProjected.metadata[ContextTrackMetadata.keyTitle], 'Decoy Classical Song');
      expect(decoyProjected.metadata[ContextTrackMetadata.keyArtistName], 'Decoy Symphony Orchestra');

      // Play track
      await audioPlaybackService.playPrivateTrack(
        trackRef: trackRef,
        isolatedFilePath: isolatedPath,
        config: vaultConfig,
      );

      expect(mobiusController.playContextCalls, 1);
      expect(mobiusController.lastPlayedContext, isNotNull);
      expect(privacyProxy.isVaultTrackActive, isTrue);
      expect(privacyProxy.isDecoyActive, isTrue);

      // Dynamic config update: showActualMetadata unmasks projection
      final unmaskedConfig = vaultConfig.copyWith(
        metadataVisibility: MetadataVisibilityPolicyEnum.showActualMetadata,
      );
      privacyProxy.updateConfig(unmaskedConfig);
      expect(privacyProxy.isDecoyActive, isFalse);

      final unmaskedProjected = privacyProxy.projectTrack(unmaskedTrack);
      expect(unmaskedProjected.metadata[ContextTrackMetadata.keyTitle], 'Real Private Title');
      expect(unmaskedProjected.metadata[ContextTrackMetadata.keyArtistName], 'Real Private Artist');
    });

    test('6. Vault Lock Strategy Execution, Queue Purge & Buffer Wiping (R2, R5, R6)', () async {
      await authService.enrollInitialCredentials(
        pin: '112233',
        template: sampleTemplate,
      );
      await authService.authenticateWithPin(pin: '112233');

      final trackRef = PrivateTrackRef(
        id: 'track_lock_test',
        playlistId: 'pl_lock',
        trackUri: 'spotify:track:lock_test',
        title: 'Lock Test Song',
        artistName: 'Lock Test Artist',
        albumTitle: 'Lock Test Album',
        durationMs: 120000,
        sourceType: TrackSourceTypeEnum.localSandbox,
        localRelativePath: 'vault_media/.nomedia/track_lock_test.mp3',
        sortOrder: 0,
        addedAtEpochMs: 1700000000000,
      );

      final isolatedPath = p.join(testTempDir.path, 'vault_media', '.nomedia', 'track_lock_test.mp3');

      final vaultConfig = VaultConfig(
        lockPlaybackBehavior: LockPlaybackBehaviorEnum.stopImmediately,
      );
      await storageRepository.saveVaultConfig(vaultConfig);
      privacyProxy.updateConfig(vaultConfig);

      await audioPlaybackService.playPrivateTrack(
        trackRef: trackRef,
        isolatedFilePath: isolatedPath,
        config: vaultConfig,
      );
      expect(privacyProxy.isVaultTrackActive, isTrue);

      // Lock session
      authService.clearSessionKeysFromRam();
      await Future<void>.delayed(Duration.zero);

      // Native session locked in hardware bridge
      expect(cryptoBridge.isSessionUnlocked, isFalse);
      expect(authService.currentSessionState, isA<VaultLockedState>());

      // Privacy proxy executed stopImmediately strategy:
      // Player stopped, ClearQueueEvent dispatched, transitioned to public passthrough
      expect(mobiusController.client.stopCallCount, greaterThanOrEqualTo(1));
      expect(mobiusController.dispatchedEvents.whereType<ClearQueueEvent>().isNotEmpty, isTrue);
      expect(privacyProxy.isIdle, isTrue);
    });

    test('7. Brute-Force Monotonic Lockout Escalation & Restart Persistence (R3)', () async {
      await authService.enrollInitialCredentials(
        pin: '998877',
        template: sampleTemplate,
      );

      // Simulate 5 incorrect PIN attempts
      for (var i = 0; i < 5; i++) {
        final result = await authService.authenticateWithPin(pin: '000000');
        expect(result, isA<VaultFailureResult<AuthSession>>());
      }

      // Tier 1 lockout active (30 seconds)
      expect(authService.currentSessionState, isA<VaultLockoutCooldownState>());
      final lockoutState = authService.currentSessionState as VaultLockoutCooldownState;
      expect(lockoutState.durationMs, 30000);

      // Monotonic deadline persisted to Drift SQLite database
      final persistedDeadline = await storageRepository.getPersistedLockoutDeadlineMs();
      expect(persistedDeadline, isNotNull);
      expect(persistedDeadline, equals(lockoutState.deadlineMonotonicMs));

      // Simulate process restart with brand new repository instance reading database
      final restartedRepository = VaultStorageRepository(
        database: database,
        cryptoBridge: cryptoBridge,
      );
      final readBackDeadline = await restartedRepository.getPersistedLockoutDeadlineMs();
      expect(readBackDeadline, equals(persistedDeadline));

      // Attempting PIN before deadline expiration fails immediately with VaultLockoutFailure
      final throttledResult = await authService.authenticateWithPin(pin: '998877');
      expect(throttledResult, isA<VaultFailureResult<AuthSession>>());
      if (throttledResult case VaultFailureResult(:final failure)) {
        expect(failure, isA<VaultLockoutFailure>());
      }
    });

    test('8. Slot 2 Biometric Invalidation Triggers CryptoFault & Slot 1 PIN Fallback (R2)', () async {
      await authService.enrollInitialCredentials(
        pin: '554433',
        template: sampleTemplate,
      );

      final config = VaultConfig(
        biometricAuth: BiometricAuthPolicyEnum.pinAndBiometricStrong,
      );
      await storageRepository.saveVaultConfig(config);

      // Simulate OS biometric change invalidating hardware KeyStore key
      cryptoBridge.simulateBiometricInvalidation = true;

      final bioResult = await authService.authenticateWithBiometrics();
      expect(bioResult, isA<VaultFailureResult<AuthSession>>());

      // Crypto fault emitted
      expect(authService.currentCryptoState, isA<CryptoEngineCryptoFaultState>());

      // Session transitioned to Slot 1 fallback recovery
      expect(authService.currentSessionState, isA<VaultAuthenticatingState>());
      final authState = authService.currentSessionState as VaultAuthenticatingState;
      expect(authState.authSessionId, 'slot1-fallback-recovery');

      // Slot 1 PIN recovery succeeds
      final recoveryResult = await authService.authenticateWithPin(pin: '554433');
      expect(recoveryResult, isA<VaultSuccess<AuthSession>>());
      expect(authService.currentSessionState, isA<VaultUnlockedState>());
    });

    test('9. Atomic Purge Routine Shreds SQLite, Files & KeyStore Aliases (R3, R4)', () async {
      await authService.enrollInitialCredentials(
        pin: '776655',
        template: sampleTemplate,
      );
      await authService.authenticateWithPin(pin: '776655');

      await storageRepository.createPlaylist(
        name: 'Playlist To Be Shredded',
        description: 'Temporary',
      );

      final dummyFile = File(p.join(testTempDir.path, 'vault_media', '.nomedia', 'purged_track.mp3'));
      dummyFile.parent.createSync(recursive: true);
      await dummyFile.writeAsBytes([1, 2, 3, 4, 5], flush: true);

      // Execute purge
      final purgeResult = await storageRepository.purgeAllVaultData();
      expect(purgeResult, isA<VaultSuccess<void>>());

      // KeyStore master key destroyed
      expect(await cryptoBridge.hasMasterKey(), isFalse);

      // Playlists shredded
      final playlists = await database.select(database.vaultPlaylistsTable).get();
      expect(playlists, isEmpty);

      // Isolated files shredded
      expect(dummyFile.existsSync(), isFalse);
    });

    test('10. Strict Verification of Zero Forbidden Audio Libraries in Vault Code (R6)', () {
      final vaultDir = Directory('lib/features/vault');
      expect(vaultDir.existsSync(), isTrue);

      final forbiddenTokens = <String>['just_audio', 'audio_service', 'exoplayer'];
      final violations = <String>[];

      for (final file in vaultDir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
          final line = lines[lineIndex];
          for (final token in forbiddenTokens) {
            if (line.toLowerCase().contains(token)) {
              violations.add('${file.path}:${lineIndex + 1}: $line');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Forbidden audio library references discovered in lib/features/vault/:\n${violations.join('\n')}',
      );
    });
  });
}
