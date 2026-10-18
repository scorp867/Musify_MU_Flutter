// 1:1 replica of com.spotify.player.model.command.options.PrefetchLevel

enum PrefetchLevel {
  none,
  media;

  static PrefetchLevel fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'MEDIA':
        return PrefetchLevel.media;
      case 'NONE':
      default:
        return PrefetchLevel.none;
    }
  }

  String toJson() {
    switch (this) {
      case PrefetchLevel.media:
        return 'MEDIA';
      case PrefetchLevel.none:
        return 'NONE';
    }
  }
}
