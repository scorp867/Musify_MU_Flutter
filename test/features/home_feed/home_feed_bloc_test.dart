import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';
import 'package:musify_mu/features/home_feed/application/home_feed_bloc.dart';
import 'package:musify_mu/features/home_feed/domain/repositories/home_repository.dart';
import 'package:musify_mu/features/home_feed/domain/usecases/load_home_feed.dart';

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

class FakeHomeRepository implements HomeRepository {
  HomeViewData? cachedData;
  HomeViewData? freshData;
  bool fetchFreshCalled = false;

  @override
  DataPool get dataPool => throw UnimplementedError();

  @override
  Stream<HomeViewData> getHomeFeed({
    HomeFacet facet = HomeFacet.all,
    CancelToken? cancelToken,
  }) async* {
    if (cachedData != null) {
      yield cachedData!;
    }
    final fresh = await fetchFresh(facet: facet, cancelToken: cancelToken);
    if (fresh != null) {
      yield fresh;
    }
  }

  @override
  Future<HomeViewData?> fetchFresh({
    HomeFacet facet = HomeFacet.all,
    CancelToken? cancelToken,
  }) async {
    fetchFreshCalled = true;
    return freshData;
  }
}

void main() {
  late FakeHomeRepository fakeRepo;
  late FakeNetworkMonitorService fakeNetworkMonitor;
  late LoadHomeFeed loadHomeFeed;

  const sampleData = HomeViewData(
    greeting: 'Good morning',
    sections: [],
    chips: [],
  );

  setUp(() {
    fakeRepo = FakeHomeRepository();
    fakeNetworkMonitor = FakeNetworkMonitorService();
    loadHomeFeed = LoadHomeFeed(fakeRepo);
  });

  tearDown(() {
    fakeNetworkMonitor.dispose();
  });

  test('offline with cached data emits HomeFeedLoaded without hanging or error screen', () async {
    fakeNetworkMonitor.setStatus(NetworkStatus.offline);
    fakeRepo.cachedData = sampleData;
    fakeRepo.freshData = null; // network returns null when offline

    final bloc = HomeFeedBloc(
      loadHomeFeed: loadHomeFeed,
      networkMonitor: fakeNetworkMonitor,
    );

    final states = <HomeFeedState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const HomeFeedLoadRequested());
    await pumpEventQueue();

    expect(states, [
      const HomeFeedLoaded(sampleData),
    ]);
    expect(fakeRepo.fetchFreshCalled, isTrue);

    await sub.cancel();
    await bloc.close();
  });

  test('refresh while offline stops refreshing spinner and emits offline notification toast', () async {
    fakeNetworkMonitor.setStatus(NetworkStatus.offline);
    fakeRepo.cachedData = sampleData;
    fakeRepo.freshData = null;

    final bloc = HomeFeedBloc(
      loadHomeFeed: loadHomeFeed,
      networkMonitor: fakeNetworkMonitor,
    );

    // Initial load
    bloc.add(const HomeFeedLoadRequested());
    await pumpEventQueue();

    final states = <HomeFeedState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const HomeFeedRefreshRequested());
    await pumpEventQueue();

    expect(states, [
      const HomeFeedLoaded(sampleData, isRefreshing: true),
      const HomeFeedLoaded(sampleData, isRefreshing: false),
      const HomeFeedError(
        "You're offline. Content will update when connected.",
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

    final bloc = HomeFeedBloc(
      loadHomeFeed: loadHomeFeed,
      networkMonitor: fakeNetworkMonitor,
    );

    bloc.add(const HomeFeedLoadRequested());
    await pumpEventQueue();

    // Trigger error state via refresh
    bloc.add(const HomeFeedRefreshRequested());
    await pumpEventQueue();

    const restoredData = HomeViewData(
      greeting: 'Good evening',
      sections: [],
      chips: [],
    );
    fakeRepo.freshData = restoredData;

    // Network is restored
    fakeNetworkMonitor.setStatus(NetworkStatus.restored);
    await pumpEventQueue();

    expect(bloc.state, isA<HomeFeedLoaded>());
    expect((bloc.state as HomeFeedLoaded).data.greeting, equals('Good evening'));

    await bloc.close();
  });

  test('inactive tab in background defers refresh until HomeFeedActivated is dispatched on tab return', () async {
    fakeNetworkMonitor.setStatus(NetworkStatus.offline);
    fakeRepo.cachedData = sampleData;
    fakeRepo.freshData = null;

    final bloc = HomeFeedBloc(
      loadHomeFeed: loadHomeFeed,
      networkMonitor: fakeNetworkMonitor,
    );

    bloc.add(const HomeFeedLoadRequested());
    await pumpEventQueue();
    expect(bloc.state, equals(const HomeFeedLoaded(sampleData)));

    // User navigates away to another tab
    bloc.add(const HomeFeedCancelRequested());
    await pumpEventQueue();

    const restoredData = HomeViewData(
      greeting: 'Deferred Good Evening',
      sections: [],
      chips: [],
    );
    fakeRepo.freshData = restoredData;

    // Network is restored while Home tab is inactive
    fakeNetworkMonitor.setStatus(NetworkStatus.restored);
    await pumpEventQueue();

    // Still showing stale data because tab is in background
    expect((bloc.state as HomeFeedLoaded).data.greeting, equals('Good morning'));

    // User navigates back to Home tab
    bloc.add(const HomeFeedActivated());
    await pumpEventQueue();

    // Now revalidation runs and fresh data is displayed
    expect((bloc.state as HomeFeedLoaded).data.greeting, equals('Deferred Good Evening'));

    await bloc.close();
  });
}
