// 1:1 replica of p199p/zsh1.java (lines 40-104), p199p/xsh1.java (lines 42-115),
// p199p/jel1.java (lines 205-232, 433-473, 2910-2946), p199p/srh1.java (line 42),
// p199p/qrh1.java (line 39), p199p/qp50.java (line 46), p199p/rrh1.java (lines 37-39),
// p199p/fk1.java (lines 54-56), p199p/lav0.java (line 31), p199p/b8s0.java (line 84),
// p199p/nsk1.java (lines 1234-1275), p199p/odk.java (lines 35-69),
// p199p/gel1.java (line 1240), p199p/a0f1.java (lines 409-422),
// p199p/lw51.java (lines 295-333), p199p/fth1.java, and p199p/qdk.java (lines 380-436).

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:musify_mu/features/connect/data/esperanto/connect_volume_service_client.dart';
import 'package:musify_mu/features/connect/data/mappers/volume_mapper.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart'
    as common_pb;
import 'package:musify_mu/features/connect/domain/interfaces/connect_native_gateway.dart';
import 'package:musify_mu/features/connect/domain/interfaces/system_volume_port.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/connect_group_device.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';

/// Maximum UI volume steps when quantizing hardware steps (`p199p/jel1.java:447-473`,
/// `p199p/odk.java:35-69`).
const int kMaxQuantizedUiSteps = 24;

/// Equality tolerance (`0.001`) for filtering redundant volume updates
/// (`p199p/nsk1.java:1234-1239`).
const double kVolumeTolerance = 0.001;

/// Leading + trailing throttle window (`200ms`) for outbound Esperanto volume
/// commands (`p199p/qrh1.java:39`, `p199p/qp50.java:46`, `p199p/rrh1.java:37-39`).
const Duration kVolumeCommandThrottleDuration = Duration(milliseconds: 200);

/// Resettable echo-suppression window (`800ms`) preventing stale remote volume
/// emissions from overwriting optimistic local drags (`p199p/fk1.java:54-56`,
/// `p199p/lav0.java:31`, `p199p/b8s0.java:84`).
const Duration kVolumeEchoSuppressionDuration = Duration(milliseconds: 800);

/// Debounce window (`200ms`) for local hardware volume events
/// (`p199p/gel1.java:1240`).
const Duration kLocalVolumeDebounceDuration = Duration(milliseconds: 200);

/// Explicitly bounds a finite [value] into `[0.0, 1.0]` using comparisons,
/// matching `p199p/swi1.java:2136-2147`.
double boundNormalizedVolume(double value) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, 'value', 'Volume must be finite');
  }
  if (value < 0.0) {
    return 0.0;
  }
  if (value > 1.0) {
    return 1.0;
  }
  return value;
}

/// Returns `true` when [next] differs from [previous] by more than
/// [kVolumeTolerance] (`0.001`), matching `p199p/nsk1.java:1234-1239`
/// (`m66602t`).
bool hasMeaningfulVolumeChange(double? previous, double next) {
  if (!next.isFinite) {
    throw ArgumentError.value(next, 'next', 'Volume must be finite');
  }
  if (previous == null) {
    return true;
  }
  return (previous - next).abs() > kVolumeTolerance;
}

/// Computes the next stepped normalized volume (`0.0..1.0`) for [direction]
/// (`+1` up, `-1` down) using Spotify's `24`-step UI cap and device hardware
/// step quantization (`p199p/jel1.java:447-473, 2910-2946`, `p199p/odk.java:35-69`).
double computeSteppedVolume({
  required double currentVolume,
  required int volumeSteps,
  required int direction,
  bool quantize = true,
}) {
  if (direction == 0) {
    throw ArgumentError.value(
      direction,
      'direction',
      'Direction must be non-zero (+1 or -1)',
    );
  }
  final boundedCurrent = boundNormalizedVolume(currentVolume);
  if (volumeSteps <= 0) {
    return boundedCurrent;
  }
  if (!quantize) {
    final deviceStep = 1.0 / volumeSteps;
    final candidate =
        direction > 0 ? boundedCurrent + deviceStep : boundedCurrent - deviceStep;
    return boundNormalizedVolume(candidate);
  }
  final uiSteps =
      volumeSteps >= kMaxQuantizedUiSteps ? kMaxQuantizedUiSteps : volumeSteps;
  final uiDelta = 1.0 / uiSteps;
  final double rawTarget;
  if (direction > 0) {
    final sum = boundedCurrent + uiDelta;
    rawTarget = sum > 1.0 ? 1.0 : sum;
  } else {
    final diff = boundedCurrent - uiDelta;
    rawTarget = diff < 0.0 ? 0.0 : diff;
  }
  final hardwareStepIndex = (rawTarget * volumeSteps).round();
  final quantized = hardwareStepIndex / volumeSteps;
  return boundNormalizedVolume(quantized);
}

final class _PendingThrottledCommand {
  final Future<ConnectVolumeStatus> Function() action;
  final List<Completer<ConnectVolumeStatus>> completers;

  _PendingThrottledCommand({
    required this.action,
    required this.completers,
  });
}

final class _ThrottleSlot {
  bool cooldownActive = false;
  Timer? cooldownTimer;
  _PendingThrottledCommand? pending;
  Future<void> serialChain = Future<void>.value();
}

/// Stateful Connect remote volume controller replicating Spotify's Mobius volume
/// loop (`zsh1`, `jel1`, `qrh1`, `qp50`, `rrh1`, `fk1`, `gel1`) above
/// [ConnectVolumeServiceClient], paired with bidirectional Android
/// [SystemVolumePort] and [ConnectNativeGateway] sync.
final class RemoteVolumeController {
  static const String _activeTargetKey = '';
  static const int _defaultLocalVolumeSteps = 15;

