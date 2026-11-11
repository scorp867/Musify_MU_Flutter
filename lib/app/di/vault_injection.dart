import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/player/application/queue/mobius/player_queue_mobius_controller.dart';
import 'package:musify_mu/features/player/data/esperanto/context_player_control_client.dart';
import 'package:musify_mu/features/vault/application/coordinator/vault_coordinator.dart';
import 'package:musify_mu/features/vault/application/gesture/gesture_engine_cubit.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/playlists/vault_playlists_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/data/database/vault_database.dart';
import 'package:musify_mu/features/vault/data/datasources/i_native_vault_crypto_bridge.dart';
import 'package:musify_mu/features/vault/data/datasources/native_vault_crypto_bridge.dart';
import 'package:musify_mu/features/vault/data/datasources/platform_security_channel.dart';
import 'package:musify_mu/features/vault/data/datasources/system_monotonic_clock.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_media_isolation_manager.dart';
import 'package:musify_mu/features/vault/data/repositories/vault_storage_repository.dart';
import 'package:musify_mu/features/vault/data/services/gesture_recognizer_service.dart';
import 'package:musify_mu/features/vault/data/services/playback_privacy_proxy.dart';
import 'package:musify_mu/features/vault/data/services/vault_audio_playback_service.dart';
import 'package:musify_mu/features/vault/data/services/vault_auth_service.dart';
import 'package:musify_mu/features/vault/data/services/vault_pbkdf2_derivation.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_screen_privacy_controller.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/usecases/enroll_gesture_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/mutate_vault_config_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/purge_vault_data_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/rotate_pin_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';

