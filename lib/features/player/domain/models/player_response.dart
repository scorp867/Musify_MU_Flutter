// 1:1 replica of Spotify player response model (p.png, p.mng, p.lng).

sealed class PlayerResponse {
  const PlayerResponse();

  static const PlayerResponse success = PlayerResponseSuccess();

  const factory PlayerResponse.failure(String reasons) = PlayerResponseFailure;

  bool get isSuccess => this is PlayerResponseSuccess;
  bool get isFailure => this is PlayerResponseFailure;
}

// 1:1 replica of Spotify Success response (p.mng).
final class PlayerResponseSuccess extends PlayerResponse {
  const PlayerResponseSuccess();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PlayerResponseSuccess;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'Success{}';
}

// 1:1 replica of Spotify Failure response (p.lng).
final class PlayerResponseFailure extends PlayerResponse {
  final String reasons;

  const PlayerResponseFailure(this.reasons);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerResponseFailure && other.reasons == reasons);

  @override
  int get hashCode => reasons.hashCode;

  @override
  String toString() => 'Failure{reasons=$reasons}';
}
