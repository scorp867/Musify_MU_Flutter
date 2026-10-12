import 'package:musify_mu/core/kodiak/statement/data_requirement.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/concert_location_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/concert_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/identity_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/track_meta_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/visual_identity_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/on_platform_reputation_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/credits_trait.dart';

/// Interface matching Spotify's `p/m3h0.java`.
///
/// Each scroll card in the Now Playing scroll view implements this interface
/// to declare the entity URIs and Kodiak [DataStatement] it depends on for data loading.
abstract class ScrollCardDescriptor {
  /// The Spotify entity URIs (artists, tracks, concerts, albums) that this card requires.
  /// Matches `p/m3h0.java -> List a()`.
  List<String> get entityUris;

  /// Declarative [DataStatement] declaring required and optional traits.
  /// Matches `p/x1.java` and `p/llk.java` in Spotify Android.
  DataStatement? get dataStatement;
}

/// Creator bio card descriptor.
/// 1:1 replica of `p/z1h0.java` (associated with `p/x1.java` `AboutCardDataElement`).
class CreatorBioCardDescriptor implements ScrollCardDescriptor {
  final String creatorUri;
  final String title;

  static const DataStatement statement = DataStatement([
    DataRequirement(
      extensionKindValue: 8,
      extensionKind: ExtensionKind.ARTIST_V4,
      priority: DataPriority.required,
      traitType: IdentityTrait,
    ),
    DataRequirement(
      extensionKindValue: 179,
      extensionKind: ExtensionKind.VISUAL_IDENTITY_TRAIT,
      priority: DataPriority.optional,
      traitType: VisualIdentityTrait,
    ),
    DataRequirement(
      extensionKindValue: 185,
      extensionKind: ExtensionKind.ON_PLATFORM_REPUTATION_TRAIT,
      priority: DataPriority.optional,
      traitType: OnPlatformReputationTrait,
    ),
  ]);

  const CreatorBioCardDescriptor({
    required this.creatorUri,
    this.title = 'About the artist',
  });

  @override
  List<String> get entityUris => [creatorUri];

  @override
  DataStatement? get dataStatement => statement;

  @override
  String toString() => 'CreatorBioCardDescriptor($title -> $creatorUri)';
}

/// Track credits card descriptor.
/// 1:1 replica of `p/a2h0.java` (associated with `p/llk.java` `CreditsCardDataElement`).
class CreditsCardDescriptor implements ScrollCardDescriptor {
  final String entityUri;
  final List<String> contributorUris;

  static const DataStatement statement = DataStatement([
    DataRequirement(
      extensionKindValue: 10,
      extensionKind: ExtensionKind.TRACK_V4,
      priority: DataPriority.required,
      traitType: TrackMetaTrait,
    ),
    DataRequirement(
      extensionKindValue: 8,
      extensionKind: ExtensionKind.ARTIST_V4,
      priority: DataPriority.optional,
      traitType: IdentityTrait,
    ),
    DataRequirement(
      extensionKindValue: 186,
      extensionKind: ExtensionKind.CREDITS_V2_TRAIT,
      priority: DataPriority.required,
      traitType: CreditsTrait,
    ),
  ]);

  const CreditsCardDescriptor({
    required this.entityUri,
    this.contributorUris = const [],
  });

  @override
  List<String> get entityUris => [entityUri, ...contributorUris];

  @override
  DataStatement? get dataStatement => statement;

  @override
  String toString() => 'CreditsCardDescriptor($entityUri, contributors: ${contributorUris.length})';
}

/// Lyrics card descriptor.
/// 1:1 replica of `p/y1h0.java` and `p/aw80.java` (which zips lyrics with VisualIdentityTrait).
class LyricsCardDescriptor implements ScrollCardDescriptor {
  final String entityUri;

  static const statement = DataStatement([
    DataRequirement(
      extensionKindValue: 179,
      extensionKind: ExtensionKind.VISUAL_IDENTITY_TRAIT,
      priority: DataPriority.optional,
      traitType: VisualIdentityTrait,
    ),
  ]);

  const LyricsCardDescriptor({required this.entityUri});

  @override
  List<String> get entityUris => [entityUri];

  @override
  DataStatement? get dataStatement => statement;

  @override
  String toString() => 'LyricsCardDescriptor($entityUri)';
}

/// Discovery feed card descriptor.
/// 1:1 replica of `p/e3h0.java`.
class DiscoveryFeedCardDescriptor implements ScrollCardDescriptor {
  final String title;
  final List<String> itemUris;

  const DiscoveryFeedCardDescriptor({
    required this.title,
    this.itemUris = const [],
  });

  @override
  List<String> get entityUris => itemUris;

  @override
  DataStatement? get dataStatement => null;

  @override
  String toString() => 'DiscoveryFeedCardDescriptor($title, items: ${itemUris.length})';
}

/// Live events / On tour card descriptor.
/// 1:1 replica of `p/b2h0.java`.
class LiveEventsCardDescriptor implements ScrollCardDescriptor {
  final String artistUri;
  final List<String> concertUris;

  static const DataStatement statement = DataStatement([
    DataRequirement(
      extensionKindValue: 122,
      extensionKind: ExtensionKind.CONCERT,
      priority: DataPriority.required,
      traitType: ConcertTrait,
    ),
    DataRequirement(
      extensionKindValue: 123,
      extensionKind: ExtensionKind.CONCERT_LOCATION,
      priority: DataPriority.optional,
      traitType: ConcertLocationTrait,
    ),
  ]);

  const LiveEventsCardDescriptor({
    required this.artistUri,
    this.concertUris = const [],
  });

  @override
  List<String> get entityUris => [artistUri, ...concertUris];

  @override
  DataStatement? get dataStatement => statement;

  @override
  String toString() => 'LiveEventsCardDescriptor($artistUri, concerts: ${concertUris.length})';
}

/// Merch card descriptor.
class MerchCardDescriptor implements ScrollCardDescriptor {
  final String entityUri;

  const MerchCardDescriptor({required this.entityUri});

  @override
  List<String> get entityUris => [entityUri];

  @override
  DataStatement? get dataStatement => null;

  @override
  String toString() => 'MerchCardDescriptor($entityUri)';
}
