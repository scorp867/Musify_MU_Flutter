// 1:1 replica of com.spotify.player.model.PlayerError

import 'error_type.dart';

class PlayerError {
  final ErrorType error;
  final String trackUri;
  final String contextUri;
  final String viewUri;
  final String reasons;

  const PlayerError({
    this.error = ErrorType.success,
    this.trackUri = '',
    this.contextUri = '',
    this.viewUri = '',
    this.reasons = '',
  });

  static PlayerErrorBuilder builder([ErrorType errorType = ErrorType.success]) =>
      PlayerErrorBuilder(error: errorType);

  PlayerErrorBuilder toBuilder() => PlayerErrorBuilder(
        error: error,
        trackUri: trackUri,
        contextUri: contextUri,
        viewUri: viewUri,
        reasons: reasons,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerError &&
          other.error == error &&
          other.trackUri == trackUri &&
          other.contextUri == contextUri &&
          other.viewUri == viewUri &&
          other.reasons == reasons);

  @override
  int get hashCode {
    var result = error.hashCode ^ 1000003;
    result = (result * 1000003) ^ trackUri.hashCode;
    result = (result * 1000003) ^ contextUri.hashCode;
    result = (result * 1000003) ^ viewUri.hashCode;
    result = (result * 1000003) ^ reasons.hashCode;
    return result;
  }

  @override
  String toString() =>
      'PlayerError{error=$error, '
      'trackUri=$trackUri, '
      'contextUri=$contextUri, '
      'viewUri=$viewUri, '
      'reasons=$reasons}';
}

class PlayerErrorBuilder {
  ErrorType _error;
  String _trackUri;
  String _contextUri;
  String _viewUri;
  String _reasons;

  PlayerErrorBuilder({
    ErrorType error = ErrorType.success,
    String trackUri = '',
    String contextUri = '',
    String viewUri = '',
    String reasons = '',
  })  : _error = error,
        _trackUri = trackUri,
        _contextUri = contextUri,
        _viewUri = viewUri,
        _reasons = reasons;

  PlayerErrorBuilder error(ErrorType errorType) {
    _error = errorType;
    return this;
  }

  PlayerErrorBuilder trackUri(String str) {
    _trackUri = str;
    return this;
  }

  PlayerErrorBuilder contextUri(String str) {
    _contextUri = str;
    return this;
  }

  PlayerErrorBuilder viewUri(String str) {
    _viewUri = str;
    return this;
  }

  PlayerErrorBuilder reasons(String str) {
    _reasons = str;
    return this;
  }

  PlayerError build() => PlayerError(
        error: _error,
        trackUri: _trackUri,
        contextUri: _contextUri,
        viewUri: _viewUri,
        reasons: _reasons,
      );
}
