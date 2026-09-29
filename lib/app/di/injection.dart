import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:musify_mu/core/audio/audio_notification_handler.dart';
import 'package:musify_mu/core/audio/audio_playback_service.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/core/media/extended_metadata_service.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/data/spotify_client_token.dart';
import 'package:musify_mu/features/auth/data/spotify_token_refresher.dart';
import 'package:musify_mu/features/auth/data/spotify_token_store.dart';
import 'package:musify_mu/features/browse/data/browse_repository.dart';
import 'package:musify_mu/features/home_feed/data/home_repository.dart';
import 'package:musify_mu/features/library/data/library_repository.dart';
import 'package:musify_mu/features/local_music/application/local_music_playback_synchronizer.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/local_music/data/datasources/device_music_data_source.dart';
import 'package:musify_mu/features/local_music/data/datasources/local_tracks_store.dart';
import 'package:musify_mu/features/local_music/data/repositories/local_music_repository_impl.dart';
import 'package:musify_mu/features/local_music/data/services/local_music_sync_service.dart';
import 'package:musify_mu/features/local_music/domain/repositories/local_music_repository.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_bloc.dart';
import 'package:musify_mu/features/spotify_client/spotify_client.dart';
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

  // --- Spotify / Online Services ---
  getIt.registerLazySingleton<SpotifyTokenStore>(() => SpotifyTokenStore());
  getIt.registerLazySingleton<SpotifyTokenRefresher>(
    () => SpotifyTokenRefresher(tokenStore: getIt<SpotifyTokenStore>()),
  );
  getIt.registerLazySingleton<SpotifyClientTokenFetcher>(
    () => SpotifyClientTokenFetcher(getIt<SpotifyTokenStore>()),
  );
  getIt.registerLazySingleton<SpotifyClient>(
    () => SpotifyClient(
      tokenStore: getIt<SpotifyTokenStore>(),
      tokenRefresher: getIt<SpotifyTokenRefresher>(),
      clientTokenFetcher: getIt<SpotifyClientTokenFetcher>(),
    ),
  );
  getIt.registerLazySingleton<ExtendedMetadataService>(
    () => ExtendedMetadataService(client: getIt<SpotifyClient>()),
  );
  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepository(client: getIt<SpotifyClient>()),
  );
  getIt.registerLazySingleton<BrowseRepository>(
    () => BrowseRepository(client: getIt<SpotifyClient>()),
  );
  getIt.registerFactoryParam<LibraryRepository, String, void>(
    (userId, _) => LibraryRepository(
      client: getIt<SpotifyClient>(),
      userId: userId,
      metadataService: getIt<ExtendedMetadataService>(),
    ),
  );
  getIt.registerFactory<AuthBloc>(() => AuthBloc());
}
