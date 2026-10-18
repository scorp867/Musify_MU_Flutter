// 1:1 replica of com.spotify.player.model.AudioStream

enum AudioStream {
  defaultStream,
  alarm;

  static AudioStream fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'ALARM':
        return AudioStream.alarm;
      case 'DEFAULT':
      default:
        return AudioStream.defaultStream;
    }
  }

  String toJson() {
    switch (this) {
      case AudioStream.alarm:
        return 'ALARM';
      case AudioStream.defaultStream:
        return 'DEFAULT';
    }
  }
}
