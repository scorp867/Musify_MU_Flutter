import 'dart:async';
import 'package:dio/dio.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/result/network_result.dart';

/// Represents an item buffered or managed in the [NetworkTrafficController].
class QueuedRequest<T> {
  final String id;
  final String? tag;
  final NetworkPriority priority;
  final Duration ttl;
  final DateTime createdAt;
  final CancelToken? cancelToken;
  final Future<NetworkResult<T>> Function() execution;
  final Completer<NetworkResult<T>> completer = Completer<NetworkResult<T>>();

  Timer? _ttlTimer;

  QueuedRequest({
    required this.id,
    this.tag,
    required this.priority,
    required this.ttl,
    required this.execution,
    this.cancelToken,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCompleted => completer.isCompleted;

  void startTtlTimer(
    void Function(QueuedRequest<T> request) onExpired, {
    void Function(QueuedRequest<T> request)? onCancelled,
  }) {
    _ttlTimer?.cancel();
    _ttlTimer = Timer(ttl, () {
      if (!isCompleted) {
        onExpired(this);
      }
    });

    if (cancelToken != null) {
      if (cancelToken!.isCancelled) {
        cancel('Request cancelled via CancelToken');
        onCancelled?.call(this);
      } else {
        cancelToken!.whenCancel.then((_) {
          if (!isCompleted) {
            cancel('Request cancelled via CancelToken');
            onCancelled?.call(this);
          }
        });
      }
    }
  }

  void complete(NetworkResult<T> result) {
    _clean();
    if (!completer.isCompleted) {
      completer.complete(result);
    }
  }

  void expire() {
    _clean();
    if (!completer.isCompleted) {
      completer.complete(
        const NetworkResult.failure(
          NetworkException(
            message: 'Request timed out in offline queue (TTL exceeded)',
            reason: NetworkFailureReason.offline,
          ),
        ),
      );
    }
  }

  void cancel([String message = 'Request was superseded or cancelled']) {
    _clean();
    if (!completer.isCompleted) {
      completer.complete(
        NetworkResult.failure(
          NetworkException(
            message: message,
            reason: NetworkFailureReason.cancelled,
          ),
        ),
      );
    }
  }

  void _clean() {
    _ttlTimer?.cancel();
    _ttlTimer = null;
  }
}
