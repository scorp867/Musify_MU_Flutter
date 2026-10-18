// 1:1 replica of com.spotify.player.model.Format

enum Format {
  unknown,
  defaultFormat,
  parrot;

  static Format fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'DEFAULT':
        return Format.defaultFormat;
      case 'PARROT':
        return Format.parrot;
      case 'UNKNOWN':
      default:
        return Format.unknown;
    }
  }

  String toJson() {
    switch (this) {
      case Format.defaultFormat:
        return 'DEFAULT';
      case Format.parrot:
        return 'PARROT';
      case Format.unknown:
        return 'UNKNOWN';
    }
  }
}
