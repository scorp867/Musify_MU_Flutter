// 1:1 replica of com.spotify.player.model.PlayerSession

class PlayerSession {
  final String session;

  const PlayerSession({required this.session});

  static PlayerSession create(String session) =>
      PlayerSession(session: session);

  static PlayerSessionBuilder builder([String session = '']) =>
      PlayerSessionBuilder(session);

  PlayerSessionBuilder toBuilder() => PlayerSessionBuilder(session);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerSession && other.session == session);

  @override
  int get hashCode => session.hashCode;

  @override
  String toString() => 'PlayerSession{session=$session}';
}

class PlayerSessionBuilder {
  String _session;

  PlayerSessionBuilder([this._session = '']);

  PlayerSessionBuilder session(String val) {
    _session = val;
    return this;
  }

  PlayerSession build() => PlayerSession(session: _session);
}
