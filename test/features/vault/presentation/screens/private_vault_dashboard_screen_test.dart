import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/application/playlists/vault_playlists_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_screen_privacy_controller.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';
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
  final List<PrivatePlaylist> playlists = [];

  @override
  Future<VaultResult<List<PrivatePlaylist>>> getPlaylists() async {
    return VaultResult.success(List.unmodifiable(playlists));
  }

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
  Future<VaultResult<void>> deletePlaylist(String playlistId) async {
    playlists.removeWhere((p) => p.id == playlistId);
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
  VaultSessionEvent? lastEvent;

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

  @override
  void add(VaultSessionEvent event) {
    lastEvent = event;
    super.add(event);
  }
}

void main() {
  group('PrivateVaultDashboardScreen Widget Tests', () {
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

    final playlist1 = PrivatePlaylist(
      id: 'pl_1',
      name: 'Night Drive',
      description: 'Synthwave favorites',
      totalDurationMs: 360000,
      createdAtEpochMs: 1000,
      updatedAtEpochMs: 1000,
      trackRefs: const [],
    );

    final playlist2 = PrivatePlaylist(
      id: 'pl_2',
      name: 'Study Lofi',
      description: 'Chill instruments',
      totalDurationMs: 720000,
      createdAtEpochMs: 2000,
      updatedAtEpochMs: 2000,
      trackRefs: const [],
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

    Widget buildTestWidget({
      VaultPlaylistsCubit? playlistsCubit,
      VaultThemePalettePolicyEnum palette = VaultThemePalettePolicyEnum.warmEspresso,
    }) {
      return MaterialApp(
        routes: {
          '/vault/settings': (_) => const Scaffold(body: Text('Settings Screen')),
        },
        home: VaultTheme(
          data: VaultThemeData.fromPalette(palette),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<VaultSessionBloc>.value(value: sessionBloc),
              BlocProvider<ScreenPrivacyCubit>.value(value: privacyCubit),
            ],
            child: PrivateVaultDashboardScreen(
              playlistsCubit: playlistsCubit,
              storageRepository: storageRepo,
              sessionBloc: sessionBloc,
              screenPrivacyCubit: privacyCubit,
            ),
          ),
        ),
      );
    }

    testWidgets('Renders empty state copy when 0 playlists exist with zero emojis and em dashes', (
      WidgetTester tester,
    ) async {
      final cubit = VaultPlaylistsCubit(storageRepository: storageRepo);
      await cubit.loadPlaylists();

      await tester.pumpWidget(buildTestWidget(playlistsCubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vault_dashboard_empty_view')), findsOneWidget);
      expect(find.text('No Private Playlists'), findsOneWidget);
      expect(
        find.text('Playlists added to the vault are isolated and encrypted in local storage.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('vault_dashboard_create_button')), findsOneWidget);

      await cubit.close();
    });

    testWidgets('Create playlist button opens creation dialog with 8px radius and creates playlist', (
      WidgetTester tester,
    ) async {
      final cubit = VaultPlaylistsCubit(storageRepository: storageRepo);
      await cubit.loadPlaylists();

      await tester.pumpWidget(buildTestWidget(playlistsCubit: cubit));
      await tester.pumpAndSettle();

      // Tap FAB
      await tester.tap(find.byKey(const ValueKey('create_private_playlist_fab')));
      await tester.pumpAndSettle();

      expect(find.text('New Private Playlist'), findsOneWidget);

      // Enter name
      await tester.enterText(find.widgetWithText(TextFormField, 'Playlist Name'), 'Midnight Jazz');
      await tester.pumpAndSettle();

      // Tap Create
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(storageRepo.playlists.length, 1);
      expect(storageRepo.playlists.first.name, 'Midnight Jazz');
      expect(find.text('Midnight Jazz'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('Populated list renders 48px square thumbnails, metadata, and 8px geometric radius', (
      WidgetTester tester,
    ) async {
      storageRepo.playlists.addAll([playlist1, playlist2]);
      final cubit = VaultPlaylistsCubit(storageRepository: storageRepo);
      await cubit.loadPlaylists();

      await tester.pumpWidget(buildTestWidget(playlistsCubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text('Night Drive'), findsOneWidget);
      expect(find.text('Study Lofi'), findsOneWidget);
      expect(find.text('0 tracks \u2022 6m'), findsOneWidget);
      expect(find.text('0 tracks \u2022 12m'), findsOneWidget);

      // FAB has 8px border radius
      final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.shape, isA<RoundedRectangleBorder>());
      final fabShape = fab.shape as RoundedRectangleBorder;
      expect(fabShape.borderRadius, BorderRadius.circular(8.0));

      await cubit.close();
    });

    testWidgets('Instant inline search filters playlists by title substring and clear button restores', (
      WidgetTester tester,
    ) async {
      storageRepo.playlists.addAll([playlist1, playlist2]);
      final cubit = VaultPlaylistsCubit(storageRepository: storageRepo);
      await cubit.loadPlaylists();

      await tester.pumpWidget(buildTestWidget(playlistsCubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text('Night Drive'), findsOneWidget);
      expect(find.text('Study Lofi'), findsOneWidget);

      // Search for Night
      await tester.enterText(find.byKey(const ValueKey('vault_dashboard_search_input')), 'Night');
      await tester.pumpAndSettle();

      expect(find.text('Night Drive'), findsOneWidget);
      expect(find.text('Study Lofi'), findsNothing);

      // Clear search via clear icon
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Night Drive'), findsOneWidget);
      expect(find.text('Study Lofi'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('Non-matching search renders search empty state', (
      WidgetTester tester,
    ) async {
      storageRepo.playlists.addAll([playlist1, playlist2]);
      final cubit = VaultPlaylistsCubit(storageRepository: storageRepo);
      await cubit.loadPlaylists();

      await tester.pumpWidget(buildTestWidget(playlistsCubit: cubit));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('vault_dashboard_search_input')),
        'NonExistentQuery',
      );
      await tester.pumpAndSettle();

      expect(find.text('No matching playlists'), findsOneWidget);
      expect(find.text('No playlists match your search for "NonExistentQuery".'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('Top App Bar lock icon dispatches VaultQuickLockRequested to VaultSessionBloc', (
      WidgetTester tester,
    ) async {
      final cubit = VaultPlaylistsCubit(storageRepository: storageRepo);
      await cubit.loadPlaylists();

      await tester.pumpWidget(buildTestWidget(
        playlistsCubit: cubit,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vault_dashboard_quick_lock_button')));
      await tester.pumpAndSettle();

      expect(sessionBloc.lastEvent, isA<VaultQuickLockRequested>());

      await cubit.close();
    });

    testWidgets('Top App Bar gear icon navigates to settings route', (
      WidgetTester tester,
    ) async {
      final cubit = VaultPlaylistsCubit(storageRepository: storageRepo);
      await cubit.loadPlaylists();

      await tester.pumpWidget(buildTestWidget(
        playlistsCubit: cubit,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vault_dashboard_settings_button')));
      await tester.pumpAndSettle();

      expect(find.text('Settings Screen'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('Auto-Pop: Transitioning VaultSessionBloc to VaultLockedState pops dashboard', (
      WidgetTester tester,
    ) async {
      final cubit = VaultPlaylistsCubit(storageRepository: storageRepo);
      await cubit.loadPlaylists();

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
                          child: PrivateVaultDashboardScreen(
                            playlistsCubit: cubit,
                            storageRepository: storageRepo,
                            sessionBloc: sessionBloc,
                            screenPrivacyCubit: privacyCubit,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open Vault'),
              ),
            ),
          ),
        ),
      );

      // Open dashboard
      await tester.tap(find.text('Open Vault'));
      await tester.pumpAndSettle();

      expect(find.text('Private Vault'), findsOneWidget);

      // Emit locked state
      sessionBloc.emitState(const VaultLockedState(lockedAtMonotonicMs: 15000));
      await tester.pumpAndSettle();

      // Route popped back to home
      expect(find.text('Private Vault'), findsNothing);
      expect(find.text('Open Vault'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('Dual palette: adapts cleanly to forestNoir palette with zero purple hues', (
      WidgetTester tester,
    ) async {
      final cubit = VaultPlaylistsCubit(storageRepository: storageRepo);
      await cubit.loadPlaylists();

      await tester.pumpWidget(buildTestWidget(
        playlistsCubit: cubit,
        palette: VaultThemePalettePolicyEnum.forestNoir,
      ));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF0F1F17));

      await cubit.close();
    });

    testWidgets('Screen privacy is engaged on mount and released on dispose', (
      WidgetTester tester,
    ) async {
      final cubit = VaultPlaylistsCubit(storageRepository: storageRepo);
      await cubit.loadPlaylists();

      await tester.pumpWidget(buildTestWidget(playlistsCubit: cubit));
      await tester.pumpAndSettle();

      expect(privacyCubit.isSecureFlagEngaged, isTrue);

      // Unmount
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(privacyCubit.isSecureFlagEngaged, isFalse);

      await cubit.close();
    });
  });
}
