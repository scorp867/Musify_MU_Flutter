import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:musify_mu/features/connect/domain/interfaces/device_environment_port.dart';
import 'package:musify_mu/features/connect/domain/models/connect_capabilities.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';

/// Encodes the exact binary protobuf wire payload for
/// `spotify.connectstate.DeviceInfo` consumed by `musify_connect_start` and
/// decoded by C++ `spotify::connectstate::decode_device_info`
/// (`ConnectStateProtos.h:973-1017, 1544-1952`, `#47 §1`).
@immutable
final class DeviceInfoPayloadBuilder {
  static const DeviceInfoPayloadBuilder instance = DeviceInfoPayloadBuilder();

  static const String defaultSpircVersion = '3.2.0';
  static const String defaultProductId = 'musify-android';
  static const String defaultLicense = 'premium';
  static const int defaultVolumeSteps = 32;
  static const List<String> defaultSupportedTypes = <String>[
    'audio/track',
    'audio/episode',
  ];

  const DeviceInfoPayloadBuilder();

  /// Builds the `DeviceInfo` protobuf wire payload directly from a
  /// [DeviceEnvironmentInfo] snapshot, canonical 40-hex [deviceId], and
  /// active [clientId].
  ///
  /// Throws [ArgumentError] if [deviceId], [environment.deviceName], or
  /// [clientId] is empty.
  Uint8List buildFromEnvironment({
    required String deviceId,
    required String clientId,
    required DeviceEnvironmentInfo environment,
    String license = defaultLicense,
    int? initialVolumeOverride,
    String productId = defaultProductId,
    String spircVersion = defaultSpircVersion,
  }) {
    final resolvedVolume = switch (initialVolumeOverride) {
      final vol? => vol,
      null => environment.initialWireVolume,
    };
    final resolvedSteps = environment.maxMusicVolumeSteps > 0
        ? environment.maxMusicVolumeSteps
        : defaultVolumeSteps;
    return build(
      deviceId: deviceId,
      name: environment.deviceName,
      clientId: clientId,
      initialSystemVolume: resolvedVolume,
      volumeSteps: resolvedSteps,
      deviceSoftwareVersion: environment.appVersionName,
      deviceType: environment.deviceType,
      spircVersion: spircVersion,
      brand: environment.brand,
      model: environment.model,
      productId: productId,
      license: license,
    );
  }

