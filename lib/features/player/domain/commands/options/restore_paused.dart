// 1:1 replica of com.spotify.player.model.command.options.RestorePaused

enum RestorePaused {
  restore,
  pause,
  resume;

  static RestorePaused fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'PAUSE':
        return RestorePaused.pause;
      case 'RESUME':
        return RestorePaused.resume;
      case 'RESTORE':
      default:
        return RestorePaused.restore;
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
