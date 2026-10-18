// 1:1 replica of com.spotify.player.model.PlaybackQuality

import 'bitrate_level.dart';
import 'bitrate_strategy.dart';
import 'file_origin.dart';
import 'hifi_status.dart';

class PlaybackQuality {
  static const PlaybackQuality empty = PlaybackQuality(
    bitrateLevel: BitrateLevel.unknown,
    strategy: BitrateStrategy.unknown,
    targetBitrateLevel: BitrateLevel.unknown,
    targetBitrateAvailable: false,
    hifiStatus: HiFiStatus.none,
    highestAvailableQuality: BitrateLevel.unknown,
    fileOrigin: FileOrigin.unknown,
  );

  final BitrateLevel bitrateLevel;
  final BitrateStrategy strategy;
  final BitrateLevel targetBitrateLevel;
  final bool targetBitrateAvailable;
  final HiFiStatus hifiStatus;
  final BitrateLevel highestAvailableQuality;
  final FileOrigin fileOrigin;

  const PlaybackQuality({
    this.bitrateLevel = BitrateLevel.unknown,
    this.strategy = BitrateStrategy.unknown,
    this.targetBitrateLevel = BitrateLevel.unknown,
    this.targetBitrateAvailable = false,
    this.hifiStatus = HiFiStatus.none,
    this.highestAvailableQuality = BitrateLevel.unknown,
    this.fileOrigin = FileOrigin.unknown,
  });

  static PlaybackQualityBuilder builder() => PlaybackQualityBuilder();

  PlaybackQualityBuilder toBuilder() => PlaybackQualityBuilder(
        bitrateLevel: bitrateLevel,
        strategy: strategy,
        targetBitrateLevel: targetBitrateLevel,
        targetBitrateAvailable: targetBitrateAvailable,
        hifiStatus: hifiStatus,
        highestAvailableQuality: highestAvailableQuality,
        fileOrigin: fileOrigin,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackQuality &&
          other.bitrateLevel == bitrateLevel &&
          other.strategy == strategy &&
          other.targetBitrateLevel == targetBitrateLevel &&
          other.targetBitrateAvailable == targetBitrateAvailable &&
          other.hifiStatus == hifiStatus &&
          other.highestAvailableQuality == highestAvailableQuality &&
          other.fileOrigin == fileOrigin);

  @override
  int get hashCode => Object.hash(
        bitrateLevel,
        strategy,
        targetBitrateLevel,
        targetBitrateAvailable,
        hifiStatus,
        highestAvailableQuality,
        fileOrigin,
      );

  @override
  String toString() =>
      'PlaybackQuality{bitrateLevel=$bitrateLevel, strategy=$strategy, targetBitrateLevel=$targetBitrateLevel, targetBitrateAvailable=$targetBitrateAvailable, hifiStatus=$hifiStatus, highestAvailableQuality=$highestAvailableQuality, fileOrigin=$fileOrigin}';
}

class PlaybackQualityBuilder {
  BitrateLevel _bitrateLevel;
  BitrateStrategy _strategy;
  BitrateLevel _targetBitrateLevel;
  bool _targetBitrateAvailable;
  HiFiStatus _hifiStatus;
  BitrateLevel _highestAvailableQuality;
  FileOrigin _fileOrigin;

  PlaybackQualityBuilder({
    BitrateLevel bitrateLevel = BitrateLevel.unknown,
    BitrateStrategy strategy = BitrateStrategy.unknown,
    BitrateLevel targetBitrateLevel = BitrateLevel.unknown,
    bool targetBitrateAvailable = false,
    HiFiStatus hifiStatus = HiFiStatus.none,
    BitrateLevel highestAvailableQuality = BitrateLevel.unknown,
    FileOrigin fileOrigin = FileOrigin.unknown,
  })  : _bitrateLevel = bitrateLevel,
        _strategy = strategy,
        _targetBitrateLevel = targetBitrateLevel,
        _targetBitrateAvailable = targetBitrateAvailable,
        _hifiStatus = hifiStatus,
        _highestAvailableQuality = highestAvailableQuality,
        _fileOrigin = fileOrigin;

  PlaybackQualityBuilder bitrateLevel(BitrateLevel val) {
    _bitrateLevel = val;
    return this;
  }

  PlaybackQualityBuilder strategy(BitrateStrategy val) {
    _strategy = val;
    return this;
  }

  PlaybackQualityBuilder targetBitrateLevel(BitrateLevel val) {
    _targetBitrateLevel = val;
    return this;
  }

  PlaybackQualityBuilder targetBitrateAvailable(bool val) {
    _targetBitrateAvailable = val;
    return this;
  }

  PlaybackQualityBuilder hifiStatus(HiFiStatus val) {
    _hifiStatus = val;
    return this;
  }

  PlaybackQualityBuilder highestAvailableQuality(BitrateLevel val) {
    _highestAvailableQuality = val;
    return this;
  }

  PlaybackQualityBuilder fileOrigin(FileOrigin val) {
    _fileOrigin = val;
    return this;
  }

  PlaybackQuality build() => PlaybackQuality(
        bitrateLevel: _bitrateLevel,
        strategy: _strategy,
        targetBitrateLevel: _targetBitrateLevel,
        targetBitrateAvailable: _targetBitrateAvailable,
        hifiStatus: _hifiStatus,
        highestAvailableQuality: _highestAvailableQuality,
        fileOrigin: _fileOrigin,
      );
}
