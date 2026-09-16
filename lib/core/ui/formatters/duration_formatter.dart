abstract final class DurationFormatter {
  static String milliseconds(int milliseconds) {
    return duration(Duration(milliseconds: milliseconds));
  }

  static String duration(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
