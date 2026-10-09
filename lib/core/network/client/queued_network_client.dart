import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:musify_mu/core/network/client/network_client.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/queue/network_traffic_controller.dart';
import 'package:musify_mu/core/network/result/network_result.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';

/// Decorator over [NetworkClient] that routes all outgoing HTTP requests
/// through a centralized [NetworkTrafficController].
///
/// Ensures all requests:
/// - Pause gracefully when offline rather than failing immediately.
/// - Prioritize playback (P0) over interactive (P1) and background (P2).
/// - Evict stale queries via TTL or superseding tags.
/// - Drain with controlled concurrency on network reconnection.
class QueuedNetworkClient implements NetworkClient {
  final NetworkClient _delegate;
  final NetworkTrafficController _controller;

  QueuedNetworkClient({
    required NetworkClient delegate,
    required NetworkMonitorService monitorService,
    NetworkTrafficController? controller,
  })  : _delegate = delegate,
        _controller = controller ??
            NetworkTrafficController(monitorService: monitorService);

  NetworkTrafficController get controller => _controller;
  NetworkClient get delegate => _delegate;

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
  }) {
    return _controller.dispatch<Uint8List>(
      priority: priority,
      tag: tag ?? uri.path,
      ttl: ttl,
      cancelToken: cancelToken,
      bufferIfOffline: bufferIfOffline,
      execution: () => _delegate.get(
        uri,
        headers: headers,
        cancelToken: cancelToken,
        priority: priority,
        timeout: timeout,
        tag: tag,
        ttl: ttl,
        bufferIfOffline: bufferIfOffline,
      ),
    );
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
    bool bufferIfOffline = false,
  }) {
    return _controller.dispatch<Uint8List>(
      priority: priority,
      tag: tag ?? uri.path,
      ttl: ttl,
      cancelToken: cancelToken,
      bufferIfOffline: bufferIfOffline,
      execution: () => _delegate.post(
        uri,
        body,
        headers: headers,
        cancelToken: cancelToken,
        priority: priority,
        contentType: contentType,
        timeout: timeout,
        tag: tag,
        ttl: ttl,
        bufferIfOffline: bufferIfOffline,
      ),
    );
  }

  @override
  Future<NetworkResult<Map<String, List<String>>>> head(
    Uri uri, {
    Map<String, String>? headers,
    Duration? timeout,
    bool bufferIfOffline = false,
  }) {
    return _controller.dispatch<Map<String, List<String>>>(
      priority: NetworkPriority.interactive,
      bufferIfOffline: bufferIfOffline,
      execution: () => _delegate.head(
        uri,
        headers: headers,
        timeout: timeout,
        bufferIfOffline: bufferIfOffline,
      ),
    );
  }

  @override
  void close({bool force = false}) {
    _controller.dispose();
    _delegate.close(force: force);
  }
}
