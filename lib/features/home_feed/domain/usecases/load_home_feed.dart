import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:musify_mu/features/home_feed/domain/repositories/home_repository.dart';

export 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';

/// Loads home feed data via SWR (cache-then-network) or network-only refresh.
class LoadHomeFeed {
  final HomeRepository _repository;

  const LoadHomeFeed(this._repository);

  /// SWR stream: yields cached data first, then fresh.
  Stream<HomeViewData> call() => _repository.getHomeFeed();

  /// Network-only refresh, skipping cache.
  Future<HomeViewData?> refresh() => _repository.fetchFresh();
}
