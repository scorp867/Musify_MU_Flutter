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
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (getIt.isRegistered<VaultCoordinator>()) {
      _vaultCoordinator = getIt<VaultCoordinator>()..initialize();
    }
  }

  @override
  void dispose() {
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
