/// 1:1 replica of Spotify's audio format enum (`p199p/ibc0.java`).
///
/// Encapsulates all 18 codec and container variants supported by Spotify's
/// metadata and streaming infrastructure.
enum SpotifyAudioFormat {
  oggVorbis96(0),
  oggVorbis160(1),
  oggVorbis320(2),
  mp3256(3),
  mp3320(4),
  mp3160(5),
  mp396(6),
  mp3160Enc(7),
  aac24(8),
  aac48(9),
  mp4128(10),
  mp4256(11),
  mp4128Dual(12),
  mp4256Dual(13),
  mp4128Cbcs(14),
  mp4256Cbcs(15),
  flacFlac(16),
  mp4Flac(17);

  final int number;

  const SpotifyAudioFormat(this.number);

  /// 1:1 replica of `ibc0.a(int i)`.
  static SpotifyAudioFormat? fromNumber(int number) {
    return switch (number) {
      0 => SpotifyAudioFormat.oggVorbis96,
      1 => SpotifyAudioFormat.oggVorbis160,
      2 => SpotifyAudioFormat.oggVorbis320,
      3 => SpotifyAudioFormat.mp3256,
      4 => SpotifyAudioFormat.mp3320,
      5 => SpotifyAudioFormat.mp3160,
      6 => SpotifyAudioFormat.mp396,
      7 => SpotifyAudioFormat.mp3160Enc,
      8 => SpotifyAudioFormat.aac24,
      9 => SpotifyAudioFormat.aac48,
      10 => SpotifyAudioFormat.mp4128,
      11 => SpotifyAudioFormat.mp4256,
      12 => SpotifyAudioFormat.mp4128Dual,
      13 => SpotifyAudioFormat.mp4256Dual,
      14 => SpotifyAudioFormat.mp4128Cbcs,
      15 => SpotifyAudioFormat.mp4256Cbcs,
      16 => SpotifyAudioFormat.flacFlac,
      17 => SpotifyAudioFormat.mp4Flac,
      _ => null,
    };
  }

  /// 1:1 replica of `getNumber()`.
  int getNumber() => number;

  bool get isVorbis =>
      this == SpotifyAudioFormat.oggVorbis96 ||
      this == SpotifyAudioFormat.oggVorbis160 ||
      this == SpotifyAudioFormat.oggVorbis320;

  bool get isMp4 =>
      this == SpotifyAudioFormat.mp4128 ||
      this == SpotifyAudioFormat.mp4256 ||
      this == SpotifyAudioFormat.mp4128Dual ||
      this == SpotifyAudioFormat.mp4256Dual ||
      this == SpotifyAudioFormat.mp4128Cbcs ||
      this == SpotifyAudioFormat.mp4256Cbcs ||
      this == SpotifyAudioFormat.mp4Flac;

  bool get isAac =>
      this == SpotifyAudioFormat.aac24 ||
      this == SpotifyAudioFormat.aac48 ||
      isMp4;
}
