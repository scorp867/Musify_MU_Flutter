// 1:1 replica of Spotify Connect subsystem bootstrap, platform ports, sorting
// DI wiring, and authenticated session coordinator:
// - ConnectNativeGateway (abstracts C++ ConnectSubsystem FFI lifecycle & RPCs)
// - DevicePickerSortingDatabase Room module (`qr0.java`, `p199p/azq.java`,
//   `p199p/in1.java`)
// - Connect Mobius loop, Esperanto clients & RemoteVolumeController
//   (`p199p/yrq.java`, `p199p/s77.java`, `p199p/zsh1.java`)
// - ConnectSessionCoordinator (`p199p/C2406w.java`, `p199p/asq.java`)

import 'package:get_it/get_it.dart';
import 'package:musify_mu/core/audio/native_playback_session_bridge.dart';
import 'package:musify_mu/core/config/device_identity_service.dart';
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/network/spotify/ap_resolve_service.dart';
import 'package:musify_mu/core/network/spotify/auth/auth_session_provider.dart';
import 'package:musify_mu/features/connect/application/lifecycle/connect_session_coordinator.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/application/sorting/device_picker_sorting_database.dart';
import 'package:musify_mu/features/connect/application/volume/remote_volume_controller.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_volume_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/dodo_service_client.dart';
import 'package:musify_mu/features/connect/data/platform/android_audio_route_adapter.dart';
import 'package:musify_mu/features/connect/data/platform/android_device_environment_adapter.dart';
import 'package:musify_mu/features/connect/data/platform/android_local_discovery_adapter.dart';
import 'package:musify_mu/features/connect/data/platform/android_system_volume_adapter.dart';
import 'package:musify_mu/features/connect/domain/interfaces/audio_route_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/connect_native_gateway.dart';
import 'package:musify_mu/features/connect/domain/interfaces/device_environment_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/local_discovery_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/system_volume_port.dart';
import 'package:musify_mu/features/connect/domain/services/connect_output_status_policy.dart';
import 'package:musify_mu/features/connect/domain/services/device_info_payload_builder.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';

/// Registers all Spotify Connect domain services, Android platform ports,
/// Esperanto clients, sorting persistence, remote volume controller, Mobius
/// controller, and auth-gated [ConnectSessionCoordinator] lazily in [sl].
///
/// Depends strictly on [EsperantoTransport] and [ConnectNativeGateway]
/// abstractions (zero concrete `NativeEsperantoTransport` coupling).
void setupConnectInjection(GetIt sl) {
  if (!sl.isRegistered<DeviceIdentityService>()) {
    sl.registerLazySingleton<DeviceIdentityService>(
      DeviceIdentityService.new,
    );
  }

  if (!sl.isRegistered<ApResolveService>()) {
    sl.registerLazySingleton<ApResolveService>(
      ApResolveService.new,
    );
  }

  if (!sl.isRegistered<DeviceInfoPayloadBuilder>()) {
    sl.registerLazySingleton<DeviceInfoPayloadBuilder>(
      () => DeviceInfoPayloadBuilder.instance,
    );
  }

  if (!sl.isRegistered<ConnectOutputStatusPolicy>()) {
    sl.registerLazySingleton<ConnectOutputStatusPolicy>(
      () => ConnectOutputStatusPolicy.instance,
    );
  }

  if (!sl.isRegistered<DeviceEnvironmentPort>()) {
    sl.registerLazySingleton<DeviceEnvironmentPort>(
      AndroidDeviceEnvironmentAdapter.new,
    );
  }

  if (!sl.isRegistered<AudioRoutePort>()) {
    sl.registerLazySingleton<AudioRoutePort>(
      AndroidAudioRouteAdapter.new,
    );
  }

  if (!sl.isRegistered<SystemVolumePort>()) {
    sl.registerLazySingleton<SystemVolumePort>(
      AndroidSystemVolumeAdapter.new,
    );
  }

  if (!sl.isRegistered<LocalDiscoveryPort>()) {
    sl.registerLazySingleton<LocalDiscoveryPort>(
      AndroidLocalDiscoveryAdapter.new,
    );
  }

  sl.registerLazySingleton<ConnectServiceClient>(
    () => ConnectServiceClient(sl<EsperantoTransport>()),
  );

  sl.registerLazySingleton<ConnectVolumeServiceClient>(
    () => ConnectVolumeServiceClient(sl<EsperantoTransport>()),
  );

  sl.registerLazySingleton<DodoServiceClient>(
    () => DodoServiceClient(sl<EsperantoTransport>()),
  );

  if (!sl.isRegistered<DevicePickerSortingDatabase>()) {
    sl.registerLazySingleton<DevicePickerSortingDatabase>(
      DevicePickerSortingDatabase.new,
      dispose: (db) => db.close(),
    );
  }

  sl.registerLazySingleton<RemoteVolumeController>(
    () {
      final hasGateway = sl.isRegistered<ConnectNativeGateway>();
      return RemoteVolumeController(
        volumeClient: sl<ConnectVolumeServiceClient>(),
        systemVolumePort: hasGateway ? sl<SystemVolumePort>() : null,
        nativeGateway: hasGateway ? sl<ConnectNativeGateway>() : null,
        autoStart: !hasGateway,
      );
    },
    dispose: (vc) => vc.dispose(),
  );

  sl.registerLazySingleton<ConnectMobiusController>(
    () {
      final hasGateway = sl.isRegistered<ConnectNativeGateway>();
      return ConnectMobiusController(
        connectServiceClient: sl<ConnectServiceClient>(),
        volumeServiceClient: sl<ConnectVolumeServiceClient>(),
        dodoServiceClient: sl<DodoServiceClient>(),
        sortingDatabase: sl<DevicePickerSortingDatabase>(),
        remoteVolumeController: sl<RemoteVolumeController>(),
        audioRoutePort: hasGateway ? sl<AudioRoutePort>() : null,
        includeLocalDevice: true,
        autoStart: false,
      );
    },
    dispose: (c) => c.close(),
  );

  if (!sl.isRegistered<ConnectSessionCoordinator>() &&
      sl.isRegistered<ConnectNativeGateway>() &&
      sl.isRegistered<AuthSessionProvider>() &&
      sl.isRegistered<NativePlaybackSessionBridge>()) {
    sl.registerLazySingleton<ConnectSessionCoordinator>(
      () => ConnectSessionCoordinator(
        authSessionProvider: sl<AuthSessionProvider>(),
        deviceIdentityService: sl<DeviceIdentityService>(),
        apResolveService: sl<ApResolveService>(),
        deviceEnvironmentPort: sl<DeviceEnvironmentPort>(),
        audioRoutePort: sl<AudioRoutePort>(),
        systemVolumePort: sl<SystemVolumePort>(),
        localDiscoveryPort: sl<LocalDiscoveryPort>(),
        nativeGateway: sl<ConnectNativeGateway>(),
        playbackSessionBridge: sl<NativePlaybackSessionBridge>(),
        connectController: sl<ConnectMobiusController>(),
        remoteVolumeController: sl<RemoteVolumeController>(),
        sortingDatabase: sl<DevicePickerSortingDatabase>(),
        runtimeContext:
            sl.isRegistered<RuntimeContext>() ? sl<RuntimeContext>() : null,
        deviceInfoPayloadBuilder: sl<DeviceInfoPayloadBuilder>(),
      ),
      dispose: (coordinator) => coordinator.dispose(),
    );
  }
}
