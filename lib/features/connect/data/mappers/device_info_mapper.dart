// 1:1 replica of p199p/n8d.java (lines 563–934), p199p/w7k.java, p199p/k7k.java,
// p199p/r370.java, p199p/u450.java, p199p/kzc.java, p199p/w9z0.java, p199p/o05.java,
// p199p/v8k.java, p199p/o690.java, and ConnectServiceImpl.cpp (lines 222–351).

import 'dart:convert';
import 'dart:typed_data';

import 'package:musify_mu/features/connect/data/mappers/group_mapper.dart';
import 'package:musify_mu/features/connect/data/proto/es_connect_messages.pb.dart'
    as connect_pb;
import 'package:musify_mu/features/connect/domain/models/connect_capabilities.dart';
import 'package:musify_mu/features/connect/domain/models/connect_device.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/hifi_status.dart';
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';

/// Pure deterministic mapper from `ConnectMessages$StateResponse$Device` and
/// its device-scoped sub-messages (`OutputPeripheral`, `Incarnation`, `Hifi`,
/// `capabilities` JSON) to M3a immutable domain entities.
final class DeviceInfoMapper {
  final GroupMapper groupMapper;

  const DeviceInfoMapper({this.groupMapper = const GroupMapper()});

  /// Decodes raw `StateResponse_Device` wire bytes and maps to [ConnectDevice].
  ConnectDevice deviceFromBuffer(Uint8List bytes) {
    final pb = connect_pb.StateResponse_Device.fromBuffer(bytes);
    return mapDevice(pb);
  }

  /// Maps [connect_pb.StateResponse_Device] (all 39 domain fields) to
  /// [ConnectDevice].
  ///
  /// Fixes JADX CFG inversions at `p199p/n8d.java:597, 759, 764` by using
  /// positive `hasOutputPeripheral()`, `hasIsAuthenticatedWithCurrentUser()`,
  /// and `hasGroupData()` checks, and eliminates the duplicated loop body at
  /// `n8d.java:573–880` vs `882–934`.
  ConnectDevice mapDevice(connect_pb.StateResponse_Device pb) {
    if (!pb.hasState() || pb.state.trim().isEmpty) {
      throw FormatException(
        'StateResponse_Device.state must be present and non-empty',
        pb.state,
      );
    }
    if (!pb.hasType() || pb.type.trim().isEmpty) {
      throw FormatException(
        'StateResponse_Device.type must be present and non-empty',
        pb.type,
      );
    }

    final state = ConnectDeviceState.fromWireName(pb.state);
    final type = DeviceType.fromWireName(pb.type);
    final incarnations =
        pb.incarnations.map(mapIncarnation).toList(growable: false);
    final capabilities = pb.hasCapabilities()
        ? parseCapabilitiesJson(pb.capabilities)
        : const <ConnectCapabilityEntry>[];
    final hifi = pb.hasHifi()
        ? mapHifiStatus(pb.hifi)
        : const ConnectHifiStatus(
            fullySupported: false,
            userEligible: false,
            deviceSupported: false,
          );
    final outputPeripheral =
        pb.hasOutputPeripheral() ? mapOutputPeripheral(pb.outputPeripheral) : null;
    final volumeSteps = pb.hasVolumeSteps() ? pb.volumeSteps : 0;
    final supportsDj = pb.hasSupportsDj() ? pb.supportsDj : false;
    final isAuthenticatedWithCurrentUser =
        pb.hasIsAuthenticatedWithCurrentUser()
            ? pb.isAuthenticatedWithCurrentUser
            : null;
    final groupData =
        pb.hasGroupData() ? groupMapper.mapGroupData(pb.groupData) : null;

    return ConnectDevice(
      isSelf: pb.isSelf,
      isActive: pb.isActive,
      isBeingActivated: pb.isBeingActivated,
      isWebapp: pb.isWebapp,
      isZeroconf: pb.isZeroconf,
      isGroup: pb.isGroup,
      isSocialConnect: pb.isSocialConnect,
      supportsLogout: pb.supportsLogout,
      supportsVolume: pb.supportsVolume,
      supportsRename: pb.supportsRename,
      creationTimeMs: pb.creationTimeMs.toInt(),
      brandDisplayName: pb.brandDisplayName,
      modelDisplayName: pb.modelDisplayName,
      localIdentifier: pb.localIdentifier,
      connectStateIdentifier: pb.connectStateIdentifier,
      name: pb.name,
      state: state,
      type: type,
      incarnations: incarnations,
      volume: pb.volume,
      isNewlyDiscovered: pb.isNewlyDiscovered,
      isDisabled: pb.isDisabled,
      capabilities: capabilities,
      hifi: hifi,
      outputPeripheral: outputPeripheral,
      volumeSteps: volumeSteps,
      isVoiceEnabled: pb.isVoiceEnabled,
      isLocal: pb.isLocal,
      localIp: pb.localIp,
      supportedMediaTypes: List<String>.of(pb.supportedMediaTypes),
      supportsDj: supportsDj,
      libraryVersion: pb.libraryVersion,
      supportsRemoteSleepTimer: pb.supportsRemoteSleepTimer,
      supportsPlaylistMixing: pb.supportsPlaylistMixing,
      supportsZephyr: pb.supportsZephyr,
      supportsRemoteAudioQualityControl: pb.supportsRemoteAudioQualityControl,
      discoveryMethod: pb.discoveryMethod,
      isAuthenticatedWithCurrentUser: isAuthenticatedWithCurrentUser,
      groupData: groupData,
    );
  }

