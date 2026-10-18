// 1:1 replica of com.spotify.player.model.PauseResumeOrigin

class PauseResumeOrigin {
  final String action;

  const PauseResumeOrigin({required this.action});

  static PauseResumeOrigin create(String action) =>
      PauseResumeOrigin(action: action);

  static PauseResumeOriginBuilder builder([String action = '']) =>
      PauseResumeOriginBuilder(action);

  PauseResumeOriginBuilder toBuilder() => PauseResumeOriginBuilder(action);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PauseResumeOrigin && other.action == action);

  @override
  int get hashCode => action.hashCode;

  @override
  String toString() => 'PauseResumeOrigin{action=$action}';
}

class PauseResumeOriginBuilder {
  String _action;

  PauseResumeOriginBuilder([this._action = '']);

  PauseResumeOriginBuilder action(String val) {
    _action = val;
    return this;
  }

  PauseResumeOrigin build() => PauseResumeOrigin(action: _action);
}
