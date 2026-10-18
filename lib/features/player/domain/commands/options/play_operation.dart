// 1:1 replica of com.spotify.player.model.command.options.PlayOperation

enum PlayOperation {
  replace,
  enqueue,
  push;

  static PlayOperation fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'ENQUEUE':
        return PlayOperation.enqueue;
      case 'PUSH':
        return PlayOperation.push;
      case 'REPLACE':
      default:
        return PlayOperation.replace;
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