  final ConnectVolumeServiceClient _volumeClient;
  final Stream<ConnectDevice?>? _activeDeviceStream;
  final SystemVolumePort? _systemVolumePort;
  final ConnectNativeGateway? _nativeGateway;
  final VolumeMapper _volumeMapper;
  final bool _quantizeSteps;
  final Duration _throttleWindow;
  final Duration _suppressionWindow;
  final Duration _localDebounceWindow;

  final StreamController<ConnectVolumeState> _stateController =
      StreamController<ConnectVolumeState>.broadcast();
  final Map<String, _ThrottleSlot> _throttleSlots = <String, _ThrottleSlot>{};
  final Map<String, Timer> _groupSuppressionTimers = <String, Timer>{};

  ConnectVolumeState _state;
  StreamSubscription<ConnectVolumeState>? _volumeSubscription;
  StreamSubscription<LocalVolumeEvent>? _localVolumeSubscription;
  StreamSubscription<ConnectDevice?>? _activeDeviceSubscription;
  StreamSubscription<SystemVolumeEvent>? _systemVolumeSubscription;
  StreamSubscription<Uint8List>? _gatewayLocalVolumeSubscription;
  Timer? _activeSuppressionTimer;
  Timer? _localDebounceTimer;

  int _lifecycleEpoch = 0;
  bool _isStarted = false;
  bool _isDisposed = false;

  bool _remoteHardwareVolumeEnabled = false;
  String? _remoteHardwareDeviceId;
  bool? _remoteHardwareSupportsVolume;
  int? _remoteHardwareVolumeSteps;
  int? _lastRemoteHardwareWireVolume;
  int? _lastObservedSystemWireVolume;
  int _lastKnownLocalVolumeSteps = _defaultLocalVolumeSteps;

  RemoteVolumeController({
    required ConnectVolumeServiceClient volumeClient,
    Stream<ConnectDevice?>? activeDeviceStream,
    SystemVolumePort? systemVolumePort,
    ConnectNativeGateway? nativeGateway,
    VolumeMapper volumeMapper = const VolumeMapper(),
    ConnectVolumeState? initialState,
    bool quantizeSteps = true,
    Duration throttleWindow = kVolumeCommandThrottleDuration,
    Duration suppressionWindow = kVolumeEchoSuppressionDuration,
    Duration localDebounceWindow = kLocalVolumeDebounceDuration,
    bool autoStart = true,
  })  : _volumeClient = volumeClient,
        _activeDeviceStream = activeDeviceStream,
        _systemVolumePort = systemVolumePort,
        _nativeGateway = nativeGateway,
        _volumeMapper = volumeMapper,
        _quantizeSteps = quantizeSteps,
        _throttleWindow = throttleWindow,
        _suppressionWindow = suppressionWindow,
        _localDebounceWindow = localDebounceWindow,
        _state = switch (initialState) {
          final value? => value,
          null => ConnectVolumeState(),
        } {
    if (autoStart) {
      start();
    }
  }

  /// Replay(1) broadcast stream of [ConnectVolumeState] updates (`p199p/zsh1.java:40`).
  Stream<ConnectVolumeState> get stream => Stream<ConnectVolumeState>.multi(
        (controller) {
          if (_isDisposed || _stateController.isClosed) {
            controller.close();
            return;
          }
          controller.add(_state);
          final subscription = _stateController.stream.listen(
            controller.add,
            onError: controller.addError,
            onDone: controller.close,
          );
          controller.onCancel = subscription.cancel;
        },
        isBroadcast: true,
      );

  /// Synchronous snapshot of the latest [ConnectVolumeState].
  ConnectVolumeState get state => _state;

  /// Effective active output volume selected by [ConnectVolumeState.outputMode].
  double? get effectiveVolume => _state.effectiveVolume;

  /// Whether the active device supports remote volume control.
  bool get isRemoteVolumeControllable => _state.isRemoteVolumeControllable;

  /// Whether stream subscriptions and hardware volume sync are currently active.
  bool get isStarted => _isStarted;

  /// Whether this controller has been permanently disposed.
  bool get isDisposed => _isDisposed;

  /// Idempotently starts Esperanto volume streams and bidirectional OS hardware
  /// volume synchronization.
  void start() {
    _ensureNotDisposed();
    if (_isStarted) {
      return;
    }

    _isStarted = true;
    _lifecycleEpoch += 1;
    final startEpoch = _lifecycleEpoch;

    _volumeSubscription = _volumeClient.volume().listen(
          _onRemoteVolumeEvent,
          onError: _onStreamError,
        );
    _localVolumeSubscription = _volumeClient.localVolume().listen(
          _onLocalVolumeEvent,
          onError: _onStreamError,
        );
    if (_activeDeviceStream case final activeStream?) {
      _activeDeviceSubscription = activeStream.listen(
        updateActiveDevice,
        onError: _onStreamError,
      );
    }

    if (_systemVolumePort case final sysPort?) {
      _systemVolumeSubscription = sysPort.watchEvents().listen(
            (event) => _onSystemVolumeEvent(startEpoch, event),
            onError: _onSystemVolumeStreamError,
          );
      unawaited(_fetchInitialLocalVolume(startEpoch, sysPort));
    }

    if (_nativeGateway case final gateway?) {
      _gatewayLocalVolumeSubscription = gateway.localVolumeStream.listen(
        (bytes) => _onGatewayLocalVolumeBytes(startEpoch, bytes),
        onError: _onGatewayLocalVolumeError,
      );
    }

    _syncHardwareVolumeRouting();
  }