  /// Encodes the `spotify.connectstate.DeviceInfo` protobuf wire payload
  /// matching `ConnectStateProtos.h` tags `1, 2, 3, 4, 6, 7, 9, 10, 11, 12,
  /// 13, 14, 15, 17, 21, 23, 32` (`#47 §1`, `#50 §6`).
  ///
  /// Throws [ArgumentError] if [deviceId], [name], or [clientId] is empty.
  /// Throws [RangeError] if [initialSystemVolume] is outside `[0, 65535]` or
  /// [volumeSteps] is `<= 0`.
  Uint8List build({
    required String deviceId,
    required String name,
    required String clientId,
    int initialSystemVolume = kMaxConnectVolumeWire,
    int volumeSteps = defaultVolumeSteps,
    String deviceSoftwareVersion = '1.0.0',
    DeviceType deviceType = DeviceType.smartphone,
    String spircVersion = defaultSpircVersion,
    String brand = 'Android',
    String model = 'Android',
    String productId = defaultProductId,
    String license = defaultLicense,
    bool canPlay = true,
    bool isPrivateSession = false,
    bool isSocialConnect = false,
    bool isOffline = false,
    bool isPublic = false,
    bool supportsRename = false,
    bool supportsPlaylistV2 = true,
    bool needsFullPlayerState = true,
    bool canBePlayer = true,
    bool restrictToLocal = false,
    bool gaiaEqConnectId = true,
    bool supportsLogout = true,
    bool isObservable = true,
    bool isControllable = true,
    bool commandAcks = true,
    bool supportsTransferCommand = true,
    bool supportsCommandRequest = true,
    bool supportsSetOptionsCommand = true,
    bool supportsGzipPushes = true,
    bool supportsExternalEpisodes = true,
    bool supportsSetBackendMetadata = true,
    bool isVoiceEnabled = false,
    bool supportsRooms = false,
    bool supportsDj = true,
    ConnectAudioQuality supportedAudioQuality = ConnectAudioQuality.veryHigh,
    bool supportsSmartShuffleMode = true,
    bool supportsRemoteSleepTimer = true,
    bool supportsPingRequest = true,
    bool supportsPlaylistMixing = true,
    bool supportsRemoteAudioQualityControl = true,
    bool supportsZephyr = true,
    bool supportsGapless = true,
    bool supportsCrossfade = true,
    List<String> supportedTypes = defaultSupportedTypes,
  }) {
    final trimmedDeviceId = deviceId.trim();
    if (trimmedDeviceId.isEmpty) {
      throw ArgumentError.value(
        deviceId,
        'deviceId',
        'DeviceInfo.device_id (tag 10) must be non-empty',
      );
    }
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'DeviceInfo.name (tag 3) must be non-empty',
      );
    }
    final trimmedClientId = clientId.trim();
    if (trimmedClientId.isEmpty) {
      throw ArgumentError.value(
        clientId,
        'clientId',
        'DeviceInfo.client_id (tag 13) must be non-empty',
      );
    }
    if (initialSystemVolume < 0 ||
        initialSystemVolume > kMaxConnectVolumeWire) {
      throw RangeError.range(
        initialSystemVolume,
        0,
        kMaxConnectVolumeWire,
        'initialSystemVolume',
        'Must be within [0, $kMaxConnectVolumeWire]',
      );
    }
    if (volumeSteps <= 0) {
      throw RangeError.value(
        volumeSteps,
        'volumeSteps',
        'Must be positive (>= 1)',
      );
    }

    final resolvedSoftwareVersion = deviceSoftwareVersion.trim().isNotEmpty
        ? deviceSoftwareVersion.trim()
        : '1.0.0';
    final resolvedSpircVersion = spircVersion.trim().isNotEmpty
        ? spircVersion.trim()
        : defaultSpircVersion;
    final resolvedBrand =
        brand.trim().isNotEmpty ? brand.trim() : 'Android';
    final resolvedModel =
        model.trim().isNotEmpty ? model.trim() : 'Android';
    final resolvedProductId = productId.trim().isNotEmpty
        ? productId.trim()
        : defaultProductId;
    final resolvedLicense =
        license.trim().isNotEmpty ? license.trim() : defaultLicense;

    final capabilitiesBytes = _encodeCapabilities(
      canBePlayer: canBePlayer,
      restrictToLocal: restrictToLocal,
      gaiaEqConnectId: gaiaEqConnectId,
      supportsLogout: supportsLogout,
      isObservable: isObservable,
      volumeSteps: volumeSteps,
      supportedTypes: supportedTypes,
      commandAcks: commandAcks,
      supportsRename: supportsRename,
      supportsPlaylistV2: supportsPlaylistV2,
      isControllable: isControllable,
      supportsExternalEpisodes: supportsExternalEpisodes,
      supportsSetBackendMetadata: supportsSetBackendMetadata,
      supportsTransferCommand: supportsTransferCommand,
      supportsCommandRequest: supportsCommandRequest,
      isVoiceEnabled: isVoiceEnabled,
      needsFullPlayerState: needsFullPlayerState,
      supportsGzipPushes: supportsGzipPushes,
      supportsSetOptionsCommand: supportsSetOptionsCommand,
      supportsRooms: supportsRooms,
      supportsDj: supportsDj,
      supportedAudioQuality: supportedAudioQuality,
      supportsSmartShuffleMode: supportsSmartShuffleMode,
      supportsRemoteSleepTimer: supportsRemoteSleepTimer,
      supportsPingRequest: supportsPingRequest,
      supportsPlaylistMixing: supportsPlaylistMixing,
      supportsRemoteAudioQualityControl: supportsRemoteAudioQualityControl,
      supportsZephyr: supportsZephyr,
      supportsGapless: supportsGapless,
      supportsCrossfade: supportsCrossfade,
    );

    final out = BytesBuilder(copy: false);
    // tag 1: can_play (bool)
    _writeBoolField(out, 1, canPlay);
    // tag 2: volume (uint32, 0..65535)
    _writeUintField(out, 2, initialSystemVolume);
    // tag 3: name (string)
    _writeStringField(out, 3, trimmedName);
    // tag 4: capabilities (Capabilities submessage)
    _writeSubmessageField(out, 4, capabilitiesBytes);
    // tag 6: device_software_version (string)
    _writeStringField(out, 6, resolvedSoftwareVersion);
    // tag 7: device_type (DeviceType wire enum)
    _writeUintField(out, 7, deviceTypeToWireCode(deviceType));
    // tag 9: spirc_version (string)
    _writeStringField(out, 9, resolvedSpircVersion);
    // tag 10: device_id (string, canonical 40-hex)
    _writeStringField(out, 10, trimmedDeviceId);
    // tag 11: is_private_session (bool)
    _writeBoolField(out, 11, isPrivateSession);
    // tag 12: is_social_connect (bool)
    _writeBoolField(out, 12, isSocialConnect);
    // tag 13: client_id (string, activeClientId)
    _writeStringField(out, 13, trimmedClientId);
    // tag 14: brand (string)
    _writeStringField(out, 14, resolvedBrand);
    // tag 15: model (string)
    _writeStringField(out, 15, resolvedModel);
    // tag 17: product_id (string)
    _writeStringField(out, 17, resolvedProductId);
    // tag 21: is_offline (bool)
    _writeBoolField(out, 21, isOffline);
    // tag 23: license (string)
    _writeStringField(out, 23, resolvedLicense);
    // tag 32: is_public (bool, explicitly encoded even when false so C++
    // decode_device_info overwrites its default `is_public{true}`).
    _writeBoolField(out, 32, isPublic);

    return out.toBytes();
  }

  /// Maps domain [DeviceType] to `spotify::connectstate::DeviceType` wire enum
  /// values (`ConnectStateProtos.h:62-82`).
  static int deviceTypeToWireCode(DeviceType type) {
    switch (type) {
      case DeviceType.unknown:
        return 0;
      case DeviceType.computer:
        return 1;
      case DeviceType.tablet:
        return 2;
      case DeviceType.smartphone:
        return 3;
      case DeviceType.speaker:
        return 4;
      case DeviceType.tv:
        return 5;
      case DeviceType.avr:
        return 6;
      case DeviceType.stb:
        return 7;
      case DeviceType.audioDongle:
        return 8;
      case DeviceType.gameConsole:
        return 9;
      case DeviceType.castVideo:
        return 10;
      case DeviceType.castAudio:
        return 11;
      case DeviceType.automobile:
        return 12;
      case DeviceType.smartwatch:
        return 13;
      case DeviceType.chromebook:
        return 14;
      case DeviceType.unknownSpotifyHw:
        return 100;
      case DeviceType.homeThing:
        return 103;
    }
  }

  /// Maps [ConnectAudioQuality] to `spotify::connectstate::AudioQuality` wire
  /// enum values (`ConnectStateProtos.h:110-118`).
  static int audioQualityToWireCode(ConnectAudioQuality quality) {
    switch (quality) {
      case ConnectAudioQuality.defaultQuality:
        return 0;
      case ConnectAudioQuality.low:
        return 1;
      case ConnectAudioQuality.normal:
        return 2;
      case ConnectAudioQuality.high:
        return 3;
      case ConnectAudioQuality.veryHigh:
        return 4;
      case ConnectAudioQuality.hifi:
        return 5;
      case ConnectAudioQuality.hifi24:
        return 6;
    }
  }

  static Uint8List _encodeCapabilities({
    required bool canBePlayer,
    required bool restrictToLocal,
    required bool gaiaEqConnectId,
    required bool supportsLogout,
    required bool isObservable,
    required int volumeSteps,
    required List<String> supportedTypes,
    required bool commandAcks,
    required bool supportsRename,
    required bool supportsPlaylistV2,
    required bool isControllable,
    required bool supportsExternalEpisodes,
    required bool supportsSetBackendMetadata,
    required bool supportsTransferCommand,
    required bool supportsCommandRequest,
    required bool isVoiceEnabled,
    required bool needsFullPlayerState,
    required bool supportsGzipPushes,
    required bool supportsSetOptionsCommand,
    required bool supportsRooms,
    required bool supportsDj,
    required ConnectAudioQuality supportedAudioQuality,
    required bool supportsSmartShuffleMode,
    required bool supportsRemoteSleepTimer,
    required bool supportsPingRequest,
    required bool supportsPlaylistMixing,
    required bool supportsRemoteAudioQualityControl,
    required bool supportsZephyr,
    required bool supportsGapless,
    required bool supportsCrossfade,
  }) {
    final buf = BytesBuilder(copy: false);
    // tag 2: can_be_player
    _writeBoolField(buf, 2, canBePlayer);
    // tag 3: restrict_to_local
    _writeBoolField(buf, 3, restrictToLocal);
    // tag 5: gaia_eq_connect_id
    _writeBoolField(buf, 5, gaiaEqConnectId);
    // tag 6: supports_logout
    _writeBoolField(buf, 6, supportsLogout);
    // tag 7: is_observable
    _writeBoolField(buf, 7, isObservable);
    // tag 8: volume_steps
    _writeUintField(buf, 8, volumeSteps);
    // tag 9: supported_types (repeated string)
    for (final mediaType in supportedTypes) {
      final trimmed = mediaType.trim();
      if (trimmed.isNotEmpty) {
        _writeStringField(buf, 9, trimmed);
      }
    }
    // tag 10: command_acks
    _writeBoolField(buf, 10, commandAcks);
    // tag 11: supports_rename (false for phone)
    _writeBoolField(buf, 11, supportsRename);
    // tag 12: hidden
    _writeBoolField(buf, 12, false);
    // tag 13: disable_volume
    _writeBoolField(buf, 13, false);
    // tag 14: connect_disabled
    _writeBoolField(buf, 14, false);
    // tag 15: supports_playlist_v2
    _writeBoolField(buf, 15, supportsPlaylistV2);
    // tag 16: is_controllable
    _writeBoolField(buf, 16, isControllable);
    // tag 17: supports_external_episodes
    _writeBoolField(buf, 17, supportsExternalEpisodes);
    // tag 18: supports_set_backend_metadata
    _writeBoolField(buf, 18, supportsSetBackendMetadata);
    // tag 19: supports_transfer_command
    _writeBoolField(buf, 19, supportsTransferCommand);
    // tag 20: supports_command_request
    _writeBoolField(buf, 20, supportsCommandRequest);
    // tag 21: is_voice_enabled
    _writeBoolField(buf, 21, isVoiceEnabled);
    // tag 22: needs_full_player_state
    _writeBoolField(buf, 22, needsFullPlayerState);
    // tag 23: supports_gzip_pushes
    _writeBoolField(buf, 23, supportsGzipPushes);
    // tag 25: supports_set_options_command
    _writeBoolField(buf, 25, supportsSetOptionsCommand);
    // tag 28: supports_rooms
    _writeBoolField(buf, 28, supportsRooms);
    // tag 29: supports_dj
    _writeBoolField(buf, 29, supportsDj);
    // tag 30: supported_audio_quality
    _writeUintField(buf, 30, audioQualityToWireCode(supportedAudioQuality));
    // tag 33: supports_smart_shuffle_mode
    _writeBoolField(buf, 33, supportsSmartShuffleMode);
    // tag 34: supports_remote_sleep_timer
    _writeBoolField(buf, 34, supportsRemoteSleepTimer);
    // tag 35: supports_ping_request
    _writeBoolField(buf, 35, supportsPingRequest);
    // tag 36: supports_playlist_mixing
    _writeBoolField(buf, 36, supportsPlaylistMixing);
    // tag 37: supports_remote_audio_quality_control
    _writeBoolField(buf, 37, supportsRemoteAudioQualityControl);
    // tag 38: supports_zephyr
    _writeBoolField(buf, 38, supportsZephyr);
    // tag 39: supports_gapless
    _writeBoolField(buf, 39, supportsGapless);
    // tag 40: supports_crossfade
    _writeBoolField(buf, 40, supportsCrossfade);

    return buf.toBytes();
  }

  static void _writeVarint(BytesBuilder out, int value) {
    var v = value;
    while (v >= 0x80) {
      out.addByte((v & 0x7F) | 0x80);
      v >>>= 7;
    }
    out.addByte(v & 0x7F);
  }

  static void _writeBoolField(BytesBuilder out, int fieldNumber, bool value) {
    _writeVarint(out, (fieldNumber << 3) | 0);
    out.addByte(value ? 1 : 0);
  }

  static void _writeUintField(BytesBuilder out, int fieldNumber, int value) {
    _writeVarint(out, (fieldNumber << 3) | 0);
    _writeVarint(out, value);
  }

  static void _writeStringField(
    BytesBuilder out,
    int fieldNumber,
    String value,
  ) {
    if (value.isEmpty) {
      return;
    }
    final bytes = utf8.encode(value);
    _writeVarint(out, (fieldNumber << 3) | 2);
    _writeVarint(out, bytes.length);
    out.add(bytes);
  }

  static void _writeSubmessageField(
    BytesBuilder out,
    int fieldNumber,
    Uint8List submessageBytes,
  ) {
    _writeVarint(out, (fieldNumber << 3) | 2);
    _writeVarint(out, submessageBytes.length);
    out.add(submessageBytes);
  }
}
