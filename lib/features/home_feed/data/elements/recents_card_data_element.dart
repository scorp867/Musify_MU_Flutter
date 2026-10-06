import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/element/data_element.dart';
import 'package:musify_mu/core/kodiak/statement/data_requirement.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// DataElement for Recents Shelf cards (section 26).
class RecentsCardDataElement implements DataElement {
  @override
  final String id;

  @override
  final DataPool dataPool;

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

  const RecentsCardDataElement({
    required this.id,
    required this.dataPool,
  });

  @override
  DataStatement get dataStatement => statement;
}
