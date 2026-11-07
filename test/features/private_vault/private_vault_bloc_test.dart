import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/private_vault/application/private_vault_bloc.dart';
import 'package:musify_mu/features/private_vault/domain/models/gesture_pattern.dart';
import 'package:musify_mu/features/private_vault/domain/models/private_playlist.dart';
import 'package:musify_mu/features/private_vault/domain/models/vault_settings.dart';
import 'package:musify_mu/features/private_vault/domain/repositories/i_vault_storage_service.dart';
import 'package:musify_mu/features/private_vault/domain/services/gesture_grid_recognizer.dart';
import 'package:musify_mu/features/private_vault/domain/services/i_native_security_channel.dart';
import 'package:musify_mu/features/private_vault/domain/services/i_vault_auth_service.dart';

class MockVaultStorageService implements IVaultStorageService {
  List<PrivatePlaylist> playlists = [];
  VaultSettings settings = VaultSettings.defaultSettings;
  GesturePattern pattern = GesturePattern.defaultPattern;
  bool memoryPurged = false;

  @override
  Future<List<PrivatePlaylist>> loadPlaylists() async => playlists;

  @override
  Future<void> savePlaylists(List<PrivatePlaylist> newPlaylists) async {
    playlists = List.from(newPlaylists);
  }

  @override
  Future<VaultSettings> loadSettings() async => settings;

  @override
  Future<void> saveSettings(VaultSettings newSettings) async {
    settings = newSettings;
  }

  @override
  Future<GesturePattern> loadGesturePattern() async => pattern;

  @override
  Future<void> saveGesturePattern(GesturePattern newPattern) async {
    pattern = newPattern;
  }

  @override
  void purgeDecryptedMemory() {
    memoryPurged = true;
  }
}

class MockVaultAuthService implements IVaultAuthService {
  BiometricAuthStatus nextStatus = BiometricAuthStatus.success;

  @override
  Future<bool> isBiometricAvailable() async => true;

  @override
  Future<BiometricAuthStatus> authenticate({required String localizedReason}) async {
    return nextStatus;
  }
}

class MockNativeSecurityChannel implements INativeSecurityChannel {
  bool? lastFlagSecure;

  @override
  Future<void> setFlagSecure({required bool enabled}) async {
    lastFlagSecure = enabled;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrivateVaultBloc State Machine Tests', () {
    late MockVaultStorageService mockStorage;
    late MockVaultAuthService mockAuth;
    late MockNativeSecurityChannel mockSecurity;
    late IGestureRecognizerService recognizer;
    late PrivateVaultBloc bloc;

    setUp(() {
      mockStorage = MockVaultStorageService();
      mockAuth = MockVaultAuthService();
      mockSecurity = MockNativeSecurityChannel();
      recognizer = const GestureGridRecognizer();

      bloc = PrivateVaultBloc(
        storageService: mockStorage,
        authService: mockAuth,
        securityChannel: mockSecurity,
        gestureRecognizer: recognizer,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is VaultStateLocked with default settings', () {
      expect(bloc.state, isA<VaultStateLocked>());
      expect(bloc.state.settings, VaultSettings.defaultSettings);
    });

    test('successful authentication unlocks vault and enables FLAG_SECURE', () async {
      mockAuth.nextStatus = BiometricAuthStatus.success;
      bloc.add(const VaultAuthRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<VaultStateAuthenticating>(),
          isA<VaultStateActive>(),
        ]),
      );

      expect(mockSecurity.lastFlagSecure, true);
    });

