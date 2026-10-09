import 'package:dio/dio.dart';
import 'package:musify_mu/features/library/domain/models/library_view_data.dart';
import 'package:musify_mu/features/library/domain/repositories/library_repository.dart';

export 'package:musify_mu/features/library/domain/models/library_view_data.dart';

/// Loads user library data via SWR (cache-then-network) or network-only refresh.
class LoadLibrary {
  final LibraryRepository _repository;

  const LoadLibrary(this._repository);

  /// SWR stream: yields cached data first, then fresh.
  Stream<LibraryViewData> call({CancelToken? cancelToken}) =>
      _repository.getLibrary(cancelToken: cancelToken);

  /// Network-only refresh, skipping cache.
  /// Forces re-sync of playlist details so mosaics and counts update.
  Future<LibraryViewData?> refresh({CancelToken? cancelToken}) =>
      _repository.fetchFresh(forceSync: true, cancelToken: cancelToken);
}
