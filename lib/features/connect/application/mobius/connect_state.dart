// 1:1 replica of p199p/v6k.java (lines 1-67), p199p/w6k.java (lines 1-54),
// p199p/tck.java (lines 6-48), p199p/xh7.java (lines 4-72),
// p199p/y9p0.java (lines 6-59), p199p/a0d.java (line 70),
// p199p/q9d.java (lines 72-86), and p199p/gtg.java (lines 442-519).

import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/connect/application/sorting/device_sorting_comparator.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pbenum.dart'
    as common_pb;
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pbenum.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/data/proto/es_dodos_messages.pb.dart'
    as dodos_pb;
import 'package:musify_mu/features/connect/domain/models/connect_cluster.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';
import 'package:musify_mu/features/connect/domain/models/transfer_state.dart';

/// Reserved local playback device identifier (`p199p/qtq.java:60`, `p199p/y280.java`).
const String kLocalDeviceIdentifier = 'local_device';

/// Reserved built-in speaker peripheral identifier (`p199p/gtg.java:464-482`).
const String kBuiltInSpeakerPeripheralId = 'built_in_speaker';

/// Immutable audio output peripheral descriptor matching `p199p/xh7.java` and
/// `p199p/y9p0.java`.
@immutable
final class LocalAudioPeripheral extends Equatable {
  /// Peripheral identifier (`xh7.f274572a`, e.g. `built_in_speaker`).
  final String id;

  /// Peripheral display name (`xh7.f274573b`).
  final String name;

  /// Whether this peripheral is currently active (`xh7.f274574c`).
  final bool isActive;

  /// Output connection type (`xh7.f274575d`, `p199p/y9p0.java`).
  final OutputPeripheralConnectionType connectionType;

  /// Whether the peripheral is currently connected (tie-breaker in `p199p/q9d.java:72-86`).
  final bool isConnected;

  /// Optional manufacturer/brand (`xh7.f274576e` / `ca7`).
  final String? brand;

  /// Optional hardware model (`xh7.f274576e` / `ca7`).
  final String? model;

  /// Optional peripheral category (`xh7.f274576e` / `ca7`).
  final OutputPeripheralCategory? category;

  LocalAudioPeripheral({
    required this.id,
    required this.name,
    required this.isActive,
    required this.connectionType,
    this.isConnected = false,
    this.brand,
    this.model,
    this.category,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Must be non-empty');
    }
  }

  /// Converts this peripheral descriptor to a domain [OutputPeripheral].
  OutputPeripheral toOutputPeripheral() {
    return OutputPeripheral(
      name: name,
      brand: brand,
      model: model,
      connectionType: connectionType,
      category: category,
    );
  }

  LocalAudioPeripheral copyWith({
    String? id,
    String? name,
    bool? isActive,
    OutputPeripheralConnectionType? connectionType,
    bool? isConnected,
    String? brand,
    bool clearBrand = false,
    String? model,
    bool clearModel = false,
    OutputPeripheralCategory? category,
    bool clearCategory = false,
  }) {
    return LocalAudioPeripheral(
      id: switch (id) {
        final value? => value,
        null => this.id,
      },
      name: switch (name) {
        final value? => value,
        null => this.name,
      },
      isActive: switch (isActive) {
        final value? => value,
        null => this.isActive,
      },
      connectionType: switch (connectionType) {
        final value? => value,
        null => this.connectionType,
      },
      isConnected: switch (isConnected) {
        final value? => value,
        null => this.isConnected,
      },
      brand: clearBrand
          ? null
          : switch (brand) {
              final value? => value,
              null => this.brand,
            },
      model: clearModel
          ? null
          : switch (model) {
              final value? => value,
              null => this.model,
            },
      category: clearCategory
          ? null
          : switch (category) {
              final value? => value,
              null => this.category,
            },
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        isActive,
        connectionType,
        isConnected,
        brand,
        model,
        category,
      ];
}

/// Classification of failures surfaced through [ConnectState.lastError].
enum ConnectFailureKind {
  clusterStream,
  peripheralStream,
  recommendedDevicesStream,
  sortingStream,
  volumeStream,
  dodoStream,
  transfer,
  pull,
  recordConnection,
  logout,
  renameDevice,
  sendPlayerCommand,
  volumeCommand,
  groupCommand,
  incarnation,
  audioRoute,
  discovery,
  refreshCluster,
  wakeDevices,
  installSpotify,
  dodoCommand,
  backendSync,
}

/// Typed immutable error descriptor surfaced by [ConnectState.lastError].
@immutable
final class ConnectFailure extends Equatable {
  final ConnectFailureKind kind;
  final String message;
  final Object? cause;
  final String? deviceIdentifier;
  final TransferFailureReason? transferFailureReason;
  final common_pb.Status? status;
  final ConnectVolumeStatus? volumeStatus;
  final connect_pb.GroupError? groupError;
  final connect_pb.RemoveGroupError? removeGroupError;
  final connect_pb.DeleteGroupError? deleteGroupError;
  final connect_pb.InstallSpotifyState? installSpotifyState;