  /// Maps [connect_pb.StateResponse_Hifi] to [ConnectHifiStatus].
  ConnectHifiStatus mapHifiStatus(connect_pb.StateResponse_Hifi pb) {
    return ConnectHifiStatus(
      fullySupported: pb.fullySupported,
      userEligible: pb.userEligible,
      deviceSupported: pb.deviceSupported,
    );
  }

  /// Maps [connect_pb.OutputPeripheral] to [OutputPeripheral].
  OutputPeripheral mapOutputPeripheral(connect_pb.OutputPeripheral pb) {
    return OutputPeripheral(
      name: pb.hasName() ? pb.name : null,
      brand: pb.hasBrand() ? pb.brand : null,
      model: pb.hasModel() ? pb.model : null,
      connectionType: pb.hasConnectionType()
          ? mapOutputPeripheralConnectionType(pb.connectionType)
          : null,
      category:
          pb.hasCategory() ? mapOutputPeripheralCategory(pb.category) : null,
    );
  }

  /// Maps [connect_pb.OutputPeripheralConnectionType] to
  /// [OutputPeripheralConnectionType].
  OutputPeripheralConnectionType mapOutputPeripheralConnectionType(
    connect_pb.OutputPeripheralConnectionType pb,
  ) {
    if (pb ==
        connect_pb.OutputPeripheralConnectionType
            .OUTPUT_PERIPHERAL_CONNECTION_TYPE_UNKNOWN) {
      return OutputPeripheralConnectionType.unknown;
    } else if (pb ==
        connect_pb.OutputPeripheralConnectionType
            .OUTPUT_PERIPHERAL_CONNECTION_TYPE_WIRED) {
      return OutputPeripheralConnectionType.wired;
    } else if (pb ==
        connect_pb.OutputPeripheralConnectionType
            .OUTPUT_PERIPHERAL_CONNECTION_TYPE_CAR_PROJECTED) {
      return OutputPeripheralConnectionType.carProjected;
    } else if (pb ==
        connect_pb.OutputPeripheralConnectionType
            .OUTPUT_PERIPHERAL_CONNECTION_TYPE_BLUETOOTH) {
      return OutputPeripheralConnectionType.bluetooth;
    } else if (pb ==
        connect_pb.OutputPeripheralConnectionType
            .OUTPUT_PERIPHERAL_CONNECTION_TYPE_AIRPLAY) {
      return OutputPeripheralConnectionType.airplay;
    } else if (pb ==
        connect_pb.OutputPeripheralConnectionType
            .OUTPUT_PERIPHERAL_CONNECTION_TYPE_BUILT_IN_SPEAKER) {
      return OutputPeripheralConnectionType.builtInSpeaker;
    } else {
      throw FormatException(
        'Unsupported OutputPeripheralConnectionType proto enum: '
        '${pb.value} (${pb.name})',
      );
    }
  }

