// 1:1 replica of p199p/w7k.java (lines 6–206), p199p/u5q.java (lines 50–123, 407–456),
// p199p/n8d.java (lines 566–1011), and StateResponse.Device in
// com/spotify/connect/esperanto/proto/ConnectMessages$StateResponse.java.

import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/connect/domain/models/connect_capabilities.dart';
import 'package:musify_mu/features/connect/domain/models/connect_group_data.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/hifi_status.dart';
import 'package:musify_mu/features/connect/domain/models/incarnation.dart';
import 'package:musify_mu/features/connect/domain/models/output_peripheral.dart';

/// Connect device lifecycle/availability state matching the 22 values in
/// `p199p/u5q.java` (lines 55–120, 407–456).
enum ConnectDeviceState {
  connecting, // 1: CONNECTING
  incompatible, // 2: INCOMPATIBLE
  unavailable, // 3: UNAVAILABLE
  loggedIn, // 4: LOGGED_IN
  notLoggedIn, // 5: NOT_LOGGED_IN
  premiumRequired, // 6: PREMIUM_REQUIRED
  notInstalled, // 7: NOT_INSTALLED
  unsupportedUri, // 8: UNSUPPORTED_URI
  sleeping, // 9: SLEEPING
  notAuthorized, // 10: NOT_AUTHORIZED
  adPlaying, // 11: AD_PLAYING
  narration, // 12: NARRATION
  timedOutWakeup, // 13: TIMED_OUT_WAKEUP
  wakingUp, // 14: WAKING_UP
  notLoaded, // 15: NOT_LOADED
  wol, // 16: WOL
  busy, // 17: BUSY
  installationAvailable, // 18: INSTALLATION_AVAILABLE
  installing, // 19: INSTALLING
  managedAccountOnDisallowedDevice, // 20: MANAGED_ACCOUNT_ON_DISALLOWED_DEVICE
  unsupportedVersion, // 21: UNSUPPORTED_VERSION
  unknown; // 22: UNKNOWN

  /// Parses a wire `StateResponse.Device.state` string matching `p199p/n8d.java:567–571`
  /// and `p199p/u5q.m83319C`.
  ///
  /// Throws [FormatException] if [raw] is empty or whitespace-only; maps
  /// unrecognized non-empty wire strings to [ConnectDeviceState.unknown].
  static ConnectDeviceState fromWireName(String raw) {
    final normalized = raw.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw FormatException(
        'ConnectDeviceState wire name must not be empty',
        raw,
      );
    }

    switch (normalized) {
      case 'CONNECTING':
        return ConnectDeviceState.connecting;
      case 'INCOMPATIBLE':
        return ConnectDeviceState.incompatible;
      case 'UNAVAILABLE':
        return ConnectDeviceState.unavailable;
      case 'LOGGED_IN':
        return ConnectDeviceState.loggedIn;
      case 'NOT_LOGGED_IN':
        return ConnectDeviceState.notLoggedIn;
      case 'PREMIUM_REQUIRED':
        return ConnectDeviceState.premiumRequired;
      case 'NOT_INSTALLED':
        return ConnectDeviceState.notInstalled;
      case 'UNSUPPORTED_URI':
        return ConnectDeviceState.unsupportedUri;
      case 'SLEEPING':
        return ConnectDeviceState.sleeping;
      case 'NOT_AUTHORIZED':
        return ConnectDeviceState.notAuthorized;
      case 'AD_PLAYING':
        return ConnectDeviceState.adPlaying;
      case 'NARRATION':
        return ConnectDeviceState.narration;
      case 'TIMED_OUT_WAKEUP':
        return ConnectDeviceState.timedOutWakeup;
      case 'WAKING_UP':
        return ConnectDeviceState.wakingUp;
      case 'NOT_LOADED':
        return ConnectDeviceState.notLoaded;
      case 'WOL':
        return ConnectDeviceState.wol;
      case 'BUSY':
        return ConnectDeviceState.busy;
      case 'INSTALLATION_AVAILABLE':
        return ConnectDeviceState.installationAvailable;
      case 'INSTALLING':
        return ConnectDeviceState.installing;
      case 'MANAGED_ACCOUNT_ON_DISALLOWED_DEVICE':
        return ConnectDeviceState.managedAccountOnDisallowedDevice;
      case 'UNSUPPORTED_VERSION':
        return ConnectDeviceState.unsupportedVersion;
      case 'UNKNOWN':
      default:
        return ConnectDeviceState.unknown;
    }
  }

  /// Canonical `p199p/u5q.m83342w` wire name.
  String get wireName {
    switch (this) {
      case ConnectDeviceState.connecting:
        return 'CONNECTING';
      case ConnectDeviceState.incompatible:
        return 'INCOMPATIBLE';
      case ConnectDeviceState.unavailable:
        return 'UNAVAILABLE';
      case ConnectDeviceState.loggedIn:
        return 'LOGGED_IN';
      case ConnectDeviceState.notLoggedIn:
        return 'NOT_LOGGED_IN';
      case ConnectDeviceState.premiumRequired:
        return 'PREMIUM_REQUIRED';
      case ConnectDeviceState.notInstalled:
        return 'NOT_INSTALLED';
      case ConnectDeviceState.unsupportedUri:
        return 'UNSUPPORTED_URI';
      case ConnectDeviceState.sleeping:
        return 'SLEEPING';
      case ConnectDeviceState.notAuthorized:
        return 'NOT_AUTHORIZED';
      case ConnectDeviceState.adPlaying:
        return 'AD_PLAYING';
      case ConnectDeviceState.narration:
        return 'NARRATION';
      case ConnectDeviceState.timedOutWakeup:
        return 'TIMED_OUT_WAKEUP';
      case ConnectDeviceState.wakingUp:
        return 'WAKING_UP';
      case ConnectDeviceState.notLoaded:
        return 'NOT_LOADED';
      case ConnectDeviceState.wol:
        return 'WOL';
      case ConnectDeviceState.busy:
        return 'BUSY';
      case ConnectDeviceState.installationAvailable:
        return 'INSTALLATION_AVAILABLE';
      case ConnectDeviceState.installing:
        return 'INSTALLING';
      case ConnectDeviceState.managedAccountOnDisallowedDevice:
        return 'MANAGED_ACCOUNT_ON_DISALLOWED_DEVICE';
      case ConnectDeviceState.unsupportedVersion:
        return 'UNSUPPORTED_VERSION';
      case ConnectDeviceState.unknown:
        return 'UNKNOWN';
    }
  }
}