  const ConnectFailure({
    required this.kind,
    required this.message,
    this.cause,
    this.deviceIdentifier,
    this.transferFailureReason,
    this.status,
    this.volumeStatus,
    this.groupError,
    this.removeGroupError,
    this.deleteGroupError,
    this.installSpotifyState,
  });

  @override
  List<Object?> get props => [
        kind,
        message,
        cause,
        deviceIdentifier,
        transferFailureReason,
        status,
        volumeStatus,
        groupError,
        removeGroupError,
        deleteGroupError,
        installSpotifyState,
      ];
}

/// Internal Connect Mobius state matching `p199p/v6k.java` (lines 1-67).
@immutable
final class ConnectInternalState extends Equatable {
  /// Local audio output peripherals (`v6k.f248953a`).
  final UnmodifiableListView<LocalAudioPeripheral> peripherals;

  /// Whether cluster state is synchronized with backend (`v6k.f248954b`).
  final bool isSyncedWithBackend;

  /// Raw cluster devices in backend-emitted order (`v6k.f248955c`).
  final UnmodifiableListView<ConnectDevice> rawDevices;

  /// Recommended local device identifiers (`v6k.f248956d`).
  final UnmodifiableListView<String> recommendedLocalDeviceIds;

  ConnectInternalState({
    required List<LocalAudioPeripheral> peripherals,
    required this.isSyncedWithBackend,
    required List<ConnectDevice> rawDevices,
    required List<String> recommendedLocalDeviceIds,
  })  : peripherals = UnmodifiableListView<LocalAudioPeripheral>(
          List<LocalAudioPeripheral>.of(peripherals),
        ),
        rawDevices = UnmodifiableListView<ConnectDevice>(
          List<ConnectDevice>.of(rawDevices),
        ),
        recommendedLocalDeviceIds = UnmodifiableListView<String>(
          List<String>.of(recommendedLocalDeviceIds),
        );

  /// Initial empty internal state matching `yrq.java:79-82`.
  factory ConnectInternalState.initial() {
    return ConnectInternalState(
      peripherals: const <LocalAudioPeripheral>[],
      isSyncedWithBackend: false,
      rawDevices: const <ConnectDevice>[],
      recommendedLocalDeviceIds: const <String>[],
    );
  }

  ConnectInternalState copyWith({
    List<LocalAudioPeripheral>? peripherals,
    bool? isSyncedWithBackend,
    List<ConnectDevice>? rawDevices,
    List<String>? recommendedLocalDeviceIds,
  }) {
    return ConnectInternalState(
      peripherals: switch (peripherals) {
        final value? => value,
        null => this.peripherals,
      },
      isSyncedWithBackend: switch (isSyncedWithBackend) {
        final value? => value,
        null => this.isSyncedWithBackend,
      },
      rawDevices: switch (rawDevices) {
        final value? => value,
        null => this.rawDevices,
      },
      recommendedLocalDeviceIds: switch (recommendedLocalDeviceIds) {
        final value? => value,
        null => this.recommendedLocalDeviceIds,
      },
    );
  }

  @override
  List<Object?> get props => [
        peripherals,
        isSyncedWithBackend,
        rawDevices,
        recommendedLocalDeviceIds,
      ];
}

/// Public immutable Connect state matching `p199p/w6k.java` (lines 1-54)
/// extended with cluster, sorted devices, timestamps, transfer, volume,
/// dodos, install progress, and typed error state.
@immutable
final class ConnectState extends Equatable {
  static const DeviceSortingComparatorFactory _comparatorFactory =
      DeviceSortingComparatorFactory();

