// 1:1 replica of com.spotify.player.model.command.options.PrefetchLevel

enum PrefetchLevel {
  none,
  media;

  static PrefetchLevel fromString(String value) {
    switch (value.toUpperCase()) {
      case 'NONE':
        return PrefetchLevel.none;
      case 'MEDIA':
        return PrefetchLevel.media;
      default:
        throw FormatException('Unknown PrefetchLevel: $value');
    }
  }

  String toJson() {
    switch (this) {
      case PrefetchLevel.none:
        return 'NONE';
      case PrefetchLevel.media:
        return 'MEDIA';
    }
  }
}
