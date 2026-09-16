import 'package:flutter/widgets.dart';
import 'package:musify_mu/app/app.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_bloc.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupInjection();

  runApp(
    MusifyApp(
      createLocalMusicBloc: () =>
          getIt<LocalMusicBloc>()..add(const LoadLocalTracks()),
      playbackController: getIt(),
    ),
  );
}
