import 'package:flutter/foundation.dart';

/// Explicit reason for a network operation failure.
enum NetworkFailureReason {
  /// No network connectivity or DNS lookup failed.
  offline,

  /// Request or connection timed out.
  timeout,

  /// HTTP 401 Unauthorized (and refresh failed or not applicable).
  unauthorized,

  /// HTTP 403 Forbidden.
  forbidden,

  /// HTTP 404 Not Found.
  notFound,

  /// HTTP 429 Too Many Requests.
  rateLimited,

  /// HTTP 4xx Client error.
  badRequest,

  /// HTTP 5xx Server error.
  serverError,

  /// Request was deliberately aborted via CancelToken.
  cancelled,

  /// Payload deserialization or decoding failed.
  parseError,

  /// Unclassified exception.
  unknown;

  /// Returns true if this error is an infrastructure/transport glitch rather
  /// than an affirmative backend statement that an entity does not exist.
  bool get isTransientOrTransportError =>
      this == NetworkFailureReason.offline ||
      this == NetworkFailureReason.timeout ||
      this == NetworkFailureReason.serverError ||
      this == NetworkFailureReason.rateLimited;
}

/// Structured network exception preserving HTTP status code and root cause.
@immutable
class NetworkException implements Exception {
  final String message;
  final NetworkFailureReason reason;
  final int? statusCode;
  final Object? cause;

  const NetworkException({
    required this.message,
    required this.reason,
    this.statusCode,
    this.cause,
  });

  @override
  String toString() =>
      'NetworkException(reason: $reason, status: $statusCode, message: $message)';
}

/// Functional result type representing either a successful response or a typed failure.
@immutable
sealed class NetworkResult<T> {
  const NetworkResult();

  const factory NetworkResult.success(T data, {int statusCode}) =
      NetworkSuccess<T>;

  const factory NetworkResult.failure(NetworkException error, {int? statusCode}) =
      NetworkFailure<T>;

  bool get isSuccess => this is NetworkSuccess<T>;
  bool get isFailure => this is NetworkFailure<T>;

  int? get statusCode => switch (this) {
        NetworkSuccess<T>(statusCode: final s) => s,
        NetworkFailure<T>(statusCode: final s) => s,
      };

  T? get dataOrNull => switch (this) {
        NetworkSuccess<T>(data: final d) => d,
        NetworkFailure<T>() => null,
      };

  NetworkException? get errorOrNull => switch (this) {
        NetworkSuccess<T>() => null,
        NetworkFailure<T>(error: final e) => e,
      };

  R fold<R>({
    required R Function(T data, int statusCode) onSuccess,
    required R Function(NetworkException error, int? statusCode) onFailure,
  }) {
    return switch (this) {
      NetworkSuccess<T>(data: final d, statusCode: final s) =>
        onSuccess(d, s),
      NetworkFailure<T>(error: final e, statusCode: final s) =>
        onFailure(e, s),
    };
  }

  NetworkResult<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      NetworkSuccess<T>(data: final d, statusCode: final s) =>
        NetworkSuccess<R>(transform(d), statusCode: s),
      NetworkFailure<T>(error: final e, statusCode: final s) =>
        NetworkFailure<R>(e, statusCode: s),
    };
  }
}

/// Represents a successful network response.
final class NetworkSuccess<T> extends NetworkResult<T> {
  final T data;
  @override
  final int statusCode;

  const NetworkSuccess(this.data, {this.statusCode = 200});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkSuccess<T> &&
          other.data == data &&
          other.statusCode == statusCode;

  @override
  int get hashCode => Object.hash(data, statusCode);
}

/// Represents a failed network response.
final class NetworkFailure<T> extends NetworkResult<T> {
  final NetworkException error;
  @override
  final int? statusCode;

  const NetworkFailure(this.error, {this.statusCode});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkFailure<T> &&
          other.error == error &&
          other.statusCode == statusCode;

  @override
  int get hashCode => Object.hash(error, statusCode);
}
