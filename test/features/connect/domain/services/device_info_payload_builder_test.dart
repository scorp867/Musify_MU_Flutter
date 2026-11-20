import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/connect/domain/interfaces/device_environment_port.dart';
import 'package:musify_mu/features/connect/domain/models/connect_capabilities.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/services/device_info_payload_builder.dart';

final class _DecodedWireMessages {
  final Map<int, List<int>> varints;
  final Map<int, List<Uint8List>> lengthDelimited;

  const _DecodedWireMessages({
    required this.varints,
    required this.lengthDelimited,
  });

  int? singleVarint(int tag) {
    final list = varints[tag];
    if (list == null || list.isEmpty) return null;
    return list.last;
  }

  String? singleString(int tag) {
    final list = lengthDelimited[tag];
    if (list == null || list.isEmpty) return null;
    return utf8.decode(list.last);
  }

  List<String> repeatedStrings(int tag) {
    final list = lengthDelimited[tag];
    if (list == null) return const <String>[];
    return list.map(utf8.decode).toList(growable: false);
  }

  Uint8List? singleBytes(int tag) {
    final list = lengthDelimited[tag];
    if (list == null || list.isEmpty) return null;
    return list.last;
  }
}

_DecodedWireMessages _decodeWire(Uint8List bytes) {
  final varints = <int, List<int>>{};
  final lengthDelimited = <int, List<Uint8List>>{};
  var offset = 0;

  int readVarint() {
    var result = 0;
    var shift = 0;
    while (offset < bytes.length) {
      final b = bytes[offset];
      offset += 1;
      result |= (b & 0x7F) << shift;
      if ((b & 0x80) == 0) {
        return result;
      }
      shift += 7;
    }
    throw const FormatException('Truncated varint in protobuf wire payload');
  }

  while (offset < bytes.length) {
    final key = readVarint();
    final tag = key >>> 3;
    final wireType = key & 0x07;
    switch (wireType) {
      case 0:
        final val = readVarint();
        varints.putIfAbsent(tag, () => <int>[]).add(val);
      case 2:
        final len = readVarint();
        if (offset + len > bytes.length) {
          throw const FormatException('Truncated length-delimited field');
        }
        final slice = Uint8List.sublistView(bytes, offset, offset + len);
        offset += len;
        lengthDelimited.putIfAbsent(tag, () => <Uint8List>[]).add(slice);
      default:
        throw FormatException('Unexpected wireType $wireType for tag $tag');
    }
  }

  return _DecodedWireMessages(
    varints: varints,
    lengthDelimited: lengthDelimited,
  );
}

