import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/element/data_element.dart';
import 'package:musify_mu/core/kodiak/statement/data_requirement.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Direct equivalent to Spotify Android's `p.u520` (`ImageLinkCardDataElement`)
/// and `p.z520` (`DataStatement` declaration).
///
/// Declares the exact 6 traits queried by Spotify:
/// - Level 1 (Required): ExtensionKind 97 (SIMPLE_TRAIT)
/// - Level 2 (Optional): ExtensionKind 178 (IDENTITY_TRAIT)
/// - Level 2 (Optional): ExtensionKind 179 (VISUAL_IDENTITY_TRAIT)
/// - Level 2 (Optional): ExtensionKind 31 (SHOW_ACCESS)
/// - Level 2 (Optional): ExtensionKind 52 (AUDIOBOOK_SPECIFICS)
/// - Level 2 (Optional): ExtensionKind 64 (AUDIOBOOK_PRICE)
class ImageLinkCardDataElement implements DataElement {
  @override
  final String id;

  @override
  final DataPool dataPool;

  /// The static, immutable DataStatement matching Spotify Android `p.z520.a`.
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
      extensionKindValue: 31,
      extensionKind: ExtensionKind.SHOW_ACCESS,
      priority: DataPriority.optional,
      traitType: ShowAccessTrait,
    ),
    DataRequirement(
      extensionKindValue: 52,
      extensionKind: ExtensionKind.AUDIOBOOK_SPECIFICS,
      priority: DataPriority.optional,
      traitType: AudiobookSpecificsTrait,
    ),
    DataRequirement(
      extensionKindValue: 64,
      extensionKind: ExtensionKind.AUDIOBOOK_PRICE,
      priority: DataPriority.optional,
      traitType: AudiobookPriceTrait,
    ),
  ]);

  const ImageLinkCardDataElement({
    required this.id,
    required this.dataPool,
  });

  @override
  DataStatement get dataStatement => statement;
}