  /// Idempotently stops active subscriptions, cancels all pending throttle and
  /// echo-suppression timers, restores local Android hardware volume routing,
  /// and resets active volume state cleanly.
  Future<void> stop() async {
    if (_isDisposed || !_isStarted) {
      return;
    }

    _isStarted = false;
    _lifecycleEpoch += 1;
    _cancelAllTimersAndThrottles();

    final cancelFutures = <Future<void>>[
      _restoreLocalHardwareVolumeRoutingOnStop(),
      if (_volumeSubscription case final sub?) sub.cancel(),
      if (_localVolumeSubscription case final sub?) sub.cancel(),
      if (_activeDeviceSubscription case final sub?) sub.cancel(),
      if (_systemVolumeSubscription case final sub?) sub.cancel(),
      if (_gatewayLocalVolumeSubscription case final sub?) sub.cancel(),
    ];
    _volumeSubscription = null;
    _localVolumeSubscription = null;
    _activeDeviceSubscription = null;
    _systemVolumeSubscription = null;
    _gatewayLocalVolumeSubscription = null;

    _remoteHardwareVolumeEnabled = false;
    _remoteHardwareDeviceId = null;
    _remoteHardwareSupportsVolume = null;
    _remoteHardwareVolumeSteps = null;
    _lastRemoteHardwareWireVolume = null;
    _lastObservedSystemWireVolume = null;

    _emitState(ConnectVolumeState());

    await Future.wait<void>(cancelFutures);
  }

  /// Updates the active [ConnectDevice] metadata used for output-mode selection,
  /// hardware step quantization, and Android `VolumeProviderCompat` routing.
  void updateActiveDevice(ConnectDevice? device) {
    if (_isDisposed) {
      return;
    }
    final VolumeOutputMode nextOutputMode;
    final String? nextDeviceId;
    final bool clearActiveDevice;
    final bool clearActiveId;

    if (device != null) {
      nextOutputMode =
          device.isLocal ? VolumeOutputMode.local : VolumeOutputMode.remote;
      nextDeviceId = device.connectStateIdentifier.isNotEmpty
          ? device.connectStateIdentifier
          : null;
      clearActiveDevice = false;
      clearActiveId = nextDeviceId == null;
    } else {
      nextOutputMode = _state.activeDevice != null
          ? VolumeOutputMode.local
          : _state.outputMode;
      nextDeviceId = null;
      clearActiveDevice = true;
      clearActiveId = true;
    }

    final activeIdChanged =
        nextDeviceId != _state.activeDeviceConnectStateIdentifier;
    var nextIsChangingVolume = _state.isChangingVolume;
    Set<String> nextPendingGroupDeviceIds = _state.pendingGroupDeviceIds;
    if (activeIdChanged || clearActiveDevice) {
      _cancelActiveAndGroupTimersAndThrottles();
      nextIsChangingVolume = false;
      nextPendingGroupDeviceIds = const <String>{};
    }

    final nextGroupVolumes =
        Map<String, GroupDeviceVolume>.of(_state.groupDeviceVolumes);
    final groupData = device?.groupData;
    if (groupData != null) {
      for (final member in groupData.devices) {
        final memberId = member.identifiers.groupDeviceIdentifier;
        final existing = nextGroupVolumes[memberId];
        final memberVol = member.volume;
        if (existing != null &&
            existing.volumeSteps == null &&
            memberVol != null &&
            memberVol.volumeSteps != null) {
          nextGroupVolumes[memberId] =
              existing.copyWith(volumeSteps: memberVol.volumeSteps);
        } else if (existing == null && memberVol != null) {
          nextGroupVolumes[memberId] = memberVol;
        }
      }
    }

    _emitState(
      _state.copyWith(
        activeDevice: device,
        clearActiveDevice: clearActiveDevice,
        outputMode: nextOutputMode,
        isChangingVolume: nextIsChangingVolume,
        activeDeviceConnectStateIdentifier: nextDeviceId,
        clearActiveDeviceConnectStateIdentifier: clearActiveId,
        groupDeviceVolumes: nextGroupVolumes,
        pendingGroupDeviceIds: nextPendingGroupDeviceIds,
      ),
    );
    _syncHardwareVolumeRouting();
  }

  /// Sets the active remote device volume in `[0.0, 1.0]`, applying `200ms`
  /// leading+trailing throttling and `800ms` echo suppression.
  Future<ConnectVolumeStatus> setVolume(
    double volume, {
    common_pb.LoggingParams? loggingParams,
  }) {
    _ensureNotDisposed();
    final bounded = boundNormalizedVolume(volume);
    final activeDevice = _state.activeDevice;
    if (activeDevice != null &&
        (activeDevice.isLocal || !activeDevice.supportsVolume)) {
      return Future<ConnectVolumeStatus>.value(ConnectVolumeStatus.ok);
    }

    _startActiveSuppression();
    _emitState(
      _state.copyWith(
        remoteVolume: bounded,
        outputMode: VolumeOutputMode.remote,
        isChangingVolume: true,
        status: ConnectVolumeStatus.ok,
      ),
    );
    _syncHardwareVolumeRouting();

    return _submitThrottled(
      targetKey: _activeTargetKey,
      action: () => _volumeClient.volumeSet(
        volume: bounded,
        loggingParams: loggingParams,
      ),
    );
  }

  /// Steps the active remote device volume up by one quantized UI step.
  Future<ConnectVolumeStatus> volumeUp({
    common_pb.LoggingParams? loggingParams,
  }) {
    return _stepActiveVolume(direction: 1, loggingParams: loggingParams);
  }

  /// Steps the active remote device volume down by one quantized UI step.
  Future<ConnectVolumeStatus> volumeDown({
    common_pb.LoggingParams? loggingParams,
  }) {
    return _stepActiveVolume(direction: -1, loggingParams: loggingParams);
  }

