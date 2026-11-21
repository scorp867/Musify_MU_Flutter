import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:musify_mu/core/kodiak/statement/data_requirement.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/artist_v4.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/concert_location_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/concert_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/credits_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/identity_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/on_platform_reputation_trait.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/track_v4/track_v4.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/visual_identity_trait.dart';

/// Pairs a list of entity URIs with the exact [DataStatement] that applies to
/// those entities, preventing inapplicable extension kinds from being queried
/// across mixed entity types (for example, requesting `TRACK_V4` on artist URIs
/// or `CONCERT` on an artist URI).
@immutable
final class EntityDataBatchRequest {
  final List<String> uris;
  final DataStatement statement;

  const EntityDataBatchRequest({
    required this.uris,
    required this.statement,
  });

  List<String> get nonEmptyUris =>
      uris.where((uri) => uri.trim().isNotEmpty).toList(growable: false);
}

/// Sealed descriptor hierarchy matching Spotify's `p/m3h0.java`.
///
/// Each scroll card in the Now Playing scroll view implements this contract to
/// declare its entity URIs and targeted Kodiak [EntityDataBatchRequest]s for
/// eager trait preloading.
@immutable
sealed class ScrollCardDescriptor {
  const ScrollCardDescriptor();

  /// The Spotify entity URIs (artists, tracks, concerts, albums) that this card
  /// depends on. Matches `p/m3h0.java -> List a()`.
  List<String> get entityUris;

  /// Primary declarative [DataStatement] for this descriptor.
  DataStatement? get dataStatement;

  /// Targeted per-entity-group batch requests to execute against `DataPool`.
  List<EntityDataBatchRequest> get batchRequests;
}

/// Creator bio card descriptor.
/// 1:1 replica of `p/z1h0.java` (associated with `p/x1.java` `AboutCardDataElement`).
@immutable
final class CreatorBioCardDescriptor extends ScrollCardDescriptor {
  final String creatorUri;
  final String title;

