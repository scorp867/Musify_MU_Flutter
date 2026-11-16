// Adversarial Protobuf Wire & Serialization Stress Test Harness
// Rigorous verification of boundary conditions, deeply nested models, maps,
// large payloads, Unicode robustness, and corrupted wire payload rejection.

import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:musify_mu/features/connect/data/proto/es_cast_messages.pb.dart';
import 'package:musify_mu/features/connect/data/proto/es_common_messages.pb.dart';
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pb.dart';
import 'package:musify_mu/features/connect/data/proto/es_volume_messages.pb.dart';
import 'package:musify_mu/features/connect/data/proto/group.pb.dart';

void main() {
  group('Adversarial Protobuf Wire & Serialization Harness', () {
    // -------------------------------------------------------------------------
    // 1. Deeply Nested Structures & Multi-Tier Compound Models
    // -------------------------------------------------------------------------
    group('1. Deeply Nested Structures & Compound Models', () {
      test('exercises multi-tier compound StateResponse with 20 devices, nested groups, incarnations, and peripherals', () {
        final devices = <StateResponse_Device>[];

        for (var i = 0; i < 20; i++) {
          final groupDevices = <GroupDevice>[
            GroupDevice(
              identifiers: GroupDeviceIdentifiers(
                groupDeviceIdentifier: 'grp_dev_${i}_sub1',
                localIdentifier: 'local_${i}_sub1',
                deduplicationId: 'dedup_${i}_sub1',
                connectStateIdentifier: 'cs_${i}_sub1',
              ),
              name: 'Sub Speaker A ($i)',
              type: 'speaker',
              modelDisplayName: 'Sonos Move $i',
              capabilities: GroupDeviceCapabilities(
                removable: i.isEven,
                removalDissolvesGroup: i % 3 == 0,
              ),
              groupingStatus: i % 2 == 0 ? GroupingStatus.GROUPED : GroupingStatus.GROUPABLE,
              volume: GroupDeviceVolume(
                volume: 1000 * i,
                volumeSteps: 16 + i,
              ),
            ),
            GroupDevice(
              identifiers: GroupDeviceIdentifiers(
                groupDeviceIdentifier: 'grp_dev_${i}_sub2',
              ),
              name: 'Sub Speaker B ($i)',
              type: 'dongle',
              modelDisplayName: 'Chromecast Audio $i',
              capabilities: GroupDeviceCapabilities(
                removable: true,
                removalDissolvesGroup: false,
              ),
              groupingStatus: GroupingStatus.GROUPING,
              volume: GroupDeviceVolume(
                volume: 65535 - (1000 * i),
                volumeSteps: 32,
              ),
            ),
          ];

          final groupData = GroupData(
            devices: groupDevices,
            capabilities: GroupCapabilities(maxDevices: 16 + i),
          );

          final incarnations = <StateResponse_Incarnation>[
            StateResponse_Incarnation(
              loginType: LoginType.CONNECT,
              identifier: 'conn_inc_$i',
              preferred: true,
              preferredReason: ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_USER_SELECTED,
              connectStateIdentifier: 'cs_inc_$i',
            ),
            StateResponse_Incarnation(
              loginType: LoginType.CAST,
              identifier: 'cast_inc_$i',
              preferred: false,
              preferredReason: ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_DEFAULT,
              connectStateIdentifier: 'cs_cast_$i',
            ),
          ];

          final device = StateResponse_Device(
            isSelf: i == 0,
            localIdentifier: 'local_id_$i',
            deduplicationId: 'dedup_id_$i',
            connectStateIdentifier: 'connect_state_id_$i',
            name: 'Complex Master Device #$i (High-Res)',
            type: i == 0 ? 'smartphone' : 'speaker',
            state: i == 0 ? 'active' : 'idle',
            isDisabled: false,
            isActive: i == 0,
            isBeingActivated: false,
            isZeroconf: i % 2 == 1,
            isWebapp: false,
            isLocal: i == 0,
            isGroup: i % 4 == 0,
            isOffline: false,
            isSocialConnect: i % 5 == 0,
            creationTimeMs: Int64(1700000000000 + (i * 86400000)),
            volume: (i * 3200).clamp(0, 65535),
            hifi: StateResponse_Hifi(
              fullySupported: i % 2 == 0,
              userEligible: true,
              deviceSupported: i % 3 != 0,
            ),
            license: 'premium',
            supportsOnDemand: true,
            supportsVolume: true,
            supportsLogout: i % 2 == 1,
            supportsRename: true,
            supportsAlarm: false,
            isVoiceEnabled: i % 3 == 0,
            isNewlyDiscovered: i > 15,
            supportedMediaTypes: ['audio/track', 'audio/episode', 'audio/livestream'],
            brandDisplayName: 'Spotify Partner Brand $i',
            modelDisplayName: 'Audiophile Pro Mark $i',
            volumeSteps: 64,
            capabilities: 'volume,transfer,crossfade,gapless',
            incarnations: incarnations,
            aliasId: 100 + i,
            supportsDj: i.isEven,
            libraryVersion: '2.14.0',
            outputPeripheral: OutputPeripheral(
              name: 'Studio Monitors Pair $i',
              brand: 'Genelec',
              model: '8341A',
              category: OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_SPEAKER,
              connectionType: OutputPeripheralConnectionType.OUTPUT_PERIPHERAL_CONNECTION_TYPE_WIRED,
            ),
            localIp: '192.168.1.${100 + i}',
            discoveryMethod: 1,
            supportsRemoteSleepTimer: true,
            supportsPlaylistMixing: true,
            groupData: groupData,
            isPublic: false,
            supportsRemoteAudioQualityControl: true,
            isAuthenticatedWithCurrentUser: true,
            supportsZephyr: true,
            supportsGapless: true,
            supportsCrossfade: true,
          );

          devices.add(device);
        }

        final original = StateResponse(
          isRunning: true,
          isConnected: true,
          localName: 'Primary Host System',
          shouldUseLocalPlayback: false,
          devices: devices,
          isActive: true,
          isActiveOnSameDevice: true,
          isSyncedWithBackend: true,
        );

        // Serialize to buffer
        final buffer = original.writeToBuffer();
        expect(buffer.isNotEmpty, isTrue);

        // Deserialize from buffer
        final restored = StateResponse.fromBuffer(buffer);

        // Verify structural equivalence
        expect(restored, equals(original));
        expect(restored.devices.length, equals(20));
        expect(restored.writeToBuffer(), equals(buffer));

        // Deep verification of node 0
        final d0 = restored.devices[0];
        expect(d0.isSelf, isTrue);
        expect(d0.name, equals('Complex Master Device #0 (High-Res)'));
        expect(d0.incarnations.length, equals(2));
        expect(d0.incarnations[0].loginType, equals(LoginType.CONNECT));
        expect(d0.incarnations[1].loginType, equals(LoginType.CAST));
        expect(d0.groupData.devices.length, equals(2));
        expect(d0.groupData.devices[0].name, equals('Sub Speaker A (0)'));
        expect(d0.groupData.capabilities.maxDevices, equals(16));
        expect(d0.outputPeripheral.brand, equals('Genelec'));

        // Deep verification of node 19
        final d19 = restored.devices[19];
        expect(d19.isSelf, isFalse);
        expect(d19.name, equals('Complex Master Device #19 (High-Res)'));
        expect(d19.isNewlyDiscovered, isTrue);
        expect(d19.groupData.devices[1].groupingStatus, equals(GroupingStatus.GROUPING));
        expect(d19.outputPeripheral.connectionType, equals(OutputPeripheralConnectionType.OUTPUT_PERIPHERAL_CONNECTION_TYPE_WIRED));

        // Verify deep cloning retains exact bytes
        final cloned = restored.clone();
        expect(cloned, equals(restored));
        expect(cloned.writeToBuffer(), equals(buffer));
      });
    });

    // -------------------------------------------------------------------------
    // 2. Numerical Extremes & Integer Boundary Cases
    // -------------------------------------------------------------------------
    group('2. Numerical Extremes & Integer Boundary Cases', () {
      test('handles Int64 MAX, MIN, ZERO, and negative varints across logging and timestamps', () {
        final extremeValues = <Int64>[
          Int64.MAX_VALUE, //  9223372036854775807
          Int64.MIN_VALUE, // -9223372036854775808
          Int64.ZERO,
          Int64.ONE,
          Int64(-1),
          Int64(0x7FFFFFFF), // 32-bit max
          Int64(-0x80000000), // 32-bit min
        ];

        for (final val in extremeValues) {
          final logParams = LoggingParams(
            commandInitiatedTime: val,
            commandReceivedTime: val,
            commandId: 'boundary_test_${val.toString()}',
          );

          final wire = logParams.writeToBuffer();
          final decoded = LoggingParams.fromBuffer(wire);

          expect(decoded.commandInitiatedTime, equals(val));
          expect(decoded.commandReceivedTime, equals(val));
          expect(decoded.commandId, equals('boundary_test_${val.toString()}'));
          expect(decoded, equals(logParams));
        }
      });

      test('handles uint32 boundaries (0, 1, 65535, 4294967295) across volume and ports', () {
        final uint32Values = <int>[
          0,
          1,
          255,
          65535, // Spotify 16-bit volume limit
          65536,
          16777215,
          4294967295, // Max 32-bit unsigned
        ];

        for (final val in uint32Values) {
          final device = StateResponse_Device(
            localIdentifier: 'dev_$val',
            volume: val,
          );
          final wire = device.writeToBuffer();
          final decoded = StateResponse_Device.fromBuffer(wire);
          expect(decoded.volume, equals(val));
          expect(decoded.localIdentifier, equals('dev_$val'));

          final installReq = InstallSpotifyRequest(
            connectDeviceIdentifier: 'tv_install_$val',
            port: val,
          );
          final installWire = installReq.writeToBuffer();
          final decodedInstall = InstallSpotifyRequest.fromBuffer(installWire);
          expect(decodedInstall.port, equals(val));
        }
      });

      test('handles signed int32 extreme values in VolumeSetRequest and ConnectionErrorRequest and rejects out-of-range ints', () {
        final int32Values = <int>[
          0,
          1,
          -1,
          65535,
          2147483647, // 32-bit signed max
          -2147483648, // 32-bit signed min
        ];

        for (final val in int32Values) {
          final volSet = VolumeSetRequest(
            volume: val,
            groupDeviceIdentifier: 'dev_$val',
          );
          final volWire = volSet.writeToBuffer();
          final decodedVol = VolumeSetRequest.fromBuffer(volWire);
          expect(decodedVol.volume, equals(val));
          expect(decodedVol.groupDeviceIdentifier, equals('dev_$val'));
        }

        for (final err in int32Values) {
          final targetCode = err == -2147483648 ? 2147483647 : (err == 2147483647 ? -2147483648 : -err);
          final req = ConnectionErrorRequest(
            deviceId: 'err_dev_$err',
            error: err,
            platformErrorCode: targetCode,
          );

          final bytes = req.writeToBuffer();
          final decoded = ConnectionErrorRequest.fromBuffer(bytes);

          expect(decoded.error, equals(err));
          expect(decoded.platformErrorCode, equals(targetCode));
          expect(decoded, equals(req));
        }

        // Out-of-range rejection: int32 max + 1 (2147483648) and int32 min - 1 (-2147483649)
        expect(
          () => ConnectionErrorRequest(error: 2147483648),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => ConnectionErrorRequest(error: -2147483649),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => ConnectionErrorRequest(platformErrorCode: 2147483648),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // 3. String & Binary Payload Adversarial Testing
    // -------------------------------------------------------------------------
    group('3. String & Binary Payload Adversarial Testing', () {
      test('retains empty, large, CJK, RTL, Emoji, and special escaped strings with zero loss', () {
        final testStrings = <String>[
          '', // Empty string
          'a', // Single ascii char
          '   \t\r\n   ', // Whitespace only
          '🔥🎧🔊🚀🎶🎵✨', // Emojis
          '客厅音响・音楽プレーヤー・한국어 오디오 장치', // CJK (Chinese, Japanese, Korean)
          'مكبر الصوت الذكي في غرفة المعيشة', // Arabic RTL
          'רמקול חכם בסלון', // Hebrew RTL
          'Éloïse, Noël, Zürich, København, Straße, Niña', // Extended Latin & Diacritics
          'Line 1\nLine 2\r\n\tTabbed\\Backslash"DoubleQuotes"\'SingleQuotes\'', // Escape sequences
          'Null\u0000Byte\u0000Embedded', // Embedded null bytes
          'A' * 40000, // 40KB long repetitive string
        ];

        for (var i = 0; i < testStrings.length; i++) {
          final str = testStrings[i];
          final peripheral = OutputPeripheral(
            name: str,
            brand: 'Brand_$i: $str',
            model: 'Model_$i: $str',
          );

          final wire = peripheral.writeToBuffer();
          final decoded = OutputPeripheral.fromBuffer(wire);

          expect(decoded.name, equals(str));
          expect(decoded.brand, equals('Brand_$i: $str'));
          expect(decoded.model, equals('Model_$i: $str'));
          expect(decoded, equals(peripheral));
        }
      });

      test('preserves arbitrary raw binary payloads (all 256 byte values, empty, large buffers)', () {
        // 1. Empty byte buffer
        final emptyReq = PutDeviceRequest(
          deviceId: 'empty_bin_dev',
          json: Uint8List(0),
        );
        final emptyWire = emptyReq.writeToBuffer();
        final decodedEmpty = PutDeviceRequest.fromBuffer(emptyWire);
        expect(decodedEmpty.json.isEmpty, isTrue);

        // 2. Full 0x00 to 0xFF byte range
        final allBytes = Uint8List.fromList(List.generate(256, (i) => i));
        final fullReq = PutDeviceRequest(
          deviceId: 'full_byte_dev',
          json: allBytes,
        );
        final fullWire = fullReq.writeToBuffer();
        final decodedFull = PutDeviceRequest.fromBuffer(fullWire);
        expect(decodedFull.json, equals(allBytes));

        // 3. Non-UTF8 byte sequence (would crash any naive UTF-8 string decoder)
        final nonUtf8 = Uint8List.fromList([0xC3, 0x28, 0xA0, 0xA1, 0xFF, 0xFE, 0x80, 0xBF]);
        final nonUtf8Req = PutDeviceRequest(
          deviceId: 'non_utf8_dev',
          json: nonUtf8,
        );
        final nonUtf8Wire = nonUtf8Req.writeToBuffer();
        final decodedNonUtf8 = PutDeviceRequest.fromBuffer(nonUtf8Wire);
        expect(decodedNonUtf8.json, equals(nonUtf8));

        // 4. Large 64KB binary buffer
        final largeBuffer = Uint8List(65536);
        for (var i = 0; i < largeBuffer.length; i++) {
          largeBuffer[i] = (i * 31) & 0xFF;
        }
        final largeReq = PutDeviceRequest(
          deviceId: 'large_bin_dev',
          json: largeBuffer,
        );
        final largeWire = largeReq.writeToBuffer();
        final decodedLarge = PutDeviceRequest.fromBuffer(largeWire);
        expect(decodedLarge.json.length, equals(65536));
        expect(decodedLarge.json, equals(largeBuffer));
      });
    });

    // -------------------------------------------------------------------------
    // 4. Map Operations & Key-Value Edge Cases (VolumeResponse.groupDeviceVolumes)
    // -------------------------------------------------------------------------
    group('4. Map Operations & Stress Testing', () {
      test('handles empty maps, 100+ entries, special keys, and extreme uint32 values', () {
        // Empty map
        final emptyMapResp = VolumeResponse(
          volume: 32000,
          status: Status.OK,
        );
        final emptyMapWire = emptyMapResp.writeToBuffer();
        final decodedEmptyMap = VolumeResponse.fromBuffer(emptyMapWire);
        expect(decodedEmptyMap.groupDeviceVolumes.isEmpty, isTrue);

        // 100 entries map with extreme values and unusual keys
        final mapEntries = <MapEntry<String, int>>[];
        mapEntries.add(const MapEntry('', 0)); // Empty key
        mapEntries.add(const MapEntry('min_val', 0));
        mapEntries.add(const MapEntry('max_val', 4294967295));
        mapEntries.add(const MapEntry('spotify_max_vol', 65535));
        mapEntries.add(const MapEntry('🔥_speaker_emoji', 50000));
        mapEntries.add(const MapEntry('客厅音响_cjk', 44000));
        mapEntries.add(const MapEntry('مكبر_arabic', 33000));

        for (var i = 0; i < 93; i++) {
          mapEntries.add(MapEntry('device_key_uuid_$i', i * 700));
        }

        final volumeResp = VolumeResponse(
          volume: 50000,
          status: Status.OK,
          activeDeviceConnectStateIdentifier: 'active_host',
          groupDeviceVolumes: mapEntries,
        );

        final wire = volumeResp.writeToBuffer();
        final decoded = VolumeResponse.fromBuffer(wire);

        expect(decoded.groupDeviceVolumes.length, equals(100));
        expect(decoded.groupDeviceVolumes[''], equals(0));
        expect(decoded.groupDeviceVolumes['min_val'], equals(0));
        expect(decoded.groupDeviceVolumes['max_val'], equals(4294967295));
        expect(decoded.groupDeviceVolumes['spotify_max_vol'], equals(65535));
        expect(decoded.groupDeviceVolumes['🔥_speaker_emoji'], equals(50000));
        expect(decoded.groupDeviceVolumes['客厅音响_cjk'], equals(44000));
        expect(decoded.groupDeviceVolumes['مكبر_arabic'], equals(33000));
        expect(decoded.groupDeviceVolumes['device_key_uuid_50'], equals(50 * 700));

        // Cloned map integrity
        final cloned = decoded.clone();
        expect(cloned.groupDeviceVolumes.length, equals(100));
        expect(cloned.groupDeviceVolumes['max_val'], equals(4294967295));
      });
    });

    // -------------------------------------------------------------------------
    // 5. Repeated Lists Scaling & Ordering Invariants
    // -------------------------------------------------------------------------
    group('5. Repeated Lists Scaling & Ordering Invariants', () {
      test('preserves exact order and contents for large repeated string and submessage lists', () {
        final strings = List.generate(500, (i) => 'interaction_event_tag_$i');
        final pages = List.generate(300, (i) => 'page_view_context_$i');

        final logParams = LoggingParams(
          commandInitiatedTime: Int64(1690000000),
          interactionIds: strings,
          pageInstanceIds: pages,
        );

        final wire = logParams.writeToBuffer();
        final decoded = LoggingParams.fromBuffer(wire);

        expect(decoded.interactionIds.length, equals(500));
        expect(decoded.pageInstanceIds.length, equals(300));
        for (var i = 0; i < 500; i++) {
          expect(decoded.interactionIds[i], equals('interaction_event_tag_$i'));
        }
        for (var i = 0; i < 300; i++) {
          expect(decoded.pageInstanceIds[i], equals('page_view_context_$i'));
        }
      });
    });

    // -------------------------------------------------------------------------
    // 6. Enums Boundary & Wire Values
    // -------------------------------------------------------------------------
    group('6. Enums Boundary & Wire Values', () {
      test('exercises enum limits and non-contiguous ordinals (InstallSpotifyState, GroupError)', () {
        // GroupError with non-contiguous ordinal 13 (BUSY)
        final addRespBusy = AddDeviceToGroupResponse(
          success: false,
          error: GroupError.BUSY,
        );
        final wireBusy = addRespBusy.writeToBuffer();
        final decodedBusy = AddDeviceToGroupResponse.fromBuffer(wireBusy);
        expect(decodedBusy.error, equals(GroupError.BUSY));
        expect(decodedBusy.error.value, equals(13));

        // RemoveGroupError with non-contiguous ordinal 12 (REMOVE_BUSY)
        final removeRespBusy = RemoveDeviceFromGroupResponse(
          success: false,
          error: RemoveGroupError.REMOVE_BUSY,
        );
        final wireRemBusy = removeRespBusy.writeToBuffer();
        final decodedRemBusy = RemoveDeviceFromGroupResponse.fromBuffer(wireRemBusy);
        expect(decodedRemBusy.error, equals(RemoveGroupError.REMOVE_BUSY));
        expect(decodedRemBusy.error.value, equals(12));

        // InstallSpotifyState non-contiguous progression (0..6 and 100..104)
        final testStates = <InstallSpotifyState>[
          InstallSpotifyState.CONNECTING, // 0
          InstallSpotifyState.SUCCESS, // 6
          InstallSpotifyState.UNKNOWN_ERROR, // 100
          InstallSpotifyState.DEVICE_NOT_FOUND, // 101
          InstallSpotifyState.DEVICE_NOT_SUPPORTED, // 102
          InstallSpotifyState.TIMEOUT, // 103
          InstallSpotifyState.CANCELLED, // 104
        ];

        for (final state in testStates) {
          final update = InstallSpotifyStatusUpdate(currentState: state);
          final wire = update.writeToBuffer();
          final decoded = InstallSpotifyStatusUpdate.fromBuffer(wire);
          expect(decoded.currentState, equals(state));
        }
      });
    });

    // -------------------------------------------------------------------------
    // 7. Corrupted Wire Payloads & Parser Error Rejection
    // -------------------------------------------------------------------------
    group('7. Corrupted Wire Payloads & Malformed Buffer Rejection', () {
      test('handles empty buffer as default zero-initialized message', () {
        final emptyBuffer = Uint8List(0);
        final state = StateResponse.fromBuffer(emptyBuffer);
        expect(state.isRunning, isFalse);
        expect(state.isConnected, isFalse);
        expect(state.devices.isEmpty, isTrue);

        final logParams = LoggingParams.fromBuffer(emptyBuffer);
        expect(logParams.commandInitiatedTime, equals(Int64.ZERO));
        expect(logParams.interactionIds.isEmpty, isTrue);
      });

      test('rejects truncated length-delimited string payload with InvalidProtocolBufferException', () {
        // Tag 1 (name), wire type 2 (length-delimited): tag byte = (1 << 3) | 2 = 0x0A
        // Length = 50 (0x32), but followed by only 4 bytes of data
        final truncatedBuffer = Uint8List.fromList([
          0x0A, 0x32, // Field 1, length 50
          0x41, 0x42, 0x43, 0x44, // Only 4 bytes
        ]);

        expect(
          () => OutputPeripheral.fromBuffer(truncatedBuffer),
          throwsA(isA<$pb.InvalidProtocolBufferException>()),
        );
      });

      test('rejects truncated varint with missing continuation bytes', () {
        // Tag 1 (commandInitiatedTime), wire type 0 (varint): tag byte = (1 << 3) | 0 = 0x08
        // Byte 0x80 has MSB set indicating more bytes follow, but buffer ends abruptly
        final truncatedVarint = Uint8List.fromList([0x08, 0x80]);

        expect(
          () => LoggingParams.fromBuffer(truncatedVarint),
          throwsA(isA<$pb.InvalidProtocolBufferException>()),
        );
      });

      test('rejects malformed varint exceeding 10 bytes (overflowing 64 bits)', () {
        // Tag 1, wire type 0: 0x08, followed by 11 continuation bytes with MSB = 1
        final overflowVarint = Uint8List.fromList([
          0x08,
          0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x01,
        ]);

        expect(
          () => LoggingParams.fromBuffer(overflowVarint),
          throwsA(isA<$pb.InvalidProtocolBufferException>()),
        );
      });

      test('rejects wire payloads with reserved/invalid wire types (6 and 7)', () {
        // Field 1, wire type 6: (1 << 3) | 6 = 0x0E
        final invalidWireType6 = Uint8List.fromList([0x0E, 0x00]);
        expect(
          () => StatusResponse.fromBuffer(invalidWireType6),
          throwsA(isA<$pb.InvalidProtocolBufferException>()),
        );

        // Field 1, wire type 7: (1 << 3) | 7 = 0x0F
        final invalidWireType7 = Uint8List.fromList([0x0F, 0x00]);
        expect(
          () => StatusResponse.fromBuffer(invalidWireType7),
          throwsA(isA<$pb.InvalidProtocolBufferException>()),
        );
      });

      test('gracefully ignores unknown field tags without crashing (forward compatibility)', () {
        // Valid StatusResponse(status: Status.OK) wire: tag 1, varint 0 -> [0x08, 0x00]
        // Plus unknown field tag 999: (999 << 3) | 0 (varint) -> varint bytes for (999 << 3) = 7992 = 0x1F38
        // 7992 in varint: 0x38 | 0x80 = 0xB8, 7992 >> 7 = 62 = 0x3E -> [0xB8, 0x3E]
        // Followed by value 42 (0x2A)
        final wireWithUnknownField = Uint8List.fromList([
          0x08, 0x00, // Known field 1 = OK
          0xB8, 0x3E, 0x2A, // Unknown field 999 = 42
        ]);

        final decoded = StatusResponse.fromBuffer(wireWithUnknownField);
        expect(decoded.status, equals(Status.OK));
        expect(decoded.unknownFields.isEmpty, isFalse);
        // Ensure unknown fields survive roundtrip serialization
        expect(decoded.writeToBuffer(), equals(wireWithUnknownField));
      });
    });

    // -------------------------------------------------------------------------
    // 8. JSON Serialization & Deep Equality Fidelity
    // -------------------------------------------------------------------------
    group('8. JSON Serialization & Deep Equality Fidelity', () {
      test('roundtrips JSON string serialization and preserves structural equality', () {
        final original = StateResponse_Incarnation(
          loginType: LoginType.CONNECT,
          identifier: 'inc_json_test',
          preferred: true,
          preferredReason: ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_STREAM_EXPANSION,
          connectStateIdentifier: 'cs_json_id',
        );

        final jsonString = original.writeToJson();
        expect(jsonString.isNotEmpty, isTrue);

        final decoded = StateResponse_Incarnation()..mergeFromJson(jsonString);
        expect(decoded, equals(original));
        expect(decoded.identifier, equals('inc_json_test'));
        expect(decoded.preferred, isTrue);
        expect(decoded.preferredReason, equals(ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_STREAM_EXPANSION));
        expect(decoded.connectStateIdentifier, equals('cs_json_id'));

        // Proto3 JSON format test
        final proto3Map = original.toProto3Json() as Map<String, dynamic>;
        expect(proto3Map['identifier'], equals('inc_json_test'));
        expect(proto3Map['preferred'], isTrue);
        expect(proto3Map['preferredReason'], equals('PROTOCOL_CHOICE_REASON_STREAM_EXPANSION'));
      });
    });
  });
}
