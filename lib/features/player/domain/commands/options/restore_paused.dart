// 1:1 replica of com.spotify.player.model.command.options.RestorePaused

enum RestorePaused {
  restore,
  pause,
  resume;

  static RestorePaused fromString(String value) {
    switch (value.toUpperCase()) {
      case 'RESTORE':
        return RestorePaused.restore;
      case 'PAUSE':
        return RestorePaused.pause;
      case 'RESUME':
        return RestorePaused.resume;
      default:
        throw FormatException('Unknown RestorePaused: $value');
    }
  }

  String toJson() {
    switch (this) {
      case RestorePaused.restore:
        return 'RESTORE';
      case RestorePaused.pause:
        return 'PAUSE';
      case RestorePaused.resume:
        return 'RESUME';
    }
  }
}
