/// 1:1 replica of Spotify Android's `Metadata.Episode.EpisodeType` (`key.f125862j`).
enum EpisodeType {
  full(1),
  trailer(2),
  bonus(3);

  final int code;

  const EpisodeType(this.code);
}
