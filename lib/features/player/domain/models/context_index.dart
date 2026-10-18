// 1:1 replica of com.spotify.player.model.ContextIndex

class ContextIndex {
  final int page;
  final int track;

  const ContextIndex({this.page = 0, this.track = 0});

  static ContextIndex create([int page = 0, int track = 0]) =>
      ContextIndex(page: page, track: track);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContextIndex &&
          other.page == page &&
          other.track == track);

  @override
  int get hashCode => Object.hash(page, track);

  @override
  String toString() => 'ContextIndex{page=$page, track=$track}';
}
