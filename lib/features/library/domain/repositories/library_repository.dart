import 'package:musify_mu/features/library/domain/models/library_view_data.dart';

/// Domain contract for user library data.
abstract interface class LibraryRepository {
  /// SWR stream: yields cached data first, then fresh data.
  Stream<LibraryViewData> getLibrary();

  /// Fetches fresh data from network only.
  ///
  /// When [forceSync] is true, re-syncs all playlist details (including
  /// already-cached ones) so that mosaic artwork and track counts update.
  Future<LibraryViewData?> fetchFresh({bool forceSync = false});
}
