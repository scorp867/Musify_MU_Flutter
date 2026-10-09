import 'package:dio/dio.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:musify_mu/features/home_feed/domain/repositories/home_repository.dart';

export 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';

/// Loads home feed data via SWR (cache-then-network) or network-only refresh.
class LoadHomeFeed {
  final HomeRepository _repository;

  const LoadHomeFeed(this._repository);

  /// SWR stream: yields cached data first, then fresh.
  Stream<HomeViewData> call({
    HomeFacet facet = HomeFacet.all,
    CancelToken? cancelToken,
  }) =>
      _repository.getHomeFeed(facet: facet, cancelToken: cancelToken);

  /// Network-only refresh, skipping cache.
  Future<HomeViewData?> refresh({
    HomeFacet facet = HomeFacet.all,
    CancelToken? cancelToken,
  }) =>
      _repository.fetchFresh(facet: facet, cancelToken: cancelToken);
}
