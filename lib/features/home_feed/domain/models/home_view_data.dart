import 'content_item.dart';

/// Complete home feed data — everything the UI needs.
class HomeViewData {
  final String greeting;
  final List<HomeSection> sections;
  final List<HomeChip> chips;

  const HomeViewData({
    this.greeting = '',
    this.sections = const [],
    this.chips = const [],
  });
}

/// A single section row on the home screen (e.g. "Recently Played").
class HomeSection {
  final String title;
  final String subtitle;
  final List<ContentItem> items;
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
}

/// Filter chip (Music, Podcasts, etc.)
class HomeChip {
  final String id;
  final String label;

  const HomeChip({required this.id, required this.label});
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
