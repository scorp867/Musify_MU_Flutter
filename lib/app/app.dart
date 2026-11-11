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
import 'package:musify_mu/core/ui/scroll/app_scroll_behavior.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/browse/application/browse_bloc.dart';
import 'package:musify_mu/features/home_feed/application/home_feed_bloc.dart';
import 'package:musify_mu/features/library/application/library_bloc.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_bloc.dart';
import 'package:musify_mu/features/player/application/queue/player_queue_bloc.dart';
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

class MusifyApp extends StatefulWidget {
  final AuthBloc Function() createAuthBloc;
  final LocalMusicBloc Function()? createLocalMusicBloc;

  const MusifyApp({
    super.key,
    required this.createAuthBloc,
    this.createLocalMusicBloc,
  });

  @override
  State<MusifyApp> createState() => _MusifyAppState();
}

class _MusifyAppState extends State<MusifyApp> with WidgetsBindingObserver {
  VaultCoordinator? _vaultCoordinator;
  StreamSubscription<VaultNavigationTarget>? _navSubscription;
  final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (getIt.isRegistered<VaultCoordinator>()) {
      final coordinator = getIt<VaultCoordinator>()..initialize();
      _vaultCoordinator = coordinator;
      _navSubscription =
          coordinator.navigationStream.listen(_handleVaultNavigation);
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
        nav.pushNamed(VaultRoutes.setup);
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
  void dispose() {
    _navSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _vaultCoordinator?.onAppLifecycleStateChanged(state);
  }

  @override
  Widget build(BuildContext context) {
    final navigatorObservers = <NavigatorObserver>[];
    if (getIt.isRegistered<VaultRouteObserver>()) {
      navigatorObservers.add(getIt<VaultRouteObserver>());
    } else if (getIt.isRegistered<ScreenPrivacyCubit>()) {
      navigatorObservers.add(
        VaultRouteObserver(privacyCubit: getIt<ScreenPrivacyCubit>()),
      );
    }

    Widget app = MaterialApp(
      navigatorKey: _rootNavigatorKey,
      title: 'Musify MU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      scrollBehavior: const AppScrollBehavior(),
      navigatorObservers: navigatorObservers,
      onGenerateRoute: VaultRoutes.onGenerateRoute,
      home: HiddenDrawerScaffold(
        modePersistence: getIt<ModePersistence>(),
        createHomeFeedBloc: () => getIt<HomeFeedBloc>(),
        createBrowseBloc: () => getIt<BrowseBloc>(),
        createLibraryBloc: (userId) => getIt<LibraryBloc>(param1: userId),
      ),
    );

    final createBloc = widget.createLocalMusicBloc;

    // Wrap with app-level RepositoryProviders and BLoC providers.
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DataPool>.value(
          value: getIt<DataPool>(),
        ),
        RepositoryProvider<ColorExtractionService>.value(
          value: getIt<ColorExtractionService>(),
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
          BlocProvider<AuthBloc>(
            create: (_) => widget.createAuthBloc(),
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
