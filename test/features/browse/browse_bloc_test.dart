import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';
import 'package:musify_mu/features/browse/application/browse_bloc.dart';
import 'package:musify_mu/features/browse/domain/repositories/browse_repository.dart';
import 'package:musify_mu/features/browse/domain/usecases/load_browse.dart';

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

class FakeBrowseRepository implements BrowseRepository {
  BrowseViewData? cachedData;
  BrowseViewData? freshData;
  bool fetchBrowseCalled = false;

  @override
  Future<BrowseViewData?> loadCached() async => cachedData;

  @override
  Future<BrowseViewData?> fetchBrowse({CancelToken? cancelToken}) async {
    fetchBrowseCalled = true;
    return freshData;
  }
}

void main() {
  late FakeBrowseRepository fakeRepo;
  late FakeNetworkMonitorService fakeNetworkMonitor;
  late LoadBrowse loadBrowse;

  const sampleData = BrowseViewData(
    sections: [
      BrowseSection(
        sectionId: 'sec_1',
        sectionType: 'grid',
        title: 'Podcasts',
        items: [],
      ),
    ],
  );

  setUp(() {
    fakeRepo = FakeBrowseRepository();
    fakeNetworkMonitor = FakeNetworkMonitorService();
    loadBrowse = LoadBrowse(fakeRepo);
  });

  tearDown(() {
    fakeNetworkMonitor.dispose();
  });

  test('offline with cached data emits BrowseLoaded immediately without loading shimmer', () async {
    fakeNetworkMonitor.setStatus(NetworkStatus.offline);
    fakeRepo.cachedData = sampleData;

    final bloc = BrowseBloc(
      loadBrowse: loadBrowse,
      networkMonitor: fakeNetworkMonitor,
    );

    final states = <BrowseState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const BrowseLoadRequested());
    await pumpEventQueue();

    expect(states, [
      const BrowseLoaded(sampleData),
    ]);
    expect(fakeRepo.fetchBrowseCalled, isTrue);

    await sub.cancel();
    await bloc.close();
  });

  test('offline without cached data emits BrowseError without hanging on shimmer', () async {
    fakeNetworkMonitor.setStatus(NetworkStatus.offline);
    fakeRepo.cachedData = null;

    final bloc = BrowseBloc(
      loadBrowse: loadBrowse,
      networkMonitor: fakeNetworkMonitor,
    );

    final states = <BrowseState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const BrowseLoadRequested());
    await pumpEventQueue();

    expect(states, [
      const BrowseError("You're offline. Please check your connection."),
    ]);

    await sub.cancel();
    await bloc.close();
  });

  test('online with cached data emits BrowseLoaded(cached) then revalidates with fresh data', () async {
    fakeNetworkMonitor.setStatus(NetworkStatus.online);
    fakeRepo.cachedData = sampleData;
    const freshData = BrowseViewData(
      sections: [
        BrowseSection(
          sectionId: 'sec_1',
          sectionType: 'grid',
          title: 'Fresh Categories',
          items: [],
        ),
      ],
    );
    fakeRepo.freshData = freshData;

    final bloc = BrowseBloc(
      loadBrowse: loadBrowse,
      networkMonitor: fakeNetworkMonitor,
    );

    final states = <BrowseState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const BrowseLoadRequested());
    await pumpEventQueue();

    expect(states, [
      const BrowseLoaded(sampleData),
      const BrowseLoaded(freshData),
    ]);
    expect(fakeRepo.fetchBrowseCalled, isTrue);

    await sub.cancel();
    await bloc.close();
  });

  test('refresh while offline stops refreshing spinner and emits offline notification toast', () async {
    fakeNetworkMonitor.setStatus(NetworkStatus.offline);
    fakeRepo.cachedData = sampleData;
    fakeRepo.freshData = null;

    final bloc = BrowseBloc(
      loadBrowse: loadBrowse,
      networkMonitor: fakeNetworkMonitor,
    );

    // Initial load
    bloc.add(const BrowseLoadRequested());
    await pumpEventQueue();

    final states = <BrowseState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const BrowseRefreshRequested());
    await pumpEventQueue();

    expect(states, [
      const BrowseLoaded(sampleData, isRefreshing: true),
      const BrowseLoaded(sampleData, isRefreshing: false),
      const BrowseError(
        "You're offline. Content will update when connected.",
        staleData: sampleData,
      ),
    ]);

    await sub.cancel();
    await bloc.close();
  });

  test('reconnection triggers refresh on active tab even when already loaded', () async {
    fakeNetworkMonitor.setStatus(NetworkStatus.offline);
    fakeRepo.cachedData = sampleData;
    fakeRepo.freshData = null;

    final bloc = BrowseBloc(
      loadBrowse: loadBrowse,
      networkMonitor: fakeNetworkMonitor,
    );

    bloc.add(const BrowseLoadRequested());
    await pumpEventQueue();
    expect(bloc.state, equals(const BrowseLoaded(sampleData)));

    const restoredData = BrowseViewData(
      sections: [
        BrowseSection(
          sectionId: 'sec_restored',
          sectionType: 'grid',
          title: 'Restored Categories',
          items: [],
        ),
      ],
    );
    fakeRepo.freshData = restoredData;

    // Network is restored
    fakeNetworkMonitor.setStatus(NetworkStatus.restored);
    await pumpEventQueue();

    expect(bloc.state, isA<BrowseLoaded>());
    expect((bloc.state as BrowseLoaded).data.sections.first.title, equals('Restored Categories'));

    await bloc.close();
  });

  test('inactive tab in background defers refresh until BrowseActivated is dispatched on tab return', () async {
    fakeNetworkMonitor.setStatus(NetworkStatus.offline);
    fakeRepo.cachedData = sampleData;
    fakeRepo.freshData = null;

    final bloc = BrowseBloc(
      loadBrowse: loadBrowse,
      networkMonitor: fakeNetworkMonitor,
    );

    bloc.add(const BrowseLoadRequested());
    await pumpEventQueue();
    expect(bloc.state, equals(const BrowseLoaded(sampleData)));

    // User switches to another tab -> cancel requested
    bloc.add(const BrowseCancelRequested());
    await pumpEventQueue();

    const restoredData = BrowseViewData(
      sections: [
        BrowseSection(
          sectionId: 'sec_restored',
          sectionType: 'grid',
          title: 'Deferred Restored Categories',
          items: [],
        ),
      ],
    );
    fakeRepo.freshData = restoredData;

    // Network is restored while tab is inactive
    fakeNetworkMonitor.setStatus(NetworkStatus.restored);
    await pumpEventQueue();

    // Still showing stale data because tab is in background
    expect((bloc.state as BrowseLoaded).data.sections.first.title, equals('Podcasts'));

    // User navigates back to Browse tab
    bloc.add(const BrowseActivated());
    await pumpEventQueue();

    // Now revalidation runs and fresh data is displayed
    expect((bloc.state as BrowseLoaded).data.sections.first.title, equals('Deferred Restored Categories'));

    await bloc.close();
  });
}
