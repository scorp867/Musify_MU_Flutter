import 'package:equatable/equatable.dart';
import 'spotify_entity.dart';

/// Spotify home feed facets (filter chips).
/// Maps 1:1 with Casita endpoint paths: /casita/v1/home/{pathSegment}.
enum HomeFacet {
  all(pathSegment: 'default', label: 'All', recentsPath: '/playlist/v2/list/recents/main'),
  music(pathSegment: 'music-chip', label: 'Music', recentsPath: '/playlist/v2/list/recents/music'),
  podcasts(pathSegment: 'podcasts-chip', label: 'Podcasts', recentsPath: '/playlist/v2/list/recents/podcasts');

  final String pathSegment;
  final String label;
  final String recentsPath;

  const HomeFacet({
    required this.pathSegment,
    required this.label,
    required this.recentsPath,
  });
}

/// Complete home feed data — everything the UI needs.
class HomeViewData extends Equatable {
  final String greeting;
  final List<HomeSection> sections;
  final List<HomeChip> chips;

  static const List<HomeChip> defaultChips = [
    HomeChip(id: 'all', label: 'All'),
    HomeChip(id: 'music', label: 'Music'),
    HomeChip(id: 'podcasts', label: 'Podcasts'),
  ];

  const HomeViewData({
    this.greeting = '',
    this.sections = const [],
    this.chips = defaultChips,
  });

  @override
  List<Object?> get props => [greeting, sections, chips];
}

/// A single section row on the home screen (e.g. "Recently Played").
class HomeSection extends Equatable {
  final String title;
  final String subtitle;
  final List<SpotifyEntity> items;
  final SectionLayout layout;
  final String? sectionUri;
  final String sectionType;
  final String? colorCode;
  final String? imageUrl;
  final Map<String, dynamic> metadata;

  const HomeSection({
    required this.title,
    this.subtitle = '',
    this.items = const [],
    this.layout = SectionLayout.carousel,
    this.sectionUri,
    this.sectionType = '',
    this.colorCode,
    this.imageUrl,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [
        title,
        subtitle,
        items,
        layout,
        sectionUri,
        sectionType,
        colorCode,
        imageUrl,
        metadata,
      ];
}

/// Filter chip (Music, Podcasts, etc.)
class HomeChip extends Equatable {
  final String id;
  final String label;

  const HomeChip({required this.id, required this.label});

  @override
  List<Object?> get props => [id, label];
}

/// How a section is laid out on screen.
enum SectionLayout {
  /// 2-column compact grid (shortcuts, quick access).
  quickGrid,

  /// Horizontal scrolling cards (standard sections).
  carousel,

  /// Full-width recommendation cards (feed).
  feed,
}
