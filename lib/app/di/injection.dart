import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:musify_mu/core/audio/audio_notification_handler.dart';
import 'package:musify_mu/core/audio/audio_playback_service.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/features/local_music/application/local_music_playback_synchronizer.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/local_music/data/datasources/device_music_data_source.dart';
import 'package:musify_mu/features/local_music/data/datasources/local_tracks_store.dart';
import 'package:musify_mu/features/local_music/data/repositories/local_music_repository_impl.dart';
import 'package:musify_mu/features/local_music/data/services/local_music_sync_service.dart';
import 'package:musify_mu/features/local_music/domain/repositories/local_music_repository.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

final getIt = GetIt.instance;

Future<void> setupInjection() async {
  getIt.registerLazySingleton<OnAudioQuery>(OnAudioQuery.new);
  getIt.registerLazySingleton<AudioPlaybackService>(AudioPlaybackService.new);

  final audioHandler = await AudioService.init(
    builder: () => AudioNotificationHandler(getIt(), getIt()),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'um.musify.mu.musify_mu.channel.audio',
      androidNotificationChannelName: 'Musify MU Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  final handler = audioHandler;
  getIt.registerSingleton<AudioNotificationHandler>(handler);
  getIt.registerSingleton<PlaybackController>(handler);

  getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);
  getIt.registerLazySingleton<LocalTracksStore>(
    () => LocalTracksStore(getIt()),
  );
  getIt.registerLazySingleton<DeviceMusicDataSource>(
    () => OnAudioQueryDeviceMusicDataSource(getIt()),
  );
  getIt.registerLazySingleton<LocalMusicSyncService>(
    () => LocalMusicSyncService(deviceMusic: getIt(), store: getIt()),
  );
  getIt.registerLazySingleton<LocalMusicRepository>(
    () => LocalMusicRepositoryImpl(
      deviceMusic: getIt(),
      store: getIt(),
      syncService: getIt(),
    ),
  );
  getIt.registerLazySingleton<LocalMusicPlaybackSynchronizer>(
    () => LocalMusicPlaybackSynchronizer(getIt()),
  );

  getIt.registerFactory<LocalMusicBloc>(
    () => LocalMusicBloc(repository: getIt(), playbackSynchronizer: getIt()),
  );
}
