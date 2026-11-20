// 1:1 Spotify Connect authenticated scope lifecycle & real-device boot SSOT:
// - p199p/C2406w.java:88-388 (authenticated Connect scope creation & teardown)
// - p199p/asq.java:74-173 (foreground recovery & device-picker discovery poll)
// - p199p/d7g.java:740-744 (local audio route change notification)
// - #47 §1, §5 (canonical device_id, APResolve, DeviceInfo wire payload, NSD)

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:musify_mu/core/audio/native_playback_session_bridge.dart';
import 'package:musify_mu/core/config/device_identity_service.dart';
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/network/spotify/ap_resolve_service.dart';
import 'package:musify_mu/core/network/spotify/auth/auth_session_provider.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/domain/entities/auth_state.dart';
import 'package:musify_mu/features/auth/domain/entities/spotify_user.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/application/sorting/device_picker_sorting_database.dart';
import 'package:musify_mu/features/connect/application/volume/remote_volume_controller.dart';
import 'package:musify_mu/features/connect/domain/interfaces/audio_route_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/connect_native_gateway.dart';
import 'package:musify_mu/features/connect/domain/interfaces/device_environment_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/local_discovery_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/system_volume_port.dart';
import 'package:musify_mu/features/connect/domain/services/device_info_payload_builder.dart';

/// Exhaustive lifecycle state hierarchy for [ConnectSessionCoordinator].
@immutable
sealed class ConnectSessionState extends Equatable {
  const ConnectSessionState();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Connect subsystem is stopped or waiting for an authenticated user session.
@immutable
final class ConnectSessionIdle extends ConnectSessionState {
  const ConnectSessionIdle();
}

/// Connect subsystem is executing its deterministic auth-gated boot sequence.
@immutable
final class ConnectSessionStarting extends ConnectSessionState {
  final String userId;

