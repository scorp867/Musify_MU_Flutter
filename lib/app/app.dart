import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/app/di/mode_persistence.dart';
import 'package:musify_mu/app/theme/app_theme.dart';
import 'package:musify_mu/core/ui/scroll/app_scroll_behavior.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/browse/application/browse_bloc.dart';
import 'package:musify_mu/features/home_feed/application/home_feed_bloc.dart';
import 'package:musify_mu/features/library/application/library_bloc.dart';
import 'package:musify_mu/core/network/status/bloc/network_status_bloc.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_bloc.dart';
import 'package:musify_mu/features/shell/presentation/hidden_drawer_scaffold.dart';

class MusifyApp extends StatelessWidget {
  final AuthBloc Function() createAuthBloc;
  final LocalMusicBloc Function()? createLocalMusicBloc;
  final PlaybackController? playbackController;

  const MusifyApp({
    super.key,
    required this.createAuthBloc,
    this.createLocalMusicBloc,
    this.playbackController,
  });

  @override
  Widget build(BuildContext context) {
    Widget app = MaterialApp(
      title: 'Musify MU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      scrollBehavior: const AppScrollBehavior(),
      home: HiddenDrawerScaffold(
        playbackController: playbackController,
        modePersistence: getIt<ModePersistence>(),
        createHomeFeedBloc: () => getIt<HomeFeedBloc>(),
        createBrowseBloc: () => getIt<BrowseBloc>(),
        createLibraryBloc: (userId) => getIt<LibraryBloc>(param1: userId),
      ),
    );

    final createBloc = createLocalMusicBloc;

    // Wrap with all app-level BLoC providers.
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => createAuthBloc(),
        ),
        if (createBloc != null)
          BlocProvider<LocalMusicBloc>(
            create: (_) => createBloc(),
          ),
        BlocProvider<NetworkStatusBloc>.value(
          value: getIt<NetworkStatusBloc>(),
        ),
      ],
      child: app,
    );
  }
}
