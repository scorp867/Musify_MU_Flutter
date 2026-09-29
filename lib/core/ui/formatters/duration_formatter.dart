abstract final class DurationFormatter {
  static String milliseconds(int milliseconds) {
    return duration(Duration(milliseconds: milliseconds.abs()));
  }

  static String duration(Duration value) {
    if (value.isNegative) value = Duration.zero;
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    final seconds = value.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