  /// Underlying 4-field `v6k` internal snapshot.
  final ConnectInternalState internal;

  /// Whether cluster state is synchronized with backend (`w6k.f259754a`).
  final bool isSyncedWithBackend;

  /// Most recent raw [ConnectCluster] from `ConnectServiceClient.state()`.
  final ConnectCluster? cluster;

  /// Available devices in raw cluster order (`w6k.f259755b`, `yrq.m95027j`).
  final UnmodifiableListView<ConnectDevice> devices;

  /// Available devices sorted via `DeviceSortingComparatorFactory` (`in1`/`c6k`).
  final UnmodifiableListView<ConnectDevice> sortedDevices;

  /// First active device in [devices], or `null` (`w6k.f259756c`).
  final ConnectDevice? activeDevice;

  /// First self/local device in [devices], or `null` (`w6k.f259757d`).
  final ConnectDevice? selfDevice;

  /// Self device audio peripherals projected and sorted via `gtg` case 17
  /// when [selfDevice] and [ConnectInternalState.peripherals] are present.
  final UnmodifiableListView<LocalAudioPeripheral> selfPeripherals;

  /// Active/first projected self peripheral when [selfPeripherals] is non-empty.
  final LocalAudioPeripheral? activeSelfPeripheral;

  /// Recommended local identifiers (`h6k`).
  final UnmodifiableListView<String> recommendedLocalDeviceIds;

  /// Last-connection timestamps map keyed by SHA-256 hashed identifier.
  final UnmodifiableMapView<String, int> lastConnectionTimestamps;

  /// Active/latest playback transfer state.
  final TransferState transferState;

  /// Latest remote/local Connect volume state.
  final ConnectVolumeState volumeState;

  /// Latest Dodo session list from `DodoServiceClient.dodoSub()`.
  final UnmodifiableListView<dodos_pb.SingleDodo> dodos;

  /// Latest `InstallSpotify` status emitted for [installSpotifyDeviceId].
  final connect_pb.InstallSpotifyState? installSpotifyState;

  /// Target device identifier for active/latest `InstallSpotify` operation.
  final String? installSpotifyDeviceId;

  /// Most recent typed Connect failure, or `null` when clear.
  final ConnectFailure? lastError;

  ConnectState({
    required this.internal,
    required this.isSyncedWithBackend,
    this.cluster,
    required List<ConnectDevice> devices,
    required List<ConnectDevice> sortedDevices,
    this.activeDevice,
    this.selfDevice,
    required List<LocalAudioPeripheral> selfPeripherals,
    this.activeSelfPeripheral,
    required List<String> recommendedLocalDeviceIds,
    required Map<String, int> lastConnectionTimestamps,
    required this.transferState,
    required this.volumeState,
    required List<dodos_pb.SingleDodo> dodos,
    this.installSpotifyState,
    this.installSpotifyDeviceId,
    this.lastError,
  })  : devices = UnmodifiableListView<ConnectDevice>(
          List<ConnectDevice>.of(devices),
        ),
        sortedDevices = UnmodifiableListView<ConnectDevice>(
          List<ConnectDevice>.of(sortedDevices),
        ),
        selfPeripherals = UnmodifiableListView<LocalAudioPeripheral>(
          List<LocalAudioPeripheral>.of(selfPeripherals),
        ),
        recommendedLocalDeviceIds = UnmodifiableListView<String>(
          List<String>.of(recommendedLocalDeviceIds),
        ),
        lastConnectionTimestamps = UnmodifiableMapView<String, int>(
          Map<String, int>.of(lastConnectionTimestamps),
        ),
        dodos = UnmodifiableListView<dodos_pb.SingleDodo>(
          List<dodos_pb.SingleDodo>.of(dodos),
        );

