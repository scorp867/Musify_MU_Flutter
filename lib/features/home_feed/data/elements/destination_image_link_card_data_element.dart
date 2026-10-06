import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/element/data_element.dart';
import 'package:musify_mu/core/kodiak/statement/data_requirement.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Direct 1:1 equivalent to Spotify Android's `p.elp` (`DestinationImageLinkCardDataElement`).
/// Used for browse destinations and grid items.
class DestinationImageLinkCardDataElement implements DataElement {
  @override
  final String id;

  @override
  final DataPool dataPool;

  /// Direct 1:1 equivalent to Spotify Android `p.elp.d`:
  /// - Level 1 (Required): ExtensionKind 97 (SIMPLE_TRAIT / c6y0)
  /// - Level 2 (Optional): ExtensionKind 178 (IDENTITY_TRAIT / l020)
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
  ]);

  const DestinationImageLinkCardDataElement({
    required this.id,
    required this.dataPool,
  });

  @override
  DataStatement get dataStatement => statement;
}
