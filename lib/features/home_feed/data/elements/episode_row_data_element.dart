import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/element/data_element.dart';
import 'package:musify_mu/core/kodiak/statement/data_requirement.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Direct 1:1 equivalent to Spotify Android's `p.w8b0` (`ContentEvaluationRowDataElement` / `EpisodeRowDataElement`).
/// Used for episode lists, chapter rows, and content evaluation shelves.
class EpisodeRowDataElement implements DataElement {
  @override
  final String id;

  @override
  final DataPool dataPool;

  /// Direct 1:1 equivalent to Spotify Android `p.w8b0.c`:
  /// - Required: Kind 97 (SIMPLE_TRAIT / c6y0), Kind 178 (IDENTITY_TRAIT / l020)
  /// - Optional: Kind 179 (VISUAL_IDENTITY_TRAIT / sw71), Kind 31 (SHOW_ACCESS / fhx0), Kind 116 (AUDIO_PREVIEW_PLAYBACK_TRAIT)
  static const DataStatement statement = DataStatement([
    DataRequirement(
      extensionKindValue: 97,
      extensionKind: ExtensionKind.SIMPLE_TRAIT,
      priority: DataPriority.required,
      traitType: SimpleCardTrait,
    ),
    DataRequirement(
      extensionKindValue: 178,
      extensionKind: ExtensionKind.IDENTITY_TRAIT,
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
      extensionKindValue: 31,
      extensionKind: ExtensionKind.SHOW_ACCESS,
      priority: DataPriority.optional,
      traitType: ShowAccessTrait,
    ),
    DataRequirement(
      extensionKindValue: 116,
      extensionKind: ExtensionKind.AUDIO_PREVIEW_PLAYBACK_TRAIT,
      priority: DataPriority.optional,
      traitType: AudioPreviewPlaybackTrait,
    ),
  ]);

  const EpisodeRowDataElement({
    required this.id,
    required this.dataPool,
  });

  @override
  DataStatement get dataStatement => statement;
}
