// 1:1 replica of com.spotify.player.model.ContextPage

import 'context_track.dart';

class ContextPage {
  static final ContextPage empty = builder().build();

  final String pageUrl;
  final String nextPageUrl;
  final Map<String, String> metadata;
  final List<ContextTrack>? tracks;

  const ContextPage({
    this.pageUrl = '',
    this.nextPageUrl = '',
    this.metadata = const <String, String>{},
    this.tracks,
  });

  static ContextPageBuilder builder() => ContextPageBuilder();

  ContextPageBuilder toBuilder() => ContextPageBuilder(
        pageUrl: pageUrl,
        nextPageUrl: nextPageUrl,
        metadata: metadata,
        tracks: tracks,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContextPage &&
          other.pageUrl == pageUrl &&
          other.nextPageUrl == nextPageUrl &&
          _mapEquals(other.metadata, metadata) &&
          _listEquals(other.tracks, tracks));

  @override
  int get hashCode => Object.hash(
        pageUrl,
        nextPageUrl,
        Object.hashAll(metadata.entries.map((e) => Object.hash(e.key, e.value))),
        tracks != null ? Object.hashAll(tracks!) : null,
      );

  @override
  String toString() =>
      'ContextPage{pageUrl=$pageUrl, nextPageUrl=$nextPageUrl, metadata=$metadata, tracks=$tracks}';

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (b[key] != a[key]) return false;
    }
    return true;
  }

  static bool _listEquals(List<ContextTrack>? a, List<ContextTrack>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class ContextPageBuilder {
  String _pageUrl;
  String _nextPageUrl;
  Map<String, String> _metadata;
  List<ContextTrack>? _tracks;

  ContextPageBuilder({
    String pageUrl = '',
    String nextPageUrl = '',
    Map<String, String> metadata = const <String, String>{},
    List<ContextTrack>? tracks,
  })  : _pageUrl = pageUrl,
        _nextPageUrl = nextPageUrl,
        _metadata = Map<String, String>.from(metadata),
        _tracks = tracks != null ? List<ContextTrack>.from(tracks) : null;

  ContextPageBuilder pageUrl(String val) {
    _pageUrl = val;
    return this;
  }

  ContextPageBuilder nextPageUrl(String val) {
    _nextPageUrl = val;
    return this;
  }

  ContextPageBuilder metadata(Map<String, String> val) {
    _metadata = Map<String, String>.from(val);
    return this;
  }

  ContextPageBuilder tracks(List<ContextTrack> val) {
    _tracks = List<ContextTrack>.from(val);
    return this;
  }

  ContextPage build() => ContextPage(
        pageUrl: _pageUrl,
        nextPageUrl: _nextPageUrl,
        metadata: Map<String, String>.unmodifiable(_metadata),
        tracks: _tracks != null ? List<ContextTrack>.unmodifiable(_tracks!) : null,
      );
}
