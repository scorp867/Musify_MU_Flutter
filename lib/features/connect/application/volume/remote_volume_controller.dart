// 1:1 replica of p199p/zsh1.java (lines 40-104), p199p/xsh1.java (lines 42-115),
// p199p/jel1.java (lines 205-232, 433-473, 2910-2946), p199p/srh1.java (line 42),
// p199p/qrh1.java (line 39), p199p/qp50.java (line 46), p199p/rrh1.java (lines 37-39),
// p199p/fk1.java (lines 54-56), p199p/lav0.java (line 31), p199p/b8s0.java (line 84),
// p199p/nsk1.java (lines 1234-1275), p199p/odk.java (lines 35-69),
// p199p/gel1.java (line 1240), p199p/a0f1.java (lines 409-422),
// and p199p/lw51.java (lines 295-333).

import 'dart:async';

import 'package:musify_mu/features/connect/data/esperanto/connect_volume_service_client.dart';
import 'package:musify_mu/features/connect/data/mappers/volume_mapper.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart'
    as common_pb;
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
/// [ConnectVolumeServiceClient].
final class RemoteVolumeController {
  static const String _activeTargetKey = '';

  final ConnectVolumeServiceClient _volumeClient;
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
  Timer? _activeSuppressionTimer;
  Timer? _localDebounceTimer;
  bool _isDisposed = false;

  RemoteVolumeController({
    required ConnectVolumeServiceClient volumeClient,
    Stream<ConnectDevice?>? activeDeviceStream,
    ConnectVolumeState? initialState,
    bool quantizeSteps = true,
    Duration throttleWindow = kVolumeCommandThrottleDuration,
    Duration suppressionWindow = kVolumeEchoSuppressionDuration,
    Duration localDebounceWindow = kLocalVolumeDebounceDuration,
  })  : _volumeClient = volumeClient,
        _quantizeSteps = quantizeSteps,
        _throttleWindow = throttleWindow,
        _suppressionWindow = suppressionWindow,
        _localDebounceWindow = localDebounceWindow,
        _state = switch (initialState) {
          final value? => value,
          null => ConnectVolumeState(),
        } {
    _volumeSubscription = _volumeClient.volume().listen(
      _onRemoteVolumeEvent,
      onError: _onStreamError,
    );
    _localVolumeSubscription = _volumeClient.localVolume().listen(
      _onLocalVolumeEvent,
      onError: _onStreamError,
    );
    if (activeDeviceStream != null) {
      _activeDeviceSubscription = activeDeviceStream.listen(
        updateActiveDevice,
        onError: _onStreamError,
      );
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

  /// Updates the active [ConnectDevice] metadata used for output-mode selection
  /// and hardware step quantization.
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
      clearActiveId = false;
    }

    final activeIdChanged = nextDeviceId != null &&
        nextDeviceId != _state.activeDeviceConnectStateIdentifier;
    var nextIsChangingVolume = _state.isChangingVolume;
    if (activeIdChanged || clearActiveDevice) {
      _activeSuppressionTimer?.cancel();
      _activeSuppressionTimer = null;
      nextIsChangingVolume = false;
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
      ),
    );
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

  /// Cancels all stream subscriptions and active timers and closes [stream].
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;

    _activeSuppressionTimer?.cancel();
    _activeSuppressionTimer = null;
    _localDebounceTimer?.cancel();
    _localDebounceTimer = null;

    for (final timer in _groupSuppressionTimers.values) {
      timer.cancel();
    }
    _groupSuppressionTimers.clear();

    for (final slot in _throttleSlots.values) {
      slot.cooldownTimer?.cancel();
      slot.cooldownTimer = null;
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
    _throttleSlots.clear();

    await _volumeSubscription?.cancel();
    _volumeSubscription = null;
    await _localVolumeSubscription?.cancel();
    _localVolumeSubscription = null;
    await _activeDeviceSubscription?.cancel();
    _activeDeviceSubscription = null;

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
    if (_isDisposed) {
      return;
    }

    final activeDeviceChanged = incoming.activeDeviceConnectStateIdentifier !=
        _state.activeDeviceConnectStateIdentifier;

    var nextIsChangingVolume = _state.isChangingVolume;
    double? nextRemoteVolume;
    bool clearRemoteVolume = false;

    if (activeDeviceChanged) {
      _activeSuppressionTimer?.cancel();
      _activeSuppressionTimer = null;
      nextIsChangingVolume = false;
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
      if (_state.pendingGroupDeviceIds.contains(id)) {
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
    for (final pendingId in _state.pendingGroupDeviceIds) {
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
      ),
    );
  }

  void _onLocalVolumeEvent(LocalVolumeEvent event) {
    if (_isDisposed) {
      return;
    }
    final bounded = boundNormalizedVolume(event.volume);
    _localDebounceTimer?.cancel();
    _localDebounceTimer = Timer(_localDebounceWindow, () {
      _localDebounceTimer = null;
      if (_isDisposed) {
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

  void _onStreamError(Object error, StackTrace stackTrace) {
    if (_isDisposed) {
      return;
    }
    _emitState(_state.copyWith(status: ConnectVolumeStatus.backendFailure));
  }

  void _startActiveSuppression() {
    _activeSuppressionTimer?.cancel();
    _activeSuppressionTimer = Timer(_suppressionWindow, () {
      _activeSuppressionTimer = null;
      if (_isDisposed) {
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
        if (_isDisposed) {
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
      } on Object catch (_) {
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
