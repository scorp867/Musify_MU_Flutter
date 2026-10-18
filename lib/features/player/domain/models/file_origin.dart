// 1:1 replica of com.spotify.player.model.FileOrigin

enum FileOrigin {
  unknown,
  internal,
  external,
  local,
  generated;

  static FileOrigin fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'INTERNAL':
        return FileOrigin.internal;
      case 'EXTERNAL':
        return FileOrigin.external;
      case 'LOCAL':
        return FileOrigin.local;
      case 'GENERATED':
        return FileOrigin.generated;
      case 'UNKNOWN':
      default:
        return FileOrigin.unknown;
    }
  }

  String toJson() {
    switch (this) {
      case FileOrigin.internal:
        return 'INTERNAL';
      case FileOrigin.external:
        return 'EXTERNAL';
      case FileOrigin.local:
        return 'LOCAL';
      case FileOrigin.generated:
        return 'GENERATED';
      case FileOrigin.unknown:
        return 'UNKNOWN';
    }
  }
}
