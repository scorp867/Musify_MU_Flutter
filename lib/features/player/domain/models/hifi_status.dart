// 1:1 replica of com.spotify.player.model.HiFiStatus

enum HiFiStatus {
  none,
  off,
  on;

  static HiFiStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'OFF':
        return HiFiStatus.off;
      case 'ON':
        return HiFiStatus.on;
      case 'NONE':
      default:
        return HiFiStatus.none;
    }
  }

  String toJson() {
    switch (this) {
      case HiFiStatus.off:
        return 'OFF';
      case HiFiStatus.on:
        return 'ON';
      case HiFiStatus.none:
        return 'NONE';
    }
  }
}
