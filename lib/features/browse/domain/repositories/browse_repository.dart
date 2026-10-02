import 'package:musify_mu/features/browse/domain/models/browse_view_data.dart';

/// Domain contract for browse tab data.
abstract interface class BrowseRepository {
  Future<BrowseViewData?> fetchBrowse();
}
