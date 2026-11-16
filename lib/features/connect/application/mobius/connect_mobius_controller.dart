// 1:1 replica of p199p/yrq.java (lines 13-166), p199p/csq.java,
// p199p/jtq.java, p199p/kg5.java (lines 1262-1271), p199p/gtg.java (lines 442-519),
// p199p/in1.java (lines 35-37), p199p/c6k.java (line 27), and p199p/roi1.java (lines 121-124).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show StateStreamableSource;
import 'package:musify_mu/features/connect/application/mobius/connect_effect.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_effect_handler.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_event.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_update.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_state.dart';
import 'package:musify_mu/features/connect/application/sorting/device_picker_sorting_database.dart';
import 'package:musify_mu/features/connect/application/volume/remote_volume_controller.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_volume_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/dodo_service_client.dart';
import 'package:musify_mu/features/connect/data/mappers/connect_proto_mappers.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/player/application/queue/mobius/mobius_loop.dart';

export 'package:musify_mu/features/connect/application/mobius/connect_effect.dart';
export 'package:musify_mu/features/connect/application/mobius/connect_effect_handler.dart';
export 'package:musify_mu/features/connect/application/mobius/connect_event.dart';
export 'package:musify_mu/features/connect/application/mobius/connect_mobius_update.dart';
export 'package:musify_mu/features/connect/application/mobius/connect_state.dart';
export 'package:musify_mu/features/player/application/queue/mobius/mobius_loop.dart';
export 'package:musify_mu/features/player/application/queue/mobius/mobius_types.dart';

/// Mutable holder forwarding intermediate effect events into the controller
/// without deferred-initialization fields (`PlayerQueueMobiusController` pattern).
final class _DynamicEventSinkRef {
  void Function(ConnectEvent event)? _sink;

  void bind(void Function(ConnectEvent event) sink) {
    _sink = sink;
  }

  void unbind() {
    _sink = null;
  }

  void call(ConnectEvent event) {
    final current = _sink;
    if (current != null) {
      current(event);
    }
  }
}

