/// Spotify home feed facets (filter chips).
/// Maps 1:1 with Casita endpoint paths: `/casita/v1/home/{pathSegment}`.
enum HomeFacet {
  all(
    pathSegment: 'default',
    label: 'All',
    recentsPath: '/playlist/v2/list/recents/main',
  ),
  music(
    pathSegment: 'music-chip',
    label: 'Music',
    recentsPath: '/playlist/v2/list/recents/music',
  ),
  podcasts(
    pathSegment: 'podcasts-chip',
    label: 'Podcasts',
    recentsPath: '/playlist/v2/list/recents/podcasts',
  );

  final String pathSegment;
  final String label;
  final String recentsPath;

  const HomeFacet({
    required this.pathSegment,
    required this.label,
    required this.recentsPath,
  });
}
