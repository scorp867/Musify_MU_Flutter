import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';
import 'package:musify_mu/features/library/application/library_bloc.dart';
import 'package:musify_mu/features/library/domain/repositories/library_repository.dart';
import 'package:musify_mu/features/library/domain/usecases/load_library.dart';

class FakeNetworkMonitorService implements NetworkMonitorService {
  final _controller = StreamController<NetworkStatus>.broadcast();
  NetworkStatus _status = NetworkStatus.online;

  @override
  NetworkStatus get currentStatus => _status;

  @override
  Stream<NetworkStatus> get statusStream => _controller.stream;

  void setStatus(NetworkStatus status) {
    _status = status;
    _controller.add(status);
  }

  @override
  void recordLatency(Duration latency) {}

  @override
  void recordTimeout() {}

  @override
  void recordConnectionError() {}

  @override
  void recordSuccess() {}

  @override
  void dispose() {
    _controller.close();
  }
}

class FakeLibraryRepository implements LibraryRepository {
  LibraryViewData? cachedData;
  LibraryViewData? freshData;
  bool fetchFreshCalled = false;

  @override
  Stream<LibraryViewData> getLibrary({CancelToken? cancelToken}) async* {
    if (cachedData != null) {
      yield cachedData!;
    }
    final fresh = await fetchFresh(cancelToken: cancelToken);
    if (fresh != null) {
      yield fresh;
    }
  }

  @override
  Future<LibraryViewData?> fetchFresh({
    bool forceSync = false,
    CancelToken? cancelToken,
  }) async {
    fetchFreshCalled = true;
    return freshData;
  }
}

void main() {
  late FakeLibraryRepository fakeRepo;
  late FakeNetworkMonitorService fakeNetworkMonitor;
  late LoadLibrary loadLibrary;

  const sampleData = LibraryViewData(items: []);

  setUp(() {
    fakeRepo = FakeLibraryRepository();
    fakeNetworkMonitor = FakeNetworkMonitorService();
    loadLibrary = LoadLibrary(fakeRepo);
  });

  tearDown(() {
    fakeNetworkMonitor.dispose();
  });

  test('offline with cached data emits LibraryLoaded without hanging or error screen', () async {
    fakeNetworkMonitor.setStatus(NetworkStatus.offline);
    fakeRepo.cachedData = sampleData;
    fakeRepo.freshData = null;

    final bloc = LibraryBloc(
      loadLibrary: loadLibrary,
      networkMonitor: fakeNetworkMonitor,
    );

    final states = <LibraryState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const LibraryLoadRequested());
    await pumpEventQueue();

    expect(states, [
      const LibraryLoaded(data: sampleData),
    ]);
    expect(fakeRepo.fetchFreshCalled, isTrue);

    await sub.cancel();
    await bloc.close();
  });

  test('refresh while offline stops refreshing spinner and emits offline notification toast', () async {
    fakeNetworkMonitor.setStatus(NetworkStatus.offline);
    fakeRepo.cachedData = sampleData;
    fakeRepo.freshData = null;

    final bloc = LibraryBloc(
      loadLibrary: loadLibrary,
      networkMonitor: fakeNetworkMonitor,
    );

    // Initial load
    bloc.add(const LibraryLoadRequested());
    await pumpEventQueue();

    final states = <LibraryState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const LibraryRefreshRequested());
    await pumpEventQueue();

    expect(states, [
      const LibraryLoaded(data: sampleData, isRefreshing: true),
      const LibraryLoaded(data: sampleData, isRefreshing: false),
      const LibraryError(
        message: "You're offline. Content will update when connected.",
        staleData: sampleData,
      ),
    ]);

    await sub.cancel();
    await bloc.close();
  });

  test('reconnection triggers refresh on active tab', () async {
    fakeNetworkMonitor.setStatus(NetworkStatus.offline);
    fakeRepo.cachedData = sampleData;
    fakeRepo.freshData = null;

    final bloc = LibraryBloc(
      loadLibrary: loadLibrary,
      networkMonitor: fakeNetworkMonitor,
    );

    bloc.add(const LibraryLoadRequested());
    await pumpEventQueue();

    const restoredData = LibraryViewData(
      items: [
        LibraryItem(
          uri: 'spotify:playlist:1',
          name: 'Restored Playlist',
          type: 'playlist',
          isPinned: false,
        ),
      ],
    );
    fakeRepo.freshData = restoredData;

    // Network restored
    fakeNetworkMonitor.setStatus(NetworkStatus.restored);
    await pumpEventQueue();

    expect(bloc.state, isA<LibraryLoaded>());
    expect((bloc.state as LibraryLoaded).data.items.first.name, equals('Restored Playlist'));

    await bloc.close();
  });

  test('inactive tab in background defers refresh until LibraryActivated is dispatched on tab return', () async {
    fakeNetworkMonitor.setStatus(NetworkStatus.offline);
    fakeRepo.cachedData = sampleData;
    fakeRepo.freshData = null;

    final bloc = LibraryBloc(
      loadLibrary: loadLibrary,
      networkMonitor: fakeNetworkMonitor,
    );

    bloc.add(const LibraryLoadRequested());
    await pumpEventQueue();
    expect(bloc.state, equals(const LibraryLoaded(data: sampleData)));

    // User switches away
    bloc.add(const LibraryCancelRequested());
    await pumpEventQueue();

    const restoredData = LibraryViewData(
      items: [
        LibraryItem(
          uri: 'spotify:playlist:1',
          name: 'Deferred Restored Playlist',
          type: 'playlist',
          isPinned: false,
        ),
      ],
    );
    fakeRepo.freshData = restoredData;

    // Network restored while in background
    fakeNetworkMonitor.setStatus(NetworkStatus.restored);
    await pumpEventQueue();

    // Still empty cached items
    expect((bloc.state as LibraryLoaded).data.items, isEmpty);

    // User navigates back
    bloc.add(const LibraryActivated());
    await pumpEventQueue();

    // Now revalidation runs
    expect((bloc.state as LibraryLoaded).data.items.first.name, equals('Deferred Restored Playlist'));

    await bloc.close();
  });
}
