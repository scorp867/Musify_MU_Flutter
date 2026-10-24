import 'package:get_it/get_it.dart';
import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/media/extended_metadata_service.dart';
import 'package:musify_mu/core/network/spotify/auth/auth_session_provider.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_client_token.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_refresher.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';
import 'package:musify_mu/core/color/color_cache.dart';
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/core/network/auth/token_refresh_mutex.dart';
import 'package:musify_mu/core/network/client/dio_network_client.dart';
import 'package:musify_mu/core/network/client/network_client.dart';
import 'package:musify_mu/core/network/client/queued_network_client.dart';
import 'package:musify_mu/core/network/status/bloc/network_status_bloc.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/spotify/transport/android_transport.dart';
import 'package:musify_mu/core/network/spotify/transport/web_player_transport.dart';
import 'package:musify_mu/features/playlist_detail/application/playlist_detail_bloc.dart';
import 'package:musify_mu/features/auth/domain/entities/spotify_user.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/data/spotify_profile_fetcher.dart';
import 'package:musify_mu/features/browse/application/browse_bloc.dart';
import 'package:musify_mu/features/browse/data/browse_repository.dart';
import 'package:musify_mu/features/browse/domain/repositories/browse_repository.dart';
import 'package:musify_mu/features/browse/domain/usecases/load_browse.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool_impl.dart';
import 'package:musify_mu/core/kodiak/dataloader/kodiak_disk_cache.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_client.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_data_source.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/plugins/builtin_plugins.dart';
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
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/local_music/data/datasources/device_music_data_source.dart';
import 'package:musify_mu/features/local_music/data/datasources/local_tracks_store.dart';
import 'package:musify_mu/features/local_music/data/repositories/local_music_repository_impl.dart';
import 'package:musify_mu/features/local_music/data/services/local_music_sync_service.dart';
import 'package:musify_mu/features/local_music/domain/repositories/local_music_repository.dart';
import 'package:musify_mu/features/local_music/presentation/bloc/local_music_bloc.dart';
import 'package:musify_mu/app/di/mode_persistence.dart';
import 'package:musify_mu/features/player/application/scroll/now_playing_scroll_bloc.dart';
import 'package:musify_mu/features/player/data/datasources/color_lyrics_client.dart';
import 'package:musify_mu/features/player/data/datasources/scrollsita_client.dart';
import 'package:musify_mu/features/player/data/repositories/color_lyrics_repository.dart';
import 'package:musify_mu/features/player/data/repositories/scrollsita_repository.dart';
import 'package:musify_mu/features/player/domain/repositories/lyrics_repository.dart';
import 'package:musify_mu/features/player/domain/repositories/scrollsita_repository.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_component.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_control_client.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_options_client.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_play_client.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_queue_client.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_state_client.dart';
import 'package:musify_mu/features/player/application/queue/player_queue_bloc.dart';
import 'package:musify_mu/features/player/data/mock/mock_queue_seeder.dart';
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

  getIt.registerFactory<LocalMusicBloc>(
    () => LocalMusicBloc(repository: getIt()),
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

  // --- Core Network Client, Monitor & Mutex ---
  getIt.registerLazySingleton<NetworkMonitorService>(
    () => NetworkMonitorServiceImpl(),
    dispose: (s) => s.dispose(),
  );
  getIt.registerLazySingleton<DioNetworkClient>(
    () => DioNetworkClient(monitorService: getIt<NetworkMonitorService>()),
  );
  getIt.registerLazySingleton<NetworkClient>(
    () => QueuedNetworkClient(
      delegate: getIt<DioNetworkClient>(),
      monitorService: getIt<NetworkMonitorService>(),
    ),
    dispose: (client) => client.close(),
  );
  getIt.registerLazySingleton<TokenRefreshMutex>(() => TokenRefreshMutex());
  getIt.registerLazySingleton<NetworkStatusBloc>(
    () => NetworkStatusBloc(monitorService: getIt<NetworkMonitorService>()),
    dispose: (bloc) => bloc.close(),
  );

  // --- Spotify Transports ---
  getIt.registerLazySingleton<WebPlayerTransport>(
    () => WebPlayerTransport(
      auth: getIt<AuthSessionProvider>(),
      client: getIt<NetworkClient>(),
      ctx: getIt<RuntimeContext>(),
      refreshMutex: getIt<TokenRefreshMutex>(),
    ),
  );
  getIt.registerLazySingleton<AndroidTransport>(
    () => AndroidTransport(
      auth: getIt<AuthSessionProvider>(),
      client: getIt<NetworkClient>(),
      ctx: getIt<RuntimeContext>(),
      refreshMutex: getIt<TokenRefreshMutex>(),
    ),
  );

  // --- Extended Metadata & Kodiak Infrastructure ---
  getIt.registerLazySingleton<ExtendedMetadataPluginRegistry>(
    () => ExtendedMetadataPluginRegistry(
      createDefaultExtendedMetadataPlugins(),
    ),
  );
  getIt.registerLazySingleton<ExtendedMetadataClient>(
    () => ExtendedMetadataClient(
      transport: getIt<AndroidTransport>(),
      ctx: getIt<RuntimeContext>(),
      registry: getIt<ExtendedMetadataPluginRegistry>(),
    ),
  );
  getIt.registerLazySingleton<ExtendedMetadataDataSourceImpl>(
    () => ExtendedMetadataDataSourceImpl(
      client: getIt<ExtendedMetadataClient>(),
    ),
  );
  getIt.registerLazySingleton<KodiakDiskCache>(
    () => KodiakDiskCache(cacheManager: getIt<AppCacheManager>()),
  );
  getIt.registerLazySingleton<DataPool>(
    () => DataPoolImpl(
      dataSource: getIt<ExtendedMetadataDataSourceImpl>(),
      diskCache: getIt<KodiakDiskCache>(),
      networkMonitor: getIt<NetworkMonitorService>(),
    ),
  );

  // --- Online Services ---
  getIt.registerLazySingleton<ExtendedMetadataService>(
    () => ExtendedMetadataService(
      client: getIt<WebPlayerTransport>(),
      ctx: getIt<RuntimeContext>(),
      cacheManager: getIt<AppCacheManager>(),
      metadataClient: getIt<ExtendedMetadataClient>(),
    ),
  );
  getIt.registerLazySingleton<ColorCache>(
    () => ColorCache(cacheManager: getIt<AppCacheManager>()),
  );
  getIt.registerLazySingleton<ColorExtractionService>(
    () => ColorExtractionService(
      cache: getIt<ColorCache>(),
      artworkFetcher: (songId) =>
          getIt<DeviceMusicDataSource>().queryArtwork(songId),
    ),
  );
  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      client: getIt<AndroidTransport>(),
      ctx: getIt<RuntimeContext>(),
      cacheManager: getIt<AppCacheManager>(),
      dataPool: getIt<DataPool>(),
    ),
  );
  getIt.registerLazySingleton<ScrollSitaClient>(
    () => ScrollSitaClient(transport: getIt<AndroidTransport>()),
  );
  getIt.registerLazySingleton<ScrollSitaRepository>(
    () => ScrollSitaRepositoryImpl(
      client: getIt<ScrollSitaClient>(),
      dataPool: getIt<DataPool>(),
    ),
  );
  getIt.registerLazySingleton<ColorLyricsClient>(
    () => ColorLyricsClient(transport: getIt<AndroidTransport>()),
  );
  getIt.registerLazySingleton<LyricsRepository>(
    () => ColorLyricsRepositoryImpl(client: getIt<ColorLyricsClient>()),
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
      transport: getIt<WebPlayerTransport>(),
      ctx: getIt<RuntimeContext>(),
      tokenStore: getIt<SpotifyTokenStore>(),
    ),
  );
  final SpotifyUser? initialUser = cachedProfile != null
      ? SpotifyUser(
          id: cachedProfile.username,
          displayName: cachedProfile.displayName,
          avatarUrl: cachedProfile.avatarUrl,
          country: cachedProfile.country,
          product: cachedProfile.product,
        )
      : null;

  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      tokenStore: getIt<SpotifyTokenStore>(),
      refresher: getIt<SpotifyTokenRefresher>(),
      profileFetcher: getIt<SpotifyProfileFetcher>(),
      cacheManager: getIt<AppCacheManager>(),
      networkMonitor: getIt<NetworkMonitorService>(),
      initialUser: initialUser,
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
    () => HomeFeedBloc(
      loadHomeFeed: getIt<LoadHomeFeed>(),
      networkMonitor: getIt<NetworkMonitorService>(),
    ),
  );
  getIt.registerFactory<BrowseBloc>(
    () => BrowseBloc(
      loadBrowse: getIt<LoadBrowse>(),
      networkMonitor: getIt<NetworkMonitorService>(),
    ),
  );
  getIt.registerFactoryParam<LibraryBloc, String, void>(
    (userId, _) => LibraryBloc(
      loadLibrary: LoadLibrary(getIt<LibraryRepository>(param1: userId)),
      networkMonitor: getIt<NetworkMonitorService>(),
    ),
  );
  getIt.registerFactory<PlaylistDetailBloc>(
    () => PlaylistDetailBloc(
      colorService: getIt<ColorExtractionService>(),
    ),
  );
  getIt.registerFactory<NowPlayingScrollBloc>(
    () => NowPlayingScrollBloc(
      scrollSitaRepository: getIt<ScrollSitaRepository>(),
      lyricsRepository: getIt<LyricsRepository>(),
    ),
  );

  // --- Spotify Esperanto Transport & ContextPlayer Factory Component (p.t0m) ---
  getIt.registerLazySingleton<EsperantoTransport>(
    () => InMemoryEsperantoTransport(),
    dispose: (t) {
      if (t is InMemoryEsperantoTransport) t.dispose();
    },
  );
  getIt.registerLazySingleton<ContextPlayerComponent>(
    () => ContextPlayerComponent(getIt<EsperantoTransport>()),
  );
  getIt.registerLazySingleton<ContextPlayerQueueClient>(
    () => getIt<ContextPlayerComponent>().queueClient,
  );
  getIt.registerLazySingleton<ContextPlayerControlClient>(
    () => getIt<ContextPlayerComponent>().controlsClient,
  );
  getIt.registerLazySingleton<ContextPlayerOptionsClient>(
    () => getIt<ContextPlayerComponent>().optionsClient,
  );
  getIt.registerLazySingleton<ContextPlayerStateClient>(
    () => getIt<ContextPlayerComponent>().stateClient,
  );
  getIt.registerLazySingleton<ContextPlayerPlayClient>(
    () => getIt<ContextPlayerComponent>().playClient,
  );

  // --- Spotify Playback & Queue BLoC ---
  getIt.registerLazySingleton<PlayerQueueBloc>(
    () {
      final bloc = PlayerQueueBloc(
        queueClient: getIt<ContextPlayerQueueClient>(),
        controlClient: getIt<ContextPlayerControlClient>(),
        optionsClient: getIt<ContextPlayerOptionsClient>(),
        stateClient: getIt<ContextPlayerStateClient>(),
        playClient: getIt<ContextPlayerPlayClient>(),
        initialQueue: MockQueueSeeder.createInitialMockQueue(),
      );
      MockQueueSeeder.seedInitialState(bloc);
      return bloc;
    },
    dispose: (bloc) => bloc.close(),
  );
}