  /// Initial empty state matching `new w6k()`.
  factory ConnectState.initial() {
    return ConnectState(
      internal: ConnectInternalState.initial(),
      isSyncedWithBackend: false,
      devices: const <ConnectDevice>[],
      sortedDevices: const <ConnectDevice>[],
      selfPeripherals: const <LocalAudioPeripheral>[],
      recommendedLocalDeviceIds: const <String>[],
      lastConnectionTimestamps: const <String, int>{},
      transferState: const TransferIdle(),
      volumeState: ConnectVolumeState(),
      dodos: const <dodos_pb.SingleDodo>[],
    );
  }

  /// Constructs a projected [ConnectState] from a cached [ConnectInternalState]
  /// (`v6k` -> `w6k`, matching `gtg` case 17 and `yrq.mo28045b()`).
  factory ConnectState.fromInternal(
    ConnectInternalState internal, {
    ConnectCluster? cluster,
    Map<String, int> lastConnectionTimestamps = const <String, int>{},
    TransferState transferState = const TransferIdle(),
    ConnectVolumeState? volumeState,
    List<dodos_pb.SingleDodo> dodos = const <dodos_pb.SingleDodo>[],
    connect_pb.InstallSpotifyState? installSpotifyState,
    String? installSpotifyDeviceId,
    ConnectFailure? lastError,
  }) {
    final resolvedVolume = switch (volumeState) {
      final value? => value,
      null => ConnectVolumeState(),
    };
    return _project(
      internal: internal,
      cluster: cluster,
      lastConnectionTimestamps: lastConnectionTimestamps,
      transferState: transferState,
      volumeState: resolvedVolume,
      dodos: dodos,
      installSpotifyState: installSpotifyState,
      installSpotifyDeviceId: installSpotifyDeviceId,
      lastError: lastError,
    );
  }

  /// Active remote device (`isActive && !isSelf`), or `null`.
  ConnectDevice? get activeRemoteDevice {
    for (final device in devices) {
      if (device.isActive && !device.isSelf) {
        return device;
      }
    }
    return null;
  }

  /// Whether [lastError] is currently populated.
  bool get hasError => lastError != null;

  /// Whether a playback transfer is currently in progress.
  bool get isTransferring => transferState is TransferInProgress;

  /// Whether [localIdentifier] is present in [recommendedLocalDeviceIds].
  bool isRecommendedLocalDevice(String localIdentifier) {
    return recommendedLocalDeviceIds.contains(localIdentifier);
  }

  /// Re-projects [devices], [sortedDevices], [activeDevice], [selfDevice],
  /// [selfPeripherals], and [activeSelfPeripheral] cleanly from [internal] and
  /// [lastConnectionTimestamps].
  ConnectState withProjection({
    ConnectInternalState? internal,
    ConnectCluster? cluster,
    bool clearCluster = false,
    Map<String, int>? lastConnectionTimestamps,
    TransferState? transferState,
    ConnectVolumeState? volumeState,
    List<dodos_pb.SingleDodo>? dodos,
    connect_pb.InstallSpotifyState? installSpotifyState,
    bool clearInstallSpotifyState = false,
    String? installSpotifyDeviceId,
    bool clearInstallSpotifyDeviceId = false,
    ConnectFailure? lastError,
    bool clearLastError = false,
  }) {
    final nextInternal = switch (internal) {
      final value? => value,
      null => this.internal,
    };
    final nextCluster = clearCluster
        ? null
        : switch (cluster) {
            final value? => value,
            null => this.cluster,
          };
    final nextTimestamps = switch (lastConnectionTimestamps) {
      final value? => value,
      null => this.lastConnectionTimestamps,
    };
    final nextTransfer = switch (transferState) {
      final value? => value,
      null => this.transferState,
    };
    final nextVolume = switch (volumeState) {
      final value? => value,
      null => this.volumeState,
    };
    final nextDodos = switch (dodos) {
      final value? => value,
      null => this.dodos,
    };
    final nextInstallState = clearInstallSpotifyState
        ? null
        : switch (installSpotifyState) {
            final value? => value,
            null => this.installSpotifyState,
          };
    final nextInstallDeviceId = clearInstallSpotifyDeviceId
        ? null
        : switch (installSpotifyDeviceId) {
            final value? => value,
            null => this.installSpotifyDeviceId,
          };
    final nextLastError = clearLastError
        ? null
        : switch (lastError) {
            final value? => value,
            null => this.lastError,
          };

    return _project(
      internal: nextInternal,
      cluster: nextCluster,
      lastConnectionTimestamps: nextTimestamps,
      transferState: nextTransfer,
      volumeState: nextVolume,
      dodos: nextDodos,
      installSpotifyState: nextInstallState,
      installSpotifyDeviceId: nextInstallDeviceId,
      lastError: nextLastError,
    );
  }

