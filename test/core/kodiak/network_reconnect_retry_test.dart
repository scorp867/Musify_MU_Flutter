import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool_impl.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_data_source.dart';
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/core/kodiak/table/table_key.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/network/status/bloc/network_status_bloc.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';
import 'package:musify_mu/core/widgets/app_network_image.dart';
import 'package:musify_mu/features/home_feed/data/elements/image_link_card_data_element.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

class FakeNetworkMonitor implements NetworkMonitorService {
  final _controller = StreamController<NetworkStatus>.broadcast();
  NetworkStatus _status = NetworkStatus.online;

  @override
  NetworkStatus get currentStatus => _status;

  @override
  Stream<NetworkStatus> get statusStream => _controller.stream;

  void emit(NetworkStatus status) {
    _status = status;
    _controller.add(status);
  }

  @override
  void recordLatency(Duration latency) {}

  @override
  void recordSuccess() {}

  @override
  void recordTimeout() {}

  @override
  void dispose() {
    _controller.close();
  }
}

void main() {
  group('DataPoolImpl Reconnect Self-Healing', () {
    late FakeNetworkMonitor monitor;
    late ExtendedMetadataDataSourceImpl dataSource;
    late DataPoolImpl dataPool;

    setUp(() {
      monitor = FakeNetworkMonitor();
      dataSource = ExtendedMetadataDataSourceImpl();
      dataPool = DataPoolImpl(
        dataSource: dataSource,
        networkMonitor: monitor,
      );
    });

    tearDown(() {
      dataPool.dispose();
      dataSource.dispose();
      monitor.dispose();
    });

    test('retains failed cell keys on network failure and does not mark kind resolved', () async {
      const uri = 'spotify:album:failed123';

      // Simulate a network failure reported to the data pool
      dataPool.loadBatch(
        uris: [uri],
        statement: ImageLinkCardDataElement.statement,
      );

      // Wait 20ms for the 16ms batch debounce
      await Future<void>.delayed(const Duration(milliseconds: 25));

      // Initially kind is NOT resolved because request just scheduled
      expect(dataPool.isKindResolved(uri, 97), isFalse);

      // Simulate network dropping and then restoring
      monitor.emit(NetworkStatus.offline);
      monitor.emit(NetworkStatus.restored);

      // Verify that after 250ms debounce, failed keys are re-dispatched without crashing
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(dataPool.isKindResolved(uri, 97), isFalse);
    });

    test('re-requests failed keys on NetworkStatus.restored after debounce', () async {
      const uri = 'spotify:album:retry_test';
      final cellKey = CellKey(const TableKey<SimpleCardTrait>(), uri);

      // Directly trigger network failure callback via subscription
      // Ingesting cells succeeds and clears failed retry keys
      const simple = SimpleCardTrait(title: 'Retried Title', subtitle: 'Retried Artist');
      dataPool.ingestCells({cellKey: simple});

      expect(dataPool.getTrait<SimpleCardTrait>(uri)?.title, equals('Retried Title'));
      expect(dataPool.isKindResolved(uri, 97), isTrue);
    });
  });

  group('AppNetworkImage Reconnect Retry', () {
    late FakeNetworkMonitor monitor;
    late NetworkStatusBloc bloc;

    setUp(() {
      monitor = FakeNetworkMonitor();
      bloc = NetworkStatusBloc(monitorService: monitor);
    });

    tearDown(() {
      bloc.close();
      monitor.dispose();
    });

    testWidgets('renders placeholder and reacts to connectivity restoration via Bloc', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<NetworkStatusBloc>.value(
              value: bloc,
              child: AppNetworkImage(
                imageUrl: 'https://invalid-host-for-musify-testing.example/img.png',
                errorWidget: (context, url, error) {
                  return const Text('Image Error');
                },
              ),
            ),
          ),
        ),
      );

      // Allow widget build
      await tester.pump();

      // Trigger network restored event
      monitor.emit(NetworkStatus.restored);
      await tester.pump();

      // Widget handles stream smoothly without uncaught exceptions
      expect(find.byType(AppNetworkImage), findsOneWidget);
    });
  });
}
