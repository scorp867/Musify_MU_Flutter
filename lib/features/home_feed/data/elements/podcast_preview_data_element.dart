import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/element/data_element.dart';
import 'package:musify_mu/core/kodiak/statement/data_requirement.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Direct equivalent to Spotify Android's `p.wab0` / `p.xab0` (`PodcastPreviewDataElement`).
/// Requests traits needed for video episode cards and audio episode preview cards:
/// - PREVIEW_CARD_TRAIT (118)
/// - AUDIO_PREVIEW_PLAYBACK_TRAIT (116)
/// - IDENTITY_TRAIT (178)
/// - VISUAL_IDENTITY_TRAIT (179)
/// - PREVIEW_PLAYBACK_TRAIT (181)
/// - EPISODE_V4 (12)
/// - SIMPLE_TRAIT (97)
/// - SHOW_ACCESS (31)
class PodcastPreviewDataElement implements DataElement {
  @override
  final String id;

  @override
  final DataPool dataPool;

  static const DataStatement statement = DataStatement([
    DataRequirement(
      extensionKindValue: 118,
      extensionKind: ExtensionKind.PREVIEW_CARD_TRAIT,
      priority: DataPriority.optional,
      traitType: PreviewCardTrait,
    ),
    DataRequirement(
      extensionKindValue: 116,
      extensionKind: ExtensionKind.AUDIO_PREVIEW_PLAYBACK_TRAIT,
      priority: DataPriority.optional,
      traitType: AudioPreviewPlaybackTrait,
    ),
    DataRequirement(
      extensionKindValue: 178,
      extensionKind: ExtensionKind.IDENTITY_TRAIT,
      priority: DataPriority.optional,
      traitType: IdentityTrait,
    ),
    DataRequirement(
      extensionKindValue: 179,
      extensionKind: ExtensionKind.VISUAL_IDENTITY_TRAIT,
      priority: DataPriority.optional,
      traitType: VisualIdentityTrait,
    ),
    DataRequirement(
      extensionKindValue: 181,
      extensionKind: ExtensionKind.PREVIEW_PLAYBACK_TRAIT,
      priority: DataPriority.optional,
      traitType: PreviewPlaybackTrait,
    ),
    DataRequirement(
      extensionKindValue: 12,
      extensionKind: ExtensionKind.EPISODE_V4,
      priority: DataPriority.optional,
      traitType: EpisodeMetaTrait,
    ),
    DataRequirement(
      extensionKindValue: 97,
      extensionKind: ExtensionKind.SIMPLE_TRAIT,
      priority: DataPriority.optional,
      traitType: SimpleCardTrait,
    ),
    DataRequirement(
      extensionKindValue: 31,
      extensionKind: ExtensionKind.SHOW_ACCESS,
      priority: DataPriority.optional,
      traitType: ShowAccessTrait,
    ),
  ]);

  const PodcastPreviewDataElement({
    required this.id,
    required this.dataPool,
  });

  @override
  DataStatement get dataStatement => statement;
}
