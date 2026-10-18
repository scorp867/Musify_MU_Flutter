// 1:1 replica of com.spotify.player.model.BitrateLevel

enum BitrateLevel {
  unknown,
  low,
  normal,
  high,
  veryHigh,
  hifi,
  hifi24;

  static BitrateLevel fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'LOW':
        return BitrateLevel.low;
      case 'NORMAL':
        return BitrateLevel.normal;
      case 'HIGH':
        return BitrateLevel.high;
      case 'VERY_HIGH':
        return BitrateLevel.veryHigh;
      case 'HIFI':
        return BitrateLevel.hifi;
      case 'HIFI_24':
      case 'HIFI24':
        return BitrateLevel.hifi24;
      case 'UNKNOWN':
      default:
        return BitrateLevel.unknown;
    }
  }

  String toJson() {
    switch (this) {
      case BitrateLevel.low:
        return 'LOW';
      case BitrateLevel.normal:
        return 'NORMAL';
      case BitrateLevel.high:
        return 'HIGH';
      case BitrateLevel.veryHigh:
        return 'VERY_HIGH';
      case BitrateLevel.hifi:
        return 'HIFI';
      case BitrateLevel.hifi24:
        return 'HIFI_24';
      case BitrateLevel.unknown:
        return 'UNKNOWN';
    }
  }
}