  /// Maps [connect_pb.OutputPeripheralCategory] to
  /// [OutputPeripheralCategory].
  OutputPeripheralCategory mapOutputPeripheralCategory(
    connect_pb.OutputPeripheralCategory pb,
  ) {
    if (pb ==
        connect_pb.OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_UNKNOWN) {
      return OutputPeripheralCategory.unknown;
    } else if (pb ==
        connect_pb.OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_CAR) {
      return OutputPeripheralCategory.car;
    } else if (pb ==
        connect_pb
            .OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_HEADPHONES) {
      return OutputPeripheralCategory.headphones;
    } else if (pb ==
        connect_pb.OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_SPEAKER) {
      return OutputPeripheralCategory.speaker;
    } else if (pb ==
        connect_pb
            .OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_WEARABLE) {
      return OutputPeripheralCategory.wearable;
    } else if (pb ==
        connect_pb.OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_GLASSES) {
      return OutputPeripheralCategory.glasses;
    } else if (pb ==
        connect_pb.OutputPeripheralCategory.OUTPUT_PERIPHERAL_CATEGORY_APP) {
      return OutputPeripheralCategory.app;
    } else {
      throw FormatException(
        'Unsupported OutputPeripheralCategory proto enum: '
        '${pb.value} (${pb.name})',
      );
    }
  }

  /// Maps [connect_pb.StateResponse_Incarnation] to [Incarnation].
  ///
  /// Reads proto3 implicit-presence enum getters (`loginType`, `preferredReason`)
  /// directly without requiring `hasLoginType()` or `hasPreferredReason()`.
  Incarnation mapIncarnation(connect_pb.StateResponse_Incarnation pb) {
    final String loginType;
    if (pb.loginType == connect_pb.LoginType.CONNECT) {
      loginType = IncarnationLoginType.connect.wireName;
    } else if (pb.loginType == connect_pb.LoginType.CAST) {
      loginType = IncarnationLoginType.cast.wireName;
    } else {
      throw FormatException(
        'Unsupported LoginType proto enum: '
        '${pb.loginType.value} (${pb.loginType.name})',
      );
    }

    final String preferredReason;
    if (pb.preferredReason ==
        connect_pb.ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_DEFAULT) {
      preferredReason = IncarnationPreferredReason.defaultReason.wireName;
    } else if (pb.preferredReason ==
        connect_pb.ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_USER_SELECTED) {
      preferredReason = IncarnationPreferredReason.userSelected.wireName;
    } else if (pb.preferredReason ==
        connect_pb
            .ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_STREAM_EXPANSION) {
      preferredReason = IncarnationPreferredReason.streamExpansion.wireName;
    } else if (pb.preferredReason ==
        connect_pb.ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_ANDROID_TV) {
      preferredReason = IncarnationPreferredReason.androidTv.wireName;
    } else if (pb.preferredReason ==
        connect_pb.ProtocolChoiceReason.PROTOCOL_CHOICE_REASON_TAP_DEVICE) {
      preferredReason = IncarnationPreferredReason.tapDevice.wireName;
    } else {
      throw FormatException(
        'Unsupported ProtocolChoiceReason proto enum: '
        '${pb.preferredReason.value} (${pb.preferredReason.name})',
      );
    }

    return Incarnation(
      loginType: loginType,
      identifier: pb.identifier,
      preferred: pb.preferred,
      preferredReason: preferredReason,
      connectStateIdentifier: pb.connectStateIdentifier,
    );
  }