/// 1:1 Connect Mobius Loop Controller matching `p199p/yrq.java`, `p199p/csq.java`,
/// and downstream `p199p/in1.java` / `p199p/c6k.java` sorting projection.
class ConnectMobiusController extends ChangeNotifier
    implements ValueListenable<ConnectState>, StateStreamableSource<ConnectState> {
  final ConnectServiceClient _connectServiceClient;
  final DodoServiceClient _dodoServiceClient;
  final DevicePickerSortingDatabase _sortingDatabase;
  final RemoteVolumeController _remoteVolumeController;
  final bool _ownsRemoteVolumeController;
  final Stream<List<LocalAudioPeripheral>>? _peripheralsStream;
  final Stream<List<String>>? _recommendedLocalDeviceIdsStream;
  final bool _showOfflineDevicesInCore;
  final bool _showOfflineAmazonDevicesAsOnline;
  final bool _includeLocalDevice;
  final bool _excludeNonLocalDevices;
  final bool _includeUserMatchUnauthenticatedDevices;

  final ConnectEffectHandler _effectHandler;
  final _DynamicEventSinkRef _intermediateSinkRef;
  final StreamController<ConnectState> _stateController =
      StreamController<ConnectState>.broadcast();
  final List<ConnectEvent> _pendingEvents = <ConnectEvent>[];
  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];
  final Set<Future<void>> _inFlightCancels = <Future<void>>{};

  MobiusLoop<ConnectState, ConnectEvent, ConnectEffect>? _loop;
  ConnectInternalState? _cachedInternalState;
  ConnectState _exposedState = ConnectState.initial();
  ConnectDevice? _lastNotifiedActiveDevice;
  Future<void>? _closeFuture;
  int _lifecycleEpoch = 0;
  bool _isStarted = false;
  bool _isClosed = false;

  ConnectMobiusController._({
    required ConnectServiceClient connectServiceClient,
    required DodoServiceClient dodoServiceClient,
    required DevicePickerSortingDatabase sortingDatabase,
    required RemoteVolumeController remoteVolumeController,
    required bool ownsRemoteVolumeController,
    required ConnectEffectHandler effectHandler,
    required _DynamicEventSinkRef intermediateSinkRef,
    required Stream<List<LocalAudioPeripheral>>? peripheralsStream,
    required Stream<List<String>>? recommendedLocalDeviceIdsStream,
    required bool showOfflineDevicesInCore,
    required bool showOfflineAmazonDevicesAsOnline,
    required bool includeLocalDevice,
    required bool excludeNonLocalDevices,
    required bool includeUserMatchUnauthenticatedDevices,
  })  : _connectServiceClient = connectServiceClient,
        _dodoServiceClient = dodoServiceClient,
        _sortingDatabase = sortingDatabase,
        _remoteVolumeController = remoteVolumeController,
        _ownsRemoteVolumeController = ownsRemoteVolumeController,
        _effectHandler = effectHandler,
        _intermediateSinkRef = intermediateSinkRef,
        _peripheralsStream = peripheralsStream,
        _recommendedLocalDeviceIdsStream = recommendedLocalDeviceIdsStream,
        _showOfflineDevicesInCore = showOfflineDevicesInCore,
        _showOfflineAmazonDevicesAsOnline = showOfflineAmazonDevicesAsOnline,
        _includeLocalDevice = includeLocalDevice,
        _excludeNonLocalDevices = excludeNonLocalDevices,
        _includeUserMatchUnauthenticatedDevices =
            includeUserMatchUnauthenticatedDevices;

  factory ConnectMobiusController({
    required ConnectServiceClient connectServiceClient,
    required ConnectVolumeServiceClient volumeServiceClient,
    required DodoServiceClient dodoServiceClient,
    required DevicePickerSortingDatabase sortingDatabase,
    RemoteVolumeController? remoteVolumeController,
    Stream<List<LocalAudioPeripheral>>? peripheralsStream,
    Stream<List<String>>? recommendedLocalDeviceIdsStream,
    ConnectProtoMappers mappers = const ConnectProtoMappers(),
    String Function()? commandIdGenerator,
    bool showOfflineDevicesInCore = false,
    bool showOfflineAmazonDevicesAsOnline = false,
    bool includeLocalDevice = false,
    bool excludeNonLocalDevices = false,
    bool includeUserMatchUnauthenticatedDevices = false,
    bool autoStart = false,
  }) {
    final ownsRemoteVolume = remoteVolumeController == null;
    final resolvedVolumeController = switch (remoteVolumeController) {
      final external? => external,
      null => RemoteVolumeController(volumeClient: volumeServiceClient),
    };

    final intermediateSinkRef = _DynamicEventSinkRef();
    final handler = ConnectEffectHandler(
      connectServiceClient: connectServiceClient,
      remoteVolumeController: resolvedVolumeController,
      dodoServiceClient: dodoServiceClient,
      sortingDatabase: sortingDatabase,
      mappers: mappers,
      onIntermediateEvent: intermediateSinkRef.call,
      commandIdGenerator: commandIdGenerator,
    );

    final controller = ConnectMobiusController._(
      connectServiceClient: connectServiceClient,
      dodoServiceClient: dodoServiceClient,
      sortingDatabase: sortingDatabase,
      remoteVolumeController: resolvedVolumeController,
      ownsRemoteVolumeController: ownsRemoteVolume,
      effectHandler: handler,
      intermediateSinkRef: intermediateSinkRef,
      peripheralsStream: peripheralsStream,
      recommendedLocalDeviceIdsStream: recommendedLocalDeviceIdsStream,
      showOfflineDevicesInCore: showOfflineDevicesInCore,
      showOfflineAmazonDevicesAsOnline: showOfflineAmazonDevicesAsOnline,
      includeLocalDevice: includeLocalDevice,
      excludeNonLocalDevices: excludeNonLocalDevices,
      includeUserMatchUnauthenticatedDevices:
          includeUserMatchUnauthenticatedDevices,
    );

    if (autoStart) {
      controller.start();
    }
    return controller;
  }

  /// Current exposed [ConnectState] snapshot (`yrq.m95025g`).
  ConnectState get currentState => _exposedState;

  @override
  ConnectState get state => _exposedState;

  @override
  ConnectState get value => _exposedState;

  /// Replay(1) broadcast stream of [ConnectState] snapshots (`yrq.f289332Y`).
  @override
  Stream<ConnectState> get stream => Stream<ConnectState>.multi(
        (controller) {
          if (_isClosed || _stateController.isClosed) {
            controller.close();
            return;
          }
          controller.add(_exposedState);
          final subscription = _stateController.stream.listen(
            controller.add,
            onError: controller.addError,
            onDone: controller.close,
          );
          controller.onCancel = subscription.cancel;
        },
        isBroadcast: true,
      );

  /// Available Connect devices in raw cluster order (`yrq.m95026i`).
  List<ConnectDevice> get devices => _exposedState.devices;

  /// Stream of available Connect devices in cluster order (`yrq.m95027j`).
  Stream<List<ConnectDevice>> get devicesStream =>
      stream.map((s) => s.devices).distinct((a, b) => listEquals(a, b));

  /// Available Connect devices sorted via `DeviceSortingComparatorFactory` (`in1`/`c6k`).
  List<ConnectDevice> get sortedDevices => _exposedState.sortedDevices;

  /// Stream of sorted Connect devices (`in1`/`c6k`/`roi1`).
  Stream<List<ConnectDevice>> get sortedDevicesStream =>
      stream.map((s) => s.sortedDevices).distinct((a, b) => listEquals(a, b));

  /// Currently active Connect device, or `null` (`yrq.m95023c`).
  ConnectDevice? get activeDevice => _exposedState.activeDevice;

  /// Stream of active Connect device updates (`yrq.m95024d`).
  Stream<ConnectDevice?> get activeDeviceStream =>
      stream.map((s) => s.activeDevice).distinct();

  /// Local self Connect device, or `null` (`yrq.m95028k`).
  ConnectDevice? get selfDevice => _exposedState.selfDevice;

  /// Stream of self Connect device updates (`yrq.m95029l`).
  Stream<ConnectDevice?> get selfDeviceStream =>
      stream.map((s) => s.selfDevice).distinct();

  /// Whether cluster state is currently synced with backend.
  bool get isSyncedWithBackend => _exposedState.isSyncedWithBackend;

  /// Stream of backend sync status (`yrq.m95030m`).
  Stream<bool> get isSyncedWithBackendStream =>
      stream.map((s) => s.isSyncedWithBackend).distinct();

  /// Remote volume controller paired with this Connect Mobius controller.
  RemoteVolumeController get remoteVolumeController => _remoteVolumeController;

  /// Effect handler executing Connect side effects.
  ConnectEffectHandler get effectHandler => _effectHandler;

  /// Whether the Mobius loop is currently started.
  bool get isStarted => _isStarted;

  @override
  bool get isClosed => _isClosed;

  /// Starts the Connect Mobius loop and subscribes to upstream Connect streams
  /// (`yrq.mo28045b()`), retaining any cached internal `v6k` snapshot across
  /// `stop()` / `start()` cycles and flushing buffered pre-start `dispatch` events.
  void start() {
    if (_isClosed) {
      throw StateError('Cannot start a closed ConnectMobiusController');
    }
    if (_isStarted) {
      return;
    }

    _lifecycleEpoch += 1;
    final startEpoch = _lifecycleEpoch;

    final initialModel = switch (_cachedInternalState) {
      final cached? => ConnectState.fromInternal(
          cached,
          volumeState: _remoteVolumeController.state,
        ),
      null => ConnectState.initial(),
    };

    final loop = MobiusLoop<ConnectState, ConnectEvent, ConnectEffect>(
      initialModel: initialModel,
      update: connectMobiusUpdate,
      effectHandler: _effectHandler,
    );

    _loop = loop;
    _isStarted = true;
    _intermediateSinkRef.bind(
      (event) => _dispatchInEpoch(startEpoch, event),
    );
    _onLoopStateForEpoch(startEpoch, loop.currentModel);
    if (_isClosed || !_isStarted || startEpoch != _lifecycleEpoch) {
      return;
    }

    _registerSubscriptionForEpoch(
      startEpoch,
      loop.models.listen(
        (state) => _onLoopStateForEpoch(startEpoch, state),
        onError: (Object error, StackTrace stackTrace) {
          _dispatchInEpoch(
            startEpoch,
            ConnectStreamErrorEvent(
              ConnectFailure(
                kind: ConnectFailureKind.clusterStream,
                message: error.toString(),
                cause: error,
              ),
            ),
          );
        },
      ),
    );

    _registerSubscriptionForEpoch(
      startEpoch,
      _connectServiceClient
          .state(
            showOfflineDevicesInCore: _showOfflineDevicesInCore,
            showOfflineAmazonDevicesAsOnline: _showOfflineAmazonDevicesAsOnline,
            includeLocalDevice: _includeLocalDevice,
            excludeNonLocalDevices: _excludeNonLocalDevices,
            includeUserMatchUnauthenticatedDevices:
                _includeUserMatchUnauthenticatedDevices,
          )
          .distinct()
          .listen(
            (cluster) => _dispatchInEpoch(
              startEpoch,
              ClusterStateUpdatedEvent(cluster),
            ),
            onError: (Object error, StackTrace stackTrace) {
              _dispatchInEpoch(
                startEpoch,
                ConnectStreamErrorEvent(
                  ConnectFailure(
                    kind: ConnectFailureKind.clusterStream,
                    message: error.toString(),
                    cause: error,
                  ),
                ),
              );
            },
          ),
    );

    final peripheralsStream = _peripheralsStream;
    if (peripheralsStream != null) {
      _registerSubscriptionForEpoch(
        startEpoch,
        peripheralsStream.listen(
          (peripherals) => _dispatchInEpoch(
            startEpoch,
            PeripheralsUpdatedEvent(peripherals),
          ),
          onError: (Object error, StackTrace stackTrace) {
            _dispatchInEpoch(
              startEpoch,
              ConnectStreamErrorEvent(
                ConnectFailure(
                  kind: ConnectFailureKind.peripheralStream,
                  message: error.toString(),
                  cause: error,
                ),
              ),
            );
          },
        ),
      );
    }

    final recommendedStream = _recommendedLocalDeviceIdsStream;
    if (recommendedStream != null) {
      _registerSubscriptionForEpoch(
        startEpoch,
        recommendedStream.listen(
          (ids) => _dispatchInEpoch(
            startEpoch,
            RecommendedLocalDevicesUpdatedEvent(ids),
          ),
          onError: (Object error, StackTrace stackTrace) {
            _dispatchInEpoch(
              startEpoch,
              ConnectStreamErrorEvent(
                ConnectFailure(
                  kind: ConnectFailureKind.recommendedDevicesStream,
                  message: error.toString(),
                  cause: error,
                ),
              ),
            );
          },
        ),
      );
    }

    _registerSubscriptionForEpoch(
      startEpoch,
      _sortingDatabase.watchLastConnectionTimestamps().listen(
            (timestamps) => _dispatchInEpoch(
              startEpoch,
              SortingTimestampsUpdatedEvent(timestamps),
            ),
            onError: (Object error, StackTrace stackTrace) {
              _dispatchInEpoch(
                startEpoch,
                ConnectStreamErrorEvent(
                  ConnectFailure(
                    kind: ConnectFailureKind.sortingStream,
                    message: error.toString(),
                    cause: error,
                  ),
                ),
              );
            },
          ),
    );

    _registerSubscriptionForEpoch(
      startEpoch,
      _remoteVolumeController.stream.listen(
        (volumeState) => _dispatchInEpoch(
          startEpoch,
          VolumeStateUpdatedEvent(volumeState),
        ),
        onError: (Object error, StackTrace stackTrace) {
          _dispatchInEpoch(
            startEpoch,
            ConnectStreamErrorEvent(
              ConnectFailure(
                kind: ConnectFailureKind.volumeStream,
                message: error.toString(),
                cause: error,
              ),
            ),
          );
        },
      ),
    );

    _registerSubscriptionForEpoch(
      startEpoch,
      _dodoServiceClient.dodoSub().listen(
            (response) => _dispatchInEpoch(
              startEpoch,
              DodoSubUpdatedEvent(response.dodos),
            ),
            onError: (Object error, StackTrace stackTrace) {
              _dispatchInEpoch(
                startEpoch,
                ConnectStreamErrorEvent(
                  ConnectFailure(
                    kind: ConnectFailureKind.dodoStream,
                    message: error.toString(),
                    cause: error,
                  ),
                ),
              );
            },
          ),
    );

    if (_pendingEvents.isNotEmpty) {
      final buffered = List<ConnectEvent>.of(_pendingEvents);
      _pendingEvents.clear();
      for (final event in buffered) {
        if (_isClosed || !_isStarted || startEpoch != _lifecycleEpoch) {
          break;
        }
        _dispatchInEpoch(startEpoch, event);
      }
    }
  }

  /// Dispatches [event] into the active Mobius loop, or buffers it (`p199p/csq.java`)
  /// if called before [start()] or while stopped.
  void dispatch(ConnectEvent event) {
    if (_isClosed) {
      return;
    }
    final activeLoop = _loop;
    if (!_isStarted || activeLoop == null) {
      _pendingEvents.add(event);
      return;
    }
    activeLoop.dispatchEvent(event);
  }

  /// Alias for [dispatch].
  void add(ConnectEvent event) => dispatch(event);

  /// Stops the active Mobius loop (`yrq.mo28044a()`), canceling active effects
  /// and upstream subscriptions, clearing remote volume active device, and
  /// resetting the exposed snapshot synchronously to [ConnectState.initial()]
  /// while retaining the cached internal `v6k` snapshot for future [start()].
  Future<void> stop() async {
    if (_isClosed || !_isStarted) {
      return;
    }
    _lifecycleEpoch += 1;
    _isStarted = false;
    _lastNotifiedActiveDevice = null;
    _intermediateSinkRef.unbind();

    final activeLoop = _loop;
    _loop = null;
    activeLoop?.dispose();

    final toCancel = List<StreamSubscription<Object?>>.of(_subscriptions);
    _subscriptions.clear();
    final cancelFuture = Future.wait<void>(<Future<void>>[
      _effectHandler.cancelActiveEffects(),
      for (final sub in toCancel) sub.cancel(),
    ]);
    _inFlightCancels.add(cancelFuture);

    _exposedState = ConnectState.initial();
    _remoteVolumeController.updateActiveDevice(null);
    if (!_isClosed && !_stateController.isClosed) {
      _stateController.add(_exposedState);
      notifyListeners();
    }

    try {
      await cancelFuture;
    } finally {
      _inFlightCancels.remove(cancelFuture);
    }
  }

  @override
  Future<void> close() {
    final existing = _closeFuture;
    if (existing != null) {
      return existing;
    }
    final future = _performClose();
    _closeFuture = future;
    return future;
  }

  Future<void> _performClose() async {
    if (_isClosed) {
      return;
    }
    _lifecycleEpoch += 1;
    _isClosed = true;
    _isStarted = false;
    _lastNotifiedActiveDevice = null;
    _pendingEvents.clear();
    _intermediateSinkRef.unbind();

    final activeLoop = _loop;
    _loop = null;
    activeLoop?.dispose();

    final toCancel = List<StreamSubscription<Object?>>.of(_subscriptions);
    _subscriptions.clear();
    final pendingCancels = List<Future<void>>.of(_inFlightCancels);
    final ownCancelFuture = Future.wait<void>(<Future<void>>[
      _effectHandler.cancelActiveEffects(),
      for (final sub in toCancel) sub.cancel(),
    ]);

    _exposedState = ConnectState.initial();
    if (!_ownsRemoteVolumeController) {
      _remoteVolumeController.updateActiveDevice(null);
    }

    await Future.wait<void>(<Future<void>>[
      ...pendingCancels,
      ownCancelFuture,
    ]);

    if (_ownsRemoteVolumeController) {
      await _remoteVolumeController.dispose();
    }
    await _stateController.close();
  }

  @override
  void dispose() {
    unawaited(close());
    super.dispose();
  }

  void _registerSubscriptionForEpoch(
    int epoch,
    StreamSubscription<Object?> subscription,
  ) {
    if (_isClosed || !_isStarted || epoch != _lifecycleEpoch) {
      _cancelOrphanSubscription(subscription);
      return;
    }
    _subscriptions.add(subscription);
  }

  Future<void> _cancelOrphanSubscription(
    StreamSubscription<Object?> subscription,
  ) async {
    final cancelFuture = subscription.cancel();
    _inFlightCancels.add(cancelFuture);
    try {
      await cancelFuture;
    } finally {
      _inFlightCancels.remove(cancelFuture);
    }
  }

  void _dispatchInEpoch(int epoch, ConnectEvent event) {
    if (_isClosed || !_isStarted || epoch != _lifecycleEpoch) {
      return;
    }
    final activeLoop = _loop;
    if (activeLoop == null) {
      return;
    }
    activeLoop.dispatchEvent(event);
  }

  void _onLoopStateForEpoch(int epoch, ConnectState newState) {
    if (_isClosed || !_isStarted || epoch != _lifecycleEpoch) {
      return;
    }
    _cachedInternalState = newState.internal;
    final changed = newState != _exposedState;
    _exposedState = newState;

    if (newState.activeDevice != _lastNotifiedActiveDevice) {
      _lastNotifiedActiveDevice = newState.activeDevice;
      _remoteVolumeController.updateActiveDevice(newState.activeDevice);
    }

    if (changed) {
      if (!_stateController.isClosed) {
        _stateController.add(newState);
      }
      notifyListeners();
    }
  }
}
