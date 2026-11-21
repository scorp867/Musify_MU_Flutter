import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/app/di/mode_persistence.dart';
import 'package:musify_mu/app/routes/vault_routes.dart';
import 'package:musify_mu/app/theme/app_theme.dart';
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/network/status/bloc/network_status_bloc.dart';
import 'package:musify_mu/core/ubi/data/lifecycle/page_instance_id_holder.dart';
import 'package:musify_mu/core/ubi/domain/logging/ubi_logger.dart';
import 'package:musify_mu/core/ui/scroll/app_scroll_behavior.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/browse/application/browse_bloc.dart';
import 'package:musify_mu/features/connect/application/lifecycle/connect_session_coordinator.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/domain/interfaces/audio_route_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/device_environment_port.dart';
import 'package:musify_mu/features/connect/domain/services/connect_output_status_policy.dart';
import 'package:musify_mu/features/home_feed/application/home_feed_bloc.dart';
import 'package:musify_mu/features/library/application/library_bloc.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_bloc.dart';
import 'package:musify_mu/features/player/application/queue/player_queue_bloc.dart';
import 'package:musify_mu/features/player/data/logging/player_logging_params_factory.dart';
import 'package:musify_mu/features/player/domain/repositories/lyrics_repository.dart';
import 'package:musify_mu/features/player/domain/repositories/scrollsita_repository.dart';
import 'package:musify_mu/features/shell/presentation/hidden_drawer_scaffold.dart';
import 'package:musify_mu/features/vault/application/coordinator/vault_coordinator.dart';
import 'package:musify_mu/features/vault/application/gesture/gesture_engine_cubit.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/data/services/playback_privacy_proxy.dart';
import 'package:musify_mu/features/vault/data/services/vault_audio_playback_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/usecases/purge_vault_data_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/rotate_pin_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';

/// Root application composition root wiring Vault, Player Queue, Now Playing
/// repositories (`ScrollSitaRepository`, `LyricsRepository`), and auth-gated
/// Spotify Connect (`ConnectSessionCoordinator` / `p199p/yrq.java` / `p199p/C2406w.java`).
class MusifyApp extends StatefulWidget {
  final AuthBloc Function() createAuthBloc;
  final LocalMusicBloc Function()? createLocalMusicBloc;
  final ConnectMobiusController? connectController;
  final ConnectSessionCoordinator? connectSessionCoordinator;
  final ConnectOutputStatusPolicy? connectOutputStatusPolicy;
  final DeviceEnvironmentPort? deviceEnvironmentPort;
  final AudioRoutePort? audioRoutePort;
  final ScrollSitaRepository? scrollSitaRepository;
  final LyricsRepository? lyricsRepository;

  const MusifyApp({
    super.key,
    required this.createAuthBloc,
    this.createLocalMusicBloc,
    this.connectController,
    this.connectSessionCoordinator,
    this.connectOutputStatusPolicy,
    this.deviceEnvironmentPort,
    this.audioRoutePort,
    this.scrollSitaRepository,
    this.lyricsRepository,
  });

  @override
  State<MusifyApp> createState() => _MusifyAppState();
}

class _MusifyAppState extends State<MusifyApp> with WidgetsBindingObserver {
  AuthBloc? _authBloc;
  ConnectSessionCoordinator? _connectSessionCoordinator;
  VaultCoordinator? _vaultCoordinator;
  final GlobalKey _materialAppKey = GlobalKey();
  final ValueNotifier<ConnectMobiusController?> _connectControllerNotifier =
      ValueNotifier<ConnectMobiusController?>(null);
  final List<NavigatorObserver> _navigatorObservers = <NavigatorObserver>[];
  StreamSubscription<VaultNavigationTarget>? _navSubscription;
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  ConnectMobiusController? _resolveConnectController() {
    if (widget.connectController case final external?) {
      return external;
    }
    if (!getIt.isRegistered<ConnectMobiusController>()) {
      return null;
    }
    return getIt<ConnectMobiusController>();
  }

