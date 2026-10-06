import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/element/data_element.dart';
import 'package:musify_mu/core/kodiak/statement/data_requirement.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// DataElement for Video Promo and Video Carousel cards (sections 18, 25, 39).
/// Matches Spotify Android's VideoPromo element declarations.
class VideoPromoCardDataElement implements DataElement {
  @override
  final String id;

  @override
  final DataPool dataPool;

  static const DataStatement statement = DataStatement([
    DataRequirement(
      extensionKindValue: 118,
      extensionKind: ExtensionKind.PREVIEW_CARD_TRAIT,
      priority: DataPriority.required,
      traitType: PreviewCardTrait,
    ),
    DataRequirement(
      extensionKindValue: 181,
      extensionKind: ExtensionKind.PREVIEW_PLAYBACK_TRAIT,
      priority: DataPriority.optional,
      traitType: PreviewPlaybackTrait,
    ),
    DataRequirement(
      extensionKindValue: 178,
      extensionKind: ExtensionKind.IDENTITY_TRAIT,
      priority: DataPriority.optional,
      traitType: IdentityTrait,
    ),
  ]);

  const VideoPromoCardDataElement({
    required this.id,
    required this.dataPool,
  });

  @override
  DataStatement get dataStatement => statement;
}
