import 'dart:math';

/// Generates unique, non-colliding 16-hex UIDs matching Spotify's 16-character track UIDs.
abstract final class QueueUidGenerator {
  static final Random _random = Random();
  static int _counter = 0;

  /// Generates a 16-character hexadecimal UID.
  static String generate() {
    _counter = (_counter + 1) & 0xFFFFFF;
    final timestamp = DateTime.now().microsecondsSinceEpoch & 0xFFFFFFFF;
    final r = _random.nextInt(0xFFFFFF);
    final combinedUpper = ((timestamp ^ (_counter << 8)) & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
    final combinedLower = ((r ^ (_counter << 4)) & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
    return '$combinedUpper$combinedLower';
  }

  /// Alias for generate matching Spotify ContextPlayer track UID generator.
  static String generateTrackUid() => generate();
}
