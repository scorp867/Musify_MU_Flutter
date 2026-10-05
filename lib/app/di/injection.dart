import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:musify_mu/core/audio/audio_notification_handler.dart';
import 'package:musify_mu/core/audio/audio_playback_service.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/media/extended_metadata_service.dart';
import 'package:musify_mu/core/network/spotify/auth/auth_session_provider.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_client_token.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_refresher.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';
import 'package:musify_mu/core/network/spotify/transport/android_transport.dart';

import 'package:musify_mu/core/network/spotify/transport/web_player_transport.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/data/spotify_profile_fetcher.dart';
import 'package:musify_mu/features/browse/application/browse_bloc.dart';
import 'package:musify_mu/features/browse/data/browse_repository.dart';
import 'package:musify_mu/features/browse/domain/repositories/browse_repository.dart';
import 'package:musify_mu/features/browse/domain/usecases/load_browse.dart';
import 'package:musify_mu/features/home_feed/application/home_feed_bloc.dart';
import 'package:musify_mu/features/home_feed/data/home_repository.dart';
import 'package:musify_mu/features/home_feed/domain/repositories/home_repository.dart';
import 'package:musify_mu/features/home_feed/domain/usecases/load_home_feed.dart';
import 'package:musify_mu/features/library/application/library_bloc.dart';
import 'package:musify_mu/features/library/data/cache/library_cache.dart';
import 'package:musify_mu/features/library/data/cache/playlist_detail_cache.dart';
import 'package:musify_mu/features/library/data/repository/library_repository_impl.dart';
import 'package:musify_mu/features/library/data/sources/library_remote_source.dart';
import 'package:musify_mu/features/library/data/sources/playlist_remote_source.dart';
import 'package:musify_mu/features/library/domain/repositories/library_repository.dart';
import 'package:musify_mu/features/library/domain/usecases/load_library.dart';
import 'package:musify_mu/features/local_music/application/local_music_playback_synchronizer.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/local_music/data/datasources/device_music_data_source.dart';
import 'package:musify_mu/features/local_music/data/datasources/local_tracks_store.dart';
import 'package:musify_mu/features/local_music/data/repositories/local_music_repository_impl.dart';
import 'package:musify_mu/features/local_music/data/services/local_music_sync_service.dart';
import 'package:musify_mu/features/local_music/domain/repositories/local_music_repository.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_bloc.dart';
import 'package:musify_mu/app/di/mode_persistence.dart';
import 'package:on_audio_query/on_audio_query.dart';

final getIt = GetIt.instance;

