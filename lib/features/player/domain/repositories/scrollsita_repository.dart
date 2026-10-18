import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';

/// Domain repository contract for Now Playing scroll card layouts (`Scrollsita`).
abstract interface class ScrollSitaRepository {
  /// Fetches the ordered list of scroll card descriptors for the active track.
  Future<List<ScrollCardDescriptor>> getScrollCards([String? trackId]);
}
