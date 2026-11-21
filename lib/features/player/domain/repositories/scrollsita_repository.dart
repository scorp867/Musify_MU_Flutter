import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';

/// Domain repository contract for Now Playing scroll card layouts (`Scrollsita`).
abstract interface class ScrollSitaRepository {
  /// Fetches the ordered list of scroll card descriptors for an eligible
  /// Spotify track.
  ///
  /// When [artistUri] is supplied, fallback descriptors retain the artist URI
  /// so Kodiak trait hydration can still populate the About the Artist card
  /// even if the Scrollsita layout endpoint times out or fails.
  Future<List<ScrollCardDescriptor>> getScrollCards([
    String? trackId,
    String? artistUri,
  ]);
}