  ConnectState copyWith({
    ConnectInternalState? internal,
    bool? isSyncedWithBackend,
    ConnectCluster? cluster,
    bool clearCluster = false,
    List<ConnectDevice>? devices,
    List<ConnectDevice>? sortedDevices,
    ConnectDevice? activeDevice,
    bool clearActiveDevice = false,
    ConnectDevice? selfDevice,
    bool clearSelfDevice = false,
    List<LocalAudioPeripheral>? selfPeripherals,
    LocalAudioPeripheral? activeSelfPeripheral,
    bool clearActiveSelfPeripheral = false,
    List<String>? recommendedLocalDeviceIds,
    Map<String, int>? lastConnectionTimestamps,
    TransferState? transferState,
    ConnectVolumeState? volumeState,
    List<dodos_pb.SingleDodo>? dodos,
    connect_pb.InstallSpotifyState? installSpotifyState,
    bool clearInstallSpotifyState = false,
    String? installSpotifyDeviceId,
    bool clearInstallSpotifyDeviceId = false,
    ConnectFailure? lastError,
    bool clearLastError = false,
  }) {
    return ConnectState(
      internal: switch (internal) {
        final value? => value,
        null => this.internal,
      },
      isSyncedWithBackend: switch (isSyncedWithBackend) {
        final value? => value,
        null => this.isSyncedWithBackend,
      },
      cluster: clearCluster
          ? null
          : switch (cluster) {
              final value? => value,
              null => this.cluster,
            },
      devices: switch (devices) {
        final value? => value,
        null => this.devices,
      },
      sortedDevices: switch (sortedDevices) {
        final value? => value,
        null => this.sortedDevices,
      },
      activeDevice: clearActiveDevice
          ? null
          : switch (activeDevice) {
              final value? => value,
              null => this.activeDevice,
            },
      selfDevice: clearSelfDevice
          ? null
          : switch (selfDevice) {
              final value? => value,
              null => this.selfDevice,
            },
      selfPeripherals: switch (selfPeripherals) {
        final value? => value,
        null => this.selfPeripherals,
      },
      activeSelfPeripheral: clearActiveSelfPeripheral
          ? null
          : switch (activeSelfPeripheral) {
              final value? => value,
              null => this.activeSelfPeripheral,
            },
      recommendedLocalDeviceIds: switch (recommendedLocalDeviceIds) {
        final value? => value,
        null => this.recommendedLocalDeviceIds,
      },
      lastConnectionTimestamps: switch (lastConnectionTimestamps) {
        final value? => value,
        null => this.lastConnectionTimestamps,
      },
      transferState: switch (transferState) {
        final value? => value,
        null => this.transferState,
      },
      volumeState: switch (volumeState) {
        final value? => value,
        null => this.volumeState,
      },
      dodos: switch (dodos) {
        final value? => value,
        null => this.dodos,
      },
      installSpotifyState: clearInstallSpotifyState
          ? null
          : switch (installSpotifyState) {
              final value? => value,
              null => this.installSpotifyState,
            },
      installSpotifyDeviceId: clearInstallSpotifyDeviceId
          ? null
          : switch (installSpotifyDeviceId) {
              final value? => value,
              null => this.installSpotifyDeviceId,
            },
      lastError: clearLastError
          ? null
          : switch (lastError) {
              final value? => value,
              null => this.lastError,
            },
    );
  }