void main() {
  const builder = DeviceInfoPayloadBuilder.instance;

  group('DeviceInfoPayloadBuilder', () {
    test('encodes exact ConnectStateProtos.h DeviceInfo and Capabilities wire tags from DeviceEnvironmentInfo', () {
      const canonicalDeviceId = '0123456789abcdef0123456789abcdef01234567';
      const activeClientId = 'd8a5ed958d274c2e8ee717e6a4b0971d';
      final env = DeviceEnvironmentInfo(
        androidId: 'pixel_android_id_99',
        deviceName: 'Pixel 9 Pro',
        brand: 'google',
        model: 'Pixel 9 Pro',
        osVersion: '15',
        sdkInt: 35,
        appVersionName: '1.2.0',
        appVersionCode: 10200,
        deviceTypeWire: 'SMARTPHONE',
        maxMusicVolumeSteps: 25,
        currentMusicVolumeRatio: 0.5,
        hasBluetoothConnectPermission: true,
        hasNearbyWifiPermission: true,
      );

      final payload = builder.buildFromEnvironment(
        deviceId: canonicalDeviceId,
        clientId: activeClientId,
        environment: env,
        license: 'premium',
      );
      expect(payload, isNotEmpty);

      final outer = _decodeWire(payload);
      // tag 1: can_play = true
      expect(outer.singleVarint(1), equals(1));
      // tag 2: volume = round(0.5 * 65535) = 32768
      expect(outer.singleVarint(2), equals(32768));
      // tag 3: name
      expect(outer.singleString(3), equals('Pixel 9 Pro'));
      // tag 6: device_software_version
      expect(outer.singleString(6), equals('1.2.0'));
      // tag 7: device_type (SMARTPHONE = 3)
      expect(outer.singleVarint(7), equals(3));
      // tag 9: spirc_version
      expect(outer.singleString(9), equals('3.2.0'));
      // tag 10: device_id
      expect(outer.singleString(10), equals(canonicalDeviceId));
      // tag 11: is_private_session = false
      expect(outer.singleVarint(11), equals(0));
      // tag 12: is_social_connect = false
      expect(outer.singleVarint(12), equals(0));
      // tag 13: client_id
      expect(outer.singleString(13), equals(activeClientId));
      // tag 14: brand
      expect(outer.singleString(14), equals('google'));
      // tag 15: model
      expect(outer.singleString(15), equals('Pixel 9 Pro'));
      // tag 17: product_id
      expect(outer.singleString(17), equals('musify-android'));
      // tag 21: is_offline = false
      expect(outer.singleVarint(21), equals(0));
      // tag 23: license
      expect(outer.singleString(23), equals('premium'));
      // tag 24: audio_output_device_info MUST be omitted when unset
      expect(outer.singleBytes(24), isNull);
      // tag 32: is_public = false (explicit 0 on wire to override C++ default true)
      expect(outer.singleVarint(32), equals(0));

      // Verify tag 4: Capabilities submessage
      final capBytes = outer.singleBytes(4);
      expect(capBytes, isNotNull);
      if (capBytes != null) {
        final caps = _decodeWire(capBytes);
        expect(caps.singleVarint(2), equals(1)); // can_be_player
        expect(caps.singleVarint(3), equals(0)); // restrict_to_local
        expect(caps.singleVarint(5), equals(1)); // gaia_eq_connect_id
        expect(caps.singleVarint(6), equals(1)); // supports_logout
        expect(caps.singleVarint(7), equals(1)); // is_observable
        expect(caps.singleVarint(8), equals(25)); // volume_steps
        expect(
          caps.repeatedStrings(9),
          equals(<String>['audio/track', 'audio/episode']),
        );
        expect(caps.singleVarint(10), equals(1)); // command_acks
        expect(caps.singleVarint(11), equals(0)); // supports_rename = false
        expect(caps.singleVarint(12), equals(0)); // hidden = false
        expect(caps.singleVarint(13), equals(0)); // disable_volume = false
        expect(caps.singleVarint(14), equals(0)); // connect_disabled = false
        expect(caps.singleVarint(15), equals(1)); // supports_playlist_v2 = true
        expect(caps.singleVarint(16), equals(1)); // is_controllable
        expect(caps.singleVarint(17), equals(1)); // supports_external_episodes
        expect(caps.singleVarint(18), equals(1)); // supports_set_backend_metadata
        expect(caps.singleVarint(19), equals(1)); // supports_transfer_command
        expect(caps.singleVarint(20), equals(1)); // supports_command_request
        expect(caps.singleVarint(21), equals(0)); // is_voice_enabled
        expect(caps.singleVarint(22), equals(1)); // needs_full_player_state
        expect(caps.singleVarint(23), equals(1)); // supports_gzip_pushes
        expect(caps.singleVarint(25), equals(1)); // supports_set_options_command
        expect(caps.singleVarint(28), equals(0)); // supports_rooms
        expect(caps.singleVarint(29), equals(1)); // supports_dj
        expect(caps.singleVarint(30), equals(4)); // supported_audio_quality = VERY_HIGH
        expect(caps.singleVarint(33), equals(1)); // supports_smart_shuffle_mode
        expect(caps.singleVarint(34), equals(1)); // supports_remote_sleep_timer
        expect(caps.singleVarint(35), equals(1)); // supports_ping_request
        expect(caps.singleVarint(36), equals(1)); // supports_playlist_mixing
        expect(caps.singleVarint(37), equals(1)); // supports_remote_audio_quality_control
        expect(caps.singleVarint(38), equals(1)); // supports_zephyr
        expect(caps.singleVarint(39), equals(1)); // supports_gapless
        expect(caps.singleVarint(40), equals(1)); // supports_crossfade
      }
    });

    test('preserves explicit zero volume (mute) and fails fast on missing mandatory fields or out-of-range volume', () {
      const deviceId = '0123456789abcdef0123456789abcdef01234567';
      const clientId = 'd8a5ed958d274c2e8ee717e6a4b0971d';

      final mutedPayload = builder.build(
        deviceId: deviceId,
        name: 'Muted Phone',
        clientId: clientId,
        initialSystemVolume: 0,
        volumeSteps: 32,
      );
      final decodedMuted = _decodeWire(mutedPayload);
      expect(decodedMuted.singleVarint(2), equals(0));

      expect(
        () => builder.build(
          deviceId: '   ',
          name: 'Pixel',
          clientId: clientId,
        ),
        throwsArgumentError,
      );
      expect(
        () => builder.build(
          deviceId: deviceId,
          name: '',
          clientId: clientId,
        ),
        throwsArgumentError,
      );
      expect(
        () => builder.build(
          deviceId: deviceId,
          name: 'Pixel',
          clientId: '  ',
        ),
        throwsArgumentError,
      );
      expect(
        () => builder.build(
          deviceId: deviceId,
          name: 'Pixel',
          clientId: clientId,
          initialSystemVolume: -1,
        ),
        throwsRangeError,
      );
      expect(
        () => builder.build(
          deviceId: deviceId,
          name: 'Pixel',
          clientId: clientId,
          initialSystemVolume: 65536,
        ),
        throwsRangeError,
      );
      expect(
        () => builder.build(
          deviceId: deviceId,
          name: 'Pixel',
          clientId: clientId,
          volumeSteps: 0,
        ),
        throwsRangeError,
      );
    });

    test('deviceTypeToWireCode and audioQualityToWireCode match ConnectStateProtos.h enums 1:1', () {
      expect(
        DeviceInfoPayloadBuilder.deviceTypeToWireCode(DeviceType.unknown),
        equals(0),
      );
      expect(
        DeviceInfoPayloadBuilder.deviceTypeToWireCode(DeviceType.computer),
        equals(1),
      );
      expect(
        DeviceInfoPayloadBuilder.deviceTypeToWireCode(DeviceType.tablet),
        equals(2),
      );
      expect(
        DeviceInfoPayloadBuilder.deviceTypeToWireCode(DeviceType.smartphone),
        equals(3),
      );
      expect(
        DeviceInfoPayloadBuilder.deviceTypeToWireCode(DeviceType.speaker),
        equals(4),
      );
      expect(
        DeviceInfoPayloadBuilder.deviceTypeToWireCode(DeviceType.tv),
        equals(5),
      );
      expect(
        DeviceInfoPayloadBuilder.deviceTypeToWireCode(DeviceType.chromebook),
        equals(14),
      );
      expect(
        DeviceInfoPayloadBuilder.deviceTypeToWireCode(
          DeviceType.unknownSpotifyHw,
        ),
        equals(100),
      );
      expect(
        DeviceInfoPayloadBuilder.deviceTypeToWireCode(DeviceType.homeThing),
        equals(103),
      );

      expect(
        DeviceInfoPayloadBuilder.audioQualityToWireCode(
          ConnectAudioQuality.defaultQuality,
        ),
        equals(0),
      );
      expect(
        DeviceInfoPayloadBuilder.audioQualityToWireCode(
          ConnectAudioQuality.veryHigh,
        ),
        equals(4),
      );
      expect(
        DeviceInfoPayloadBuilder.audioQualityToWireCode(
          ConnectAudioQuality.hifi24,
        ),
        equals(6),
      );
    });
  });
}
