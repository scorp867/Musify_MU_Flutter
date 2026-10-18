// 1:1 replica of com.spotify.player.model.Context

import 'context_page.dart';
import 'context_track.dart';
import 'restrictions.dart';

class Context {
  final String uri;
  final String url;
  final Map<String, String> metadata;
  final List<ContextPage>? pages;
  final Restrictions? restrictions;

  const Context({
    required this.uri,
    this.url = '',
    this.metadata = const <String, String>{},
    this.pages,
    this.restrictions,
  });

  static ContextBuilder builder([String uri = '']) =>
      ContextBuilder(uri: uri);

  static Context fromUri(String uri) =>
      builder(uri).url('context://$uri').build();

  static Context fromTrackUris(String uri, List<String> trackUris) {
    final tracks = trackUris.map((tUri) => ContextTrack.create(tUri)).toList();
    return builder(uri)
        .pages([ContextPage.builder().tracks(tracks).build()])
        .build();
  }

  ContextBuilder toBuilder() => ContextBuilder(
        uri: uri,
        url: url,
        metadata: metadata,
        pages: pages,
        restrictions: restrictions,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Context &&
          other.uri == uri &&
          other.url == url &&
          _mapEquals(other.metadata, metadata) &&
          _listEquals(other.pages, pages) &&
          other.restrictions == restrictions);

  @override
  int get hashCode => Object.hash(
        uri,
        url,
        Object.hashAll(metadata.entries.map((e) => Object.hash(e.key, e.value))),
        pages != null ? Object.hashAll(pages!) : null,
        restrictions,
      );

  @override
  String toString() =>
      'Context{uri=$uri, url=$url, metadata=$metadata, pages=$pages, restrictions=$restrictions}';

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (b[key] != a[key]) return false;
    }
    return true;
  }

  static bool _listEquals(List<ContextPage>? a, List<ContextPage>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class ContextBuilder {
  String _uri;
  String _url;
  Map<String, String> _metadata;
  List<ContextPage>? _pages;
  Restrictions? _restrictions;

  ContextBuilder({
    String uri = '',
    String url = '',
    Map<String, String> metadata = const <String, String>{},
    List<ContextPage>? pages,
    Restrictions? restrictions,
  })  : _uri = uri,
        _url = url,
        _metadata = Map<String, String>.from(metadata),
        _pages = pages != null ? List<ContextPage>.from(pages) : null,
        _restrictions = restrictions;

  ContextBuilder uri(String val) {
    _uri = val;
    return this;
  }

  ContextBuilder url(String val) {
    _url = val;
    return this;
  }

  ContextBuilder metadata(Map<String, String> val) {
    _metadata = Map<String, String>.from(val);
    return this;
  }

  ContextBuilder pages(List<ContextPage> val) {
    _pages = List<ContextPage>.from(val);
    return this;
  }

  ContextBuilder restrictions(Restrictions val) {
    _restrictions = val;
    return this;
  }

  Context build() => Context(
        uri: _uri,
        url: _url,
        metadata: Map<String, String>.unmodifiable(_metadata),
        pages: _pages != null ? List<ContextPage>.unmodifiable(_pages!) : null,
        restrictions: _restrictions,
      );
}

abstract class ContextMetadata {
  static const String keyAutoplayCandidate = 'autoplay_candidate';
  static const String keyContextDescription = 'context_description';
  static const String keyContextLongDescription = 'context_long_description';
  static const String keyContextOwner = 'context_owner';
  static const String keyDuration = 'duration';
  static const String keyEndContextAction = 'end_of_context_action';
  static const String keyFilteringPredicate = 'filtering.predicate';
  static const String keyFormatListType = 'format_list_type';
  static const String keyImageLargeUrl = 'image_large_url';
  static const String keyImageSmallUrl = 'image_small_url';
  static const String keyImageUrl = 'image_url';
  static const String keyImageXlargeUrl = 'image_xlarge_url';
  static const String keyInterruptionManifestIds = 'mod.interruption_manifest_ids';
  static const String keyIsAlgotorial = 'isAlgotorial';
  static const String keyIsAudiobook = 'is_audiobook';
  static const String keyIsDataSaverContext = 'is_data_saver_context';
  static const String keyIsLoading = 'is_loading';
  static const String keyIsMusicVideoContext = 'is_music_video_context';
  static const String keyIsStripped = 'is_stripped';
  static const String keyLicense = 'license';
  static const String keyLicenseOnDemandWhenFree = 'mobile_on_demand';
  static const String keyMediaType = 'media.type';
  static const String keyReportingUri = 'reporting.uri';
  static const String keyShuffleAlgorithm = 'shuffle.algorithm';
  static const String keySortingCriteria = 'sorting.criteria';
  static const String keyTrackCount = 'track_count';
  static const String keyTransformingFailed = 'transforming.failed';
  static const String keyTransformingOngoing = 'transforming.ongoing';
  static const String keyTransformingShuffle = 'transforming.shuffle';
  static const String keyTransformingStatus = 'transforming.status';
  static const String keyTransformingTimeout = 'transforming.timeout';
  static const String keyTransformingUrl = 'transforming.url';
  static const String keyTransformingWait = 'transforming.wait';
  static const String licenseOnDemandWhenFree = 'mod';
  static const String shuffleAlgorithmHistory = 'history';
  static const String shuffleAlgorithmHistoryOnly = 'history_only';
  static const String shuffleAlgorithmNone = 'none';
  static const String shuffleAlgorithmStable = 'stable';
  static const String shuffleAlgorithmWeighted = 'weighted';
}
