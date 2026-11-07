/// 1:1 Spotify `com.spotify.localfiles.proto.LocalFile$Metadata$ImageState`.
enum LocalFileImageState {
  unknown(0),
  available(1),
  unavailable(2);

  final int value;

  const LocalFileImageState(this.value);

  static LocalFileImageState fromValue(int value) => switch (value) {
    1 => LocalFileImageState.available,
    2 => LocalFileImageState.unavailable,
    _ => LocalFileImageState.unknown,
  };
}
