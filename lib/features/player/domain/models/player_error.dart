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
  int get hashCode => Object.hash(
        error,
        trackUri,
        contextUri,
        viewUri,
        reasons,
      );

  @override
  String toString() =>
      'PlayerError{error=$error, trackUri=$trackUri, contextUri=$contextUri, viewUri=$viewUri, reasons=$reasons}';
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

  PlayerErrorBuilder error(ErrorType val) {
    _error = val;
    return this;
  }

  PlayerErrorBuilder trackUri(String val) {
    _trackUri = val;
    return this;
  }

  PlayerErrorBuilder contextUri(String val) {
    _contextUri = val;
    return this;
  }

  PlayerErrorBuilder viewUri(String val) {
    _viewUri = val;
    return this;
  }

  PlayerErrorBuilder reasons(String val) {
    _reasons = val;
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
