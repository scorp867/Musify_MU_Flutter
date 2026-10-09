import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:musify_mu/core/network/status/network_status.dart';

abstract class NetworkMonitorService {
  NetworkStatus get currentStatus;
  Stream<NetworkStatus> get statusStream;

  void recordLatency(Duration latency);
  void recordTimeout();
  void recordConnectionError() {}
  void recordSuccess();
  void dispose();
}

class NetworkMonitorServiceImpl implements NetworkMonitorService {
  final Connectivity _connectivity;
  final _statusController = StreamController<NetworkStatus>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  NetworkStatus _currentStatus = NetworkStatus.online;

  final List<int> _recentLatenciesMs = [];
  int _consecutiveTimeouts = 0;
  static const int _maxRecentSamples = 5;
  static const int _slowLatencyThresholdMs = 2500;
  static const int _fastLatencyThresholdMs = 1200;

  NetworkMonitorServiceImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  void _init() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChanged,
    );
    // Initial check
    _connectivity.checkConnectivity().then(_handleConnectivityChanged);
  }

  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    final isNone = results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);

    if (isNone) {
      _updateStatus(NetworkStatus.offline);
    } else {
      // Reconnected
      if (_currentStatus == NetworkStatus.offline ||
          _currentStatus == NetworkStatus.slow) {
        _updateStatus(NetworkStatus.restored);
      } else {
        _updateStatus(NetworkStatus.online);
      }
    }
  }

  @override
  NetworkStatus get currentStatus => _currentStatus;

  @override
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  @override
  void recordLatency(Duration latency) {
    if (_currentStatus == NetworkStatus.offline) return;

    final ms = latency.inMilliseconds;
    _recentLatenciesMs.add(ms);
    if (_recentLatenciesMs.length > _maxRecentSamples) {
      _recentLatenciesMs.removeAt(0);
    }

    final averageMs =
        _recentLatenciesMs.reduce((a, b) => a + b) / _recentLatenciesMs.length;

    if (averageMs >= _slowLatencyThresholdMs && _currentStatus == NetworkStatus.online) {
      _updateStatus(NetworkStatus.slow);
    } else if (averageMs <= _fastLatencyThresholdMs &&
        _currentStatus == NetworkStatus.slow) {
      _updateStatus(NetworkStatus.restored);
    }
  }

  @override
  void recordTimeout() {
    if (_currentStatus == NetworkStatus.offline) return;

    _consecutiveTimeouts++;
    if (_consecutiveTimeouts >= 2 && _currentStatus == NetworkStatus.online) {
      _updateStatus(NetworkStatus.slow);
    }
  }

  @override
  void recordConnectionError() {
    _consecutiveTimeouts++;
    if (_currentStatus != NetworkStatus.offline) {
      _updateStatus(NetworkStatus.offline);
    }
  }

  @override
  void recordSuccess() {
    _consecutiveTimeouts = 0;
    if (_currentStatus == NetworkStatus.restored) {
      _updateStatus(NetworkStatus.online);
    }
  }

  void _updateStatus(NetworkStatus newStatus) {
    if (_currentStatus == newStatus) return;
    _currentStatus = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(newStatus);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
  }
}
