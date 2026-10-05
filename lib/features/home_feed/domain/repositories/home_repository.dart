import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';

/// Domain contract for home feed data.
abstract interface class HomeRepository {
  /// SWR stream: yields cached data first, then fresh data.
  Stream<HomeViewData> getHomeFeed({HomeFacet facet = HomeFacet.all});

  /// Fetches fresh data from network only.
  Future<HomeViewData?> fetchFresh({HomeFacet facet = HomeFacet.all});
}
