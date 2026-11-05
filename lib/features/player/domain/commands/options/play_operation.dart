// 1:1 replica of com.spotify.player.model.command.options.PlayOperation

enum PlayOperation {
  replace,
  enqueue,
  push;

  static PlayOperation fromString(String value) {
    switch (value.toUpperCase()) {
      case 'REPLACE':
        return PlayOperation.replace;
      case 'ENQUEUE':
        return PlayOperation.enqueue;
      case 'PUSH':
        return PlayOperation.push;
      default:
        throw FormatException('Unknown PlayOperation: $value');
    }
  }

  String toJson() {
    switch (this) {
      case PlayOperation.replace:
        return 'REPLACE';
      case PlayOperation.enqueue:
        return 'ENQUEUE';
      case PlayOperation.push:
        return 'PUSH';
    }
  }
}
