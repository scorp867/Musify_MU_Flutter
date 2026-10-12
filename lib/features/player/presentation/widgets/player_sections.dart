library;

/// Barrel export for Now Playing card sections and components.
///
/// Follows modular single-responsibility structure:
/// - [PlayerLyricsSection]: `sections/lyrics_card.dart`
/// - [PlayerAboutArtistSection]: `sections/about_artist_card.dart`
/// - [PlayerCreditsSection]: `sections/credits_card.dart`
/// - [PlayerEventsSection]: `sections/events_card.dart`
/// - [PlayerMerchSection]: `sections/merch_card.dart`
export 'sections/about_artist_card.dart';
export 'sections/credits_card.dart';
export 'sections/events_card.dart';
export 'sections/lyrics_card.dart';
export 'sections/merch_card.dart';

import 'sections/credits_card.dart';

/// Backwards compatibility alias for [PlayerCreditsSection].
typedef PlayerTrackDetailsSection = PlayerCreditsSection;
