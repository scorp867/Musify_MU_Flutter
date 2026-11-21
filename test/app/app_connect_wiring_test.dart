// 1:1 replica of Spotify Connect root application wiring tests for
// lib/app/app.dart (p199p/yrq.java, p199p/edi0.java, ConnectSubsystem.cpp:74).

import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:musify_mu/app/app.dart';
import 'package:musify_mu/app/di/connect_injection.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/application/sorting/device_picker_sorting_database.dart';
import 'package:musify_mu/features/connect/application/volume/remote_volume_controller.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/connect_volume_service_client.dart';
import 'package:musify_mu/features/connect/data/esperanto/dodo_service_client.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart'
    as common_pb;
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pbenum.dart'
    as common_pbenum;
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pb.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/presentation/screens/device_picker_sheet.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_device_label.dart';
import 'package:musify_mu/features/player/application/queue/mobius/queue_event.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';
import 'package:musify_mu/features/player/presentation/widgets/mini_player.dart';
import 'package:musify_mu/features/shell/presentation/hidden_drawer_scaffold.dart';
import 'package:musify_mu/features/shell/presentation/main_screen.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';

import '../features/vault/integration/integration_test_helpers.dart';

final class _AppFakeTransport implements EsperantoTransport {
  final StreamController<Uint8List> stateStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> volumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> localVolumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> dodoStreamController =
      StreamController<Uint8List>.broadcast();

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    return Uint8List.fromList(
      common_pb.StatusResponse(
        status: common_pbenum.Status.OK,
      ).writeToBuffer(),
    );
  }

  @override
  Stream<Uint8List> callStream(
    String service,
    String method,
    Uint8List payload,
  ) {
    if (service == ConnectServiceClient.serviceName && method == 'State') {
      return stateStreamController.stream;
    }
    if (service == ConnectVolumeServiceClient.serviceName &&
        method == 'Volume') {
      return volumeStreamController.stream;
    }
    if (service == ConnectVolumeServiceClient.serviceName &&
        method == 'LocalVolume') {
      return localVolumeStreamController.stream;
    }
    if (service == DodoServiceClient.serviceName && method == 'DodoSub') {
      return dodoStreamController.stream;
    }
    return const Stream<Uint8List>.empty();
  }

  @override
  Uint8List callSync(String service, String method, Uint8List payload) {
    return Uint8List(0);
  }

  void emitCluster({
    required bool selfActive,
    String? remoteName,
    bool remoteActive = false,
  }) {
    final devices = <connect_pb.StateResponse_Device>[
      connect_pb.StateResponse_Device(
        isSelf: true,
        isActive: selfActive,
        isLocal: true,
        supportsLogout: false,
        supportsVolume: true,
        connectStateIdentifier: 'self-1',
        localIdentifier: 'local-self-1',
        name: 'My Phone',
        state: 'LOGGED_IN',
        type: 'SMARTPHONE',
        volume: 32768,
        volumeSteps: 24,
        capabilities: '[]',
      ),
      if (remoteName != null)
        connect_pb.StateResponse_Device(
          isSelf: false,
          isActive: remoteActive,
          isLocal: true,
          supportsLogout: true,
          supportsVolume: true,
          connectStateIdentifier: 'remote-1',
          localIdentifier: 'local-remote-1',
          name: remoteName,
          state: 'LOGGED_IN',
          type: 'SPEAKER',
          volume: 32768,
          volumeSteps: 24,
          capabilities: '[]',
        ),
    ];
    final response = connect_pb.StateResponse(
      isActive: false,
      devices: devices,
      isSyncedWithBackend: true,
    );
    stateStreamController.add(
      Uint8List.fromList(response.writeToBuffer()),
    );
  }

  Future<void> close() async {
    await stateStreamController.close();
    await volumeStreamController.close();
    await localVolumeStreamController.close();
    await dodoStreamController.close();
  }
}

final class _ConnectTestBundle {
  _ConnectTestBundle._({
    required this.transport,
    required this.sortingDb,
    required this.volumeController,
    required this.controller,
  });

