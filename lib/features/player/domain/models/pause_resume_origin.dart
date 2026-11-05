// 1:1 replica of com.spotify.player.model.PauseResumeOrigin

class PauseResumeOrigin {
  final String featureIdentifier;

  const PauseResumeOrigin({required this.featureIdentifier});

  // Backward compatibility alias
  String get action => featureIdentifier;

  static PauseResumeOrigin create(String featureIdentifier) =>
      builder(featureIdentifier).build();

  static PauseResumeOriginBuilder builder([String featureIdentifier = '']) =>
      PauseResumeOriginBuilder(featureIdentifier: featureIdentifier);

  PauseResumeOriginBuilder toBuilder() =>
      PauseResumeOriginBuilder(featureIdentifier: featureIdentifier);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PauseResumeOrigin &&
          other.featureIdentifier == featureIdentifier);

  @override
  int get hashCode => featureIdentifier.hashCode ^ 1000003;

  @override
  String toString() =>
      'PauseResumeOrigin{featureIdentifier=$featureIdentifier}';
}

class PauseResumeOriginBuilder {
  String _featureIdentifier;

  PauseResumeOriginBuilder({String featureIdentifier = ''})
      : _featureIdentifier = featureIdentifier;

  PauseResumeOriginBuilder featureIdentifier(String str) {
    _featureIdentifier = str;
    return this;
  }

  // Backward compatibility alias
  PauseResumeOriginBuilder action(String val) => featureIdentifier(val);

  PauseResumeOrigin build() =>
      PauseResumeOrigin(featureIdentifier: _featureIdentifier);
}
