import 'package:musify_mu/features/browse/domain/models/browse_view_data.dart';
import 'package:musify_mu/features/browse/domain/repositories/browse_repository.dart';

export 'package:musify_mu/features/browse/domain/models/browse_view_data.dart';

/// Loads browse tab data (initial load and refresh use the same fetch).
class LoadBrowse {
  final BrowseRepository _repository;

  const LoadBrowse(this._repository);

  Future<BrowseViewData?> call() => _repository.fetchBrowse();
}
