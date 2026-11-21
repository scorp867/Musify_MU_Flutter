import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/app/theme/app_theme.dart';
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
import 'package:musify_mu/features/connect/data/proto/es_volume_messages.pb.dart'
    as volume_pb;
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_volume_slider.dart';
import 'package:musify_mu/features/player/data/esperanto/esperanto_transport.dart';

final class _VolumeFakeTransport implements EsperantoTransport {
  final StreamController<Uint8List> stateStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> volumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> localVolumeStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> dodoStreamController =
      StreamController<Uint8List>.broadcast();

  final List<String> singleMethods = <String>[];
  final List<int> setVolumeValues = <int>[];

  @override
  Future<Uint8List> callSingle(
    String service,
    String method,
    Uint8List payload,
  ) async {
    singleMethods.add(method);
    if (service == ConnectVolumeServiceClient.serviceName) {
      if (method == 'VolumeSet') {
        final req = volume_pb.VolumeSetRequest.fromBuffer(payload);
        setVolumeValues.add(req.volume);
      }
      return Uint8List.fromList(
        common_pb.StatusResponse(
          status: common_pbenum.Status.OK,
        ).writeToBuffer(),
      );
    }
    return Uint8List(0);
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

  Future<void> close() async {
    await stateStreamController.close();
    await volumeStreamController.close();
    await localVolumeStreamController.close();
    await dodoStreamController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpotifyVolumeSliderBar & ConnectVolumeSlider (jel1/jth1)', () {
    testWidgets(
      'displays floating drag percentage flipping to white left of thumb above 85%',
      (tester) async {
        double latestValue = 0.5;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: SpotifyVolumeSliderBar(
                    value: latestValue,
                    deviceName: 'Kitchen Sonos',
                    enabled: true,
                    onChanged: (v) => latestValue = v,
                  ),
                ),
              ),
            ),
          ),
        );

        // Idle: percentage label hidden.
        expect(
          find.byKey(const ValueKey<String>('volume_drag_percentage_label')),
          findsNothing,
        );

        final trackFinder = find.byKey(
          const ValueKey<String>('connect_volume_track'),
        );
        final rect = tester.getRect(trackFinder);

        // Press at ~50% -> percentage label visible in #1ED760.
        final gesture = await tester.startGesture(
          Offset(rect.left + rect.width * 0.5, rect.center.dy),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 160));

        final labelFinder = find.byKey(
          const ValueKey<String>('volume_drag_percentage_label'),
        );
        expect(labelFinder, findsOneWidget);
        final midText = tester.widget<Text>(
          find.descendant(of: labelFinder, matching: find.byType(Text)),
        );
        expect(midText.style?.color, equals(ConnectEncoreTheme.brightAccent));

        // Drag above 85% -> percentage label turns white #FFFFFF.
        await gesture.moveTo(
          Offset(rect.left + rect.width * 0.92, rect.center.dy),
        );
        await tester.pump();
        final highText = tester.widget<Text>(
          find.descendant(of: labelFinder, matching: find.byType(Text)),
        );
        expect(highText.style?.color, equals(ConnectEncoreTheme.textBase));
        expect(latestValue, greaterThan(0.85));

        // Release -> percentage label disappears cleanly.
        await gesture.up();
        await tester.pumpAndSettle();
        expect(labelFinder, findsNothing);
      },
    );

    testWidgets(
      'taps step icons and drags through ConnectMobiusController to dispatch volume RPCs',
      (tester) async {
        final transport = _VolumeFakeTransport();
        final sortingDb = DevicePickerSortingDatabase.forTesting(
          NativeDatabase.memory(),
        );
        final volumeClient = ConnectVolumeServiceClient(transport);
        final volumeCtrl = RemoteVolumeController(
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
          remoteVolumeController: volumeCtrl,
        )..start();
        addTearDown(() async {
          await tester.runAsync(() async {
            await controller.close();
            await volumeCtrl.dispose();
            await sortingDb.close();
            await transport.close();
          });
        });

        transport.stateStreamController.add(
          Uint8List.fromList(
            connect_pb.StateResponse(
              isActive: true,
              isSyncedWithBackend: true,
              devices: [
                connect_pb.StateResponse_Device(
                  isSelf: false,
                  isActive: true,
                  isLocal: false,
                  connectStateIdentifier: 'sonos-1',
                  localIdentifier: 'local-sonos',
                  name: 'Kitchen Sonos',
                  state: 'LOGGED_IN',
                  type: 'SPEAKER',
                  volume: 32768,
                  volumeSteps: 24,
                  supportsVolume: true,
                  capabilities: '[]',
                ),
              ],
            ).writeToBuffer(),
          ),
        );
        transport.volumeStreamController.add(
          Uint8List.fromList(
            volume_pb.VolumeResponse(volume: 32768).writeToBuffer(),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: SizedBox(
                width: 340,
                child: ConnectVolumeSlider(
                  controller: controller,
                  deviceName: 'Kitchen Sonos',
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        // Tap volume down and volume up Encore icon buttons.
        await tester.tap(find.byKey(const ValueKey<String>('volume_icon_start')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey<String>('volume_icon_end')));
        await tester.pumpAndSettle();

        expect(transport.singleMethods, contains('VolumeSet'));
        expect(transport.setVolumeValues.length, greaterThanOrEqualTo(2));
        expect(transport.setVolumeValues[0], lessThan(32768));
        expect(transport.setVolumeValues[1], greaterThan(transport.setVolumeValues[0]));

        // Drag slider track to trigger SetVolumeRequested.
        final int countBeforeDrag = transport.setVolumeValues.length;
        final trackFinder = find.byKey(
          const ValueKey<String>('connect_volume_track'),
        );
        await tester.drag(trackFinder, const Offset(80, 0));
        await tester.pumpAndSettle();

        expect(transport.setVolumeValues.length, greaterThan(countBeforeDrag));
      },
    );

    testWidgets('disabled slider ignores drag and step taps', (tester) async {
      var changedCount = 0;
      var stepCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: SpotifyVolumeSliderBar(
                value: 0.4,
                deviceName: 'Locked Speaker',
                enabled: false,
                onChanged: (_) => changedCount++,
                onStepDown: () => stepCount++,
                onStepUp: () => stepCount++,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey<String>('volume_icon_start')));
      await tester.tap(find.byKey(const ValueKey<String>('volume_icon_end')));
      await tester.drag(
        find.byKey(const ValueKey<String>('connect_volume_track')),
        const Offset(60, 0),
      );
      await tester.pump();

      expect(changedCount, equals(0));
      expect(stepCount, equals(0));
    });
  });
}