/// Immutable Connect device domain entity matching the exact 39 fields of
/// `p199p/w7k.java` (lines 125–165).
@immutable
final class ConnectDevice extends Equatable {
  static const int maxWireVolume = 65535;

  final bool isSelf; // 1: w7k.f260093a
  final bool isActive; // 2: w7k.f260094b
  final bool isBeingActivated; // 3: w7k.f260095c
  final bool isWebapp; // 4: w7k.f260096d
  final bool isZeroconf; // 5: w7k.f260097e
  final bool isGroup; // 6: w7k.f260098f
  final bool isSocialConnect; // 7: w7k.f260099g
  final bool supportsLogout; // 8: w7k.f260100h
  final bool supportsVolume; // 9: w7k.f260101i
  final bool supportsRename; // 10: w7k.f260102j
  final int creationTimeMs; // 11: w7k.f260103k
  final String brandDisplayName; // 12: w7k.f260104l
  final String modelDisplayName; // 13: w7k.f260105m
  final String localIdentifier; // 14: w7k.f260106n
  final String connectStateIdentifier; // 15: w7k.f260107o
  final String name; // 16: w7k.f260108p
  final ConnectDeviceState state; // 17: w7k.f260092M
  final DeviceType type; // 18: w7k.f260109q
  final UnmodifiableListView<Incarnation> incarnations; // 19: w7k.f260110r
  final int volume; // 20: w7k.f260111s (0..65535)
  final bool isNewlyDiscovered; // 21: w7k.f260112t
  final bool isDisabled; // 22: w7k.f260113u
  final UnmodifiableListView<ConnectCapabilityEntry> capabilities; // 23: w7k.f260114v
  final ConnectHifiStatus hifi; // 24: w7k.f260115w
  final OutputPeripheral? outputPeripheral; // 25: w7k.f260116x (nullable)
  final int volumeSteps; // 26: w7k.f260117y
  final bool isVoiceEnabled; // 27: w7k.f260118z
  final bool isLocal; // 28: w7k.f260080A
  final String localIp; // 29: w7k.f260081B
  final UnmodifiableListView<String> supportedMediaTypes; // 30: w7k.f260082C
  final bool supportsDj; // 31: w7k.f260083D
  final String libraryVersion; // 32: w7k.f260084E
  final bool supportsRemoteSleepTimer; // 33: w7k.f260085F
  final bool supportsPlaylistMixing; // 34: w7k.f260086G
  final bool supportsZephyr; // 35: w7k.f260087H
  final bool supportsRemoteAudioQualityControl; // 36: w7k.f260088I
  final int discoveryMethod; // 37: w7k.f260089J
  final bool? isAuthenticatedWithCurrentUser; // 38: w7k.f260090K (nullable)
  final ConnectGroupData? groupData; // 39: w7k.f260091L (nullable)

