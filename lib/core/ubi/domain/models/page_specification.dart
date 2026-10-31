library;

/// 1:1 replica of Spotify `p199p.mlp0` (PageSpecification).
abstract interface class PageSpecification {
  /// Resolves the page ID category (e.g. "playlist", "album", "artist").
  /// Corresponds to `p199p.mlp0#mo63270a()`.
  String pageId();

  /// Resolves the canonical relative path (e.g. "playlist", "playlist/allsongs").
  /// Corresponds to `p199p.mlp0#path()`.
  String path();
}
