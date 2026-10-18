// 1:1 replica of com.spotify.player.model.command.options.SkipToTrack

class SkipToTrack {
  static final SkipToTrack empty = builder().build();

  final int? pageIndex;
  final String? pageUrl;
  final int? trackIndex;
  final String? trackUid;
  final String? trackUri;

  const SkipToTrack({
    this.pageIndex,
    this.pageUrl,
    this.trackIndex,
    this.trackUid,
    this.trackUri,
  });

  static SkipToTrackBuilder builder() => SkipToTrackBuilder();

  static SkipToTrack fromIndices(int? trackIndex, int? pageIndex) =>
      builder().trackIndex(trackIndex).pageIndex(pageIndex).build();

  static SkipToTrack fromUid(String uid) =>
      builder().trackUid(uid).build();

  static SkipToTrack fromUri(String uri) =>
      builder().trackUri(uri).build();

  SkipToTrackBuilder toBuilder() => SkipToTrackBuilder(
        pageIndex: pageIndex,
        pageUrl: pageUrl,
        trackIndex: trackIndex,
        trackUid: trackUid,
        trackUri: trackUri,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SkipToTrack &&
          other.pageIndex == pageIndex &&
          other.pageUrl == pageUrl &&
          other.trackIndex == trackIndex &&
          other.trackUid == trackUid &&
          other.trackUri == trackUri);

  @override
  int get hashCode => Object.hash(
        pageIndex,
        pageUrl,
        trackIndex,
        trackUid,
        trackUri,
      );

  @override
  String toString() =>
      'SkipToTrack{pageIndex=$pageIndex, pageUrl=$pageUrl, trackIndex=$trackIndex, trackUid=$trackUid, trackUri=$trackUri}';
}

class SkipToTrackBuilder {
  int? _pageIndex;
  String? _pageUrl;
  int? _trackIndex;
  String? _trackUid;
  String? _trackUri;

  SkipToTrackBuilder({
    int? pageIndex,
    String? pageUrl,
    int? trackIndex,
    String? trackUid,
    String? trackUri,
  })  : _pageIndex = pageIndex,
        _pageUrl = pageUrl,
        _trackIndex = trackIndex,
        _trackUid = trackUid,
        _trackUri = trackUri;

  SkipToTrackBuilder pageIndex(int? val) {
    _pageIndex = val;
    return this;
  }

  SkipToTrackBuilder pageUrl(String? val) {
    _pageUrl = val;
    return this;
  }

  SkipToTrackBuilder trackIndex(int? val) {
    _trackIndex = val;
    return this;
  }

  SkipToTrackBuilder trackUid(String? val) {
    _trackUid = val;
    return this;
  }

  SkipToTrackBuilder trackUri(String? val) {
    _trackUri = val;
    return this;
  }

  SkipToTrack build() => SkipToTrack(
        pageIndex: _pageIndex,
        pageUrl: _pageUrl,
        trackIndex: _trackIndex,
        trackUid: _trackUid,
        trackUri: _trackUri,
      );
}