  static const DataStatement statement = DataStatement([
    DataRequirement(
      extensionKindValue: 178,
      extensionKind: ExtensionKind.IDENTITY_TRAIT,
      priority: DataPriority.required,
      traitType: IdentityTrait,
    ),
    DataRequirement(
      extensionKindValue: 8,
      extensionKind: ExtensionKind.ARTIST_V4,
      priority: DataPriority.optional,
      traitType: ArtistV4,
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
  List<String> get entityUris =>
      creatorUri.isEmpty ? const [] : <String>[creatorUri];

  @override
  DataStatement? get dataStatement => statement;

  @override
  List<EntityDataBatchRequest> get batchRequests => creatorUri.isEmpty
      ? const []
      : <EntityDataBatchRequest>[
          EntityDataBatchRequest(
            uris: <String>[creatorUri],
            statement: statement,
          ),
        ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreatorBioCardDescriptor &&
        other.creatorUri == creatorUri &&
        other.title == title;
  }

  @override
  int get hashCode => Object.hash(creatorUri, title);

  @override
  String toString() => 'CreatorBioCardDescriptor($title -> $creatorUri)';
}

/// Track credits card descriptor.
/// 1:1 replica of `p/a2h0.java` (associated with `p/llk.java` `CreditsCardDataElement`).
@immutable
final class CreditsCardDescriptor extends ScrollCardDescriptor {
  final String entityUri;
  final List<String> contributorUris;

  static const DataStatement trackStatement = DataStatement([
    DataRequirement(
      extensionKindValue: 10,
      extensionKind: ExtensionKind.TRACK_V4,
      priority: DataPriority.required,
      traitType: TrackV4,
    ),
    DataRequirement(
      extensionKindValue: 186,
      extensionKind: ExtensionKind.CREDITS_V2_TRAIT,
      priority: DataPriority.required,
      traitType: CreditsTrait,
    ),
  ]);

  static const DataStatement contributorStatement = DataStatement([
    DataRequirement(
      extensionKindValue: 178,
      extensionKind: ExtensionKind.IDENTITY_TRAIT,
      priority: DataPriority.optional,
      traitType: IdentityTrait,
    ),
  ]);

  static const DataStatement statement = DataStatement([
    DataRequirement(
      extensionKindValue: 10,
      extensionKind: ExtensionKind.TRACK_V4,
      priority: DataPriority.required,
      traitType: TrackV4,
    ),
    DataRequirement(
      extensionKindValue: 178,
      extensionKind: ExtensionKind.IDENTITY_TRAIT,
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
  List<String> get entityUris => UnmodifiableListView<String>([
    if (entityUri.isNotEmpty) entityUri,
    for (final uri in contributorUris)
      if (uri.isNotEmpty) uri,
  ]);

  @override
  DataStatement? get dataStatement => statement;

  @override
  List<EntityDataBatchRequest> get batchRequests {
    final requests = <EntityDataBatchRequest>[];
    if (entityUri.isNotEmpty) {
      requests.add(
        EntityDataBatchRequest(
          uris: <String>[entityUri],
          statement: trackStatement,
        ),
      );
    }
    final validContributors = contributorUris
        .where((u) => u.isNotEmpty)
        .toList(growable: false);
    if (validContributors.isNotEmpty) {
      requests.add(
        EntityDataBatchRequest(
          uris: validContributors,
          statement: contributorStatement,
        ),
      );
    }
    return requests;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreditsCardDescriptor &&
        other.entityUri == entityUri &&
        listEquals(other.contributorUris, contributorUris);
  }

  @override
  int get hashCode =>
      Object.hash(entityUri, Object.hashAll(contributorUris));

  @override
  String toString() =>
      'CreditsCardDescriptor($entityUri, contributors: ${contributorUris.length})';
}

/// Lyrics card descriptor.
/// 1:1 replica of `p/y1h0.java` and `p/aw80.java` (which zips lyrics with VisualIdentityTrait).
@immutable
final class LyricsCardDescriptor extends ScrollCardDescriptor {
  final String entityUri;

  static const DataStatement statement = DataStatement([
    DataRequirement(
      extensionKindValue: 179,
      extensionKind: ExtensionKind.VISUAL_IDENTITY_TRAIT,
      priority: DataPriority.optional,
      traitType: VisualIdentityTrait,
    ),
  ]);

  const LyricsCardDescriptor({required this.entityUri});

  @override
  List<String> get entityUris =>
      entityUri.isEmpty ? const [] : <String>[entityUri];

  @override
  DataStatement? get dataStatement => statement;

  @override
  List<EntityDataBatchRequest> get batchRequests => entityUri.isEmpty
      ? const []
      : <EntityDataBatchRequest>[
          EntityDataBatchRequest(
            uris: <String>[entityUri],
            statement: statement,
          ),
        ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LyricsCardDescriptor && other.entityUri == entityUri;
  }

  @override
  int get hashCode => entityUri.hashCode;

  @override
  String toString() => 'LyricsCardDescriptor($entityUri)';
}

/// Discovery feed card descriptor.
/// 1:1 replica of `p/e3h0.java`.
@immutable
final class DiscoveryFeedCardDescriptor extends ScrollCardDescriptor {
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
  List<EntityDataBatchRequest> get batchRequests => const [];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiscoveryFeedCardDescriptor &&
        other.title == title &&
        listEquals(other.itemUris, itemUris);
  }

  @override
  int get hashCode => Object.hash(title, Object.hashAll(itemUris));

  @override
  String toString() =>
      'DiscoveryFeedCardDescriptor($title, items: ${itemUris.length})';
}

/// Live events / On tour card descriptor.
/// 1:1 replica of `p/b2h0.java`.
@immutable
final class LiveEventsCardDescriptor extends ScrollCardDescriptor {
  final String artistUri;
  final List<String> concertUris;

  static const DataStatement concertStatement = DataStatement([
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

  static const DataStatement artistStatement = DataStatement([
    DataRequirement(
      extensionKindValue: 178,
      extensionKind: ExtensionKind.IDENTITY_TRAIT,
      priority: DataPriority.optional,
      traitType: IdentityTrait,
    ),
    DataRequirement(
      extensionKindValue: 8,
      extensionKind: ExtensionKind.ARTIST_V4,
      priority: DataPriority.optional,
      traitType: ArtistV4,
    ),
    DataRequirement(
      extensionKindValue: 179,
      extensionKind: ExtensionKind.VISUAL_IDENTITY_TRAIT,
      priority: DataPriority.optional,
      traitType: VisualIdentityTrait,
    ),
  ]);

  static const DataStatement statement = concertStatement;

  const LiveEventsCardDescriptor({
    required this.artistUri,
    this.concertUris = const [],
  });

  @override
  List<String> get entityUris => UnmodifiableListView<String>([
    if (artistUri.isNotEmpty) artistUri,
    for (final uri in concertUris)
      if (uri.isNotEmpty) uri,
  ]);

  @override
  DataStatement? get dataStatement => statement;

  @override
  List<EntityDataBatchRequest> get batchRequests {
    final requests = <EntityDataBatchRequest>[];
    final validConcerts = concertUris
        .where((u) => u.isNotEmpty)
        .toList(growable: false);
    if (validConcerts.isNotEmpty) {
      requests.add(
        EntityDataBatchRequest(
          uris: validConcerts,
          statement: concertStatement,
        ),
      );
    }
    if (artistUri.isNotEmpty) {
      requests.add(
        EntityDataBatchRequest(
          uris: <String>[artistUri],
          statement: artistStatement,
        ),
      );
    }
    return requests;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveEventsCardDescriptor &&
        other.artistUri == artistUri &&
        listEquals(other.concertUris, concertUris);
  }

  @override
  int get hashCode =>
      Object.hash(artistUri, Object.hashAll(concertUris));

  @override
  String toString() =>
      'LiveEventsCardDescriptor($artistUri, concerts: ${concertUris.length})';
}

/// Merch card descriptor.
@immutable
final class MerchCardDescriptor extends ScrollCardDescriptor {
  final String entityUri;

  const MerchCardDescriptor({required this.entityUri});

  @override
  List<String> get entityUris =>
      entityUri.isEmpty ? const [] : <String>[entityUri];

  @override
  DataStatement? get dataStatement => null;

  @override
  List<EntityDataBatchRequest> get batchRequests => const [];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MerchCardDescriptor && other.entityUri == entityUri;
  }

  @override
  int get hashCode => entityUri.hashCode;

  @override
  String toString() => 'MerchCardDescriptor($entityUri)';
}