Future<void> setupInjection() async {
  // --- Runtime Context ---
  final runtimeContext = RuntimeContext();
  await runtimeContext.init();
  getIt.registerSingleton<RuntimeContext>(runtimeContext);

  // --- Cache Manager ---
  final cacheManager = AppCacheManager();
  await cacheManager.init();
  getIt.registerSingleton<AppCacheManager>(cacheManager);

  // Restore cached profile values from secure storage so RuntimeContext
  // and AppCacheManager have correct values before the first network call.
  final tokenStore = SpotifyTokenStore();
  final cachedProfile = await tokenStore.getCachedProfile();
  if (cachedProfile != null) {
    runtimeContext.updateFromProfile(
      userCountry: cachedProfile.country,
      product: cachedProfile.product,
    );
    await cacheManager.setUser(cachedProfile.username);
  }

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

  getIt.registerLazySingleton<AppDatabase>(
    AppDatabase.new,
    dispose: (db) => db.close(),
  );
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
    dispose: (repo) => (repo as LocalMusicRepositoryImpl).dispose(),
  );
  getIt.registerLazySingleton<LocalMusicPlaybackSynchronizer>(
    () => LocalMusicPlaybackSynchronizer(getIt()),
  );

  getIt.registerFactory<LocalMusicBloc>(
    () => LocalMusicBloc(repository: getIt(), playbackSynchronizer: getIt()),
  );

  // --- Spotify Auth Infrastructure ---
  getIt.registerLazySingleton<SpotifyTokenStore>(() => SpotifyTokenStore());
  getIt.registerLazySingleton<SpotifyTokenRefresher>(
    () => SpotifyTokenRefresher(tokenStore: getIt<SpotifyTokenStore>()),
  );
  getIt.registerLazySingleton<SpotifyClientTokenFetcher>(
    () => SpotifyClientTokenFetcher(getIt<SpotifyTokenStore>()),
  );
  getIt.registerLazySingleton<AuthSessionProvider>(
    () => SpotifyAuthSessionProvider(
      tokenStore: getIt<SpotifyTokenStore>(),
      tokenRefresher: getIt<SpotifyTokenRefresher>(),
      clientTokenFetcher: getIt<SpotifyClientTokenFetcher>(),
    ),
  );

  // --- Spotify Transports ---
  getIt.registerLazySingleton<WebPlayerTransport>(
    () => WebPlayerTransport(
      auth: getIt<AuthSessionProvider>(),
      ctx: getIt<RuntimeContext>(),
    ),
  );
  getIt.registerLazySingleton<AndroidTransport>(
    () => AndroidTransport(
      auth: getIt<AuthSessionProvider>(),
      ctx: getIt<RuntimeContext>(),
    ),
  );

  // --- Online Services ---
  getIt.registerLazySingleton<ExtendedMetadataService>(
    () => ExtendedMetadataService(
      client: getIt<WebPlayerTransport>(),
      ctx: getIt<RuntimeContext>(),
      cacheManager: getIt<AppCacheManager>(),
    ),
  );
  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      client: getIt<AndroidTransport>(),
      ctx: getIt<RuntimeContext>(),
      cacheManager: getIt<AppCacheManager>(),
    ),
  );
  getIt.registerLazySingleton<BrowseRepository>(
    () => BrowseRepositoryImpl(
      client: getIt<WebPlayerTransport>(),
      ctx: getIt<RuntimeContext>(),
      cacheManager: getIt<AppCacheManager>(),
    ),
  );
  getIt.registerFactoryParam<LibraryRepository, String, void>(
    (userId, _) => LibraryRepositoryImpl(
      librarySource: LibraryRemoteSource(
        webTransport: getIt<WebPlayerTransport>(),
        androidTransport: getIt<AndroidTransport>(),
        ctx: getIt<RuntimeContext>(),
        userId: userId,
      ),
      playlistSource: PlaylistRemoteSource(
        client: getIt<WebPlayerTransport>(),
      ),
      libraryCache: LibraryCache(
        cacheManager: getIt<AppCacheManager>(),
      ),
      playlistCache: PlaylistDetailCache(
        cacheManager: getIt<AppCacheManager>(),
      ),
      metadataService: getIt<ExtendedMetadataService>(),
      userId: userId,
    ),
  );
  getIt.registerLazySingleton<SpotifyProfileFetcher>(
    () => SpotifyProfileFetcher(
      ctx: getIt<RuntimeContext>(),
      tokenStore: getIt<SpotifyTokenStore>(),
    ),
  );
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      tokenStore: getIt<SpotifyTokenStore>(),
      refresher: getIt<SpotifyTokenRefresher>(),
      profileFetcher: getIt<SpotifyProfileFetcher>(),
      cacheManager: getIt<AppCacheManager>(),
    ),
  );

  // --- Mode Persistence ---
  getIt.registerLazySingleton<ModePersistence>(() => ModePersistence());

  // --- Use Cases ---
  getIt.registerLazySingleton<LoadHomeFeed>(
    () => LoadHomeFeed(getIt<HomeRepository>()),
  );
  getIt.registerLazySingleton<LoadBrowse>(
    () => LoadBrowse(getIt<BrowseRepository>()),
  );

  // --- Feature BLoC Factories ---
  getIt.registerFactory<HomeFeedBloc>(
    () => HomeFeedBloc(loadHomeFeed: getIt<LoadHomeFeed>()),
  );
  getIt.registerFactory<BrowseBloc>(
    () => BrowseBloc(loadBrowse: getIt<LoadBrowse>()),
  );
  getIt.registerFactoryParam<LibraryBloc, String, void>(
    (userId, _) => LibraryBloc(
      loadLibrary: LoadLibrary(getIt<LibraryRepository>(param1: userId)),
    ),
  );
}
