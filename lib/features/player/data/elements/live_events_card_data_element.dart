import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/element/data_element.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';

/// DataElement for the Live Events / Concerts scroll card in Now Playing view.
///
/// 1:1 replica of Spotify Android's `p/wlk.java` (case 3).
class LiveEventsCardDataElement implements DataElement {
  @override
  final String id;

  @override
  final DataPool dataPool;

  final String artistUri;
  final List<String> concertUris;

  const LiveEventsCardDataElement({
    required this.id,
    required this.dataPool,
    required this.artistUri,
    this.concertUris = const [],
  });

  @override
  DataStatement get dataStatement => LiveEventsCardDescriptor.statement;
}
