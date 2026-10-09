import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/network/client/network_client.dart';
import 'package:musify_mu/core/network/client/queued_network_client.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/queue/network_traffic_controller.dart';
import 'package:musify_mu/core/network/result/network_result.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';

class FakeNetworkMonitor implements NetworkMonitorService {
  final _controller = StreamController<NetworkStatus>.broadcast();
  NetworkStatus _status;

  FakeNetworkMonitor({NetworkStatus initialStatus = NetworkStatus.online})
      : _status = initialStatus;

  @override
  NetworkStatus get currentStatus => _status;

  @override
  Stream<NetworkStatus> get statusStream => _controller.stream;

  void emit(NetworkStatus status) {
    _status = status;
    _controller.add(status);
  }

  @override
  void recordLatency(Duration latency) {}

  @override
  void recordSuccess() {}

  @override
  void recordTimeout() {}

  @override
  void recordConnectionError() {}

  @override
  void dispose() {
    _controller.close();
  }
}

void main() {
  group('NetworkTrafficController', () {
    late FakeNetworkMonitor monitor;
    late NetworkTrafficController controller;

    setUp(() {
      monitor = FakeNetworkMonitor(initialStatus: NetworkStatus.online);
      controller = NetworkTrafficController(
        monitorService: monitor,
        maxConcurrent: 2,
      );
    });

    tearDown(() {
      controller.dispose();
      monitor.dispose();
    });

    test('dispatches directly when online', () async {
      var executed = false;
      final result = await controller.dispatch(
        execution: () async {
          executed = true;
          return NetworkResult.success(Uint8List(0));
        },
        priority: NetworkPriority.interactive,
      );

      expect(executed, isTrue);
      expect(result.isSuccess, isTrue);
    });

    test('buffers requests when offline and drains in priority order on restore', () async {
      monitor.emit(NetworkStatus.offline);

      final executionOrder = <String>[];

      // Enqueue background request first
      final bgFuture = controller.dispatch(
        execution: () async {
          executionOrder.add('background');
          return NetworkResult.success(Uint8List(0));
        },
        priority: NetworkPriority.background,
        bufferIfOffline: true,
      );

      // Enqueue playback request second (higher priority P0)
      final pbFuture = controller.dispatch(
        execution: () async {
          executionOrder.add('playback');
          return NetworkResult.success(Uint8List(0));
        },
        priority: NetworkPriority.playback,
        bufferIfOffline: true,
      );

      // Enqueue interactive request third (P1)
      final interFuture = controller.dispatch(
        execution: () async {
          executionOrder.add('interactive');
          return NetworkResult.success(Uint8List(0));
        },
        priority: NetworkPriority.interactive,
        bufferIfOffline: true,
      );

      // While offline, none should have executed yet
      expect(executionOrder, isEmpty);
      expect(controller.queueLength, equals(3));

      // Reconnect network
      monitor.emit(NetworkStatus.restored);

      // Await all futures
      await Future.wait([bgFuture, pbFuture, interFuture]);

      // Verify that playback (P0) ran before interactive (P1) which ran before background (P2)
      expect(executionOrder, equals(['playback', 'interactive', 'background']));
      expect(controller.queueLength, equals(0));
    });

    test('supersedes older requests with identical tag', () async {
      monitor.emit(NetworkStatus.offline);

      final firstFuture = controller.dispatch(
        execution: () async => NetworkResult.success(Uint8List(0)),
        tag: 'search_query',
        priority: NetworkPriority.interactive,
        bufferIfOffline: true,
      );

      // Enqueue second search query with same tag
      final secondFuture = controller.dispatch(
        execution: () async => NetworkResult.success(Uint8List(1)),
        tag: 'search_query',
        priority: NetworkPriority.interactive,
        bufferIfOffline: true,
      );

      // First query must be cancelled / superseded immediately
      final firstResult = await firstFuture;
      expect(firstResult.isFailure, isTrue);
      expect(
        firstResult.errorOrNull?.reason,
        equals(NetworkFailureReason.cancelled),
      );

      // Restore network -> second query succeeds
      monitor.emit(NetworkStatus.restored);
      final secondResult = await secondFuture;
      expect(secondResult.isSuccess, isTrue);
    });

    test('expires requests via TTL while offline', () async {
      monitor.emit(NetworkStatus.offline);

      final future = controller.dispatch(
        execution: () async => NetworkResult.success(Uint8List(0)),
        priority: NetworkPriority.interactive,
        ttl: const Duration(milliseconds: 50),
        bufferIfOffline: true,
      );

      // Wait for TTL expiration
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final result = await future;
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.reason, equals(NetworkFailureReason.offline));
      expect(controller.queueLength, equals(0));
    });

    test('evicts request when CancelToken is cancelled', () async {
      monitor.emit(NetworkStatus.offline);
      final cancelToken = CancelToken();

      final future = controller.dispatch(
        execution: () async => NetworkResult.success(Uint8List(0)),
        priority: NetworkPriority.interactive,
        cancelToken: cancelToken,
        bufferIfOffline: true,
      );

      expect(controller.queueLength, equals(1));

      // Cancel token
      cancelToken.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final result = await future;
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.reason, equals(NetworkFailureReason.cancelled));
    });
  });

  group('QueuedNetworkClient', () {
    late FakeNetworkMonitor monitor;
    late FakeNetworkClient delegate;
    late QueuedNetworkClient client;

    setUp(() {
      monitor = FakeNetworkMonitor(initialStatus: NetworkStatus.online);
      delegate = FakeNetworkClient();
      client = QueuedNetworkClient(
        delegate: delegate,
        monitorService: monitor,
      );
    });

    tearDown(() {
      client.close();
      delegate.close();
      monitor.dispose();
    });

    test('transparently routes get and post through delegate when online', () async {
      final getResult = await client.get(Uri.parse('https://api.spotify.com/v1/test'));
      expect(getResult.isSuccess, isTrue);
      expect(delegate.getCalls, equals(1));

      final postResult = await client.post(
        Uri.parse('https://api.spotify.com/v1/test'),
        Uint8List(0),
      );
      expect(postResult.isSuccess, isTrue);
      expect(delegate.postCalls, equals(1));
    });

    test('dispatches GET directly when offline without buffering (fail-fast read)', () async {
      monitor.emit(NetworkStatus.offline);

      final result = await client.get(Uri.parse('https://api.spotify.com/v1/instant'));
      expect(delegate.getCalls, equals(1));
      expect(result.isSuccess, isTrue);
    });

    test('dispatches POST directly when offline without buffering (fail-fast read query)', () async {
      monitor.emit(NetworkStatus.offline);

      final result = await client.post(
        Uri.parse('https://api.spotify.com/v1/query'),
        Uint8List(0),
      );
      expect(delegate.postCalls, equals(1));
      expect(result.isSuccess, isTrue);
    });

    test('buffers POST mutations when bufferIfOffline is true and executes on reconnect (outbox pattern)', () async {
      monitor.emit(NetworkStatus.offline);

      final future = client.post(
        Uri.parse('https://api.spotify.com/v1/mutation'),
        Uint8List(0),
        bufferIfOffline: true,
      );
      expect(delegate.postCalls, equals(0));

      monitor.emit(NetworkStatus.restored);
      final result = await future;

      expect(result.isSuccess, isTrue);
      expect(delegate.postCalls, equals(1));
    });

    test('buffers GET when bufferIfOffline is explicitly set to true', () async {
      monitor.emit(NetworkStatus.offline);

      final future = client.get(
        Uri.parse('https://api.spotify.com/v1/deferred'),
        bufferIfOffline: true,
      );
      expect(delegate.getCalls, equals(0));

      monitor.emit(NetworkStatus.restored);
      final result = await future;

      expect(result.isSuccess, isTrue);
      expect(delegate.getCalls, equals(1));
    });
  });
}

class FakeNetworkClient implements NetworkClient {
  int getCalls = 0;
  int postCalls = 0;
  int headCalls = 0;

  @override
  Future<NetworkResult<Uint8List>> get(
    Uri uri, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
    NetworkPriority priority = NetworkPriority.interactive,
    Duration? timeout,
    String? tag,
    Duration? ttl,
    bool bufferIfOffline = false,
  }) async {
    getCalls++;
    return NetworkResult.success(Uint8List(0));
  }

  @override
  Future<NetworkResult<Uint8List>> post(
    Uri uri,
    Uint8List body, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
    NetworkPriority priority = NetworkPriority.interactive,
    String contentType = 'application/x-protobuf',
    Duration? timeout,
    String? tag,
    Duration? ttl,
    bool bufferIfOffline = true,
  }) async {
    postCalls++;
    return NetworkResult.success(Uint8List(0));
  }

  @override
  Future<NetworkResult<Map<String, List<String>>>> head(
    Uri uri, {
    Map<String, String>? headers,
    Duration? timeout,
    bool bufferIfOffline = false,
  }) async {
    headCalls++;
    return const NetworkResult.success({});
  }

  @override
  void close({bool force = false}) {}
}