  /// Strictly parses `StateResponse_Device.capabilities` JSON payload matching
  /// `p199p/v8k.java`, `p199p/o690.java`, `p199p/kzc.java`, `p199p/w9z0.java`,
  /// and `p199p/o05.java`.
  ///
  /// Returns an empty list if JSON literal `null` is decoded (matching
  /// `n8d.java:577`). Throws [FormatException] on invalid JSON or mismatched
  /// schema types.
  List<ConnectCapabilityEntry> parseCapabilitiesJson(String rawJson) {
    final Object? decoded = jsonDecode(rawJson);
    if (decoded == null) {
      return const <ConnectCapabilityEntry>[];
    }
    if (decoded is! List<Object?>) {
      throw FormatException(
        'Expected JSON array for device capabilities',
        rawJson,
      );
    }

    final entries = <ConnectCapabilityEntry>[];
    for (final Object? item in decoded) {
      if (item is! Map<Object?, Object?>) {
        throw FormatException(
          'Expected JSON object element in device capabilities',
          item,
        );
      }

      final id = _readOptionalString(item, 'id');
      final defaultTitle = _readOptionalString(item, 'defaultTitle');
      final iconUrl = _readOptionalString(item, 'iconUrl');
      final redirectMap = _readOptionalObjectMap(item, 'redirectUris');
      final ConnectCapabilityRedirectUris? redirectUris;
      if (redirectMap == null) {
        redirectUris = null;
      } else {
        final androidMap = _readOptionalObjectMap(redirectMap, 'android');
        final ConnectCapabilityAndroidUris? androidUris;
        if (androidMap == null) {
          androidUris = null;
        } else {
          androidUris = ConnectCapabilityAndroidUris(
            uri: _readOptionalString(androidMap, 'uri'),
            redirectBackAppParam:
                _readOptionalString(androidMap, 'redirectBackAppParam'),
            deviceNameParam:
                _readOptionalString(androidMap, 'deviceNameParam'),
            fallbackUrl: _readOptionalString(androidMap, 'fallbackUrl'),
          );
        }
        redirectUris = ConnectCapabilityRedirectUris(android: androidUris);
      }
      final localizedTitle = _readOptionalStringMap(item, 'localizedTitle');

      entries.add(
        ConnectCapabilityEntry(
          id: id,
          defaultTitle: defaultTitle,
          iconUrl: iconUrl,
          redirectUris: redirectUris,
          localizedTitle: localizedTitle,
        ),
      );
    }
    return entries;
  }

  static String? _readOptionalString(
    Map<Object?, Object?> map,
    String key,
  ) {
    final Object? value = map[key];
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    throw FormatException(
      'Expected String or null for capability key "$key"',
      value,
    );
  }

  static Map<Object?, Object?>? _readOptionalObjectMap(
    Map<Object?, Object?> map,
    String key,
  ) {
    final Object? value = map[key];
    if (value == null) {
      return null;
    }
    if (value is Map<Object?, Object?>) {
      return value;
    }
    throw FormatException(
      'Expected JSON object or null for capability key "$key"',
      value,
    );
  }

  static Map<String, String>? _readOptionalStringMap(
    Map<Object?, Object?> map,
    String key,
  ) {
    final Object? value = map[key];
    if (value == null) {
      return null;
    }
    if (value is! Map<Object?, Object?>) {
      throw FormatException(
        'Expected JSON object or null for capability key "$key"',
        value,
      );
    }

    final result = <String, String>{};
    for (final entry in value.entries) {
      final Object? entryKey = entry.key;
      final Object? entryValue = entry.value;
      if (entryKey is! String || entryValue is! String) {
        throw FormatException(
          'Expected String->String entries for capability key "$key"',
          entry,
        );
      }
      result[entryKey] = entryValue;
    }
    return result;
  }
}
