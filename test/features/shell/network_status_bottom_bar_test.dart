import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/network/status/bloc/network_status_bloc.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';
import 'package:musify_mu/features/shell/presentation/widgets/network_status_bottom_bar.dart';

class MockNetworkMonitorService implements NetworkMonitorService {
  final _controller = StreamController<NetworkStatus>.broadcast();
  NetworkStatus _status = NetworkStatus.online;

  @override
  NetworkStatus get currentStatus => _status;

  @override
  Stream<NetworkStatus> get statusStream => _controller.stream;

  void emitStatus(NetworkStatus status) {
    _status = status;
    _controller.add(status);
  }

  @override
  void recordLatency(Duration latency) {}

  @override
  void recordTimeout() {}

  @override
  void recordSuccess() {}

  @override
  void dispose() {
    _controller.close();
  }
}

void main() {
  group('NetworkStatusBottomBar', () {
    late MockNetworkMonitorService mockService;
    late NetworkStatusBloc bloc;

    Widget createWidgetUnderTest(
      NetworkStatusBloc blocInstance, {
      EdgeInsets padding = EdgeInsets.zero,
    }) {
      return MediaQuery(
        data: MediaQueryData(padding: padding),
        child: MaterialApp(
          home: Scaffold(
            body: BlocProvider<NetworkStatusBloc>.value(
              value: blocInstance,
              child: const NetworkStatusBottomBar(),
            ),
          ),
        ),
      );
    }

    setUp(() {
      mockService = MockNetworkMonitorService();
    });

    tearDown(() {
      bloc.close();
      mockService.dispose();
    });

    testWidgets('renders 0 height when online', (tester) async {
      bloc = NetworkStatusBloc(monitorService: mockService);

      await tester.pumpWidget(createWidgetUnderTest(bloc));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        tester.getSize(find.byType(AnimatedContainer)).height,
        equals(0.0),
      );
      expect(find.text('No internet connection'), findsNothing);
    });

    testWidgets('renders 16px red bar with correct text when offline', (tester) async {
      bloc = NetworkStatusBloc(
        monitorService: mockService,
        initialState: const NetworkStatusState(
          status: NetworkStatus.offline,
          message: 'No internet connection',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest(bloc));
      await tester.pump(const Duration(milliseconds: 300));

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        tester.getSize(find.byType(AnimatedContainer)).height,
        equals(16.0),
      );
      final decoration = animatedContainer.decoration as BoxDecoration?;
      expect(decoration?.color, equals(const Color(0xFFE22134)));
      expect(find.text('No internet connection'), findsOneWidget);
    });

    testWidgets('renders 16px + bottom inset when system navigation bar is present', (tester) async {
      bloc = NetworkStatusBloc(
        monitorService: mockService,
        initialState: const NetworkStatusState(
          status: NetworkStatus.offline,
          message: 'No internet connection',
        ),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          bloc,
          padding: const EdgeInsets.only(bottom: 28.0),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        tester.getSize(find.byType(AnimatedContainer)).height,
        equals(16.0 + 28.0),
      );
      expect(find.text('No internet connection'), findsOneWidget);
    });

    testWidgets('renders 16px amber bar with correct text when slow', (tester) async {
      bloc = NetworkStatusBloc(
        monitorService: mockService,
        initialState: const NetworkStatusState(
          status: NetworkStatus.slow,
          message: 'Slow connection',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest(bloc));
      await tester.pump(const Duration(milliseconds: 300));

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        tester.getSize(find.byType(AnimatedContainer)).height,
        equals(16.0),
      );
      final decoration = animatedContainer.decoration as BoxDecoration?;
      expect(decoration?.color, equals(const Color(0xFFFFA000)));
      expect(find.text('Slow connection'), findsOneWidget);
    });

    testWidgets('renders 16px green bar when restored', (tester) async {
      bloc = NetworkStatusBloc(
        monitorService: mockService,
        initialState: const NetworkStatusState(
          status: NetworkStatus.restored,
          message: 'Back online',
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest(bloc));
      await tester.pump(const Duration(milliseconds: 300));

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        tester.getSize(find.byType(AnimatedContainer)).height,
        equals(16.0),
      );
      final decoration = animatedContainer.decoration as BoxDecoration?;
      expect(decoration?.color, equals(const Color(0xFF1DB954)));
      expect(find.text('Back online'), findsOneWidget);
    });
  });
}
