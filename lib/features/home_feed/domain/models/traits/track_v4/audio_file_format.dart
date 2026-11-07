/// 1:1 replica of Spotify Android's `p199p/i3i0.java` (`AudioFileFormat`).
enum AudioFileFormat {
  oggVorbis96(0),
  oggVorbis160(1),
  oggVorbis320(2),
  mp3_256(3),
  mp3_320(4),
  mp3_160(5),
  mp3_96(6),
  mp3_160Enc(7),
  aac24(8),
  aac48(9),
  mp4_128(10),
  mp4_256(11),
  mp4_128Dual(12),
  mp4_256Dual(13),
  mp4_128Cbcs(14),
  mp4_256Cbcs(15),
  flacFlac(16),
  mp4Flac(17),
  unknown(-1);

  final int value;

  const AudioFileFormat(this.value);

  static AudioFileFormat fromValue(int value) {
    for (final format in AudioFileFormat.values) {
      if (format.value == value) {
        return format;
      }
    }
    return AudioFileFormat.unknown;
  }
}