  ConnectDevice({
    required this.isSelf,
    required this.isActive,
    required this.isBeingActivated,
    required this.isWebapp,
    required this.isZeroconf,
    required this.isGroup,
    required this.isSocialConnect,
    required this.supportsLogout,
    required this.supportsVolume,
    required this.supportsRename,
    required this.creationTimeMs,
    required this.brandDisplayName,
    required this.modelDisplayName,
    required this.localIdentifier,
    required this.connectStateIdentifier,
    required this.name,
    required this.state,
    required this.type,
    required List<Incarnation> incarnations,
    required this.volume,
    required this.isNewlyDiscovered,
    required this.isDisabled,
    required List<ConnectCapabilityEntry> capabilities,
    required this.hifi,
    this.outputPeripheral,
    required this.volumeSteps,
    required this.isVoiceEnabled,
    required this.isLocal,
    required this.localIp,
    required List<String> supportedMediaTypes,
    required this.supportsDj,
    required this.libraryVersion,
    required this.supportsRemoteSleepTimer,
    required this.supportsPlaylistMixing,
    required this.supportsZephyr,
    required this.supportsRemoteAudioQualityControl,
    required this.discoveryMethod,
    this.isAuthenticatedWithCurrentUser,
    this.groupData,
  })  : incarnations = UnmodifiableListView<Incarnation>(
          List<Incarnation>.of(incarnations),
        ),
        capabilities = UnmodifiableListView<ConnectCapabilityEntry>(
          List<ConnectCapabilityEntry>.of(capabilities),
        ),
        supportedMediaTypes = UnmodifiableListView<String>(
          List<String>.of(supportedMediaTypes),
        ) {
    if (creationTimeMs < 0) {
      throw RangeError.value(
        creationTimeMs,
        'creationTimeMs',
        'Must be non-negative',
      );
    }
    if (volume < 0 || volume > maxWireVolume) {
      throw RangeError.range(
        volume,
        0,
        maxWireVolume,
        'volume',
        'Must be within [0, $maxWireVolume]',
      );
    }
    if (volumeSteps < 0) {
      throw RangeError.value(
        volumeSteps,
        'volumeSteps',
        'Must be non-negative',
      );
    }
    if (discoveryMethod < 0) {
      throw RangeError.value(
        discoveryMethod,
        'discoveryMethod',
        'Must be non-negative',
      );
    }
  }

  /// Normalized device volume in `[0.0, 1.0]`.
  double get normalizedVolume => volume / maxWireVolume;

  /// Whether this device is currently offline/unavailable.
  bool get isOffline => state == ConnectDeviceState.unavailable;

  /// Whether remote volume control is supported for this device (`p199p/nsk1.m66607y`).
  bool get isVolumeControllable =>
      !isLocal && supportsVolume && volumeSteps > 0;

