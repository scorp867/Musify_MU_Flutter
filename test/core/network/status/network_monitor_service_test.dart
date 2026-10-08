import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';

class FakeConnectivity implements Connectivity {
  final _controller = StreamController<List<ConnectivityResult>>.broadcast();
  List<ConnectivityResult> currentResults = [ConnectivityResult.wifi];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _controller.stream;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => currentResults;

  void emit(List<ConnectivityResult> results) {
    currentResults = results;
    _controller.add(results);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('NetworkMonitorService', () {
    late FakeConnectivity fakeConnectivity;
    late NetworkMonitorServiceImpl service;

    setUp(() {
      fakeConnectivity = FakeConnectivity();
      service = NetworkMonitorServiceImpl(connectivity: fakeConnectivity);
    });

    tearDown(() {
      service.dispose();
      fakeConnectivity.dispose();
    });

    test('transitions to offline when connectivity drops', () async {
      final statuses = <NetworkStatus>[];
      final sub = service.statusStream.listen(statuses.add);

      fakeConnectivity.emit([ConnectivityResult.none]);
      await pumpEventQueue();

      expect(service.currentStatus, equals(NetworkStatus.offline));
      expect(statuses, contains(NetworkStatus.offline));

      await sub.cancel();
    });

    test('transitions to restored when connectivity returns from offline', () async {
      fakeConnectivity.emit([ConnectivityResult.none]);
      await pumpEventQueue();
      expect(service.currentStatus, equals(NetworkStatus.offline));

      final statuses = <NetworkStatus>[];
      final sub = service.statusStream.listen(statuses.add);

      fakeConnectivity.emit([ConnectivityResult.wifi]);
      await pumpEventQueue();

      expect(service.currentStatus, equals(NetworkStatus.restored));
      expect(statuses, contains(NetworkStatus.restored));

      await sub.cancel();
    });

    test('detects slow connection when request latencies are consistently high', () async {
      final statuses = <NetworkStatus>[];
      final sub = service.statusStream.listen(statuses.add);

      // Record high latency requests
      for (var i = 0; i < 3; i++) {
        service.recordLatency(const Duration(milliseconds: 3000));
      }
      await pumpEventQueue();

      expect(service.currentStatus, equals(NetworkStatus.slow));
      expect(statuses, contains(NetworkStatus.slow));

      await sub.cancel();
    });

    test('detects slow connection on consecutive timeouts', () async {
      final statuses = <NetworkStatus>[];
      final sub = service.statusStream.listen(statuses.add);

      service.recordTimeout();
      service.recordTimeout();
      await pumpEventQueue();

      expect(service.currentStatus, equals(NetworkStatus.slow));
      expect(statuses, contains(NetworkStatus.slow));

      await sub.cancel();
    });
  });
}
