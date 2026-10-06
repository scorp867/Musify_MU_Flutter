import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/element/data_element.dart';
import 'package:musify_mu/core/kodiak/statement/data_requirement.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Direct equivalent to Spotify Android's `p.swe` / `p.aox0` (`ShowcaseCardDataElement`).
class ShowcaseCardDataElement implements DataElement {
  @override
  final String id;

  @override
  final DataPool dataPool;

  static const DataStatement statement = DataStatement([
    DataRequirement(
      extensionKindValue: 178,
      extensionKind: ExtensionKind.IDENTITY_TRAIT,
      priority: DataPriority.required,
      traitType: IdentityTrait,
    ),
    DataRequirement(
      extensionKindValue: 167,
      extensionKind: ExtensionKind.PROMO_V1_TRAIT,
      priority: DataPriority.required,
      traitType: PromoV1Trait,
    ),
    DataRequirement(
      extensionKindValue: 179,
      extensionKind: ExtensionKind.VISUAL_IDENTITY_TRAIT,
      priority: DataPriority.required,
      traitType: VisualIdentityTrait,
    ),
    DataRequirement(
      extensionKindValue: 181,
      extensionKind: ExtensionKind.PREVIEW_PLAYBACK_TRAIT,
      priority: DataPriority.optional,
      traitType: PreviewPlaybackTrait,
    ),
    DataRequirement(
      extensionKindValue: 116,
      extensionKind: ExtensionKind.AUDIO_PREVIEW_PLAYBACK_TRAIT,
      priority: DataPriority.optional,
      traitType: AudioPreviewPlaybackTrait,
    ),
  ]);

  const ShowcaseCardDataElement({
    required this.id,
    required this.dataPool,
  });

  @override
  DataStatement get dataStatement => statement;
}