  ConnectSessionCoordinator? _resolveConnectSessionCoordinator() {
    if (widget.connectSessionCoordinator case final external?) {
      return external;
    }
    if (!getIt.isRegistered<ConnectSessionCoordinator>()) {
      return null;
    }
    return getIt<ConnectSessionCoordinator>();
  }

  ConnectOutputStatusPolicy _resolveConnectOutputStatusPolicy() {
    if (widget.connectOutputStatusPolicy case final external?) {
      return external;
    }
    if (getIt.isRegistered<ConnectOutputStatusPolicy>()) {
      return getIt<ConnectOutputStatusPolicy>();
    }
    return ConnectOutputStatusPolicy.instance;
  }

  DeviceEnvironmentPort? _resolveDeviceEnvironmentPort() {
    if (widget.deviceEnvironmentPort case final external?) {
      return external;
    }
    if (getIt.isRegistered<DeviceEnvironmentPort>()) {
      return getIt<DeviceEnvironmentPort>();
    }
    return null;
  }

  AudioRoutePort? _resolveAudioRoutePort() {
    if (widget.audioRoutePort case final external?) {
      return external;
    }
    if (getIt.isRegistered<AudioRoutePort>()) {
      return getIt<AudioRoutePort>();
    }
    return null;
  }

  ScrollSitaRepository? _resolveScrollSitaRepository() {
    if (widget.scrollSitaRepository case final external?) {
      return external;
    }
    if (getIt.isRegistered<ScrollSitaRepository>()) {
      return getIt<ScrollSitaRepository>();
    }
    return null;
  }

