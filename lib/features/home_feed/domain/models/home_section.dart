import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/home_feed/domain/models/section_layout.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// A single section row on the home screen.
@immutable
final class HomeSection extends Equatable {
  final String title;
  final String subtitle;
  final List<SpotifyEntity> items;
  final SectionLayout layout;
  final String? sectionUri;
  final String sectionType;
  final String? colorCode;
  final String? imageUrl;
  final Map<String, Object?> metadata;

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