  static ConnectState _project({
    required ConnectInternalState internal,
    required ConnectCluster? cluster,
    required Map<String, int> lastConnectionTimestamps,
    required TransferState transferState,
    required ConnectVolumeState volumeState,
    required List<dodos_pb.SingleDodo> dodos,
    required connect_pb.InstallSpotifyState? installSpotifyState,
    required String? installSpotifyDeviceId,
    required ConnectFailure? lastError,
  }) {
    final clusterDevices = List<ConnectDevice>.of(internal.rawDevices);
    final comparator = _comparatorFactory.createForDevices(
      lastConnectionTimestamps: lastConnectionTimestamps,
      devices: clusterDevices,
    );
    final sorted = comparator.sortDevices(clusterDevices);

    ConnectDevice? active;
    ConnectDevice? self;
    for (final device in clusterDevices) {
      if (active == null && device.isActive) {
        active = device;
      }
      if (self == null && device.isSelf) {
        self = device;
      }
    }

    final List<LocalAudioPeripheral> projectedPeripherals;
    final LocalAudioPeripheral? activePeripheral;
    if (self != null && internal.peripherals.isNotEmpty) {
      projectedPeripherals = _projectPeripherals(internal.peripherals);
      activePeripheral =
          projectedPeripherals.isNotEmpty ? projectedPeripherals.first : null;
    } else {
      projectedPeripherals = const <LocalAudioPeripheral>[];
      activePeripheral = null;
    }

    return ConnectState(
      internal: internal,
      isSyncedWithBackend: internal.isSyncedWithBackend,
      cluster: cluster,
      devices: clusterDevices,
      sortedDevices: sorted,
      activeDevice: active,
      selfDevice: self,
      selfPeripherals: projectedPeripherals,
      activeSelfPeripheral: activePeripheral,
      recommendedLocalDeviceIds: internal.recommendedLocalDeviceIds,
      lastConnectionTimestamps: lastConnectionTimestamps,
      transferState: transferState,
      volumeState: volumeState,
      dodos: dodos,
      installSpotifyState: installSpotifyState,
      installSpotifyDeviceId: installSpotifyDeviceId,
      lastError: lastError,
    );
  }

  /// 1:1 with `p199p/gtg.java:448-484`, `p199p/a0d.java:70`, `p199p/q9d.java:72-86`.
  static List<LocalAudioPeripheral> _projectPeripherals(
    List<LocalAudioPeripheral> rawPeripherals,
  ) {
    var activeIndex = -1;
    var builtInIndex = -1;
    for (var i = 0; i < rawPeripherals.length; i++) {
      final item = rawPeripherals[i];
      if (activeIndex == -1 && item.isActive) {
        activeIndex = i;
      }
      if (builtInIndex == -1 && item.id == kBuiltInSpeakerPeripheralId) {
        builtInIndex = i;
      }
    }

    final projected = List<LocalAudioPeripheral>.of(rawPeripherals);
    if (activeIndex == -1) {
      if (builtInIndex == -1) {
        projected.add(
          LocalAudioPeripheral(
            id: kBuiltInSpeakerPeripheralId,
            name: kBuiltInSpeakerPeripheralId,
            isActive: true,
            connectionType: OutputPeripheralConnectionType.builtInSpeaker,
          ),
        );
      } else {
        projected[builtInIndex] = projected[builtInIndex].copyWith(
          isActive: true,
        );
      }
    } else if (builtInIndex == -1) {
      projected.add(
        LocalAudioPeripheral(
          id: kBuiltInSpeakerPeripheralId,
          name: kBuiltInSpeakerPeripheralId,
          isActive: false,
          connectionType: OutputPeripheralConnectionType.builtInSpeaker,
        ),
      );
    } else if (rawPeripherals.length != 1) {
      projected[builtInIndex] = projected[builtInIndex].copyWith(
        isActive: false,
      );
    }

    projected.sort((a, b) {
      if (a.isActive != b.isActive) {
        return b.isActive ? 1 : -1;
      }
      final aConnected = a.isConnected ||
          a.connectionType == OutputPeripheralConnectionType.carProjected;
      final bConnected = b.isConnected ||
          b.connectionType == OutputPeripheralConnectionType.carProjected;
      if (aConnected != bConnected) {
        return bConnected ? 1 : -1;
      }
      return 0;
    });

    return projected;
  }

  @override
  List<Object?> get props => [
        internal,
        isSyncedWithBackend,
        cluster,
        devices,
        sortedDevices,
        activeDevice,
        selfDevice,
        selfPeripherals,
        activeSelfPeripheral,
        recommendedLocalDeviceIds,
        lastConnectionTimestamps,
        transferState,
        volumeState,
        dodos,
        installSpotifyState,
        installSpotifyDeviceId,
        lastError,
      ];
}
