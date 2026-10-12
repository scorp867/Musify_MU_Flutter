import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/element/data_element.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';

/// DataElement for the "About the Artist" scroll card in Now Playing view.
///
/// 1:1 replica of Spotify Android's `p/x1.java` (`AboutCardDataElement`).
/// Coordinates trait declaration and binding to [DataPool].
class AboutArtistDataElement implements DataElement {
  @override
  final String id;

  @override
  final DataPool dataPool;

  final String artistUri;
  final String title;

  const AboutArtistDataElement({
    required this.id,
    required this.dataPool,
    required this.artistUri,
    this.title = 'About the artist',
  });

  @override
  DataStatement get dataStatement => CreatorBioCardDescriptor.statement;
}
