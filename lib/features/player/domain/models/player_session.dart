// 1:1 replica of com.spotify.player.model.PlayerSession

class PlayerSession {
  final String session;

  const PlayerSession({required this.session});

  static PlayerSession create(String session) =>
      builder(session).build();

  static PlayerSessionBuilder builder([String session = '']) =>
      PlayerSessionBuilder(session: session);

  PlayerSessionBuilder toBuilder() =>
      PlayerSessionBuilder(session: session);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerSession && other.session == session);

  @override
  int get hashCode => session.hashCode ^ 1000003;

  @override
  String toString() => 'PlayerSession{session=$session}';
}

class PlayerSessionBuilder {
  String _session;

  PlayerSessionBuilder({String session = ''}) : _session = session;

  PlayerSessionBuilder session(String str) {
    _session = str;
    return this;
  }

  PlayerSession build() => PlayerSession(session: _session);
}
