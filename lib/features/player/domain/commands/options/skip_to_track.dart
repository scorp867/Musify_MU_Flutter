// 1:1 replica of com.spotify.player.model.command.options.SkipToTrack

class SkipToTrack {
  static final SkipToTrack empty = builder().build();

  final String? pageUrl;
  final int? pageIndex;
  final String? trackUid;
  final String? trackUri;
  final int? trackIndex;

  const SkipToTrack({
    this.pageUrl,
    this.pageIndex,
    this.trackUid,
    this.trackUri,
    this.trackIndex,
  });

  static SkipToTrackBuilder builder() => SkipToTrackBuilder();

  static SkipToTrack fromIndices(int? trackIndex, int? pageIndex) =>
      builder().trackIndex(trackIndex).pageIndex(pageIndex).build();

  static SkipToTrack fromUid(String trackUid) =>
      builder().trackUid(trackUid).build();

  static SkipToTrack fromUri(String trackUri) =>
      builder().trackUri(trackUri).build();

  SkipToTrackBuilder toBuilder() => SkipToTrackBuilder(
        pageUrl: pageUrl,
        pageIndex: pageIndex,
        trackUid: trackUid,
        trackUri: trackUri,
        trackIndex: trackIndex,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SkipToTrack &&
          other.pageUrl == pageUrl &&
          other.pageIndex == pageIndex &&
          other.trackUid == trackUid &&
          other.trackUri == trackUri &&
          other.trackIndex == trackIndex);

  @override
  int get hashCode => Object.hash(
        pageUrl,
        pageIndex,
        trackUid,
        trackUri,
        trackIndex,
      );

  @override
  String toString() =>
      'SkipToTrack{pageUrl=$pageUrl, pageIndex=$pageIndex, trackUid=$trackUid, trackUri=$trackUri, trackIndex=$trackIndex}';
}

class SkipToTrackBuilder {
  String? _pageUrl;
  int? _pageIndex;
  String? _trackUid;
  String? _trackUri;
  int? _trackIndex;

  SkipToTrackBuilder({
    String? pageUrl,
    int? pageIndex,
    String? trackUid,
    String? trackUri,
    int? trackIndex,
  })  : _pageUrl = pageUrl,
        _pageIndex = pageIndex,
        _trackUid = trackUid,
        _trackUri = trackUri,
        _trackIndex = trackIndex;

  static SkipToTrackBuilder builder() => SkipToTrack.builder();

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
        pageUrl: _pageUrl,
        pageIndex: _pageIndex,
        trackUid: _trackUid,
        trackUri: _trackUri,
        trackIndex: _trackIndex,
      );
}
