import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/connect/data/platform/android_audio_route_adapter.dart';
import 'package:musify_mu/features/connect/data/platform/android_device_environment_adapter.dart';
import 'package:musify_mu/features/connect/data/platform/android_local_discovery_adapter.dart';
import 'package:musify_mu/features/connect/data/platform/android_system_volume_adapter.dart';
import 'package:musify_mu/features/connect/domain/interfaces/audio_route_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/device_environment_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/local_discovery_port.dart';
import 'package:musify_mu/features/connect/domain/interfaces/system_volume_port.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';

Future<void> _emitStandardEventChannelPayload(
  String channelName,
  Object? payload,
) async {
  final encoded = const StandardMethodCodec().encodeSuccessEnvelope(payload);
  final completer = Completer<void>();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
    channelName,
    encoded,
    (_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    },
  );
  await completer.future;
}

void _registerMockEventChannel(String channelName) {
  final methodChannel = MethodChannel(channelName);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
    return null;
  });
}

void _unregisterMockChannel(String channelName) {
  final methodChannel = MethodChannel(channelName);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(methodChannel, null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    _unregisterMockChannel(AndroidDeviceEnvironmentAdapter.channelName);
    _unregisterMockChannel(AndroidAudioRouteAdapter.controlChannelName);
    _unregisterMockChannel(AndroidAudioRouteAdapter.eventChannelName);
    _unregisterMockChannel(AndroidSystemVolumeAdapter.controlChannelName);
    _unregisterMockChannel(AndroidSystemVolumeAdapter.eventChannelName);
    _unregisterMockChannel(AndroidLocalDiscoveryAdapter.controlChannelName);
    _unregisterMockChannel(AndroidLocalDiscoveryAdapter.eventChannelName);
  });

  group('AndroidDeviceEnvironmentAdapter', () {
    test('getDeviceEnvironment, requestConnectPermissions, openAppSettings, and fail-fast FormatException validation', () async {
      const channel = MethodChannel(AndroidDeviceEnvironmentAdapter.channelName);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'getDeviceEnvironment') {
          return <String, Object>{
            'androidId': 'pixel_9_android_id',
            'deviceName': 'Pixel 9 Pro',
            'brand': 'google',
            'model': 'Pixel 9 Pro',
            'osVersion': '15',
            'sdkInt': 35,
            'appVersionName': '1.5.0',
            'appVersionCode': 150,
            'deviceTypeWire': 'SMARTPHONE',
            'maxMusicVolumeSteps': 25,
            'currentMusicVolumeRatio': 0.4,
            'hasBluetoothConnectPermission': true,
            'hasNearbyWifiPermission': false,
          };
        }
        return null;
      });

      final adapter = AndroidDeviceEnvironmentAdapter(
        permissionRequester: () async => const ConnectPermissionStatus(
          bluetoothConnect: true,
          nearbyWifi: true,
        ),
        appSettingsOpener: () async => true,
      );

      final env = await adapter.getDeviceEnvironment();
      expect(env.androidId, equals('pixel_9_android_id'));
      expect(env.deviceName, equals('Pixel 9 Pro'));
      expect(env.brand, equals('google'));
      expect(env.model, equals('Pixel 9 Pro'));
      expect(env.deviceType, equals(DeviceType.smartphone));
      expect(env.maxMusicVolumeSteps, equals(25));
      expect(env.initialWireVolume, equals((0.4 * 65535.0).round()));
      expect(env.permissionStatus.bluetoothConnect, isTrue);
      expect(env.permissionStatus.nearbyWifi, isFalse);
      expect(env.permissionStatus.anyMissing, isTrue);
      expect(env.permissionStatus.allGranted, isFalse);

      final granted = await adapter.requestConnectPermissions();
      expect(granted.allGranted, isTrue);
      expect(granted.anyMissing, isFalse);
      expect(await adapter.openAppSettings(), isTrue);

      // Fail-fast boundary validation
      expect(
        () => AndroidDeviceEnvironmentAdapter.parseEnvironmentMap('not-a-map'),
        throwsFormatException,
      );
      expect(
        () => AndroidDeviceEnvironmentAdapter.parseEnvironmentMap(<String, Object>{
          'androidId': 'id',
          'deviceName': '   ',
          'brand': 'google',
          'model': 'Pixel',
          'osVersion': '15',
          'sdkInt': 35,
          'appVersionName': '1.0',
          'appVersionCode': 1,
          'deviceTypeWire': 'SMARTPHONE',
          'maxMusicVolumeSteps': 25,
          'currentMusicVolumeRatio': 0.5,
          'hasBluetoothConnectPermission': true,
          'hasNearbyWifiPermission': true,
        }),
        throwsFormatException,
      );
      expect(
        () => AndroidDeviceEnvironmentAdapter.parseEnvironmentMap(<String, Object>{
          'androidId': 'id',
          'deviceName': 'Pixel',
          'brand': 'google',
          'model': 'Pixel',
          'osVersion': '15',
          'sdkInt': 35,
          'appVersionName': '1.0',
          'appVersionCode': 1,
          'deviceTypeWire': '   ',
          'maxMusicVolumeSteps': 25,
          'currentMusicVolumeRatio': 0.5,
          'hasBluetoothConnectPermission': true,
          'hasNearbyWifiPermission': true,
        }),
        throwsFormatException,
      );
      expect(
        () => AndroidDeviceEnvironmentAdapter.parseEnvironmentMap(<String, Object>{
          'androidId': 'id',
          'deviceName': 'Pixel',
          'brand': 'google',
          'model': 'Pixel',
          'osVersion': '15',
          'sdkInt': 35,
          'appVersionName': '1.0',
          'appVersionCode': 1,
          'deviceTypeWire': 'SMARTPHONE',
          'maxMusicVolumeSteps': 25,
          'currentMusicVolumeRatio': 1.5,
          'hasBluetoothConnectPermission': true,
          'hasNearbyWifiPermission': true,
        }),
        throwsFormatException,
      );
    });
  });

  group('AndroidAudioRouteAdapter', () {
    test('getPeripherals, watchPeripherals, openSystemOutputSwitcher, and ordinal FormatException validation', () async {
      const controlChannel = MethodChannel(
        AndroidAudioRouteAdapter.controlChannelName,
      );
      var switcherResponse = <Object?>[true];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(controlChannel, (MethodCall call) async {
        switch (call.method) {
          case 'getPeripherals':
            return <Map<String, Object?>>[
              <String, Object?>{
                'id': kBuiltInSpeakerPeripheralId,
                'name': 'This phone',
                'isActive': false,
                'isConnected': true,
                'connectionTypeIndex': 5, // builtInSpeaker
                'categoryIndex': 3, // speaker
                'brand': 'google',
                'model': 'Pixel 9 Pro',
              },
              <String, Object?>{
                'id': 'bt_a2dp:AA:BB:CC',
                'name': 'Sony WH-1000XM5',
                'isActive': true,
                'isConnected': true,
                'connectionTypeIndex': 3, // bluetooth
                'categoryIndex': 2, // headphones
                'brand': 'Sony',
                'model': 'WH-1000XM5',
              },
            ];
          case 'openSystemOutputSwitcher':
            return switcherResponse.first;
          default:
            return null;
        }
      });
      _registerMockEventChannel(AndroidAudioRouteAdapter.eventChannelName);

      final adapter = AndroidAudioRouteAdapter();
      final peripherals = await adapter.getPeripherals();
      expect(peripherals, hasLength(2));
      expect(peripherals[0].id, equals(kBuiltInSpeakerPeripheralId));
      expect(
        peripherals[0].connectionType,
        equals(OutputPeripheralConnectionType.builtInSpeaker),
      );
      expect(peripherals[1].name, equals('Sony WH-1000XM5'));
      expect(peripherals[1].isActive, isTrue);
      expect(
        peripherals[1].connectionType,
        equals(OutputPeripheralConnectionType.bluetooth),
      );
      expect(
        peripherals[1].category,
        equals(OutputPeripheralCategory.headphones),
      );

      expect(await adapter.openSystemOutputSwitcher(), isTrue);
      switcherResponse = <Object?>['not-a-bool'];
      await expectLater(
        adapter.openSystemOutputSwitcher,
        throwsFormatException,
      );

      final streamed = <List<LocalAudioPeripheral>>[];
      final sub = adapter.watchPeripherals().listen(streamed.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();

      await _emitStandardEventChannelPayload(
        AndroidAudioRouteAdapter.eventChannelName,
        <Map<String, Object?>>[
          <String, Object?>{
            'id': kBuiltInSpeakerPeripheralId,
            'name': 'This phone',
            'isActive': true,
            'isConnected': true,
            'connectionTypeIndex': 5,
            'categoryIndex': -1,
            'brand': null,
            'model': null,
          },
        ],
      );
      await pumpEventQueue();

      expect(streamed, hasLength(1));
      expect(streamed.single.single.isActive, isTrue);
      expect(streamed.single.single.category, isNull);

      // Fail-fast boundary validation
      expect(
        () => AndroidAudioRouteAdapter.parsePeripheralList('not-a-list'),
        throwsFormatException,
      );
      expect(
        () => AndroidAudioRouteAdapter.parsePeripheralMap(<String, Object?>{
          'id': 'bt-1',
          'name': 'Headphones',
          'isActive': true,
          'isConnected': true,
          'connectionTypeIndex': 6, // out of range 0..5
        }),
        throwsFormatException,
      );
      expect(
        () => AndroidAudioRouteAdapter.parsePeripheralMap(<String, Object?>{
          'id': 'bt-1',
          'name': 'Headphones',
          'isActive': true,
          'isConnected': true,
          'connectionTypeIndex': 3,
          'categoryIndex': 7, // out of range 0..6
        }),
        throwsFormatException,
      );
    });
  });

  group('AndroidSystemVolumeAdapter', () {
    test('getLocalVolume, setLocalVolume, configureRemoteHardwareVolume, updateRemoteHardwareVolume, watchEvents, and fail-fast validation', () async {
      const controlChannel = MethodChannel(
        AndroidSystemVolumeAdapter.controlChannelName,
      );
      final recordedCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(controlChannel, (MethodCall call) async {
        recordedCalls.add(call);
        switch (call.method) {
          case 'getLocalVolume':
            return <String, Object>{
              'volume': 32768,
              'steps': 25,
              'currentStep': 12,
            };
          case 'setLocalVolume':
          case 'configureRemoteHardwareVolume':
          case 'updateRemoteHardwareVolume':
            return true;
          default:
            return null;
        }
      });
      _registerMockEventChannel(AndroidSystemVolumeAdapter.eventChannelName);

      final adapter = AndroidSystemVolumeAdapter();
      final snapshot = await adapter.getLocalVolume();
      expect(snapshot.volume, equals(32768));
      expect(snapshot.steps, equals(25));
      expect(snapshot.currentStep, equals(12));
      expect(snapshot.normalizedVolume, closeTo(32768 / 65535.0, 1e-6));

      expect(
        await adapter.setLocalVolume(volume: 40000, showUi: true),
        isTrue,
      );
      expect(
        await adapter.configureRemoteHardwareVolume(
          enabled: true,
          supportsVolume: true,
          volumeSteps: 64,
          currentVolume: 50000,
        ),
        isTrue,
      );
      expect(
        await adapter.updateRemoteHardwareVolume(currentVolume: 55000),
        isTrue,
      );
      expect(
        recordedCalls.map((c) => c.method).toList(),
        equals(<String>[
          'getLocalVolume',
          'setLocalVolume',
          'configureRemoteHardwareVolume',
          'updateRemoteHardwareVolume',
        ]),
      );

      final events = <SystemVolumeEvent>[];
      final sub = adapter.watchEvents().listen(events.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();

      await _emitStandardEventChannelPayload(
        AndroidSystemVolumeAdapter.eventChannelName,
        <String, Object>{
          'type': 'local_volume_changed',
          'volume': 16384,
          'steps': 25,
          'currentStep': 6,
        },
      );
      await _emitStandardEventChannelPayload(
        AndroidSystemVolumeAdapter.eventChannelName,
        <String, Object>{
          'type': 'remote_volume_adjust',
          'direction': 1,
        },
      );
      await _emitStandardEventChannelPayload(
        AndroidSystemVolumeAdapter.eventChannelName,
        <String, Object>{
          'type': 'remote_volume_set',
          'volume': 65535,
        },
      );
      await pumpEventQueue();

      expect(
        events,
        equals(<SystemVolumeEvent>[
          LocalVolumeChanged(volume: 16384, steps: 25, currentStep: 6),
          RemoteVolumeAdjust(direction: 1),
          RemoteVolumeSet(volume: 65535),
        ]),
      );

      // Fail-fast validation
      expect(
        () => adapter.setLocalVolume(volume: -1),
        throwsRangeError,
      );
      expect(
        () => adapter.setLocalVolume(volume: 65536),
        throwsRangeError,
      );
      expect(
        () => AndroidSystemVolumeAdapter.parseEventMap(<String, Object>{
          'type': 'remote_volume_adjust',
          'direction': 0, // ADJUST_SAME is forbidden
        }),
        throwsFormatException,
      );
      expect(
        () => AndroidSystemVolumeAdapter.parseEventMap(<String, Object>{
          'type': 'unknown_event',
        }),
        throwsFormatException,
      );
    });
  });

  group('AndroidLocalDiscoveryAdapter', () {
    test('startDiscovery, stopDiscovery, getDiscoveredServices, watchDiscoveredServices, encodeListToJson, and fail-fast validation', () async {
      const controlChannel = MethodChannel(
        AndroidLocalDiscoveryAdapter.controlChannelName,
      );
      final controlCalls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(controlChannel, (MethodCall call) async {
        controlCalls.add(call.method);
        if (call.method == 'getDiscoveredServices') {
          return <Map<String, Object?>>[
            <String, Object?>{
              'serviceName': 'LivingRoom-Spotify',
              'host': '192.168.1.50',
              'port': 8009,
              'cPath': '/zc',
              'version': '2.12.0',
              'stack': 'libspotify',
            },
          ];
        }
        return true;
      });
      _registerMockEventChannel(AndroidLocalDiscoveryAdapter.eventChannelName);

      final adapter = AndroidLocalDiscoveryAdapter();
      await adapter.startDiscovery();
      final discovered = await adapter.getDiscoveredServices();
      await adapter.stopDiscovery();

      expect(
        controlCalls,
        equals(<String>[
          'startDiscovery',
          'getDiscoveredServices',
          'stopDiscovery',
        ]),
      );
      expect(discovered, hasLength(1));
      expect(discovered.single.serviceName, equals('LivingRoom-Spotify'));
      expect(discovered.single.host, equals('192.168.1.50'));
      expect(discovered.single.port, equals(8009));
      expect(discovered.single.cPath, equals('/zc'));
      expect(discovered.single.version, equals('2.12.0'));
      expect(discovered.single.stack, equals('libspotify'));

      final encodedJson = DiscoveredNsdService.encodeListToJson(discovered);
      final decodedList = jsonDecode(encodedJson);
      expect(decodedList, isA<List<Object?>>());

      final watched = <List<DiscoveredNsdService>>[];
      final sub = adapter.watchDiscoveredServices().listen(watched.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();

      await _emitStandardEventChannelPayload(
        AndroidLocalDiscoveryAdapter.eventChannelName,
        <Map<String, Object?>>[
          <String, Object?>{
            'serviceName': 'Kitchen-Speaker',
            'host': '192.168.1.60',
            'port': 57621,
            'cPath': '/spotify',
            'version': '2.12.0',
            'stack': null,
          },
        ],
      );
      await pumpEventQueue();

      expect(watched, hasLength(1));
      expect(watched.single.single.serviceName, equals('Kitchen-Speaker'));
      expect(watched.single.single.stack, isEmpty);

      // Fail-fast boundary validation
      expect(
        () => AndroidLocalDiscoveryAdapter.parseServiceList('not-a-list'),
        throwsFormatException,
      );
      expect(
        () => AndroidLocalDiscoveryAdapter.parseServiceMap(<String, Object?>{
          'serviceName': '',
          'host': '192.168.1.10',
          'port': 8000,
          'cPath': '/zc',
          'version': '2.12.0',
        }),
        throwsFormatException,
      );
      expect(
        () => AndroidLocalDiscoveryAdapter.parseServiceMap(<String, Object?>{
          'serviceName': 'Speaker',
          'host': '192.168.1.10',
          'port': 70000,
          'cPath': '/zc',
          'version': '2.12.0',
        }),
        throwsFormatException,
      );
    });
  });
}