/// Registers all Secure Vault (Phase 4) infrastructure, repositories, services,
/// use cases, BLoCs, cubits, and central coordinator into the GetIt service locator.
void setupVaultInjection(GetIt sl) {
  // ---------------------------------------------------------------------------
  // Tier 1: Low-Level Infrastructure & Hardware Drivers
  // ---------------------------------------------------------------------------
  if (!sl.isRegistered<FlutterSecureStorage>()) {
    sl.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    );
  }

  sl.registerLazySingleton<VaultPbkdf2Derivation>(
    () => const VaultPbkdf2Derivation(),
  );

  sl.registerLazySingleton<VaultDatabase>(
    VaultDatabase.new,
    dispose: (db) => db.close(),
  );

  sl.registerLazySingleton<INativeVaultCryptoBridge>(
    () => const NativeVaultCryptoBridge(),
  );

  sl.registerLazySingleton<IMonotonicClock>(
    SystemMonotonicClock.new,
  );

  sl.registerLazySingleton<IScreenPrivacyController>(
    PlatformSecurityChannel.new,
    dispose: (c) {
      if (c is PlatformSecurityChannel) {
        c.dispose();
      }
    },
  );

  sl.registerLazySingleton<IGestureRecognizer>(
    GestureRecognizerService.new,
  );

  sl.registerLazySingleton<IVaultMediaIsolationManager>(
    () => VaultMediaIsolationManager(
      localDatabase:
          sl.isRegistered<AppDatabase>() ? sl<AppDatabase>() : null,
    ),
  );

  // ---------------------------------------------------------------------------
  // Tier 2: Storage Repositories & Cryptographic Auth Services
  // ---------------------------------------------------------------------------
  sl.registerLazySingleton<IVaultStorageRepository>(
    () => VaultStorageRepository(
      database: sl<VaultDatabase>(),
      cryptoBridge: sl<INativeVaultCryptoBridge>(),
      onShredMediaFiles: () =>
          sl<IVaultMediaIsolationManager>().shredAllIsolatedMedia(),
    ),
  );

  sl.registerLazySingleton<IVaultAuthService>(
    () => VaultAuthService(
      cryptoBridge: sl<INativeVaultCryptoBridge>(),
      storageRepository: sl<IVaultStorageRepository>(),
      monotonicClock: sl<IMonotonicClock>(),
      secureStorage: sl<FlutterSecureStorage>(),
      pbkdf2Derivation: sl<VaultPbkdf2Derivation>(),
    ),
    dispose: (auth) {
      if (auth is VaultAuthService) {
        auth.close();
      }
    },
  );

  // ---------------------------------------------------------------------------
  // Tier 3: Audio Playback & Privacy Proxies
  // ---------------------------------------------------------------------------
  sl.registerLazySingleton<PlaybackPrivacyProxy>(
    () => PlaybackPrivacyProxy(
      vaultAuthService: sl<IVaultAuthService>(),
      mobiusController: sl<PlayerQueueMobiusController>(),
      storageRepository: sl<IVaultStorageRepository>(),
      controlClient: sl.isRegistered<ContextPlayerControlClient>()
          ? sl<ContextPlayerControlClient>()
          : null,
    ),
    dispose: (proxy) => proxy.dispose(),
  );

  sl.registerLazySingleton<VaultAudioPlaybackService>(
    () => VaultAudioPlaybackService(
      mobiusController: sl<PlayerQueueMobiusController>(),
      privacyProxy: sl<PlaybackPrivacyProxy>(),
      isolationManager: sl<IVaultMediaIsolationManager>(),
    ),
  );

  // ---------------------------------------------------------------------------
  // Tier 4: Domain Interactor Use Cases
  // ---------------------------------------------------------------------------
  sl.registerLazySingleton<UnlockVaultUseCase>(
    () => UnlockVaultUseCase(authService: sl<IVaultAuthService>()),
  );

  sl.registerLazySingleton<RotatePinUseCase>(
    () => RotatePinUseCase(authService: sl<IVaultAuthService>()),
  );

  sl.registerLazySingleton<PurgeVaultDataUseCase>(
    () => PurgeVaultDataUseCase(
      authService: sl<IVaultAuthService>(),
      storageRepository: sl<IVaultStorageRepository>(),
    ),
  );

  sl.registerLazySingleton<MutateVaultConfigUseCase>(
    () => MutateVaultConfigUseCase(
      authService: sl<IVaultAuthService>(),
      storageRepository: sl<IVaultStorageRepository>(),
    ),
  );

  sl.registerLazySingleton<EnrollGestureUseCase>(
    () => EnrollGestureUseCase(
      authService: sl<IVaultAuthService>(),
      recognizer: sl<IGestureRecognizer>(),
      storageRepository: sl<IVaultStorageRepository>(),
    ),
  );

  sl.registerLazySingleton<VerifySessionCoolOffUseCase>(
    () => VerifySessionCoolOffUseCase(clock: sl<IMonotonicClock>()),
  );

  // ---------------------------------------------------------------------------
  // Tier 5: Presentation BLoCs & Cubits
  // ---------------------------------------------------------------------------
  sl.registerLazySingleton<VaultSessionBloc>(
    () => VaultSessionBloc(
      authService: sl<IVaultAuthService>(),
      storageRepository: sl<IVaultStorageRepository>(),
      monotonicClock: sl<IMonotonicClock>(),
      verifyCoolOffUseCase: sl<VerifySessionCoolOffUseCase>(),
    ),
    dispose: (bloc) => bloc.close(),
  );

  sl.registerLazySingleton<SettingsMutationCubit>(
    () => SettingsMutationCubit(
      storageRepository: sl<IVaultStorageRepository>(),
      mutateVaultConfigUseCase: sl<MutateVaultConfigUseCase>(),
      authService: sl<IVaultAuthService>(),
      monotonicClock: sl<IMonotonicClock>(),
    ),
    dispose: (cubit) => cubit.close(),
  );

  sl.registerLazySingleton<ScreenPrivacyCubit>(
    () => ScreenPrivacyCubit(
      privacyController: sl<IScreenPrivacyController>(),
      monotonicClock: sl<IMonotonicClock>(),
    ),
    dispose: (cubit) => cubit.close(),
  );

  sl.registerLazySingleton<GestureEngineCubit>(
    () => GestureEngineCubit(
      recognizer: sl<IGestureRecognizer>(),
      storageRepository: sl<IVaultStorageRepository>(),
      vaultAuthService: sl<IVaultAuthService>(),
    ),
    dispose: (cubit) => cubit.close(),
  );

  sl.registerLazySingleton<PinPadCubit>(
    () => PinPadCubit(
      unlockVaultUseCase: sl<UnlockVaultUseCase>(),
      authService: sl<IVaultAuthService>(),
      monotonicClock: sl<IMonotonicClock>(),
    ),
    dispose: (cubit) => cubit.close(),
  );

  sl.registerFactory<VaultPlaylistsCubit>(
    () => VaultPlaylistsCubit(storageRepository: sl<IVaultStorageRepository>()),
  );

  // ---------------------------------------------------------------------------
  // Tier 6: Central Coordinator Orchestrator & Route Observer
  // ---------------------------------------------------------------------------
  sl.registerLazySingleton<VaultCoordinator>(
    () => VaultCoordinator(
      sessionBloc: sl<VaultSessionBloc>(),
      playbackPrivacyProxy: sl<PlaybackPrivacyProxy>(),
      screenPrivacyCubit: sl<ScreenPrivacyCubit>(),
      gestureEngineCubit: sl<GestureEngineCubit>(),
      settingsMutationCubit: sl<SettingsMutationCubit>(),
      pinPadCubit: sl<PinPadCubit>(),
      monotonicClock: sl<IMonotonicClock>(),
    )..initialize(),
    dispose: (coordinator) => coordinator.dispose(),
  );

  sl.registerLazySingleton<VaultRouteObserver>(
    () => VaultRouteObserver(privacyCubit: sl<ScreenPrivacyCubit>()),
  );
}
