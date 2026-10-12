import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/element/data_element.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';

/// DataElement for the Track Credits scroll card in Now Playing view.
///
/// 1:1 replica of Spotify Android's `p/llk.java` (case 0, `CreditsCardDataElement`).
/// Declares level 1 requirement for track metadata and level 2 for contributor identities.
class CreditsCardDataElement implements DataElement {
  @override
  final String id;

  @override
  final DataPool dataPool;

  final String trackUri;
  final List<String> contributorUris;

  const CreditsCardDataElement({
    required this.id,
    required this.dataPool,
    required this.trackUri,
    this.contributorUris = const [],
  });

  @override
  DataStatement get dataStatement => CreditsCardDescriptor.statement;
}