  ConnectDevice copyWith({
    bool? isSelf,
    bool? isActive,
    bool? isBeingActivated,
    bool? isWebapp,
    bool? isZeroconf,
    bool? isGroup,
    bool? isSocialConnect,
    bool? supportsLogout,
    bool? supportsVolume,
    bool? supportsRename,
    int? creationTimeMs,
    String? brandDisplayName,
    String? modelDisplayName,
    String? localIdentifier,
    String? connectStateIdentifier,
    String? name,
    ConnectDeviceState? state,
    DeviceType? type,
    List<Incarnation>? incarnations,
    int? volume,
    bool? isNewlyDiscovered,
    bool? isDisabled,
    List<ConnectCapabilityEntry>? capabilities,
    ConnectHifiStatus? hifi,
    OutputPeripheral? outputPeripheral,
    bool clearOutputPeripheral = false,
    int? volumeSteps,
    bool? isVoiceEnabled,
    bool? isLocal,
    String? localIp,
    List<String>? supportedMediaTypes,
    bool? supportsDj,
    String? libraryVersion,
    bool? supportsRemoteSleepTimer,
    bool? supportsPlaylistMixing,
    bool? supportsZephyr,
    bool? supportsRemoteAudioQualityControl,
    int? discoveryMethod,
    bool? isAuthenticatedWithCurrentUser,
    bool clearIsAuthenticatedWithCurrentUser = false,
    ConnectGroupData? groupData,
    bool clearGroupData = false,
  }) {
    return ConnectDevice(
      isSelf: switch (isSelf) {
        final value? => value,
        null => this.isSelf,
      },
      isActive: switch (isActive) {
        final value? => value,
        null => this.isActive,
      },
      isBeingActivated: switch (isBeingActivated) {
        final value? => value,
        null => this.isBeingActivated,
      },
      isWebapp: switch (isWebapp) {
        final value? => value,
        null => this.isWebapp,
      },
      isZeroconf: switch (isZeroconf) {
        final value? => value,
        null => this.isZeroconf,
      },
      isGroup: switch (isGroup) {
        final value? => value,
        null => this.isGroup,
      },
      isSocialConnect: switch (isSocialConnect) {
        final value? => value,
        null => this.isSocialConnect,
      },
      supportsLogout: switch (supportsLogout) {
        final value? => value,
        null => this.supportsLogout,
      },
      supportsVolume: switch (supportsVolume) {
        final value? => value,
        null => this.supportsVolume,
      },
      supportsRename: switch (supportsRename) {
        final value? => value,
        null => this.supportsRename,
      },
      creationTimeMs: switch (creationTimeMs) {
        final value? => value,
        null => this.creationTimeMs,
      },
      brandDisplayName: switch (brandDisplayName) {
        final value? => value,
        null => this.brandDisplayName,
      },
      modelDisplayName: switch (modelDisplayName) {
        final value? => value,
        null => this.modelDisplayName,
      },
      localIdentifier: switch (localIdentifier) {
        final value? => value,
        null => this.localIdentifier,
      },
      connectStateIdentifier: switch (connectStateIdentifier) {
        final value? => value,
        null => this.connectStateIdentifier,
      },
      name: switch (name) {
        final value? => value,
        null => this.name,
      },
      state: switch (state) {
        final value? => value,
        null => this.state,
      },
      type: switch (type) {
        final value? => value,
        null => this.type,
      },
      incarnations: switch (incarnations) {
        final value? => value,
        null => this.incarnations,
      },
      volume: switch (volume) {
        final value? => value,
        null => this.volume,
      },
      isNewlyDiscovered: switch (isNewlyDiscovered) {
        final value? => value,
        null => this.isNewlyDiscovered,
      },
      isDisabled: switch (isDisabled) {
        final value? => value,
        null => this.isDisabled,
      },
      capabilities: switch (capabilities) {
        final value? => value,
        null => this.capabilities,
      },
      hifi: switch (hifi) {
        final value? => value,
        null => this.hifi,
      },
      outputPeripheral: clearOutputPeripheral
          ? null
          : switch (outputPeripheral) {
              final value? => value,
              null => this.outputPeripheral,
            },
      volumeSteps: switch (volumeSteps) {
        final value? => value,
        null => this.volumeSteps,
      },
      isVoiceEnabled: switch (isVoiceEnabled) {
        final value? => value,
        null => this.isVoiceEnabled,
      },
      isLocal: switch (isLocal) {
        final value? => value,
        null => this.isLocal,
      },
      localIp: switch (localIp) {
        final value? => value,
        null => this.localIp,
      },
      supportedMediaTypes: switch (supportedMediaTypes) {
        final value? => value,
        null => this.supportedMediaTypes,
      },
      supportsDj: switch (supportsDj) {
        final value? => value,
        null => this.supportsDj,
      },
      libraryVersion: switch (libraryVersion) {
        final value? => value,
        null => this.libraryVersion,
      },
      supportsRemoteSleepTimer: switch (supportsRemoteSleepTimer) {
        final value? => value,
        null => this.supportsRemoteSleepTimer,
      },
      supportsPlaylistMixing: switch (supportsPlaylistMixing) {
        final value? => value,
        null => this.supportsPlaylistMixing,
      },
      supportsZephyr: switch (supportsZephyr) {
        final value? => value,
        null => this.supportsZephyr,
      },
      supportsRemoteAudioQualityControl:
          switch (supportsRemoteAudioQualityControl) {
        final value? => value,
        null => this.supportsRemoteAudioQualityControl,
      },
      discoveryMethod: switch (discoveryMethod) {
        final value? => value,
        null => this.discoveryMethod,
      },
      isAuthenticatedWithCurrentUser: clearIsAuthenticatedWithCurrentUser
          ? null
          : switch (isAuthenticatedWithCurrentUser) {
              final value? => value,
              null => this.isAuthenticatedWithCurrentUser,
            },
      groupData: clearGroupData
          ? null
          : switch (groupData) {
              final value? => value,
              null => this.groupData,
            },
    );
  }

  @override
  List<Object?> get props => [
        isSelf,
        isActive,
        isBeingActivated,
        isWebapp,
        isZeroconf,
        isGroup,
        isSocialConnect,
        supportsLogout,
        supportsVolume,
        supportsRename,
        creationTimeMs,
        brandDisplayName,
        modelDisplayName,
        localIdentifier,
        connectStateIdentifier,
        name,
        state,
        type,
        incarnations,
        volume,
        isNewlyDiscovered,
        isDisabled,
        capabilities,
        hifi,
        outputPeripheral,
        volumeSteps,
        isVoiceEnabled,
        isLocal,
        localIp,
        supportedMediaTypes,
        supportsDj,
        libraryVersion,
        supportsRemoteSleepTimer,
        supportsPlaylistMixing,
        supportsZephyr,
        supportsRemoteAudioQualityControl,
        discoveryMethod,
        isAuthenticatedWithCurrentUser,
        groupData,
      ];
}
