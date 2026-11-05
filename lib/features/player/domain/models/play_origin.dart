// 1:1 replica of com.spotify.player.model.PlayOrigin

import 'dart:collection';

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
  int get hashCode {
    var result = featureIdentifier.hashCode ^ 1000003;
    result = (result * 1000003) ^ featureVersion.hashCode;
    result = (result * 1000003) ^ viewUri.hashCode;
    result = (result * 1000003) ^ externalReferrer.hashCode;
    result = (result * 1000003) ^ referrerIdentifier.hashCode;
    result = (result * 1000003) ^ deviceIdentifier.hashCode;
    result = (result * 1000003) ^ Object.hashAll(featureClasses);
    result = (result * 1000003) ^ restrictionIdentifier.hashCode;
    return result;
  }

  @override
  String toString() =>
      'PlayOrigin{featureIdentifier=$featureIdentifier, '
      'featureVersion=$featureVersion, '
      'viewUri=$viewUri, '
      'externalReferrer=$externalReferrer, '
      'referrerIdentifier=$referrerIdentifier, '
      'deviceIdentifier=$deviceIdentifier, '
      'featureClasses=$featureClasses, '
      'restrictionIdentifier=$restrictionIdentifier}';
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

  PlayOriginBuilder featureIdentifier(String str) {
    _featureIdentifier = str;
    return this;
  }

  PlayOriginBuilder featureVersion(String str) {
    _featureVersion = str;
    return this;
  }

  PlayOriginBuilder viewUri(String str) {
    _viewUri = str;
    return this;
  }

  PlayOriginBuilder externalReferrer(String str) {
    _externalReferrer = str;
    return this;
  }

  PlayOriginBuilder referrerIdentifier(String str) {
    _referrerIdentifier = str;
    return this;
  }

  PlayOriginBuilder deviceIdentifier(String str) {
    _deviceIdentifier = str;
    return this;
  }

  PlayOriginBuilder featureClasses(Set<String> set) {
    _featureClasses = Set<String>.from(set);
    return this;
  }

  PlayOriginBuilder restrictionIdentifier(String str) {
    _restrictionIdentifier = str;
    return this;
  }

  PlayOrigin build() => PlayOrigin(
        featureIdentifier: _featureIdentifier,
        featureVersion: _featureVersion,
        viewUri: _viewUri,
        externalReferrer: _externalReferrer,
        referrerIdentifier: _referrerIdentifier,
        deviceIdentifier: _deviceIdentifier,
        featureClasses: UnmodifiableSetView<String>(_featureClasses),
        restrictionIdentifier: _restrictionIdentifier,
      );
}
