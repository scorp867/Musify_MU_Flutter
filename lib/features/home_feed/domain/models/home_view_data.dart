import 'package:equatable/equatable.dart';
import 'spotify_entity.dart';

/// Spotify home feed facets (filter chips).
/// Maps 1:1 with Casita endpoint paths: /casita/v1/home/{pathSegment}.
enum HomeFacet {
  all(pathSegment: 'default', label: 'All'),
  music(pathSegment: 'music', label: 'Music'),
  podcasts(pathSegment: 'podcasts', label: 'Podcasts & Shows');

  final String pathSegment;
  final String label;

  const HomeFacet({required this.pathSegment, required this.label});
}

/// Complete home feed data — everything the UI needs.
class HomeViewData extends Equatable {
  final String greeting;
  final List<HomeSection> sections;
  final List<HomeChip> chips;

  const HomeViewData({
    this.greeting = '',
    this.sections = const [],
    this.chips = const [],
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

  const HomeSection({
    required this.title,
    this.subtitle = '',
    this.items = const [],
    this.layout = SectionLayout.carousel,
    this.sectionUri,
    this.sectionType = '',
  });

  @override
  List<Object?> get props => [
        title,
        subtitle,
        items,
        layout,
        sectionUri,
        sectionType,
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