  /// Sets a speaker group member's normalized volume in `[0.0, 1.0]`.
  Future<ConnectVolumeStatus> setGroupVolume({
    required String groupDeviceIdentifier,
    required double volume,
    common_pb.LoggingParams? loggingParams,
  }) {
    _ensureNotDisposed();
    _validateGroupDeviceId(groupDeviceIdentifier);
    final bounded = boundNormalizedVolume(volume);

    final nextGroupVolumes =
        Map<String, GroupDeviceVolume>.of(_state.groupDeviceVolumes);
    final existingSteps = _resolveGroupDeviceSteps(groupDeviceIdentifier);
    nextGroupVolumes[groupDeviceIdentifier] = GroupDeviceVolume(
      volume: bounded,
      volumeSteps: existingSteps,
    );

    final nextPending = Set<String>.of(_state.pendingGroupDeviceIds)
      ..add(groupDeviceIdentifier);
    _startGroupSuppression(groupDeviceIdentifier);

    _emitState(
      _state.copyWith(
        groupDeviceVolumes: nextGroupVolumes,
        pendingGroupDeviceIds: nextPending,
        status: ConnectVolumeStatus.ok,
      ),
    );

    return _submitThrottled(
      targetKey: groupDeviceIdentifier,
      action: () => _volumeClient.volumeSet(
        volume: bounded,
        loggingParams: loggingParams,
        groupDeviceIdentifier: groupDeviceIdentifier,
      ),
    );
  }

  /// Steps a speaker group member's volume up (`p199p/lw51.java:295-315`,
  /// `p199p/rrh1.java:37-39`).
  Future<ConnectVolumeStatus> groupVolumeUp({
    required String groupDeviceIdentifier,
    common_pb.LoggingParams? loggingParams,
  }) {
    return _stepGroupVolume(
      groupDeviceIdentifier: groupDeviceIdentifier,
      direction: 1,
      loggingParams: loggingParams,
    );
  }

  /// Steps a speaker group member's volume down (`p199p/lw51.java:295-333`,
  /// `p199p/rrh1.java:37-39`).
  Future<ConnectVolumeStatus> groupVolumeDown({
    required String groupDeviceIdentifier,
    common_pb.LoggingParams? loggingParams,
  }) {
    return _stepGroupVolume(
      groupDeviceIdentifier: groupDeviceIdentifier,
      direction: -1,
      loggingParams: loggingParams,
    );
  }

  /// Cancels all stream subscriptions and active timers, restores local
  /// hardware volume routing if active, and closes [stream].
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _isStarted = false;
    _lifecycleEpoch += 1;

    _cancelAllTimersAndThrottles();

    final cancelFutures = <Future<void>>[
      _restoreLocalHardwareVolumeRoutingOnStop(),
      if (_volumeSubscription case final sub?) sub.cancel(),
      if (_localVolumeSubscription case final sub?) sub.cancel(),
      if (_activeDeviceSubscription case final sub?) sub.cancel(),
      if (_systemVolumeSubscription case final sub?) sub.cancel(),
      if (_gatewayLocalVolumeSubscription case final sub?) sub.cancel(),
    ];
    _volumeSubscription = null;
    _localVolumeSubscription = null;
    _activeDeviceSubscription = null;
    _systemVolumeSubscription = null;
    _gatewayLocalVolumeSubscription = null;

    _remoteHardwareVolumeEnabled = false;
    _remoteHardwareDeviceId = null;
    _remoteHardwareSupportsVolume = null;
    _remoteHardwareVolumeSteps = null;
    _lastRemoteHardwareWireVolume = null;
    _lastObservedSystemWireVolume = null;

