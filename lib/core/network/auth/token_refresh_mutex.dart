import 'dart:async';
import 'dart:developer' as dev;

/// Mutex that guarantees only one token refresh operation runs at a time.
///
/// If multiple concurrent network requests receive HTTP 401, all requests
/// await the single in-flight refresh operation rather than bombarding
/// Spotify's `/api/token` with redundant TOTP refresh requests.
class TokenRefreshMutex {
  Completer<String?>? _inFlight;

  /// Runs [refreshAction] under the mutex lock.
  /// If another refresh is already executing, waits for its result.
  Future<String?> lock(Future<String?> Function() refreshAction) async {
    if (_inFlight != null) {
      dev.log(
        'TokenRefreshMutex: Awaiting existing in-flight refresh...',
        name: 'Auth',
      );
      return _inFlight!.future;
    }

    final completer = Completer<String?>();
    _inFlight = completer;

    try {
      dev.log('TokenRefreshMutex: Executing primary refresh...', name: 'Auth');
      final newToken = await refreshAction();
      completer.complete(newToken);
      return newToken;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _inFlight = null;
    }
  }

  /// Whether a refresh is currently running.
  bool get isRefreshing => _inFlight != null;
}
