import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/element/data_element.dart';
import 'package:musify_mu/core/kodiak/statement/data_requirement.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// DataElement for Campaign Carousels and Concerts (section 12).
class CampaignCardDataElement implements DataElement {
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
      extensionKindValue: 122,
      extensionKind: ExtensionKind.CONCERT,
      priority: DataPriority.optional,
      traitType: ConcertTrait,
    ),
    DataRequirement(
      extensionKindValue: 123,
      extensionKind: ExtensionKind.CONCERT_LOCATION,
      priority: DataPriority.optional,
      traitType: ConcertLocationTrait,
    ),
    DataRequirement(
      extensionKindValue: 124,
      extensionKind: ExtensionKind.CONCERT_MARKETING,
      priority: DataPriority.optional,
      traitType: ConcertMarketingTrait,
    ),
  ]);

  const CampaignCardDataElement({
    required this.id,
    required this.dataPool,
  });

  @override
  DataStatement get dataStatement => statement;
}