    test('canceled authentication returns state to VaultStateLocked', () async {
      mockAuth.nextStatus = BiometricAuthStatus.canceled;
      bloc.add(const VaultAuthRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<VaultStateAuthenticating>(),
          isA<VaultStateLocked>(),
        ]),
      );
    });

    test('lock request purges decrypted memory and clears FLAG_SECURE', () async {
      mockAuth.nextStatus = BiometricAuthStatus.success;
      bloc.add(const VaultAuthRequested());
      await bloc.stream.firstWhere((s) => s is VaultStateActive);

      bloc.add(const VaultLockRequested());

      await expectLater(
        bloc.stream,
        emits(isA<VaultStateLocked>()),
      );

      expect(mockStorage.memoryPurged, true);
      expect(mockSecurity.lastFlagSecure, false);
    });

    test('creates private playlist and updates state sequentially', () async {
      mockAuth.nextStatus = BiometricAuthStatus.success;
      bloc.add(const VaultAuthRequested());
      await bloc.stream.firstWhere((s) => s is VaultStateActive);

      bloc.add(const VaultPlaylistCreateRequested(
        name: 'Late Night Classified',
        description: 'Testing vault isolation',
      ));

      final state = await bloc.stream.firstWhere(
        (s) => s is VaultStateActive && s.playlists.isNotEmpty,
      ) as VaultStateActive;

      expect(state.playlists.length, 1);
      expect(state.playlists.first.name, 'Late Night Classified');
      expect(mockStorage.playlists.length, 1);
    });

    test('rejects duplicate playlist names in vault', () async {
      mockAuth.nextStatus = BiometricAuthStatus.success;
      bloc.add(const VaultAuthRequested());
      await bloc.stream.firstWhere((s) => s is VaultStateActive);

      bloc.add(const VaultPlaylistCreateRequested(name: 'Duplicate Test'));
      await bloc.stream.firstWhere(
        (s) => s is VaultStateActive && s.playlists.isNotEmpty,
      );

      bloc.add(const VaultPlaylistCreateRequested(name: 'duplicate test'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<VaultStateFailure>(),
          isA<VaultStateActive>(),
        ]),
      );
    });

    test('deletes private playlist correctly', () async {
      mockAuth.nextStatus = BiometricAuthStatus.success;
      bloc.add(const VaultAuthRequested());
      await bloc.stream.firstWhere((s) => s is VaultStateActive);

      bloc.add(const VaultPlaylistCreateRequested(name: 'To Delete'));
      final stateWithPlaylist = await bloc.stream.firstWhere(
        (s) => s is VaultStateActive && s.playlists.isNotEmpty,
      ) as VaultStateActive;

      final playlistId = stateWithPlaylist.playlists.first.id;
      bloc.add(VaultPlaylistDeleteRequested(playlistId: playlistId));

      final stateAfterDelete = await bloc.stream.firstWhere(
        (s) => s is VaultStateActive && s.playlists.isEmpty,
      ) as VaultStateActive;

      expect(stateAfterDelete.playlists.isEmpty, true);
    });

    test('adds and removes track URIs within a private playlist', () async {
      mockAuth.nextStatus = BiometricAuthStatus.success;
      bloc.add(const VaultAuthRequested());
      await bloc.stream.firstWhere((s) => s is VaultStateActive);

      bloc.add(const VaultPlaylistCreateRequested(name: 'Track Holder'));
      final stateWithPlaylist = await bloc.stream.firstWhere(
        (s) => s is VaultStateActive && s.playlists.isNotEmpty,
      ) as VaultStateActive;

      final playlistId = stateWithPlaylist.playlists.first.id;

      // Add track
      bloc.add(VaultTrackAddRequested(
        playlistId: playlistId,
        trackUri: '/storage/music/secret_track.flac',
      ));

      final stateWithTrack = await bloc.stream.firstWhere(
        (s) =>
            s is VaultStateActive &&
            s.playlists.first.trackUris.isNotEmpty,
      ) as VaultStateActive;

      expect(stateWithTrack.playlists.first.trackUris.length, 1);
      expect(stateWithTrack.playlists.first.trackUris.first, '/storage/music/secret_track.flac');

      // Remove track
      bloc.add(VaultTrackRemoveRequested(
        playlistId: playlistId,
        trackUri: '/storage/music/secret_track.flac',
      ));

      final stateAfterRemove = await bloc.stream.firstWhere(
        (s) =>
            s is VaultStateActive &&
            s.playlists.first.trackUris.isEmpty,
      ) as VaultStateActive;

      expect(stateAfterRemove.playlists.first.trackUris.isEmpty, true);
    });

    test('immediate cool-off locks vault upon app pause', () async {
      mockAuth.nextStatus = BiometricAuthStatus.success;
      bloc.add(const VaultAuthRequested());
      await bloc.stream.firstWhere((s) => s is VaultStateActive);

      // Set cool-off to immediate
      bloc.add(const VaultSettingsUpdateRequested(
        newSettings: VaultSettings(
          coolOffDuration: CoolOffDuration.immediate,
          maskMediaSession: true,
          preventScreenshots: true,
          theme: VaultTheme.deepMoss,
          showDrawerGestureTrail: false,
        ),
      ));
      await bloc.stream.firstWhere((s) => s.settings.coolOffDuration == CoolOffDuration.immediate);

      // App pauses
      bloc.add(VaultLifecycleAppPaused(pausedAt: DateTime.now()));

      await expectLater(
        bloc.stream,
        emits(isA<VaultStateLocked>()),
      );
    });

    test('exiting vault screen enters VaultStateStandby when cool-off is active', () async {
      mockAuth.nextStatus = BiometricAuthStatus.success;
      bloc.add(const VaultAuthRequested());
      await bloc.stream.firstWhere((s) => s is VaultStateActive);

      bloc.add(const VaultScreenExited());

      final standbyState = await bloc.stream.firstWhere((s) => s is VaultStateStandby);
      expect(standbyState, isA<VaultStateStandby>());
    });

    test('drawing gesture in VaultStateStandby returns to VaultStateActive without prompting biometrics', () async {
      mockAuth.nextStatus = BiometricAuthStatus.success;
      bloc.add(const VaultAuthRequested());
      await bloc.stream.firstWhere((s) => s is VaultStateActive);

      // User exits vault screen
      bloc.add(const VaultScreenExited());
      await bloc.stream.firstWhere((s) => s is VaultStateStandby);

      // Set mockAuth to failed to verify biometrics are bypassed completely
      mockAuth.nextStatus = BiometricAuthStatus.failed;

      // Draw the canonical P stroke in the drawer
      final rawP = <Offset>[
        const Offset(20, 20),
        const Offset(20, 50),
        const Offset(20, 100),
        const Offset(20, 150),
        const Offset(20, 180),
        const Offset(20, 100),
        const Offset(20, 20),
        const Offset(50, 20),
        const Offset(80, 40),
        const Offset(90, 60),
        const Offset(80, 80),
        const Offset(50, 100),
        const Offset(20, 100),
      ];
      bloc.add(VaultGestureStrokeReceived(
        strokePoints: rawP,
        canvasSize: const Size(200, 200),
      ));

      // Must emit VaultStateActive directly
      final activeState = await bloc.stream.firstWhere((s) => s is VaultStateActive);
      expect(activeState, isA<VaultStateActive>());
    });

    test('VaultStandbyExpired transitions to VaultStateLocked and purges memory', () async {
      mockAuth.nextStatus = BiometricAuthStatus.success;
      bloc.add(const VaultAuthRequested());
      await bloc.stream.firstWhere((s) => s is VaultStateActive);

      bloc.add(const VaultScreenExited());
      await bloc.stream.firstWhere((s) => s is VaultStateStandby);

      bloc.add(const VaultStandbyExpired());

      final lockedState = await bloc.stream.firstWhere((s) => s is VaultStateLocked);
      expect(lockedState, isA<VaultStateLocked>());
      expect(mockStorage.memoryPurged, true);
    });

    test('exiting vault screen with immediate cool-off transitions directly to VaultStateLocked', () async {
      mockAuth.nextStatus = BiometricAuthStatus.success;
      bloc.add(const VaultAuthRequested());
      await bloc.stream.firstWhere((s) => s is VaultStateActive);

      bloc.add(const VaultSettingsUpdateRequested(
        newSettings: VaultSettings(
          coolOffDuration: CoolOffDuration.immediate,
          maskMediaSession: true,
          preventScreenshots: true,
          theme: VaultTheme.deepMoss,
          showDrawerGestureTrail: false,
        ),
      ));
      await bloc.stream.firstWhere((s) => s.settings.coolOffDuration == CoolOffDuration.immediate);

      bloc.add(const VaultScreenExited());

      final lockedState = await bloc.stream.firstWhere((s) => s is VaultStateLocked);
      expect(lockedState, isA<VaultStateLocked>());
      expect(mockStorage.memoryPurged, true);
    });
  });
}