  const ConnectSessionStarting({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Connect subsystem is running for [userId] with canonical [deviceId] and
/// active [endpoints].
@immutable
final class ConnectSessionRunning extends ConnectSessionState {
  final String userId;
  final String deviceId;
  final ApResolveEndpoints endpoints;

  const ConnectSessionRunning({
    required this.userId,
    required this.deviceId,
    required this.endpoints,
  });

  @override
  List<Object?> get props => [userId, deviceId, endpoints];
}

/// Connect boot failed with an explicit typed error (never silently ignored).
@immutable
final class ConnectSessionFailed extends ConnectSessionState {
  final String userId;
  final String message;
  final Object error;

  const ConnectSessionFailed({
    required this.userId,
    required this.message,
    required this.error,
  });

  @override
  List<Object?> get props => [userId, message, error];
}

/// Coordinator has been permanently disposed.
@immutable
final class ConnectSessionDisposed extends ConnectSessionState {
  const ConnectSessionDisposed();
}

/// Single source of truth orchestrating the Spotify Connect authenticated
/// session lifecycle across native FFI, Android platform bridges, APResolve,
/// connectivity, foreground recovery, and Device Picker discovery polling.
final class ConnectSessionCoordinator with WidgetsBindingObserver {
  static const Duration defaultPickerRefreshInterval = Duration(seconds: 10);

  final AuthSessionProvider _authSessionProvider;
  final DeviceIdentityService _deviceIdentityService;
  final ApResolveService _apResolveService;
  final DeviceEnvironmentPort _deviceEnvironmentPort;
  final AudioRoutePort _audioRoutePort;
  final SystemVolumePort _systemVolumePort;
  final LocalDiscoveryPort _localDiscoveryPort;
  final ConnectNativeGateway _nativeGateway;
  final NativePlaybackSessionBridge _playbackSessionBridge;
  final ConnectMobiusController _connectController;
  final RemoteVolumeController _remoteVolumeController;
  final DevicePickerSortingDatabase? _sortingDatabase;
  final Future<void> Function()? _clearSortingDatabase;
  final RuntimeContext? _runtimeContext;
  final DeviceInfoPayloadBuilder _deviceInfoPayloadBuilder;
  final Connectivity _connectivity;
  final WidgetsBinding? _widgetsBindingOverride;
  final bool _observeAppLifecycle;
  final bool _isAndroid;
  final Duration _pickerRefreshInterval;

  final StreamController<ConnectSessionState> _stateController =
      StreamController<ConnectSessionState>.broadcast();

  ConnectSessionState _state = const ConnectSessionIdle();
  AuthBloc? _boundAuthBloc;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<List<DiscoveredNsdService>>? _nsdSubscription;
  StreamSubscription<List<LocalAudioPeripheral>>? _audioRouteSubscription;
  StreamSubscription<String>? _diagnosticSubscription;
  WidgetsBinding? _observedBinding;

  Timer? _pickerRefreshTimer;
  int _openPickerCount = 0;

  Future<void> _opTail = Future<void>.value();
  int _sessionEpoch = 0;
  String? _activeUserId;
  bool _hasAuthenticatedSession = false;
  bool? _lastKnownOnline;
  LocalAudioPeripheral? _lastNotifiedAudioRoute;
  bool _isDisposed = false;

  ConnectSessionCoordinator({
    AuthBloc? authBloc,
    required AuthSessionProvider authSessionProvider,
    required DeviceIdentityService deviceIdentityService,
    required ApResolveService apResolveService,
    required DeviceEnvironmentPort deviceEnvironmentPort,
    required AudioRoutePort audioRoutePort,
    required SystemVolumePort systemVolumePort,
    required LocalDiscoveryPort localDiscoveryPort,
    required ConnectNativeGateway nativeGateway,
    required NativePlaybackSessionBridge playbackSessionBridge,
    required ConnectMobiusController connectController,
    required RemoteVolumeController remoteVolumeController,
    DevicePickerSortingDatabase? sortingDatabase,
    Future<void> Function()? clearSortingDatabase,
    RuntimeContext? runtimeContext,
    DeviceInfoPayloadBuilder deviceInfoPayloadBuilder =
        DeviceInfoPayloadBuilder.instance,
    Connectivity? connectivity,
    WidgetsBinding? widgetsBinding,
    bool observeAppLifecycle = true,
    bool? isAndroidOverride,
    Duration pickerRefreshInterval = defaultPickerRefreshInterval,
  })  : _authSessionProvider = authSessionProvider,
        _deviceIdentityService = deviceIdentityService,
        _apResolveService = apResolveService,
        _deviceEnvironmentPort = deviceEnvironmentPort,
        _audioRoutePort = audioRoutePort,
        _systemVolumePort = systemVolumePort,
        _localDiscoveryPort = localDiscoveryPort,
        _nativeGateway = nativeGateway,
        _playbackSessionBridge = playbackSessionBridge,
        _connectController = connectController,
        _remoteVolumeController = remoteVolumeController,
        _sortingDatabase = sortingDatabase,
        _clearSortingDatabase = clearSortingDatabase,
        _runtimeContext = runtimeContext,
        _deviceInfoPayloadBuilder = deviceInfoPayloadBuilder,
        _connectivity = switch (connectivity) {
          final provided? => provided,
          null => Connectivity(),
        },
        _widgetsBindingOverride = widgetsBinding,
        _observeAppLifecycle = observeAppLifecycle,
        _isAndroid = switch (isAndroidOverride) {
          final override? => override,
          null => Platform.isAndroid,
        },
        _pickerRefreshInterval = pickerRefreshInterval {
    if (authBloc != null) {
      bindAuthBloc(authBloc);
    }
  }

  /// Current coordinator lifecycle state.
  ConnectSessionState get state => _state;

  /// Replay(1) broadcast stream of [ConnectSessionState] transitions.
  Stream<ConnectSessionState> get stateStream =>
      Stream<ConnectSessionState>.multi(
        (controller) {
          if (_isDisposed || _stateController.isClosed) {
            controller.close();
            return;
          }
          controller.add(_state);
          final sub = _stateController.stream.listen(
            controller.add,
            onError: controller.addError,
            onDone: controller.close,
          );
          controller.onCancel = sub.cancel;
        },
        isBroadcast: true,
      );

  /// Whether Connect is currently active and running for an authenticated user.
  bool get isRunning => _state is ConnectSessionRunning;

  /// Whether at least one Device Picker surface is currently open.
  bool get isDevicePickerOpen => _openPickerCount > 0;

  /// Whether this coordinator has been permanently disposed.
  bool get isDisposed => _isDisposed;

  /// Exposed for deterministic test synchronization against the FIFO queue.
  @visibleForTesting
  Future<void> get pendingOperations => _opTail;

  /// Binds this coordinator to the application's [AuthBloc] and attaches the
  /// [WidgetsBindingObserver] lifecycle hook.
  void bindAuthBloc(AuthBloc authBloc) {
    if (_isDisposed) {
      throw StateError('Cannot bind AuthBloc to a disposed ConnectSessionCoordinator');
    }
    if (identical(_boundAuthBloc, authBloc)) {
      return;
    }

    _detachAuthSubscriptionOnly();
    _boundAuthBloc = authBloc;
    _attachLifecycleObserverIfNeeded();

    _authSubscription = authBloc.stream.listen(
      _onAuthStateChanged,
      onError: (Object error, StackTrace stackTrace) {
        dev.log(
          'ConnectSessionCoordinator: AuthBloc stream error: $error',
          name: 'CONNECT',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    _onAuthStateChanged(authBloc.state);
  }

  /// Detaches the bound [AuthBloc] subscription and [WidgetsBindingObserver]
  /// without permanently disposing this coordinator (used when the root widget
  /// unmounts while GetIt owns the singleton lifecycle).
  void detachAuthBloc() {
    _detachAuthSubscriptionOnly();
    _detachLifecycleObserver();
    _cancelPickerRefreshTimer();
    _openPickerCount = 0;
  }

  /// Notifies the coordinator that the Connect Device Picker opened
  /// (`p199p/asq.java:151-172`).
  ///
  /// Triggers immediate discovery, cluster refresh, and sleeping-device wake,
  /// and runs a clean 10-second discovery refresh timer strictly while the
  /// picker remains open.
  void onDevicePickerOpened() {
    if (_isDisposed) {
      return;
    }
    _openPickerCount += 1;
    if (_openPickerCount == 1) {
      dev.log(
        'ConnectSessionCoordinator: DevicePicker opened -> triggering discovery/cluster/wake',
        name: 'CONNECT',
      );
      _triggerPickerDiscoveryPass();
      _schedulePickerRefreshTick();
    }
  }

  /// Notifies the coordinator that the Connect Device Picker closed
  /// (`p199p/asq.java:151-172`).
  ///
  /// Deterministically cancels the 10-second picker refresh timer once all
  /// picker surfaces are closed.
  void onDevicePickerClosed() {
    if (_openPickerCount <= 0) {
      return;
    }
    _openPickerCount -= 1;
    if (_openPickerCount == 0) {
      dev.log(
        'ConnectSessionCoordinator: DevicePicker closed -> cancelling picker refresh timer',
        name: 'CONNECT',
      );
      _cancelPickerRefreshTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) {
      return;
    }
    switch (state) {
      case AppLifecycleState.resumed:
        if (_state is ConnectSessionRunning) {
          final epoch = _sessionEpoch;
          dev.log(
            'ConnectSessionCoordinator: App resumed -> syncing auth & reconnecting Connect',
            name: 'CONNECT',
          );
          unawaited(
            _enqueueOperation(() => _recoverOnForeground(epoch)),
          );
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Permanently tears down active Connect subsystems, cancels all timers and
  /// stream subscriptions, removes the lifecycle observer, and closes
  /// [stateStream].
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _sessionEpoch += 1;
    _openPickerCount = 0;
    _cancelPickerRefreshTimer();
    _detachLifecycleObserver();

    final authSub = _authSubscription;
    _authSubscription = null;
    _boundAuthBloc = null;
    if (authSub != null) {
      await authSub.cancel();
    }

    await _opTail;
    await _teardownSubsystems(wipeSortingDatabase: false);

    _emitState(const ConnectSessionDisposed());
    await _stateController.close();
  }

  /// Returns `true` when [results] indicates at least one active network
  /// interface (not exclusively [ConnectivityResult.none]).
  static bool isOnlineConnectivity(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return false;
    }
    for (final result in results) {
      if (result != ConnectivityResult.none) {
        return true;
      }
    }
    return false;
  }

  void _onAuthStateChanged(AuthState authState) {
    if (_isDisposed) {
      return;
    }
    switch (authState) {
      case Authenticated(:final user):
        if (_activeUserId == user.id &&
            (_state is ConnectSessionRunning ||
                _state is ConnectSessionStarting)) {
          return;
        }
        final switchingUsers =
            _hasAuthenticatedSession && _activeUserId != user.id;
        _sessionEpoch += 1;
        final bootEpoch = _sessionEpoch;
        _hasAuthenticatedSession = true;
        _activeUserId = user.id;
        unawaited(
          _enqueueOperation(() async {
            if (_isDisposed || bootEpoch != _sessionEpoch) {
              return;
            }
            if (switchingUsers) {
              await _teardownSubsystems(wipeSortingDatabase: true);
              if (_isDisposed || bootEpoch != _sessionEpoch) {
                return;
              }
            }
            await _bootConnectSession(user: user, epoch: bootEpoch);
          }),
        );
      case Unauthenticated():
        if (!_hasAuthenticatedSession && _state is ConnectSessionIdle) {
          return;
        }
        _sessionEpoch += 1;
        final teardownEpoch = _sessionEpoch;
        _hasAuthenticatedSession = false;
        _activeUserId = null;
        _cancelPickerRefreshTimer();
        unawaited(
          _enqueueOperation(() async {
            if (_isDisposed || teardownEpoch != _sessionEpoch) {
              return;
            }
            await _teardownSubsystems(wipeSortingDatabase: true);
            if (!_isDisposed && teardownEpoch == _sessionEpoch) {
              _emitState(const ConnectSessionIdle());
            }
          }),
        );
      case Authenticating():
      case AuthError():
        break;
    }
  }

  Future<void> _bootConnectSession({
    required SpotifyUser user,
    required int epoch,
  }) async {
    if (!_isAndroid) {
      dev.log(
        'ConnectSessionCoordinator: skipping native Connect boot on non-Android host',
        name: 'CONNECT',
      );
      _emitState(const ConnectSessionIdle());
      return;
    }

    _emitState(ConnectSessionStarting(userId: user.id));
    dev.log(
      'ConnectSessionCoordinator: starting auth-gated Connect boot for user=${user.id}',
      name: 'CONNECT',
    );

    try {
      // Step 1: Resolve Android device hardware & volume environment.
      final env = await _deviceEnvironmentPort.getDeviceEnvironment();
      if (_isStale(epoch)) return;
      dev.log(
        'ConnectSessionCoordinator: DeviceEnvironment '
        'name=${env.deviceName} brand=${env.brand} model=${env.model} '
        'type=${env.deviceTypeWire} volSteps=${env.maxMusicVolumeSteps} '
        'initialWireVol=${env.initialWireVolume}',
        name: 'CONNECT',
      );

      // Step 2: Resolve canonical persistent 40-hex device_id.
      final canonicalDeviceId = await _deviceIdentityService
          .getOrCreateDeviceId(androidId: env.androidId);
      if (_isStale(epoch)) return;
      dev.log(
        'ConnectSessionCoordinator: canonical device_id resolved '
        '(len=${canonicalDeviceId.length})',
        name: 'CONNECT',
      );

      // Step 3: Ensure auth credentials + client token exist and sync coherent
      // AuthClientProfileConfig + session credentials to native AuthSessionStore.
      await _authSessionProvider.getAccessToken();
      if (_isStale(epoch)) return;
      await _authSessionProvider.getClientToken();
      if (_isStale(epoch)) return;
      await _playbackSessionBridge.syncSessionToNative();
      if (_isStale(epoch)) return;
      final activeClientId = await _authSessionProvider.getActiveClientId();
      if (_isStale(epoch)) return;

      // Step 4: Resolve dynamic Spotify endpoints via APResolve and push to native.
      final endpoints = await _apResolveService.resolve();
      if (_isStale(epoch)) return;
      final endpointRc = _nativeGateway.setEndpoints(
        spclientBaseUrl: endpoints.spclientBaseUrl,
        dealerWsUrl: endpoints.dealerWsUrl,
      );
      if (endpointRc != 0) {
        dev.log(
          'ConnectSessionCoordinator: setEndpoints returned error code=$endpointRc '
          '(spclient=${endpoints.spclientBaseUrl}, dealer=${endpoints.dealerWsUrl})',
          name: 'CONNECT',
        );
      } else {
        dev.log(
          'ConnectSessionCoordinator: endpoints configured '
          'spclient=${endpoints.spclientBaseUrl} dealer=${endpoints.dealerWsUrl} '
          'fallback=${endpoints.resolvedFromFallback}',
          name: 'CONNECT',
        );
      }

      // Step 5: Build real non-empty DeviceInfo protobuf wire payload.
      final license = _resolveLicense(user);
      final deviceInfoBytes = _deviceInfoPayloadBuilder.buildFromEnvironment(
        deviceId: canonicalDeviceId,
        clientId: activeClientId,
        environment: env,
        license: license,
      );

      // Step 6: Start native ConnectSubsystem (fail fast on negative code).
      final startRc = _nativeGateway.start(deviceInfoBytes);
      if (startRc < 0) {
        final message =
            'ConnectNativeGateway.start failed with native error code $startRc';
        dev.log('ConnectSessionCoordinator: $message', name: 'CONNECT');
        throw StateError(message);
      }
      dev.log(
        'ConnectSessionCoordinator: native Connect started (rc=$startRc, '
        'deviceInfoBytes=${deviceInfoBytes.length})',
        name: 'CONNECT',
      );

      // Step 7: Push initial OS network availability and initial OS volume.
      final initialConnectivity = await _connectivity.checkConnectivity();
      if (_isStale(epoch)) {
        _safeStopNativeGateway();
        return;
      }
      final initialOnline = isOnlineConnectivity(initialConnectivity);
      _lastKnownOnline = initialOnline;
      _nativeGateway.setNetworkAvailable(initialOnline);

      final initialVolumeSnapshot = await _readInitialVolumeForBoot(env);
      if (_isStale(epoch)) {
        _safeStopNativeGateway();
        return;
      }
      final initialVolSteps = initialVolumeSnapshot.steps > 0
          ? initialVolumeSnapshot.steps
          : env.maxMusicVolumeSteps;
      final volRc = _nativeGateway.setLocalVolume(
        volume0To65535: initialVolumeSnapshot.volume,
        volumeSteps: initialVolSteps,
        reason: ConnectLocalVolumeReason.system,
      );
      if (volRc != 0) {
        dev.log(
          'ConnectSessionCoordinator: initial setLocalVolume returned $volRc',
          name: 'CONNECT',
        );
      }

      // Step 8: Start Mobius controller, volume controller, NSD, audio route,
      // connectivity watcher, and diagnostic stream logging.
      _diagnosticSubscription = _nativeGateway.diagnosticStream.listen(
        (diagnosticJson) {
          dev.log('[CONNECT-DIAG] $diagnosticJson', name: 'CONNECT');
        },
        onError: (Object error, StackTrace stackTrace) {
          dev.log(
            'ConnectSessionCoordinator: diagnosticStream error: $error',
            name: 'CONNECT',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );

      _remoteVolumeController.start();
      _connectController.start();

      _nsdSubscription = _localDiscoveryPort.watchDiscoveredServices().listen(
        (services) => _pushNsdSnapshot(epoch, services),
        onError: (Object error, StackTrace stackTrace) {
          dev.log(
            'ConnectSessionCoordinator: NSD watchDiscoveredServices error: $error',
            name: 'CONNECT',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );
      await _startLocalDiscoveryBestEffort(epoch);
      if (_isStale(epoch)) {
        await _teardownSubsystems(wipeSortingDatabase: false);
        return;
      }

      if (!_connectController.hasAudioRouteBinding) {
        _audioRouteSubscription = _audioRoutePort.watchPeripherals().listen(
          (peripherals) => _handlePeripheralsSnapshot(epoch, peripherals),
          onError: (Object error, StackTrace stackTrace) {
            dev.log(
              'ConnectSessionCoordinator: audioRoutePort.watchPeripherals error: $error',
              name: 'CONNECT',
              error: error,
              stackTrace: stackTrace,
            );
          },
        );
        unawaited(_fetchInitialAudioRouteSnapshot(epoch));
      }

      _connectivitySubscription =
          _connectivity.onConnectivityChanged.listen(
        (results) => _onConnectivityChanged(epoch, results),
        onError: (Object error, StackTrace stackTrace) {
          dev.log(
            'ConnectSessionCoordinator: connectivity stream error: $error',
            name: 'CONNECT',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );

      _emitState(
        ConnectSessionRunning(
          userId: user.id,
          deviceId: canonicalDeviceId,
          endpoints: endpoints,
        ),
      );
      dev.log(
        'ConnectSessionCoordinator: Connect session running for user=${user.id}',
        name: 'CONNECT',
      );

      if (_openPickerCount > 0) {
        _triggerPickerDiscoveryPass();
        _schedulePickerRefreshTick();
      }
    } on Object catch (error, stackTrace) {
      dev.log(
        'ConnectSessionCoordinator: Connect boot failed for user=${user.id}: $error',
        name: 'CONNECT',
        error: error,
        stackTrace: stackTrace,
      );
      if (!_isStale(epoch)) {
        _emitState(
          ConnectSessionFailed(
            userId: user.id,
            message: error.toString(),
            error: error,
          ),
        );
      }
    }
  }

  Future<void> _teardownSubsystems({
    required bool wipeSortingDatabase,
  }) async {
    dev.log(
      'ConnectSessionCoordinator: tearing down Connect subsystems '
      '(wipeSortingDatabase=$wipeSortingDatabase)',
      name: 'CONNECT',
    );

    _cancelPickerRefreshTimer();

    final subsToCancel = <StreamSubscription<Object?>>[
      ?_diagnosticSubscription,
      ?_nsdSubscription,
      ?_audioRouteSubscription,
      ?_connectivitySubscription,
    ];
    _diagnosticSubscription = null;
    _nsdSubscription = null;
    _audioRouteSubscription = null;
    _connectivitySubscription = null;
    _lastKnownOnline = null;
    _lastNotifiedAudioRoute = null;

    for (final sub in subsToCancel) {
      try {
        await sub.cancel();
      } on Object catch (error, stackTrace) {
        dev.log(
          'ConnectSessionCoordinator: stream cancel error during teardown: $error',
          name: 'CONNECT',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    try {
      await _localDiscoveryPort.stopDiscovery();
    } on Object catch (error, stackTrace) {
      dev.log(
        'ConnectSessionCoordinator: stopDiscovery error during teardown: $error',
        name: 'CONNECT',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await _remoteVolumeController.stop();
    } on Object catch (error, stackTrace) {
      dev.log(
        'ConnectSessionCoordinator: remoteVolumeController.stop error: $error',
        name: 'CONNECT',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await _connectController.stop(clearCache: wipeSortingDatabase);
    } on Object catch (error, stackTrace) {
      dev.log(
        'ConnectSessionCoordinator: connectController.stop error: $error',
        name: 'CONNECT',
        error: error,
        stackTrace: stackTrace,
      );
    }

    _safeStopNativeGateway();

    try {
      await _playbackSessionBridge.clearNativeAuthSession();
    } on Object catch (error, stackTrace) {
      dev.log(
        'ConnectSessionCoordinator: clearNativeAuthSession error: $error',
        name: 'CONNECT',
        error: error,
        stackTrace: stackTrace,
      );
    }

    if (wipeSortingDatabase) {
      await _wipeSortingDatabase();
    }
  }

  Future<void> _wipeSortingDatabase() async {
    try {
      if (_clearSortingDatabase case final clearCallback?) {
        await clearCallback();
      } else if (_sortingDatabase case final db?) {
        await db.clearAllTables();
      }
    } on Object catch (error, stackTrace) {
      dev.log(
        'ConnectSessionCoordinator: failed to clear DevicePickerSortingDatabase: $error',
        name: 'CONNECT',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _recoverOnForeground(int epoch) async {
    if (_isStale(epoch) || _state is! ConnectSessionRunning) {
      return;
    }
    try {
      await _authSessionProvider.getAccessToken();
      if (_isStale(epoch)) return;
      await _playbackSessionBridge.syncSessionToNative();
      if (_isStale(epoch)) return;
      final rc = _nativeGateway.reconnect(ConnectReconnectReason.foreground);
      if (rc < 0) {
        dev.log(
          'ConnectSessionCoordinator: foreground reconnect returned $rc',
          name: 'CONNECT',
        );
      }
      if (_connectController.isStarted) {
        _connectController.dispatch(const RefreshClusterRequested());
      }
    } on Object catch (error, stackTrace) {
      dev.log(
        'ConnectSessionCoordinator: foreground recovery failed: $error',
        name: 'CONNECT',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _onConnectivityChanged(int epoch, List<ConnectivityResult> results) {
    if (_isStale(epoch) || _state is! ConnectSessionRunning) {
      return;
    }
    final isNowOnline = isOnlineConnectivity(results);
    final wasOffline = _lastKnownOnline == false;
    final changed = _lastKnownOnline != isNowOnline;
    _lastKnownOnline = isNowOnline;

    if (changed) {
      dev.log(
        'ConnectSessionCoordinator: connectivity changed -> online=$isNowOnline',
        name: 'CONNECT',
      );
      try {
        _nativeGateway.setNetworkAvailable(isNowOnline);
      } on Object catch (error, stackTrace) {
        dev.log(
          'ConnectSessionCoordinator: setNetworkAvailable($isNowOnline) failed: $error',
          name: 'CONNECT',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    if (wasOffline && isNowOnline) {
      dev.log(
        'ConnectSessionCoordinator: network restored offline -> online, reconnecting Connect',
        name: 'CONNECT',
      );
      unawaited(
        _enqueueOperation(() => _recoverOnNetworkRestored(epoch)),
      );
    }
  }

  Future<void> _recoverOnNetworkRestored(int epoch) async {
    if (_isStale(epoch) || _state is! ConnectSessionRunning) {
      return;
    }
    try {
      await _authSessionProvider.getAccessToken();
      if (_isStale(epoch)) return;
      await _playbackSessionBridge.syncSessionToNative();
      if (_isStale(epoch)) return;
      final rc =
          _nativeGateway.reconnect(ConnectReconnectReason.networkRestored);
      if (rc < 0) {
        dev.log(
          'ConnectSessionCoordinator: networkRestored reconnect returned $rc',
          name: 'CONNECT',
        );
      }
      if (_connectController.isStarted) {
        _connectController.dispatch(const RefreshClusterRequested());
      }
    } on Object catch (error, stackTrace) {
      dev.log(
        'ConnectSessionCoordinator: network restoration recovery failed: $error',
        name: 'CONNECT',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<SystemVolumeSnapshot> _readInitialVolumeForBoot(
    DeviceEnvironmentInfo env,
  ) async {
    try {
      return await _systemVolumePort.getLocalVolume();
    } on Object catch (error, stackTrace) {
      dev.log(
        'ConnectSessionCoordinator: getLocalVolume failed during boot, '
        'using DeviceEnvironmentInfo snapshot: $error',
        name: 'CONNECT',
        error: error,
        stackTrace: stackTrace,
      );
      final currentStep =
          (env.currentMusicVolumeRatio * env.maxMusicVolumeSteps).round();
      return SystemVolumeSnapshot(
        volume: env.initialWireVolume,
        steps: env.maxMusicVolumeSteps,
        currentStep: currentStep,
      );
    }
  }

  Future<void> _startLocalDiscoveryBestEffort(int epoch) async {
    try {
      await _localDiscoveryPort.startDiscovery();
      if (_isStale(epoch)) return;
      final initialServices = await _localDiscoveryPort.getDiscoveredServices();
      if (_isStale(epoch)) return;
      if (initialServices.isNotEmpty) {
        _pushNsdSnapshot(epoch, initialServices);
      }
    } on Object catch (error, stackTrace) {
      dev.log(
        'ConnectSessionCoordinator: local NSD discovery unavailable (continuing cloud Connect): $error',
        name: 'CONNECT',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _pushNsdSnapshot(int epoch, List<DiscoveredNsdService> services) {
    if (_isStale(epoch)) {
      return;
    }
    try {
      final jsonPayload = DiscoveredNsdService.encodeListToJson(services);
      final rc = _nativeGateway.updateNsdServices(jsonPayload);
      if (rc != 0) {
        dev.log(
          'ConnectSessionCoordinator: updateNsdServices returned $rc '
          '(count=${services.length})',
          name: 'CONNECT',
        );
      }
    } on Object catch (error, stackTrace) {
      dev.log(
        'ConnectSessionCoordinator: updateNsdServices threw: $error',
        name: 'CONNECT',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _fetchInitialAudioRouteSnapshot(int epoch) async {
    try {
      final peripherals = await _audioRoutePort.getPeripherals();
      if (_isStale(epoch)) return;
      _handlePeripheralsSnapshot(epoch, peripherals);
    } on Object catch (error, stackTrace) {
      dev.log(
        'ConnectSessionCoordinator: audioRoutePort.getPeripherals failed: $error',
        name: 'CONNECT',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _handlePeripheralsSnapshot(
    int epoch,
    List<LocalAudioPeripheral> peripherals,
  ) {
    if (_isStale(epoch) || !_connectController.isStarted) {
      return;
    }
    _connectController.dispatch(PeripheralsUpdatedEvent(peripherals));

    LocalAudioPeripheral? activeRoute;
    LocalAudioPeripheral? builtInFallback;
    for (final peripheral in peripherals) {
      if (peripheral.isActive) {
        activeRoute = peripheral;
        break;
      }
      if (builtInFallback == null &&
          peripheral.id == kBuiltInSpeakerPeripheralId) {
        builtInFallback = peripheral;
      }
    }
    final resolvedActive = switch (activeRoute) {
      final active? => active,
      null => builtInFallback,
    };
    if (resolvedActive != null && resolvedActive != _lastNotifiedAudioRoute) {
      _lastNotifiedAudioRoute = resolvedActive;
      _connectController.dispatch(
        NotifyAudioRouteChangedRequested(
          audioOutputDeviceName: resolvedActive.name,
          connectionType: resolvedActive.connectionType,
          audioOutputDeviceBrand: resolvedActive.brand,
          audioOutputDeviceModel: resolvedActive.model,
          category: resolvedActive.category,
        ),
      );
    }
  }

  void _triggerPickerDiscoveryPass() {
    if (_isDisposed || !_connectController.isStarted) {
      return;
    }
    _connectController.dispatch(const PerformDiscoveryRequested());
    _connectController.dispatch(const RefreshClusterRequested());
    _connectController.dispatch(const WakeSleepingDevicesRequested());
  }

  void _schedulePickerRefreshTick() {
    _cancelPickerRefreshTimer();
    if (_isDisposed || _openPickerCount <= 0) {
      return;
    }
    _pickerRefreshTimer = Timer(_pickerRefreshInterval, () {
      _pickerRefreshTimer = null;
      if (_isDisposed || _openPickerCount <= 0) {
        return;
      }
      _triggerPickerDiscoveryPass();
      _schedulePickerRefreshTick();
    });
  }

  void _cancelPickerRefreshTimer() {
    _pickerRefreshTimer?.cancel();
    _pickerRefreshTimer = null;
  }

  String _resolveLicense(SpotifyUser user) {
    if (_runtimeContext case final ctx?) {
      final catalogue = ctx.catalogue.trim();
      if (catalogue.isNotEmpty) {
        return catalogue;
      }
    }
    if (user.product case final product? when product.trim().isNotEmpty) {
      return product.trim();
    }
    return DeviceInfoPayloadBuilder.defaultLicense;
  }

  void _safeStopNativeGateway() {
    try {
      _nativeGateway.stop();
    } on Object catch (error, stackTrace) {
      dev.log(
        'ConnectSessionCoordinator: nativeGateway.stop threw: $error',
        name: 'CONNECT',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _attachLifecycleObserverIfNeeded() {
    if (!_observeAppLifecycle || _observedBinding != null) {
      return;
    }
    final binding = switch (_widgetsBindingOverride) {
      final provided? => provided,
      null => WidgetsBinding.instance,
    };
    binding.addObserver(this);
    _observedBinding = binding;
  }

  void _detachLifecycleObserver() {
    if (_observedBinding case final binding?) {
      binding.removeObserver(this);
      _observedBinding = null;
    }
  }

  void _detachAuthSubscriptionOnly() {
    if (_authSubscription case final sub?) {
      _authSubscription = null;
      unawaited(sub.cancel());
    }
    _boundAuthBloc = null;
  }

  Future<void> _enqueueOperation(Future<void> Function() task) {
    final previousTail = _opTail;
    final tailCompleter = Completer<void>();
    _opTail = tailCompleter.future;

    () async {
      await previousTail;
      if (_isDisposed) {
        return;
      }
      try {
        await task();
      } on Object catch (error, stackTrace) {
        dev.log(
          'ConnectSessionCoordinator: queued operation failed: $error',
          name: 'CONNECT',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }()
        .whenComplete(() {
      if (!tailCompleter.isCompleted) {
        tailCompleter.complete();
      }
    });

    return tailCompleter.future;
  }

  bool _isStale(int epoch) => _isDisposed || epoch != _sessionEpoch;

  void _emitState(ConnectSessionState nextState) {
    if (nextState == _state) {
      return;
    }
    _state = nextState;
    if (!_stateController.isClosed) {
      _stateController.add(nextState);
    }
  }
}
