// 1:1 replica of Spotify Connect subsystem bootstrap and sorting DI wiring:
// - Native C++ ConnectSubsystem lifecycle (`android/app/src/main/cpp/ffi_bridge.cpp:854`
//   `musify_connect_start`, `android/app/src/main/cpp/connect/ConnectSubsystem.cpp:74`)
// - DevicePickerSortingDatabase Room module (`qr0.java`, `p199p/azq.java`,
//   `p199p/in1.java`)
// - Connect Mobius loop & Esperanto client graph (`p199p/yrq.java`, `p199p/s77.java`)

import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/application/sorting/device_picker_sorting_database.dart';
import 'package:musify_mu/features/connect/application/volume/remote_volume_controller.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_volume_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/dodo_service_client.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import 'package:musify_mu/features/player/data/esperanto/native_esperanto_transport.dart';

/// Registers all Spotify Connect Esperanto clients, sorting persistence,
/// remote volume controller, and Mobius controller lazily in [sl].
///
/// Lazy registration ensures host unit tests that do not resolve Connect
/// singletons never load `libmusify_audio.so` or invoke `path_provider`.
void setupConnectInjection(GetIt sl) {
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
    () => RemoteVolumeController(
      volumeClient: sl<ConnectVolumeServiceClient>(),
    ),
    dispose: (vc) => vc.dispose(),
  );

  sl.registerLazySingleton<ConnectMobiusController>(
    () => ConnectMobiusController(
      connectServiceClient: sl<ConnectServiceClient>(),
      volumeServiceClient: sl<ConnectVolumeServiceClient>(),
      dodoServiceClient: sl<DodoServiceClient>(),
      sortingDatabase: sl<DevicePickerSortingDatabase>(),
      remoteVolumeController: sl<RemoteVolumeController>(),
      autoStart: false,
    ),
    dispose: (c) => c.close(),
  );
}

/// Starts the native C++ `ConnectSubsystem` when running on Android and
/// activates the Dart [ConnectMobiusController] loop (`ffi_bridge.cpp:854`,
/// `ConnectSubsystem.cpp:74`).
void startConnectSubsystemIfSupported({
  required ConnectMobiusController controller,
  EsperantoTransport? transport,
  bool? isAndroidOverride,
}) {
  final bool isAndroid = switch (isAndroidOverride) {
    final override? => override,
    null => Platform.isAndroid,
  };
  if (!isAndroid || controller.isClosed || controller.isStarted) {
    return;
  }
  if (transport case final NativeEsperantoTransport nativeTransport) {
    nativeTransport.connectStart();
  }
  controller.start();
}