  factory _ConnectTestBundle({required String commandId}) {
    final transport = _AppFakeTransport();
    final sortingDb = DevicePickerSortingDatabase.forTesting(
      NativeDatabase.memory(),
    );
    final volumeClient = ConnectVolumeServiceClient(transport);
    final volumeController = RemoteVolumeController(
      volumeClient: volumeClient,
      throttleWindow: Duration.zero,
      suppressionWindow: Duration.zero,
      localDebounceWindow: Duration.zero,
    );
    final controller = ConnectMobiusController(
      connectServiceClient: ConnectServiceClient(transport),
      volumeServiceClient: volumeClient,
      dodoServiceClient: DodoServiceClient(transport),
      sortingDatabase: sortingDb,
      remoteVolumeController: volumeController,
      commandIdGenerator: () => commandId,
    )..start();
    return _ConnectTestBundle._(
      transport: transport,
      sortingDb: sortingDb,
      volumeController: volumeController,
      controller: controller,
    );
  }

  final _AppFakeTransport transport;
  final DevicePickerSortingDatabase sortingDb;
  final RemoteVolumeController volumeController;
  final ConnectMobiusController controller;

  Future<void> dispose() async {
    await controller.close();
    await volumeController.dispose();
    await sortingDb.close();
    await transport.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<TestVaultHarness> createSeededVaultHarness(
    WidgetTester tester,
  ) async {
    final harness = TestVaultHarness();
    await tester.runAsync(harness.setup);
    // Omit imageUrl so FakeColorExtractionService is not invoked.
    harness.mobiusController.dispatch(
      const QueueUpdatedEvent(
        PlayerQueue(
          track: ContextTrack(
            uri: 'spotify:track:app-wiring-1',
            metadata: <String, String>{
              'title': 'App Track',
              'artist_name': 'App Artist',
            },
          ),
        ),
      ),
    );
    return harness;
  }

  Widget buildMusifyApp({ConnectMobiusController? connectController}) {
    return MusifyApp(
      createAuthBloc: () => FakeAuthBloc(),
      createLocalMusicBloc: () => FakeLocalMusicBloc(),
      connectController: connectController,
    );
  }

  Finder rootNavigatorFinder() {
    return find.ancestor(
      of: find.byType(HiddenDrawerScaffold),
      matching: find.byType(Navigator),
    );
  }

  void expectForwardedController(
    WidgetTester tester,
    ConnectMobiusController? expectedController,
  ) {
    final hiddenDrawer = tester.widget<HiddenDrawerScaffold>(
      find.byType(HiddenDrawerScaffold),
    );
    final mainScreen = tester.widget<MainScreen>(find.byType(MainScreen));
    final miniPlayer = tester.widget<MiniPlayer>(find.byType(MiniPlayer));

    expect(
      identical(hiddenDrawer.connectController, expectedController),
      isTrue,
    );
    expect(identical(mainScreen.connectController, expectedController), isTrue);
    expect(identical(miniPlayer.connectController, expectedController), isTrue);

    final materialAppElement = tester.element(find.byType(MaterialApp));
    if (expectedController case final active?) {
      expect(
        identical(materialAppElement.read<ConnectMobiusController>(), active),
        isTrue,
      );
    } else {
      expect(
        () => materialAppElement.read<ConnectMobiusController>(),
        throwsA(isA<ProviderNotFoundException>()),
      );
    }
  }

  group('MusifyApp Connect Wiring & State Preservation', () {
    testWidgets(
      'transitions null -> ctrlA -> ctrlB -> null without MaterialApp or VaultSessionBloc teardown',
      (tester) async {
        configureViewport(tester);
        final harness = await createSeededVaultHarness(tester);
        final bundleA = _ConnectTestBundle(
          commandId: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        );
        final bundleB = _ConnectTestBundle(
          commandId: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        );
        addTearDown(() async {
          await tester.runAsync(() async {
            await bundleA.dispose();
            await bundleB.dispose();
            await harness.tearDown();
          });
        });

        await tester.pumpWidget(buildMusifyApp());
        await tester.pump();
        await tester.pump();

        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('mini_player_connect_label')),
          findsNothing,
        );
        expectForwardedController(tester, null);

        final initialMaterialAppState = tester.state(find.byType(MaterialApp));
        final initialVaultBlocElement = tester.element(
          find.byType(BlocProvider<VaultSessionBloc>),
        );
        final initialRootNavigatorState = tester.state<NavigatorState>(
          rootNavigatorFinder(),
        );
        final initialHiddenDrawerState = tester.state(
          find.byType(HiddenDrawerScaffold),
        );
        final initialMainScreenState = tester.state(find.byType(MainScreen));

        // Step 1: null -> ctrlA
        await tester.pumpWidget(
          buildMusifyApp(connectController: bundleA.controller),
        );
        bundleA.transport.emitCluster(
          selfActive: false,
          remoteName: 'Speaker Alpha',
          remoteActive: true,
        );
        await tester.pump();
        await tester.pump();

        expect(
          identical(
            tester.state(find.byType(MaterialApp)),
            initialMaterialAppState,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.element(find.byType(BlocProvider<VaultSessionBloc>)),
            initialVaultBlocElement,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.state<NavigatorState>(rootNavigatorFinder()),
            initialRootNavigatorState,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.state(find.byType(HiddenDrawerScaffold)),
            initialHiddenDrawerState,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.state(find.byType(MainScreen)),
            initialMainScreenState,
          ),
          isTrue,
        );
        expectForwardedController(tester, bundleA.controller);
        expect(
          find.byKey(const ValueKey<String>('mini_player_connect_label')),
          findsOneWidget,
        );
        expect(find.text('Speaker Alpha'), findsOneWidget);

        // Step 2: ctrlA -> ctrlB
        await tester.pumpWidget(
          buildMusifyApp(connectController: bundleB.controller),
        );
        bundleB.transport.emitCluster(
          selfActive: false,
          remoteName: 'Speaker Beta',
          remoteActive: true,
        );
        await tester.pump();
        await tester.pump();

        expect(
          identical(
            tester.state(find.byType(MaterialApp)),
            initialMaterialAppState,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.element(find.byType(BlocProvider<VaultSessionBloc>)),
            initialVaultBlocElement,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.state<NavigatorState>(rootNavigatorFinder()),
            initialRootNavigatorState,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.state(find.byType(HiddenDrawerScaffold)),
            initialHiddenDrawerState,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.state(find.byType(MainScreen)),
            initialMainScreenState,
          ),
          isTrue,
        );
        expectForwardedController(tester, bundleB.controller);
        expect(
          find.byKey(const ValueKey<String>('mini_player_connect_label')),
          findsOneWidget,
        );
        expect(find.text('Speaker Beta'), findsOneWidget);

        // Step 3: ctrlB -> null
        await tester.pumpWidget(buildMusifyApp());
        await tester.pump();
        await tester.pump();

        expect(
          identical(
            tester.state(find.byType(MaterialApp)),
            initialMaterialAppState,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.element(find.byType(BlocProvider<VaultSessionBloc>)),
            initialVaultBlocElement,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.state<NavigatorState>(rootNavigatorFinder()),
            initialRootNavigatorState,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.state(find.byType(HiddenDrawerScaffold)),
            initialHiddenDrawerState,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.state(find.byType(MainScreen)),
            initialMainScreenState,
          ),
          isTrue,
        );
        expectForwardedController(tester, null);
        expect(
          find.byKey(const ValueKey<String>('mini_player_connect_label')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'transitions ctrlA -> null, dropping BlocProvider and hiding MiniPlayer Connect label with zero teardown',
      (tester) async {
        configureViewport(tester);
        final harness = await createSeededVaultHarness(tester);
        final bundleA = _ConnectTestBundle(
          commandId: 'cccccccccccccccccccccccccccccccc',
        );
        addTearDown(() async {
          await tester.runAsync(() async {
            await bundleA.dispose();
            await harness.tearDown();
          });
        });

        await tester.pumpWidget(
          buildMusifyApp(connectController: bundleA.controller),
        );
        bundleA.transport.emitCluster(
          selfActive: false,
          remoteName: 'Living Room Soundbar',
          remoteActive: true,
        );
        await tester.pump();
        await tester.pump();

        expectForwardedController(tester, bundleA.controller);
        expect(
          find.byKey(const ValueKey<String>('mini_player_connect_label')),
          findsOneWidget,
        );
        expect(find.text('Living Room Soundbar'), findsOneWidget);

        final initialMaterialAppState = tester.state(find.byType(MaterialApp));
        final initialVaultBlocElement = tester.element(
          find.byType(BlocProvider<VaultSessionBloc>),
        );
        final initialRootNavigatorState = tester.state<NavigatorState>(
          rootNavigatorFinder(),
        );
        final initialHiddenDrawerState = tester.state(
          find.byType(HiddenDrawerScaffold),
        );
        final initialMainScreenState = tester.state(find.byType(MainScreen));

        await tester.pumpWidget(buildMusifyApp());
        await tester.pump();
        await tester.pump();

        expect(
          identical(
            tester.state(find.byType(MaterialApp)),
            initialMaterialAppState,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.element(find.byType(BlocProvider<VaultSessionBloc>)),
            initialVaultBlocElement,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.state<NavigatorState>(rootNavigatorFinder()),
            initialRootNavigatorState,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.state(find.byType(HiddenDrawerScaffold)),
            initialHiddenDrawerState,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.state(find.byType(MainScreen)),
            initialMainScreenState,
          ),
          isTrue,
        );
        expectForwardedController(tester, null);
        expect(
          find.byKey(const ValueKey<String>('mini_player_connect_label')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'resolves ConnectMobiusController from GetIt and swaps cleanly across null (DI) -> external -> null (DI)',
      (tester) async {
        configureViewport(tester);
        final harness = await createSeededVaultHarness(tester);
        final diTransport = _AppFakeTransport();
        final diSortingDb = DevicePickerSortingDatabase.forTesting(
          NativeDatabase.memory(),
        );
        final sl = GetIt.instance;
        sl.registerSingleton<EsperantoTransport>(diTransport);
        sl.registerSingleton<DevicePickerSortingDatabase>(
          diSortingDb,
          dispose: (db) => db.close(),
        );
        setupConnectInjection(sl);

        final externalBundle = _ConnectTestBundle(
          commandId: 'dddddddddddddddddddddddddddddddd',
        );
        addTearDown(() async {
          await tester.runAsync(() async {
            await externalBundle.dispose();
            await harness.tearDown();
            await diTransport.close();
          });
        });

        await tester.pumpWidget(buildMusifyApp());
        await tester.pump();
        await tester.pump();

        final diController = sl<ConnectMobiusController>();
        // On non-Android hosts, autoStart remains false until explicit start.
        expect(diController.isStarted, isFalse);
        diController.start();
        diTransport.emitCluster(
          selfActive: false,
          remoteName: 'DI Studio Speaker',
          remoteActive: true,
        );
        await tester.pump();
        await tester.pump();

        expectForwardedController(tester, diController);
        expect(find.byType(ConnectDeviceLabel), findsOneWidget);
        expect(find.text('DI Studio Speaker'), findsOneWidget);

        final initialMaterialAppState = tester.state(find.byType(MaterialApp));
        final initialVaultBlocElement = tester.element(
          find.byType(BlocProvider<VaultSessionBloc>),
        );
        final initialRootNavigatorState = tester.state<NavigatorState>(
          rootNavigatorFinder(),
        );
        final initialHiddenDrawerState = tester.state(
          find.byType(HiddenDrawerScaffold),
        );
        final initialMainScreenState = tester.state(find.byType(MainScreen));

        // External override
        await tester.pumpWidget(
          buildMusifyApp(connectController: externalBundle.controller),
        );
        externalBundle.transport.emitCluster(
          selfActive: false,
          remoteName: 'External Speaker',
          remoteActive: true,
        );
        await tester.pump();
        await tester.pump();

        expect(
          identical(
            tester.state(find.byType(MaterialApp)),
            initialMaterialAppState,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.element(find.byType(BlocProvider<VaultSessionBloc>)),
            initialVaultBlocElement,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.state<NavigatorState>(rootNavigatorFinder()),
            initialRootNavigatorState,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.state(find.byType(HiddenDrawerScaffold)),
            initialHiddenDrawerState,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.state(find.byType(MainScreen)),
            initialMainScreenState,
          ),
          isTrue,
        );
        expectForwardedController(tester, externalBundle.controller);
        expect(find.text('External Speaker'), findsOneWidget);

        // Revert to DI controller (widget.connectController == null)
        await tester.pumpWidget(buildMusifyApp());
        await tester.pump();
        await tester.pump();

        expect(
          identical(
            tester.state(find.byType(MaterialApp)),
            initialMaterialAppState,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.element(find.byType(BlocProvider<VaultSessionBloc>)),
            initialVaultBlocElement,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.state<NavigatorState>(rootNavigatorFinder()),
            initialRootNavigatorState,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.state(find.byType(HiddenDrawerScaffold)),
            initialHiddenDrawerState,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.state(find.byType(MainScreen)),
            initialMainScreenState,
          ),
          isTrue,
        );
        expectForwardedController(tester, diController);
        expect(find.text('DI Studio Speaker'), findsOneWidget);
      },
    );

    testWidgets(
      'MainScreen renders remote_active_connect_fallback_bar when local nowPlaying == null and a remote Connect device is active, and tapping remote_fallback_open_picker_button opens DevicePickerSheet',
      (tester) async {
        configureViewport(tester);
        final harness = TestVaultHarness();
        await tester.runAsync(harness.setup);
        final bundle = _ConnectTestBundle(
          commandId: 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
        );
        addTearDown(() async {
          await tester.runAsync(() async {
            await bundle.dispose();
            await harness.tearDown();
          });
        });

        // Ensure local nowPlaying is null
        expect(harness.mobiusController.state.nowPlaying, isNull);

        await tester.pumpWidget(
          buildMusifyApp(connectController: bundle.controller),
        );
        await tester.pump();
        await tester.pump();

        final fallbackBarFinder = find.byKey(
          const ValueKey<String>('remote_active_connect_fallback_bar'),
        );
        final openPickerButtonFinder = find.byKey(
          const ValueKey<String>('remote_fallback_open_picker_button'),
        );

        // When self device is active and nowPlaying == null, neither MiniPlayer nor fallback bar is shown
        bundle.transport.emitCluster(selfActive: true);
        await tester.pump();
        await tester.pump();

        expect(find.byType(MiniPlayer), findsNothing);
        expect(fallbackBarFinder, findsNothing);

        // When a remote Connect device becomes active while nowPlaying == null, fallback bar renders
        bundle.transport.emitCluster(
          selfActive: false,
          remoteName: 'Living Room Sonos',
          remoteActive: true,
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(MiniPlayer), findsNothing);
        expect(fallbackBarFinder, findsOneWidget);
        expect(openPickerButtonFinder, findsOneWidget);
        expect(find.text('Listening on Living Room Sonos'), findsOneWidget);
        expect(find.text('Living Room Sonos'), findsOneWidget);

        // Tapping remote_fallback_open_picker_button opens DevicePickerSheet
        await tester.tap(openPickerButtonFinder);
        await tester.pumpAndSettle();

        expect(find.byType(DevicePickerSheet), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(DevicePickerSheet),
            matching: find.text('Living Room Sonos'),
          ),
          findsOneWidget,
        );

        Navigator.of(
          tester.element(find.byType(DevicePickerSheet)),
        ).pop();
        await tester.pumpAndSettle();
        expect(find.byType(DevicePickerSheet), findsNothing);

        // When local nowPlaying becomes non-null, MainScreen switches from fallback bar to MiniPlayer
        harness.mobiusController.dispatch(
          const QueueUpdatedEvent(
            PlayerQueue(
              track: ContextTrack(
                uri: 'spotify:track:app-wiring-fallback-1',
                metadata: <String, String>{
                  'title': 'Mirrored Track',
                  'artist_name': 'Mirrored Artist',
                },
              ),
            ),
          ),
        );
        await tester.runAsync(() => pumpEventQueue());
        await tester.pump();
        await tester.pump();

        expect(fallbackBarFinder, findsNothing);
        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('mini_player_single_line_connect_mode')),
          findsOneWidget,
        );
        expect(find.text('Living Room Sonos'), findsOneWidget);
      },
    );
  });
}