  LyricsRepository? _resolveLyricsRepository() {
    if (widget.lyricsRepository case final external?) {
      return external;
    }
    if (getIt.isRegistered<LyricsRepository>()) {
      return getIt<LyricsRepository>();
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final authBloc = widget.createAuthBloc();
    _authBloc = authBloc;

    final initialConnectController = _resolveConnectController();
    if (!identical(_connectControllerNotifier.value, initialConnectController)) {
      _connectControllerNotifier.value = initialConnectController;
    }

    // Bind auth-gated Connect lifecycle coordinator instead of starting
    // native Connect prematurely before authentication succeeds.
    final coordinator = _resolveConnectSessionCoordinator();
    if (coordinator != null) {
      _connectSessionCoordinator = coordinator;
      coordinator.bindAuthBloc(authBloc);
    }

    if (getIt.isRegistered<VaultRouteObserver>()) {
      _navigatorObservers.add(getIt<VaultRouteObserver>());
    } else if (getIt.isRegistered<ScreenPrivacyCubit>()) {
      _navigatorObservers.add(
        VaultRouteObserver(privacyCubit: getIt<ScreenPrivacyCubit>()),
      );
    }

    if (getIt.isRegistered<VaultCoordinator>()) {
      final vaultCoordinator = getIt<VaultCoordinator>()..initialize();
      _vaultCoordinator = vaultCoordinator;
      _navSubscription =
          vaultCoordinator.navigationStream.listen(_handleVaultNavigation);
    }
    if (getIt.isRegistered<GestureEngineCubit>()) {
      getIt<GestureEngineCubit>().initialize();
    }
    if (getIt.isRegistered<PlaybackPrivacyProxy>()) {
      getIt<PlaybackPrivacyProxy>().initialize();
    }
    if (getIt.isRegistered<SettingsMutationCubit>()) {
      getIt<SettingsMutationCubit>().initialize();
    }
    if (getIt.isRegistered<VaultSessionBloc>()) {
      getIt<VaultSessionBloc>().add(const VaultInitializeRequested());
    }
  }

  void _handleVaultNavigation(VaultNavigationTarget target) {
    final nav = _rootNavigatorKey.currentState;
    if (nav == null) return;

    switch (target) {
      case VaultNavigationTarget.setupScreen:
        nav.pushNamed(VaultRoutes.setup).then((setupResult) {
          if (setupResult == true) {
            nav.pushNamed(VaultRoutes.dashboard);
          }
        });
      case VaultNavigationTarget.unlockScreen:
        nav.pushNamed(VaultRoutes.auth).then((unlocked) {
          if (unlocked == true) {
            nav.pushNamed(VaultRoutes.dashboard);
          }
        });
      case VaultNavigationTarget.dashboardScreen:
        nav.pushNamed(VaultRoutes.dashboard);
      case VaultNavigationTarget.reauthOverlay:
        // Handled in-place by ReauthBlurOverlay to preserve screen state and uninterrupted playback.
        break;
    }
  }

  @override
  void didUpdateWidget(covariant MusifyApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.connectController != oldWidget.connectController) {
      final resolved = _resolveConnectController();
      if (!identical(_connectControllerNotifier.value, resolved)) {
        _connectControllerNotifier.value = resolved;
      }
    }
    if (widget.connectSessionCoordinator !=
        oldWidget.connectSessionCoordinator) {
      final nextCoordinator = _resolveConnectSessionCoordinator();
      if (!identical(_connectSessionCoordinator, nextCoordinator)) {
        _connectSessionCoordinator?.detachAuthBloc();
        _connectSessionCoordinator = nextCoordinator;
        if (nextCoordinator != null) {
          if (_authBloc case final authBloc?) {
            nextCoordinator.bindAuthBloc(authBloc);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _connectSessionCoordinator?.detachAuthBloc();
    _connectSessionCoordinator = null;
    if (_authBloc case final authBloc?) {
      _authBloc = null;
      unawaited(authBloc.close());
    }
    _navSubscription?.cancel();
    _connectControllerNotifier.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _vaultCoordinator?.onAppLifecycleStateChanged(state);
  }

  @override
  Widget build(BuildContext context) {
    final authBloc = _authBloc;
    if (authBloc == null) {
      throw StateError('MusifyApp AuthBloc was not initialized in initState');
    }

    final Widget themedApp = MaterialApp(
      key: _materialAppKey,
      navigatorKey: _rootNavigatorKey,
      title: 'Musify MU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      scrollBehavior: const AppScrollBehavior(),
      navigatorObservers: _navigatorObservers,
      onGenerateRoute: VaultRoutes.onGenerateRoute,
      home: ValueListenableBuilder<ConnectMobiusController?>(
        valueListenable: _connectControllerNotifier,
        builder: (
          BuildContext context,
          ConnectMobiusController? activeConnectController,
          Widget? child,
        ) {
          return HiddenDrawerScaffold(
            modePersistence: getIt<ModePersistence>(),
            createHomeFeedBloc: () => getIt<HomeFeedBloc>(),
            createBrowseBloc: () => getIt<BrowseBloc>(),
            createLibraryBloc: (userId) => getIt<LibraryBloc>(param1: userId),
            connectController: activeConnectController,
          );
        },
      ),
    );

    final Widget app = switch (_connectControllerNotifier.value) {
      final activeConnect? => BlocProvider<ConnectMobiusController>.value(
          value: activeConnect,
          child: themedApp,
        ),
      null => themedApp,
    };

    final createBloc = widget.createLocalMusicBloc;
    final outputStatusPolicy = _resolveConnectOutputStatusPolicy();
    final deviceEnvironmentPort = _resolveDeviceEnvironmentPort();
    final audioRoutePort = _resolveAudioRoutePort();
    final scrollSitaRepository = _resolveScrollSitaRepository();
    final lyricsRepository = _resolveLyricsRepository();

    // Wrap with app-level RepositoryProviders and BLoC providers so downstream
    // presentation widgets resolve dependencies cleanly via context.read<T>().
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DataPool>.value(
          value: getIt<DataPool>(),
        ),
        RepositoryProvider<ColorExtractionService>.value(
          value: getIt<ColorExtractionService>(),
        ),
        RepositoryProvider<ConnectOutputStatusPolicy>.value(
          value: outputStatusPolicy,
        ),
        if (scrollSitaRepository case final repo?)
          RepositoryProvider<ScrollSitaRepository>.value(
            value: repo,
          ),
        if (lyricsRepository case final repo?)
          RepositoryProvider<LyricsRepository>.value(
            value: repo,
          ),
        if (_connectSessionCoordinator case final coordinator?)
          RepositoryProvider<ConnectSessionCoordinator>.value(
            value: coordinator,
          ),
        if (deviceEnvironmentPort != null)
          RepositoryProvider<DeviceEnvironmentPort>.value(
            value: deviceEnvironmentPort,
          ),
        if (audioRoutePort != null)
          RepositoryProvider<AudioRoutePort>.value(
            value: audioRoutePort,
          ),
        if (getIt.isRegistered<UbiLogger>())
          RepositoryProvider<UbiLogger>.value(
            value: getIt<UbiLogger>(),
          ),
        if (getIt.isRegistered<PlayerLoggingParamsFactory>())
          RepositoryProvider<PlayerLoggingParamsFactory>.value(
            value: getIt<PlayerLoggingParamsFactory>(),
          ),
        if (getIt.isRegistered<PageInstanceIdHolder>())
          RepositoryProvider<PageInstanceIdHolder>.value(
            value: getIt<PageInstanceIdHolder>(),
          ),
        if (getIt.isRegistered<IVaultStorageRepository>())
          RepositoryProvider<IVaultStorageRepository>.value(
            value: getIt<IVaultStorageRepository>(),
          ),
        if (getIt.isRegistered<IVaultAuthService>())
          RepositoryProvider<IVaultAuthService>.value(
            value: getIt<IVaultAuthService>(),
          ),
        if (getIt.isRegistered<VaultAudioPlaybackService>())
          RepositoryProvider<VaultAudioPlaybackService>.value(
            value: getIt<VaultAudioPlaybackService>(),
          ),
        if (getIt.isRegistered<IMonotonicClock>())
          RepositoryProvider<IMonotonicClock>.value(
            value: getIt<IMonotonicClock>(),
          ),
        if (getIt.isRegistered<UnlockVaultUseCase>())
          RepositoryProvider<UnlockVaultUseCase>.value(
            value: getIt<UnlockVaultUseCase>(),
          ),
        if (getIt.isRegistered<RotatePinUseCase>())
          RepositoryProvider<RotatePinUseCase>.value(
            value: getIt<RotatePinUseCase>(),
          ),
        if (getIt.isRegistered<PurgeVaultDataUseCase>())
          RepositoryProvider<PurgeVaultDataUseCase>.value(
            value: getIt<PurgeVaultDataUseCase>(),
          ),
        if (getIt.isRegistered<VaultCoordinator>())
          RepositoryProvider<VaultCoordinator>.value(
            value: getIt<VaultCoordinator>(),
          ),
        if (getIt.isRegistered<PlaybackPrivacyProxy>())
          RepositoryProvider<PlaybackPrivacyProxy>.value(
            value: getIt<PlaybackPrivacyProxy>(),
          ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(
            value: authBloc,
          ),
          if (createBloc != null)
            BlocProvider<LocalMusicBloc>(
              create: (_) => createBloc(),
            ),
          BlocProvider<NetworkStatusBloc>.value(
            value: getIt<NetworkStatusBloc>(),
          ),
          BlocProvider<PlayerQueueBloc>.value(
            value: getIt<PlayerQueueBloc>(),
          ),
          if (getIt.isRegistered<VaultSessionBloc>())
            BlocProvider<VaultSessionBloc>.value(
              value: getIt<VaultSessionBloc>(),
            ),
          if (getIt.isRegistered<SettingsMutationCubit>())
            BlocProvider<SettingsMutationCubit>.value(
              value: getIt<SettingsMutationCubit>(),
            ),
          if (getIt.isRegistered<ScreenPrivacyCubit>())
            BlocProvider<ScreenPrivacyCubit>.value(
              value: getIt<ScreenPrivacyCubit>(),
            ),
          if (getIt.isRegistered<GestureEngineCubit>())
            BlocProvider<GestureEngineCubit>.value(
              value: getIt<GestureEngineCubit>(),
            ),
          if (getIt.isRegistered<PinPadCubit>())
            BlocProvider<PinPadCubit>.value(
              value: getIt<PinPadCubit>(),
            ),
        ],
        child: app,
      ),
    );
  }
}
