import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/network/status/bloc/network_status_bloc.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';

class MockNetworkMonitorService implements NetworkMonitorService {
  final _controller = StreamController<NetworkStatus>.broadcast();
  NetworkStatus _status = NetworkStatus.online;

  @override
  NetworkStatus get currentStatus => _status;

  @override
  Stream<NetworkStatus> get statusStream => _controller.stream;

  void emitStatus(NetworkStatus status) {
    _status = status;
    _controller.add(status);
  }

  @override
  void recordLatency(Duration latency) {}

  @override
  void recordTimeout() {}

  @override
  void recordConnectionError() {}

  @override
  void recordSuccess() {}

  @override
  void dispose() {
    _controller.close();
  }
}

void main() {
  group('NetworkStatusBloc', () {
    late MockNetworkMonitorService mockService;
    late NetworkStatusBloc bloc;

    setUp(() {
      mockService = MockNetworkMonitorService();
      bloc = NetworkStatusBloc(monitorService: mockService);
    });

    tearDown(() {
      bloc.close();
      mockService.dispose();
    });

    test('initial state is online with null message', () {
      expect(bloc.state.status, equals(NetworkStatus.online));
      expect(bloc.state.message, isNull);
      expect(bloc.state.isVisible, isFalse);
    });

    test('emits offline state with message when service reports offline', () async {
      mockService.emitStatus(NetworkStatus.offline);
      await pumpEventQueue();

      expect(bloc.state.status, equals(NetworkStatus.offline));
      expect(bloc.state.message, equals('No internet connection'));
      expect(bloc.state.isVisible, isTrue);
    });

    test('emits slow state with message when service reports slow', () async {
      mockService.emitStatus(NetworkStatus.slow);
      await pumpEventQueue();

      expect(bloc.state.status, equals(NetworkStatus.slow));
      expect(bloc.state.message, equals('Slow connection'));
      expect(bloc.state.isVisible, isTrue);
    });

    test('emits restored state and auto-collapses to online', () async {
      mockService.emitStatus(NetworkStatus.restored);
      await pumpEventQueue();

      expect(bloc.state.status, equals(NetworkStatus.restored));
      expect(bloc.state.message, equals('Back online'));
      expect(bloc.state.isVisible, isTrue);

      // Wait for 2.1s auto-dismiss timer
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      await pumpEventQueue();

      expect(bloc.state.status, equals(NetworkStatus.online));
      expect(bloc.state.message, isNull);
      expect(bloc.state.isVisible, isFalse);
    });
  });
}