    await Future.wait<void>(cancelFutures);
    await _stateController.close();
  }

  Future<ConnectVolumeStatus> _stepActiveVolume({
    required int direction,
    common_pb.LoggingParams? loggingParams,
  }) {
    _ensureNotDisposed();
    final activeDevice = _state.activeDevice;
    if (activeDevice != null &&
        (activeDevice.isLocal || !activeDevice.supportsVolume)) {
      return Future<ConnectVolumeStatus>.value(ConnectVolumeStatus.ok);
    }

    if (activeDevice != null && activeDevice.volumeSteps > 0) {
      final baseline = switch (_state.remoteVolume) {
        final remote? => remote,
        null => activeDevice.normalizedVolume,
      };
      final target = computeSteppedVolume(
        currentVolume: baseline,
        volumeSteps: activeDevice.volumeSteps,
        direction: direction,
        quantize: _quantizeSteps,
      );
      _startActiveSuppression();
      _emitState(
        _state.copyWith(
          remoteVolume: target,
          outputMode: VolumeOutputMode.remote,
          isChangingVolume: true,
          status: ConnectVolumeStatus.ok,
        ),
      );
      _syncHardwareVolumeRouting();
      return _submitThrottled(
        targetKey: _activeTargetKey,
        action: () => _volumeClient.volumeSet(
          volume: target,
          loggingParams: loggingParams,
        ),
      );
    }

    _startActiveSuppression();
    _emitState(
      _state.copyWith(
        outputMode: VolumeOutputMode.remote,
        isChangingVolume: true,
        status: ConnectVolumeStatus.ok,
      ),
    );
    return _submitThrottled(
      targetKey: _activeTargetKey,
      action: direction > 0
          ? () => _volumeClient.volumeUp(loggingParams: loggingParams)
          : () => _volumeClient.volumeDown(loggingParams: loggingParams),
    );
  }

  Future<ConnectVolumeStatus> _stepGroupVolume({
    required String groupDeviceIdentifier,
    required int direction,
    common_pb.LoggingParams? loggingParams,
  }) {
    _ensureNotDisposed();
    _validateGroupDeviceId(groupDeviceIdentifier);

    final nextGroupVolumes =
        Map<String, GroupDeviceVolume>.of(_state.groupDeviceVolumes);
    final existing = nextGroupVolumes[groupDeviceIdentifier];
    final steps = _resolveGroupDeviceSteps(groupDeviceIdentifier);
    if (existing != null && steps != null && steps > 0) {
      final stepped = computeSteppedVolume(
        currentVolume: existing.volume,
        volumeSteps: steps,
        direction: direction,
        quantize: _quantizeSteps,
      );
      nextGroupVolumes[groupDeviceIdentifier] = GroupDeviceVolume(
        volume: stepped,
        volumeSteps: steps,
      );
    }

    final nextPending = Set<String>.of(_state.pendingGroupDeviceIds)
      ..add(groupDeviceIdentifier);
    _startGroupSuppression(groupDeviceIdentifier);

    _emitState(
      _state.copyWith(
        groupDeviceVolumes: nextGroupVolumes,
        pendingGroupDeviceIds: nextPending,
        status: ConnectVolumeStatus.ok,
      ),
    );

    return _submitThrottled(
      targetKey: groupDeviceIdentifier,
      action: direction > 0
          ? () => _volumeClient.volumeUp(
                loggingParams: loggingParams,
                groupDeviceIdentifier: groupDeviceIdentifier,
              )
          : () => _volumeClient.volumeDown(
                loggingParams: loggingParams,
                groupDeviceIdentifier: groupDeviceIdentifier,
              ),
    );
  }

  void _onRemoteVolumeEvent(ConnectVolumeState incoming) {
    if (_isDisposed || !_isStarted) {
      return;
    }

    final activeDeviceChanged = incoming.activeDeviceConnectStateIdentifier !=
        _state.activeDeviceConnectStateIdentifier;

    var nextIsChangingVolume = _state.isChangingVolume;
    Set<String> nextPendingGroupDeviceIds = _state.pendingGroupDeviceIds;
    double? nextRemoteVolume;
    bool clearRemoteVolume = false;

    if (activeDeviceChanged) {
      _cancelActiveAndGroupTimersAndThrottles();
      nextIsChangingVolume = false;
      nextPendingGroupDeviceIds = const <String>{};
      nextRemoteVolume = incoming.remoteVolume;
      clearRemoteVolume = incoming.remoteVolume == null;
    } else if (_state.isChangingVolume) {
      nextRemoteVolume = _state.remoteVolume;
      clearRemoteVolume = _state.remoteVolume == null;
    } else {
      final incomingRemote = incoming.remoteVolume;
      if (incomingRemote == null) {
        nextRemoteVolume = null;
        clearRemoteVolume = true;
      } else {
        final boundedIncoming = boundNormalizedVolume(incomingRemote);
        if (hasMeaningfulVolumeChange(_state.remoteVolume, boundedIncoming)) {
          nextRemoteVolume = boundedIncoming;
        } else {
          nextRemoteVolume = _state.remoteVolume;
        }
      }
    }

    final mergedGroupVolumes = <String, GroupDeviceVolume>{};
    for (final entry in incoming.groupDeviceVolumes.entries) {
      final id = entry.key;
      final incomingGroupVol = entry.value;
      if (nextPendingGroupDeviceIds.contains(id)) {
        final optimistic = _state.groupDeviceVolumes[id];
        if (optimistic != null) {
          mergedGroupVolumes[id] = optimistic;
          continue;
        }
      }
      final existingGroupVol = _state.groupDeviceVolumes[id];
      final resolvedSteps = switch (incomingGroupVol.volumeSteps) {
        final steps? => steps,
        null => _resolveGroupDeviceSteps(id),
      };
      final boundedIncomingGroup =
          boundNormalizedVolume(incomingGroupVol.volume);
      if (existingGroupVol != null &&
          existingGroupVol.volumeSteps == resolvedSteps &&
          !hasMeaningfulVolumeChange(
            existingGroupVol.volume,
            boundedIncomingGroup,
          )) {
        mergedGroupVolumes[id] = existingGroupVol;
      } else {
        mergedGroupVolumes[id] = GroupDeviceVolume(
          volume: boundedIncomingGroup,
          volumeSteps: resolvedSteps,
        );
      }
    }
    for (final pendingId in nextPendingGroupDeviceIds) {
      if (!mergedGroupVolumes.containsKey(pendingId)) {
        final optimistic = _state.groupDeviceVolumes[pendingId];
        if (optimistic != null) {
          mergedGroupVolumes[pendingId] = optimistic;
        }
      }
    }

    final nextActiveDevice = switch (incoming.activeDevice) {
      final device? => device,
      null => _state.activeDevice,
    };
    final nextLocalVolume = switch (incoming.localVolume) {
      final local? => boundNormalizedVolume(local),
      null => _state.localVolume,
    };
    final nextOutputMode = nextActiveDevice != null
        ? (nextActiveDevice.isLocal
            ? VolumeOutputMode.local
            : VolumeOutputMode.remote)
        : incoming.outputMode;
    final nextActiveId = incoming.activeDeviceConnectStateIdentifier;

    _emitState(
      _state.copyWith(
        remoteVolume: nextRemoteVolume,
        clearRemoteVolume: clearRemoteVolume,
        localVolume: nextLocalVolume,
        activeDevice: nextActiveDevice,
        outputMode: nextOutputMode,
        isChangingVolume: nextIsChangingVolume,
        status: incoming.status,
        activeDeviceConnectStateIdentifier: nextActiveId,
        clearActiveDeviceConnectStateIdentifier: nextActiveId == null,
        groupDeviceVolumes: mergedGroupVolumes,
        pendingGroupDeviceIds: nextPendingGroupDeviceIds,
      ),
    );
    _syncHardwareVolumeRouting();
  }

  void _onLocalVolumeEvent(LocalVolumeEvent event) {
    if (_isDisposed || !_isStarted) {
      return;
    }
    final bounded = boundNormalizedVolume(event.volume);
    _localDebounceTimer?.cancel();
    _localDebounceTimer = Timer(_localDebounceWindow, () {
      _localDebounceTimer = null;
      if (_isDisposed || !_isStarted) {
        return;
      }
      if (!hasMeaningfulVolumeChange(_state.localVolume, bounded) &&
          _state.status == ConnectVolumeStatus.ok) {
        return;
      }
      _emitState(
        _state.copyWith(
          localVolume: bounded,
          status: ConnectVolumeStatus.ok,
        ),
      );
    });
  }

  Future<void> _fetchInitialLocalVolume(
    int epoch,
    SystemVolumePort sysPort,
  ) async {
    try {
      final snapshot = await sysPort.getLocalVolume();
      if (_isDisposed || !_isStarted || epoch != _lifecycleEpoch) {
        return;
      }
      _lastObservedSystemWireVolume = snapshot.volume;
      if (snapshot.steps > 0) {
        _lastKnownLocalVolumeSteps = snapshot.steps;
      }
      final normalized = boundNormalizedVolume(snapshot.normalizedVolume);
      if (hasMeaningfulVolumeChange(_state.localVolume, normalized)) {
        _emitState(_state.copyWith(localVolume: normalized));
      }
    } on Object catch (error, stackTrace) {
      dev.log(
        'RemoteVolumeController: initial getLocalVolume failed: $error',
        name: 'CONNECT_VOLUME',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _onSystemVolumeEvent(int epoch, SystemVolumeEvent event) {
    if (_isDisposed || !_isStarted || epoch != _lifecycleEpoch) {
      return;
    }
    switch (event) {
      case LocalVolumeChanged(:final volume, :final steps):
        _lastObservedSystemWireVolume = volume;
        if (steps > 0) {
          _lastKnownLocalVolumeSteps = steps;
        }
        final active = _state.activeDevice;
        final isLocalActive = active == null || active.isLocal;
        final normalized = boundNormalizedVolume(event.normalizedVolume);
        if (hasMeaningfulVolumeChange(_state.localVolume, normalized)) {
          _emitState(_state.copyWith(localVolume: normalized));
        }
        if (isLocalActive) {
          if (_nativeGateway case final gateway?) {
            final effectiveSteps =
                steps > 0 ? steps : _lastKnownLocalVolumeSteps;
            try {
              final rc = gateway.setLocalVolume(
                volume0To65535: volume,
                volumeSteps: effectiveSteps,
                reason: ConnectLocalVolumeReason.user,
              );
              if (rc != 0) {
                dev.log(
                  'RemoteVolumeController: gateway.setLocalVolume returned $rc',
                  name: 'CONNECT_VOLUME',
                );
              }
            } on Object catch (error, stackTrace) {
              dev.log(
                'RemoteVolumeController: gateway.setLocalVolume threw: $error',
                name: 'CONNECT_VOLUME',
                error: error,
                stackTrace: stackTrace,
              );
            }
          }
        }
      case RemoteVolumeAdjust(:final direction):
        final future = direction > 0 ? volumeUp() : volumeDown();
        unawaited(
          future.then(
            (_) {},
            onError: (Object error, StackTrace stackTrace) {
              dev.log(
                'RemoteVolumeController: RemoteVolumeAdjust($direction) failed: $error',
                name: 'CONNECT_VOLUME',
                error: error,
                stackTrace: stackTrace,
              );
            },
          ),
        );
      case RemoteVolumeSet():
        final normalized = boundNormalizedVolume(event.normalizedVolume);
        unawaited(
          setVolume(normalized).then(
            (_) {},
            onError: (Object error, StackTrace stackTrace) {
              dev.log(
                'RemoteVolumeController: RemoteVolumeSet(${event.volume}) failed: $error',
                name: 'CONNECT_VOLUME',
                error: error,
                stackTrace: stackTrace,
              );
            },
          ),
        );
    }
  }

  void _onGatewayLocalVolumeBytes(int epoch, Uint8List bytes) {
    if (_isDisposed || !_isStarted || epoch != _lifecycleEpoch) {
      return;
    }
    final LocalVolumeEvent decoded;
    try {
      decoded = _volumeMapper.localVolumeFromBuffer(bytes);
    } on Object catch (error, stackTrace) {
      dev.log(
        'RemoteVolumeController: failed to decode gateway localVolumeStream: $error',
        name: 'CONNECT_VOLUME',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }

    final active = _state.activeDevice;
    final isLocalActive = active == null || active.isLocal;
    if (!isLocalActive) {
      return;
    }

    final wireVolume = _volumeMapper.normalizedToWire(
      boundNormalizedVolume(decoded.volume),
    );
    if (_systemVolumePort case final sysPort?) {
      if (wireVolume != _lastObservedSystemWireVolume) {
        _lastObservedSystemWireVolume = wireVolume;
        unawaited(
          sysPort.setLocalVolume(volume: wireVolume, showUi: false).then(
            (_) {},
            onError: (Object error, StackTrace stackTrace) {
              dev.log(
                'RemoteVolumeController: sysPort.setLocalVolume($wireVolume) failed: $error',
                name: 'CONNECT_VOLUME',
                error: error,
                stackTrace: stackTrace,
              );
            },
          ),
        );
      }
    }
  }

  void _syncHardwareVolumeRouting() {
    if (_isDisposed || !_isStarted) {
      return;
    }
    final sysPort = _systemVolumePort;
    if (sysPort == null) {
      return;
    }

    final active = _state.activeDevice;
    if (active != null && !active.isLocal) {
      final supportsVolume = active.supportsVolume;
      final volumeSteps = active.volumeSteps;
      final effectiveNormalized = switch (_state.remoteVolume) {
        final remote? => boundNormalizedVolume(remote),
        null => boundNormalizedVolume(active.normalizedVolume),
      };
      final wireVolume = _volumeMapper.normalizedToWire(effectiveNormalized);

      final needsReconfigure = !_remoteHardwareVolumeEnabled ||
          _remoteHardwareDeviceId != active.connectStateIdentifier ||
          _remoteHardwareSupportsVolume != supportsVolume ||
          _remoteHardwareVolumeSteps != volumeSteps;

      if (needsReconfigure) {
        _remoteHardwareVolumeEnabled = true;
        _remoteHardwareDeviceId = active.connectStateIdentifier;
        _remoteHardwareSupportsVolume = supportsVolume;
        _remoteHardwareVolumeSteps = volumeSteps;
        _lastRemoteHardwareWireVolume = wireVolume;
        unawaited(
          sysPort
              .configureRemoteHardwareVolume(
                enabled: true,
                supportsVolume: supportsVolume,
                volumeSteps: volumeSteps,
                currentVolume: wireVolume,
              )
              .then(
                (_) {},
                onError: (Object error, StackTrace stackTrace) {
                  dev.log(
                    'RemoteVolumeController: configureRemoteHardwareVolume(enabled: true) failed: $error',
                    name: 'CONNECT_VOLUME',
                    error: error,
                    stackTrace: stackTrace,
                  );
                },
              ),
        );
      } else if (_lastRemoteHardwareWireVolume != wireVolume) {
        _lastRemoteHardwareWireVolume = wireVolume;
        unawaited(
          sysPort.updateRemoteHardwareVolume(currentVolume: wireVolume).then(
            (_) {},
            onError: (Object error, StackTrace stackTrace) {
              dev.log(
                'RemoteVolumeController: updateRemoteHardwareVolume($wireVolume) failed: $error',
                name: 'CONNECT_VOLUME',
                error: error,
                stackTrace: stackTrace,
              );
            },
          ),
        );
      }
      return;
    }

    if (_remoteHardwareVolumeEnabled) {
      _remoteHardwareVolumeEnabled = false;
      _remoteHardwareDeviceId = null;
      _remoteHardwareSupportsVolume = null;
      _remoteHardwareVolumeSteps = null;
      _lastRemoteHardwareWireVolume = null;
      final localWire = _resolveCurrentLocalWireVolume();
      unawaited(
        sysPort
            .configureRemoteHardwareVolume(
              enabled: false,
              supportsVolume: true,
              volumeSteps: _lastKnownLocalVolumeSteps,
              currentVolume: localWire,
            )
            .then(
              (_) {},
              onError: (Object error, StackTrace stackTrace) {
                dev.log(
                  'RemoteVolumeController: configureRemoteHardwareVolume(enabled: false) failed: $error',
                  name: 'CONNECT_VOLUME',
                  error: error,
                  stackTrace: stackTrace,
                );
              },
            ),
      );
    }
  }

  Future<void> _restoreLocalHardwareVolumeRoutingOnStop() async {
    final sysPort = _systemVolumePort;
    if (sysPort == null || !_remoteHardwareVolumeEnabled) {
      return;
    }
    try {
      await sysPort.configureRemoteHardwareVolume(
        enabled: false,
        supportsVolume: true,
        volumeSteps: _lastKnownLocalVolumeSteps,
        currentVolume: _resolveCurrentLocalWireVolume(),
      );
    } on Object catch (error, stackTrace) {
      dev.log(
        'RemoteVolumeController: restoring local hardware volume on stop failed: $error',
        name: 'CONNECT_VOLUME',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  int _resolveCurrentLocalWireVolume() {
    if (_lastObservedSystemWireVolume case final observed?) {
      return observed;
    }
    if (_state.localVolume case final local?) {
      return _volumeMapper.normalizedToWire(boundNormalizedVolume(local));
    }
    return 0;
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    dev.log(
      'RemoteVolumeController: Esperanto volume stream error: $error',
      name: 'CONNECT_VOLUME',
      error: error,
      stackTrace: stackTrace,
    );
    if (_isDisposed || !_isStarted) {
      return;
    }
    _emitState(_state.copyWith(status: ConnectVolumeStatus.backendFailure));
  }

  void _onSystemVolumeStreamError(Object error, StackTrace stackTrace) {
    dev.log(
      'RemoteVolumeController: SystemVolumePort stream error: $error',
      name: 'CONNECT_VOLUME',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _onGatewayLocalVolumeError(Object error, StackTrace stackTrace) {
    dev.log(
      'RemoteVolumeController: ConnectNativeGateway localVolumeStream error: $error',
      name: 'CONNECT_VOLUME',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _startActiveSuppression() {
    _activeSuppressionTimer?.cancel();
    _activeSuppressionTimer = Timer(_suppressionWindow, () {
      _activeSuppressionTimer = null;
      if (_isDisposed || !_isStarted) {
        return;
      }
      if (_state.isChangingVolume) {
        _emitState(_state.copyWith(isChangingVolume: false));
      }
    });
  }

  void _startGroupSuppression(String groupDeviceIdentifier) {
    _groupSuppressionTimers[groupDeviceIdentifier]?.cancel();
    _groupSuppressionTimers[groupDeviceIdentifier] = Timer(
      _suppressionWindow,
      () {
        _groupSuppressionTimers.remove(groupDeviceIdentifier);
        if (_isDisposed || !_isStarted) {
          return;
        }
        if (_state.pendingGroupDeviceIds.contains(groupDeviceIdentifier)) {
          final nextPending = Set<String>.of(_state.pendingGroupDeviceIds)
            ..remove(groupDeviceIdentifier);
          _emitState(_state.copyWith(pendingGroupDeviceIds: nextPending));
        }
      },
    );
  }

  void _cancelActiveAndGroupTimersAndThrottles() {
    _activeSuppressionTimer?.cancel();
    _activeSuppressionTimer = null;

    for (final timer in _groupSuppressionTimers.values) {
      timer.cancel();
    }
    _groupSuppressionTimers.clear();

    _cancelAndClearAllThrottleSlots();
  }

  void _cancelAllTimersAndThrottles() {
    _cancelActiveAndGroupTimersAndThrottles();
    _localDebounceTimer?.cancel();
    _localDebounceTimer = null;
  }

  void _cancelAndClearAllThrottleSlots() {
    final slots = List<_ThrottleSlot>.of(_throttleSlots.values);
    _throttleSlots.clear();
    for (final slot in slots) {
      slot.cooldownTimer?.cancel();
      slot.cooldownTimer = null;
      slot.cooldownActive = false;
      final pending = slot.pending;
      slot.pending = null;
      if (pending != null) {
        for (final completer in pending.completers) {
          if (!completer.isCompleted) {
            completer.complete(ConnectVolumeStatus.ok);
          }
        }
      }
    }
  }

  Future<ConnectVolumeStatus> _submitThrottled({
    required String targetKey,
    required Future<ConnectVolumeStatus> Function() action,
  }) {
    final slot = _throttleSlots.putIfAbsent(targetKey, _ThrottleSlot.new);
    final completer = Completer<ConnectVolumeStatus>();

    if (!slot.cooldownActive) {
      slot.cooldownActive = true;
      slot.cooldownTimer = Timer(_throttleWindow, () {
        _onThrottleCooldownElapsed(targetKey);
      });
      _enqueueSerialized(slot, action, <Completer<ConnectVolumeStatus>>[
        completer,
      ]);
    } else {
      final existingPending = slot.pending;
      if (existingPending != null) {
        existingPending.completers.add(completer);
        slot.pending = _PendingThrottledCommand(
          action: action,
          completers: existingPending.completers,
        );
      } else {
        slot.pending = _PendingThrottledCommand(
          action: action,
          completers: <Completer<ConnectVolumeStatus>>[completer],
        );
      }
    }
    return completer.future;
  }

  void _onThrottleCooldownElapsed(String targetKey) {
    if (_isDisposed) {
      return;
    }
    final slot = _throttleSlots[targetKey];
    if (slot == null) {
      return;
    }
    final pending = slot.pending;
    if (pending != null) {
      slot.pending = null;
      slot.cooldownActive = true;
      slot.cooldownTimer = Timer(_throttleWindow, () {
        _onThrottleCooldownElapsed(targetKey);
      });
      _enqueueSerialized(slot, pending.action, pending.completers);
    } else {
      slot.cooldownActive = false;
      slot.cooldownTimer = null;
    }
  }

  void _enqueueSerialized(
    _ThrottleSlot slot,
    Future<ConnectVolumeStatus> Function() action,
    List<Completer<ConnectVolumeStatus>> completers,
  ) {
    slot.serialChain = slot.serialChain.then((_) async {
      if (_isDisposed) {
        for (final completer in completers) {
          if (!completer.isCompleted) {
            completer.complete(ConnectVolumeStatus.ok);
          }
        }
        return;
      }
      ConnectVolumeStatus resultStatus;
      try {
        resultStatus = await action();
        if (!_isDisposed && resultStatus != _state.status) {
          _emitState(_state.copyWith(status: resultStatus));
        }
      } on Object catch (error, stackTrace) {
        dev.log(
          'RemoteVolumeController: volume RPC failed: $error',
          name: 'CONNECT_VOLUME',
          error: error,
          stackTrace: stackTrace,
        );
        resultStatus = ConnectVolumeStatus.backendFailure;
        if (!_isDisposed) {
          _emitState(
            _state.copyWith(status: ConnectVolumeStatus.backendFailure),
          );
        }
      }
      for (final completer in completers) {
        if (!completer.isCompleted) {
          completer.complete(resultStatus);
        }
      }
    });
  }

  int? _resolveGroupDeviceSteps(String groupDeviceIdentifier) {
    final existing = _state.groupDeviceVolumes[groupDeviceIdentifier];
    if (existing != null && existing.volumeSteps != null) {
      return existing.volumeSteps;
    }
    final groupData = _state.activeDevice?.groupData;
    if (groupData != null) {
      for (final ConnectGroupDevice member in groupData.devices) {
        if (member.identifiers.groupDeviceIdentifier == groupDeviceIdentifier) {
          return member.volume?.volumeSteps;
        }
      }
    }
    return null;
  }

  void _emitState(ConnectVolumeState nextState) {
    if (_isDisposed || nextState == _state) {
      return;
    }
    _state = nextState;
    if (!_stateController.isClosed) {
      _stateController.add(nextState);
    }
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError('RemoteVolumeController is disposed');
    }
  }

  static void _validateGroupDeviceId(String groupDeviceIdentifier) {
    if (groupDeviceIdentifier.trim().isEmpty) {
      throw ArgumentError.value(
        groupDeviceIdentifier,
        'groupDeviceIdentifier',
        'Must be non-empty',
      );
    }
  }
}
