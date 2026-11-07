import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_chip.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_section.dart';

export 'home_chip.dart';
export 'home_facet.dart';
export 'home_section.dart';
export 'section_layout.dart';

/// Complete home feed view model containing sections and filter chips.
@immutable
final class HomeViewData extends Equatable {
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
