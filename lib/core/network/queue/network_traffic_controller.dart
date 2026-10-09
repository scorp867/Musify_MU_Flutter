import 'dart:async';
import 'package:dio/dio.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/queue/queued_request.dart';
import 'package:musify_mu/core/network/result/network_result.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';

/// Central traffic controller that schedules, prioritizes, and pauses outbound
/// network requests based on device connectivity and priority levels.
///
/// Features:
/// - **Offline Gating**: Buffers requests when offline instead of failing immediately.
/// - **Priority-Ordered Draining**: Playback (P0) > Interactive (P1) > Background (P2).
/// - **TTL Eviction**: Automatically drops stale offline requests when their TTL expires.
/// - **Tag-Based Superseding**: New requests with the same tag cancel and replace older ones.
/// - **Controlled Concurrency**: Limits concurrent draining to prevent socket starvation.
class NetworkTrafficController {
  final NetworkMonitorService _monitorService;
  final int maxConcurrent;
  final int maxQueueCapacity;

  final List<QueuedRequest<dynamic>> _queue = [];
  int _activeExecutions = 0;
  int _counter = 0;

  StreamSubscription<NetworkStatus>? _statusSubscription;
  bool _isDisposed = false;

  NetworkTrafficController({
    required NetworkMonitorService monitorService,
    this.maxConcurrent = 4,
    this.maxQueueCapacity = 64,
  }) : _monitorService = monitorService {
    _statusSubscription = _monitorService.statusStream.listen(_onStatusChanged);
  }

  int get queueLength => _queue.length;
  int get activeExecutions => _activeExecutions;
  bool get isOffline => _monitorService.currentStatus == NetworkStatus.offline;

  Duration _defaultTtlFor(NetworkPriority priority) {
    return switch (priority) {
      NetworkPriority.playback => const Duration(seconds: 10),
      NetworkPriority.interactive => const Duration(seconds: 15),
      NetworkPriority.background => const Duration(seconds: 60),
    };
  }

  void _onStatusChanged(NetworkStatus status) {
    if (_isDisposed) return;
    if (status == NetworkStatus.restored || status == NetworkStatus.online) {
      _drainQueue();
    }
  }

  /// Dispatches an operation through the priority traffic controller.
  ///
  /// When [bufferIfOffline] is false (default for read/GET requests), requests
  /// bypass offline buffering and execute directly against the network adapter,
  /// failing fast via socket errors if the connection is down.
  /// When true (default for write/POST mutations), requests buffer in the queue
  /// and drain upon reconnection (outbox pattern).
  Future<NetworkResult<T>> dispatch<T>({
    required Future<NetworkResult<T>> Function() execution,
    NetworkPriority priority = NetworkPriority.interactive,
    String? tag,
    Duration? ttl,
    CancelToken? cancelToken,
    bool bufferIfOffline = false,
  }) {
    if (_isDisposed) {
      return Future.value(
        const NetworkResult.failure(
          NetworkException(
            message: 'NetworkTrafficController is disposed',
            reason: NetworkFailureReason.cancelled,
          ),
        ),
      );
    }

    final effectiveTtl = ttl ?? _defaultTtlFor(priority);
    final request = QueuedRequest<T>(
      id: 'req_${++_counter}',
      tag: tag,
      priority: priority,
      ttl: effectiveTtl,
      execution: execution,
      cancelToken: cancelToken,
    );

    // If device is offline:
    if (isOffline) {
      if (bufferIfOffline) {
        _enqueue(request);
        return request.completer.future;
      } else {
        // Direct execution for fail-fast reads: lets socket verify or fail immediately.
        _executeDirectly(request);
        return request.completer.future;
      }
    }

    // When online:
    // If queue is empty and slot available, execute immediately
    if (_queue.isEmpty) {
      if (priority == NetworkPriority.playback ||
          _activeExecutions < maxConcurrent) {
        _executeDirectly(request);
        return request.completer.future;
      }
    }

    // Otherwise, join queue and trigger drain
    _enqueue(request);
    _drainQueue();
    return request.completer.future;
  }

  void _enqueue<T>(QueuedRequest<T> request) {
    // 1. Tag-based superseding: cancel and evict existing request with identical tag
    if (request.tag != null) {
      for (var i = _queue.length - 1; i >= 0; i--) {
        final existing = _queue[i];
        if (existing.tag == request.tag) {
          _queue.removeAt(i);
          existing.cancel('Superseded by newer request with tag "${request.tag}"');
        }
      }
    }

    // 2. Capacity overflow: drop oldest background request if exceeding limit
    if (_queue.length >= maxQueueCapacity) {
      final dropIndex = _queue.indexWhere(
        (r) => r.priority == NetworkPriority.background,
      );
      if (dropIndex != -1) {
        final dropped = _queue.removeAt(dropIndex);
        dropped.cancel('Dropped from queue due to capacity overflow');
      }
    }

    // 3. Add to queue and arm TTL timer + cancellation listener
    _queue.add(request);
    request.startTtlTimer(
      (expiredReq) {
        _queue.remove(expiredReq);
        expiredReq.expire();
      },
      onCancelled: (cancelledReq) {
        _queue.remove(cancelledReq);
      },
    );
  }

  void _executeDirectly<T>(QueuedRequest<T> request) {
    final isPlayback = request.priority == NetworkPriority.playback;
    if (!isPlayback) {
      _activeExecutions++;
    }

    if (request.cancelToken != null) {
      if (request.cancelToken!.isCancelled) {
        request.cancel('Request cancelled via CancelToken');
        if (!isPlayback) {
          _activeExecutions--;
        }
        _drainQueue();
        return;
      }
      request.cancelToken!.whenCancel.then((_) {
        if (!request.isCompleted) {
          request.cancel('Request cancelled via CancelToken');
        }
      });
    }

    request.execution().then((result) {
      request.complete(result);
    }).catchError((e, stack) {
      request.complete(
        NetworkResult.failure(
          NetworkException(
            message: e.toString(),
            reason: NetworkFailureReason.unknown,
            cause: e,
          ),
        ),
      );
    }).whenComplete(() {
      if (!isPlayback) {
        _activeExecutions--;
      }
      _drainQueue();
    });
  }

  void _drainQueue() {
    if (_isDisposed || _queue.isEmpty || isOffline) return;

    // Sort queue: P0 (playback: 0) < P1 (interactive: 1) < P2 (background: 2),
    // ties broken by oldest createdAt (FIFO)
    _queue.sort((a, b) {
      final prioCompare = a.priority.value.compareTo(b.priority.value);
      if (prioCompare != 0) return prioCompare;
      return a.createdAt.compareTo(b.createdAt);
    });

    for (var i = 0; i < _queue.length; i++) {
      final candidate = _queue[i];
      if (candidate.isCompleted) {
        _queue.removeAt(i);
        i--;
        continue;
      }

      final isPlayback = candidate.priority == NetworkPriority.playback;
      final hasSlot = isPlayback || _activeExecutions < maxConcurrent;

      if (hasSlot) {
        _queue.removeAt(i);
        i--;
        _executeDirectly(candidate);
      } else {
        // Since queue is sorted by priority, if no slot for interactive/background, break
        break;
      }
    }
  }

  void dispose() {
    _isDisposed = true;
    _statusSubscription?.cancel();
    for (final req in _queue) {
      req.cancel('NetworkTrafficController was disposed');
    }
    _queue.clear();
  }
}
