// 1:1 replica of com.spotify.player.model.BitrateStrategy

enum BitrateStrategy {
  unknown,
  bestMatching,
  backendAdvised,
  offlinedFile,
  cachedFile,
  localFile;

  static BitrateStrategy fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'BEST_MATCHING':
        return BitrateStrategy.bestMatching;
      case 'BACKEND_ADVISED':
        return BitrateStrategy.backendAdvised;
      case 'OFFLINED_FILE':
        return BitrateStrategy.offlinedFile;
      case 'CACHED_FILE':
        return BitrateStrategy.cachedFile;
      case 'LOCAL_FILE':
        return BitrateStrategy.localFile;
      case 'UNKNOWN':
      default:
        return BitrateStrategy.unknown;
    }
  }

  String toJson() {
    switch (this) {
      case BitrateStrategy.bestMatching:
        return 'BEST_MATCHING';
      case BitrateStrategy.backendAdvised:
        return 'BACKEND_ADVISED';
      case BitrateStrategy.offlinedFile:
        return 'OFFLINED_FILE';
      case BitrateStrategy.cachedFile:
        return 'CACHED_FILE';
      case BitrateStrategy.localFile:
        return 'LOCAL_FILE';
      case BitrateStrategy.unknown:
        return 'UNKNOWN';
    }
  }
}
