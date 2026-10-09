import 'package:dio/dio.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';

/// Domain contract for home feed data.
abstract interface class HomeRepository {
  /// SWR stream: yields cached data first, then fresh data.
  Stream<HomeViewData> getHomeFeed({
    HomeFacet facet = HomeFacet.all,
    CancelToken? cancelToken,
  });

  /// Fetches fresh data from network only.
  Future<HomeViewData?> fetchFresh({
    HomeFacet facet = HomeFacet.all,
    CancelToken? cancelToken,
  });

  /// Kodiak DataPool instance for reactive, viewport-scoped trait hydration.
  DataPool get dataPool;
}
