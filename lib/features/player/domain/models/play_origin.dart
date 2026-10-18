// 1:1 replica of com.spotify.player.model.PlayOrigin

class PlayOrigin {
  final String featureIdentifier;
  final String featureVersion;
  final String viewUri;
  final String externalReferrer;
  final String referrerIdentifier;
  final String deviceIdentifier;
  final Set<String> featureClasses;
  final String restrictionIdentifier;

  const PlayOrigin({
    this.featureIdentifier = '',
    this.featureVersion = '',
    this.viewUri = '',
    this.externalReferrer = '',
    this.referrerIdentifier = '',
    this.deviceIdentifier = '',
    this.featureClasses = const <String>{},
    this.restrictionIdentifier = '',
  });

  static PlayOrigin create(String featureIdentifier) =>
      builder(featureIdentifier).build();

  static PlayOriginBuilder builder([String featureIdentifier = '']) =>
      PlayOriginBuilder(featureIdentifier: featureIdentifier);

  PlayOriginBuilder toBuilder() => PlayOriginBuilder(
        featureIdentifier: featureIdentifier,
        featureVersion: featureVersion,
        viewUri: viewUri,
        externalReferrer: externalReferrer,
        referrerIdentifier: referrerIdentifier,
        deviceIdentifier: deviceIdentifier,
        featureClasses: featureClasses,
        restrictionIdentifier: restrictionIdentifier,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayOrigin &&
          other.featureIdentifier == featureIdentifier &&
          other.featureVersion == featureVersion &&
          other.viewUri == viewUri &&
          other.externalReferrer == externalReferrer &&
          other.referrerIdentifier == referrerIdentifier &&
          other.deviceIdentifier == deviceIdentifier &&
          other.restrictionIdentifier == restrictionIdentifier &&
          other.featureClasses.length == featureClasses.length &&
          other.featureClasses.containsAll(featureClasses));

  @override
  int get hashCode => Object.hash(
        featureIdentifier,
        featureVersion,
        viewUri,
        externalReferrer,
        referrerIdentifier,
        deviceIdentifier,
        restrictionIdentifier,
        Object.hashAll(featureClasses),
      );

  @override
  String toString() =>
      'PlayOrigin{featureIdentifier=$featureIdentifier, featureVersion=$featureVersion, viewUri=$viewUri, externalReferrer=$externalReferrer, referrerIdentifier=$referrerIdentifier, deviceIdentifier=$deviceIdentifier, featureClasses=$featureClasses, restrictionIdentifier=$restrictionIdentifier}';
}

class PlayOriginBuilder {
  String _featureIdentifier;
  String _featureVersion;
  String _viewUri;
  String _externalReferrer;
  String _referrerIdentifier;
  String _deviceIdentifier;
  Set<String> _featureClasses;
  String _restrictionIdentifier;

  PlayOriginBuilder({
    String featureIdentifier = '',
    String featureVersion = '',
    String viewUri = '',
    String externalReferrer = '',
    String referrerIdentifier = '',
    String deviceIdentifier = '',
    Set<String> featureClasses = const <String>{},
    String restrictionIdentifier = '',
  })  : _featureIdentifier = featureIdentifier,
        _featureVersion = featureVersion,
        _viewUri = viewUri,
        _externalReferrer = externalReferrer,
        _referrerIdentifier = referrerIdentifier,
        _deviceIdentifier = deviceIdentifier,
        _featureClasses = Set<String>.from(featureClasses),
        _restrictionIdentifier = restrictionIdentifier;

  PlayOriginBuilder featureIdentifier(String val) {
    _featureIdentifier = val;
    return this;
  }

  PlayOriginBuilder featureVersion(String val) {
    _featureVersion = val;
    return this;
  }

  PlayOriginBuilder viewUri(String val) {
    _viewUri = val;
    return this;
  }

  PlayOriginBuilder externalReferrer(String val) {
    _externalReferrer = val;
    return this;
  }

  PlayOriginBuilder referrerIdentifier(String val) {
    _referrerIdentifier = val;
    return this;
  }

  PlayOriginBuilder deviceIdentifier(String val) {
    _deviceIdentifier = val;
    return this;
  }

  PlayOriginBuilder featureClasses(Set<String> val) {
    _featureClasses = Set<String>.from(val);
    return this;
  }

  PlayOriginBuilder restrictionIdentifier(String val) {
    _restrictionIdentifier = val;
    return this;
  }

  PlayOrigin build() => PlayOrigin(
        featureIdentifier: _featureIdentifier,
        featureVersion: _featureVersion,
        viewUri: _viewUri,
        externalReferrer: _externalReferrer,
        referrerIdentifier: _referrerIdentifier,
        deviceIdentifier: _deviceIdentifier,
        featureClasses: Set<String>.unmodifiable(_featureClasses),
        restrictionIdentifier: _restrictionIdentifier,
      );
}
