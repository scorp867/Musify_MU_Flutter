import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/app/theme/app_theme.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/application/auth_event.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_bloc.dart';
import 'package:musify_mu/features/shell/presentation/hidden_drawer_scaffold.dart';

class MusifyApp extends StatelessWidget {
  final LocalMusicBloc Function()? createLocalMusicBloc;
  final PlaybackController? playbackController;

  const MusifyApp({
    super.key,
    this.createLocalMusicBloc,
    this.playbackController,
  });

  @override
  Widget build(BuildContext context) {
    Widget app = MaterialApp(
      title: 'Musify MU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: HiddenDrawerScaffold(playbackController: playbackController),
    );

    final createBloc = createLocalMusicBloc;

    // Wrap with all app-level BLoC providers.
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc()..add(const AuthSessionRestored()),
        ),
        if (createBloc != null)
          BlocProvider<LocalMusicBloc>(
            create: (_) => createBloc(),
          ),
      ],
      child: app,
    );
  }
}
