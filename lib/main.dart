import "dart:developer";
import "package:flutter/foundation.dart";
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:musify_mu/app/app.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/features/auth/application/auth_event.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_bloc.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0x00000000),
      systemNavigationBarDividerColor: Color(0x00000000),
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  await setupInjection();

  if (kDebugMode) {
    void logVmService([int attempts = 0]) {
      Service.getInfo().then((info) {
        if (info.serverUri != null) {
          debugPrint('VIVO_PORT: ${info.serverUri!.port}');
          debugPrint('VIVO_PATH: ${info.serverUri!.path}');
        } else if (attempts < 10) {
          Future<void>.delayed(
            const Duration(milliseconds: 200),
            () => logVmService(attempts + 1),
          );
        }
      });
    }

    logVmService();
  }

  runApp(
    MusifyApp(
      createAuthBloc: () =>
          getIt()..add(const AuthSessionRestored()),
      createLocalMusicBloc: () =>
          getIt<LocalMusicBloc>()..add(const LoadLocalTracks()),
      playbackController: getIt(),
    ),
  );
}

