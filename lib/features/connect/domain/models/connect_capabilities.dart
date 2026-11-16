// 1:1 replica of p199p/szc.java (lines 10–152), p199p/y9z0.java (lines 8–60),
// p199p/q05.java (lines 8–113), p199p/w7k.java (line 111), and
// protos/spotify/connect/devices.proto (AudioQuality lines 62–70, Capabilities lines 93–129).

import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/connect/domain/models/hifi_status.dart';

/// Android deep-link URI configuration inside a Connect capability entry
/// (`p199p/q05.java`).
@immutable
final class ConnectCapabilityAndroidUris extends Equatable {
  /// Target Android intent URI (`q05.f190437a`, JSON `"uri"`).
  final String? uri;

  /// Query/intent parameter for redirecting back to the companion app
  /// (`q05.f190438b`, JSON `"redirectBackAppParam"`).
  final String? redirectBackAppParam;

  /// Query/intent parameter carrying the device name (`q05.f190439c`, JSON `"deviceNameParam"`).
  final String? deviceNameParam;

  /// Fallback web URL when the companion app is not installed
  /// (`q05.f190440d`, JSON `"fallbackUrl"`).
  final String? fallbackUrl;

  const ConnectCapabilityAndroidUris({
    this.uri,
    this.redirectBackAppParam,
    this.deviceNameParam,
    this.fallbackUrl,
  });

  ConnectCapabilityAndroidUris copyWith({
    String? uri,
    bool clearUri = false,
    String? redirectBackAppParam,
    bool clearRedirectBackAppParam = false,
    String? deviceNameParam,
    bool clearDeviceNameParam = false,
    String? fallbackUrl,
    bool clearFallbackUrl = false,
  }) {
    return ConnectCapabilityAndroidUris(
      uri: clearUri
          ? null
          : switch (uri) {
              final value? => value,
              null => this.uri,
            },
      redirectBackAppParam: clearRedirectBackAppParam
          ? null
          : switch (redirectBackAppParam) {
              final value? => value,
              null => this.redirectBackAppParam,
            },
      deviceNameParam: clearDeviceNameParam
          ? null
          : switch (deviceNameParam) {
              final value? => value,
              null => this.deviceNameParam,
            },
      fallbackUrl: clearFallbackUrl
          ? null
          : switch (fallbackUrl) {
              final value? => value,
              null => this.fallbackUrl,
            },
    );
  }

  @override
  List<Object?> get props => [
        uri,
        redirectBackAppParam,
        deviceNameParam,
        fallbackUrl,
      ];
}

/// Platform redirect URIs container inside a Connect capability entry
/// (`p199p/y9z0.java`).
@immutable
final class ConnectCapabilityRedirectUris extends Equatable {
  /// Android redirect URI configuration (`y9z0.f284123a`, JSON `"android"`).
  final ConnectCapabilityAndroidUris? android;

  const ConnectCapabilityRedirectUris({this.android});

  ConnectCapabilityRedirectUris copyWith({
    ConnectCapabilityAndroidUris? android,
    bool clearAndroid = false,
  }) {
    return ConnectCapabilityRedirectUris(
      android: clearAndroid
          ? null
          : switch (android) {
              final value? => value,
              null => this.android,
            },
    );
  }

  @override
  List<Object?> get props => [android];
}

/// Parsed JSON Connect capability action entry (`com.spotify.connect.core.model.Capability`,
/// `p199p/szc.java`) stored in `ConnectDevice.capabilities` (`w7k.f260114v`).
@immutable
final class ConnectCapabilityEntry extends Equatable {
  /// Capability identifier (`szc.f224149a`, JSON `"id"`).
  final String? id;

  /// Default unlocalized capability title (`szc.f224150b`, JSON `"defaultTitle"`).
  final String? defaultTitle;

  /// Capability icon URL (`szc.f224151c`, JSON `"iconUrl"`).
  final String? iconUrl;

  /// Redirect URIs configuration (`szc.f224152d`, JSON `"redirectUris"`).
  final ConnectCapabilityRedirectUris? redirectUris;

  /// Locale-keyed localized titles (`szc.f224153e`, JSON `"localizedTitle"`).
  final UnmodifiableMapView<String, String>? localizedTitle;

  ConnectCapabilityEntry({
    this.id,
    this.defaultTitle,
    this.iconUrl,
    this.redirectUris,
    Map<String, String>? localizedTitle,
  }) : localizedTitle = switch (localizedTitle) {
          final map? => UnmodifiableMapView<String, String>(
              Map<String, String>.of(map),
            ),
          null => null,
        };

  ConnectCapabilityEntry copyWith({
    String? id,
    bool clearId = false,
    String? defaultTitle,
    bool clearDefaultTitle = false,
    String? iconUrl,
    bool clearIconUrl = false,
    ConnectCapabilityRedirectUris? redirectUris,
    bool clearRedirectUris = false,
    Map<String, String>? localizedTitle,
    bool clearLocalizedTitle = false,
  }) {
    return ConnectCapabilityEntry(
      id: clearId
          ? null
          : switch (id) {
              final value? => value,
              null => this.id,
            },
      defaultTitle: clearDefaultTitle
          ? null
          : switch (defaultTitle) {
              final value? => value,
              null => this.defaultTitle,
            },
      iconUrl: clearIconUrl
          ? null
          : switch (iconUrl) {
              final value? => value,
              null => this.iconUrl,
            },
      redirectUris: clearRedirectUris
          ? null
          : switch (redirectUris) {
              final value? => value,
              null => this.redirectUris,
            },
      localizedTitle: clearLocalizedTitle
          ? null
          : switch (localizedTitle) {
              final value? => value,
              null => this.localizedTitle,
            },
    );
  }

  @override
  List<Object?> get props => [
        id,
        defaultTitle,
        iconUrl,
        redirectUris,
        localizedTitle,
      ];
}

/// Supported Connect audio quality tier matching `spotify.connectstate.AudioQuality`
/// (`protos/spotify/connect/devices.proto:62–70`).
enum ConnectAudioQuality {
  defaultQuality, // 0: AUDIO_QUALITY_DEFAULT
  low, // 1: AUDIO_QUALITY_LOW
  normal, // 2: AUDIO_QUALITY_NORMAL
  high, // 3: AUDIO_QUALITY_HIGH
  veryHigh, // 4: AUDIO_QUALITY_VERY_HIGH
  hifi, // 5: AUDIO_QUALITY_HIFI
  hifi24; // 6: AUDIO_QUALITY_HIFI_24

  static ConnectAudioQuality fromProtoIndex(int value) {
    switch (value) {
      case 0:
        return ConnectAudioQuality.defaultQuality;
      case 1:
        return ConnectAudioQuality.low;
      case 2:
        return ConnectAudioQuality.normal;
      case 3:
        return ConnectAudioQuality.high;
      case 4:
        return ConnectAudioQuality.veryHigh;
      case 5:
        return ConnectAudioQuality.hifi;
      case 6:
        return ConnectAudioQuality.hifi24;
      default:
        throw RangeError.range(
          value,
          0,
          6,
          'value',
          'Invalid ConnectAudioQuality proto index',
        );
    }
  }

  String get wireName {
    switch (this) {
      case ConnectAudioQuality.defaultQuality:
        return 'AUDIO_QUALITY_DEFAULT';
      case ConnectAudioQuality.low:
        return 'AUDIO_QUALITY_LOW';
      case ConnectAudioQuality.normal:
        return 'AUDIO_QUALITY_NORMAL';
      case ConnectAudioQuality.high:
        return 'AUDIO_QUALITY_HIGH';
      case ConnectAudioQuality.veryHigh:
        return 'AUDIO_QUALITY_VERY_HIGH';
      case ConnectAudioQuality.hifi:
        return 'AUDIO_QUALITY_HIFI';
      case ConnectAudioQuality.hifi24:
        return 'AUDIO_QUALITY_HIFI_24';
    }
  }
}

/// Complete 35-field Connect device capability descriptor matching
/// `spotify.connectstate.Capabilities` (`protos/spotify/connect/devices.proto:93–129`).
@immutable
final class ConnectCapabilities extends Equatable {
  final bool canBePlayer; // tag 2
  final bool restrictToLocal; // tag 3
  final bool gaiaEqConnectId; // tag 5
  final bool supportsLogout; // tag 6
  final bool isObservable; // tag 7
  final int volumeSteps; // tag 8
  final UnmodifiableListView<String> supportedTypes; // tag 9
  final bool commandAcks; // tag 10
  final bool supportsRename; // tag 11
  final bool hidden; // tag 12
  final bool disableVolume; // tag 13
  final bool connectDisabled; // tag 14
  final bool supportsPlaylistV2; // tag 15
  final bool isControllable; // tag 16
  final bool supportsExternalEpisodes; // tag 17
  final bool supportsSetBackendMetadata; // tag 18
  final bool supportsTransferCommand; // tag 19
  final bool supportsCommandRequest; // tag 20
  final bool isVoiceEnabled; // tag 21
  final bool needsFullPlayerState; // tag 22
  final bool supportsGzipPushes; // tag 23
  final bool supportsSetOptionsCommand; // tag 25
  final ConnectHifiStatus? supportsHifi; // tag 26
  final String connectCapabilities; // tag 27 (JSON capabilities payload)
  final bool supportsRooms; // tag 28
  final bool supportsDj; // tag 29
  final ConnectAudioQuality supportedAudioQuality; // tag 30
  final bool supportsSmartShuffleMode; // tag 33
  final bool supportsRemoteSleepTimer; // tag 34
  final bool supportsPingRequest; // tag 35
  final bool supportsPlaylistMixing; // tag 36
  final bool supportsRemoteAudioQualityControl; // tag 37
  final bool supportsZephyr; // tag 38
  final bool supportsGapless; // tag 39
  final bool supportsCrossfade; // tag 40

  ConnectCapabilities({
    this.canBePlayer = false,
    this.restrictToLocal = false,
    this.gaiaEqConnectId = false,
    this.supportsLogout = false,
    this.isObservable = false,
    this.volumeSteps = 0,
    List<String> supportedTypes = const <String>[],
    this.commandAcks = false,
    this.supportsRename = false,
    this.hidden = false,
    this.disableVolume = false,
    this.connectDisabled = false,
    this.supportsPlaylistV2 = false,
    this.isControllable = false,
    this.supportsExternalEpisodes = false,
    this.supportsSetBackendMetadata = false,
    this.supportsTransferCommand = false,
    this.supportsCommandRequest = false,
    this.isVoiceEnabled = false,
    this.needsFullPlayerState = false,
    this.supportsGzipPushes = false,
    this.supportsSetOptionsCommand = false,
    this.supportsHifi,
    this.connectCapabilities = '',
    this.supportsRooms = false,
    this.supportsDj = false,
    this.supportedAudioQuality = ConnectAudioQuality.defaultQuality,
    this.supportsSmartShuffleMode = false,
    this.supportsRemoteSleepTimer = false,
    this.supportsPingRequest = false,
    this.supportsPlaylistMixing = false,
    this.supportsRemoteAudioQualityControl = false,
    this.supportsZephyr = false,
    this.supportsGapless = false,
    this.supportsCrossfade = false,
  }) : supportedTypes = UnmodifiableListView<String>(
          List<String>.of(supportedTypes),
        ) {
    if (volumeSteps < 0) {
      throw RangeError.value(
        volumeSteps,
        'volumeSteps',
        'Must be non-negative',
      );
    }
  }

  /// Derived inverse of [disableVolume], matching `StateResponse.Device.supports_volume`.
  bool get supportsVolume => !disableVolume;

  ConnectCapabilities copyWith({
    bool? canBePlayer,
    bool? restrictToLocal,
    bool? gaiaEqConnectId,
    bool? supportsLogout,
    bool? isObservable,
    int? volumeSteps,
    List<String>? supportedTypes,
    bool? commandAcks,
    bool? supportsRename,
    bool? hidden,
    bool? disableVolume,
    bool? connectDisabled,
    bool? supportsPlaylistV2,
    bool? isControllable,
    bool? supportsExternalEpisodes,
    bool? supportsSetBackendMetadata,
    bool? supportsTransferCommand,
    bool? supportsCommandRequest,
    bool? isVoiceEnabled,
    bool? needsFullPlayerState,
    bool? supportsGzipPushes,
    bool? supportsSetOptionsCommand,
    ConnectHifiStatus? supportsHifi,
    bool clearSupportsHifi = false,
    String? connectCapabilities,
    bool? supportsRooms,
    bool? supportsDj,
    ConnectAudioQuality? supportedAudioQuality,
    bool? supportsSmartShuffleMode,
    bool? supportsRemoteSleepTimer,
    bool? supportsPingRequest,
    bool? supportsPlaylistMixing,
    bool? supportsRemoteAudioQualityControl,
    bool? supportsZephyr,
    bool? supportsGapless,
    bool? supportsCrossfade,
  }) {
    return ConnectCapabilities(
      canBePlayer: switch (canBePlayer) {
        final value? => value,
        null => this.canBePlayer,
      },
      restrictToLocal: switch (restrictToLocal) {
        final value? => value,
        null => this.restrictToLocal,
      },
      gaiaEqConnectId: switch (gaiaEqConnectId) {
        final value? => value,
        null => this.gaiaEqConnectId,
      },
      supportsLogout: switch (supportsLogout) {
        final value? => value,
        null => this.supportsLogout,
      },
      isObservable: switch (isObservable) {
        final value? => value,
        null => this.isObservable,
      },
      volumeSteps: switch (volumeSteps) {
        final value? => value,
        null => this.volumeSteps,
      },
      supportedTypes: switch (supportedTypes) {
        final value? => value,
        null => this.supportedTypes,
      },
      commandAcks: switch (commandAcks) {
        final value? => value,
        null => this.commandAcks,
      },
      supportsRename: switch (supportsRename) {
        final value? => value,
        null => this.supportsRename,
      },
      hidden: switch (hidden) {
        final value? => value,
        null => this.hidden,
      },
      disableVolume: switch (disableVolume) {
        final value? => value,
        null => this.disableVolume,
      },
      connectDisabled: switch (connectDisabled) {
        final value? => value,
        null => this.connectDisabled,
      },
      supportsPlaylistV2: switch (supportsPlaylistV2) {
        final value? => value,
        null => this.supportsPlaylistV2,
      },
      isControllable: switch (isControllable) {
        final value? => value,
        null => this.isControllable,
      },
      supportsExternalEpisodes: switch (supportsExternalEpisodes) {
        final value? => value,
        null => this.supportsExternalEpisodes,
      },
      supportsSetBackendMetadata: switch (supportsSetBackendMetadata) {
        final value? => value,
        null => this.supportsSetBackendMetadata,
      },
      supportsTransferCommand: switch (supportsTransferCommand) {
        final value? => value,
        null => this.supportsTransferCommand,
      },
      supportsCommandRequest: switch (supportsCommandRequest) {
        final value? => value,
        null => this.supportsCommandRequest,
      },
      isVoiceEnabled: switch (isVoiceEnabled) {
        final value? => value,
        null => this.isVoiceEnabled,
      },
      needsFullPlayerState: switch (needsFullPlayerState) {
        final value? => value,
        null => this.needsFullPlayerState,
      },
      supportsGzipPushes: switch (supportsGzipPushes) {
        final value? => value,
        null => this.supportsGzipPushes,
      },
      supportsSetOptionsCommand: switch (supportsSetOptionsCommand) {
        final value? => value,
        null => this.supportsSetOptionsCommand,
      },
      supportsHifi: clearSupportsHifi
          ? null
          : switch (supportsHifi) {
              final value? => value,
              null => this.supportsHifi,
            },
      connectCapabilities: switch (connectCapabilities) {
        final value? => value,
        null => this.connectCapabilities,
      },
      supportsRooms: switch (supportsRooms) {
        final value? => value,
        null => this.supportsRooms,
      },
      supportsDj: switch (supportsDj) {
        final value? => value,
        null => this.supportsDj,
      },
      supportedAudioQuality: switch (supportedAudioQuality) {
        final value? => value,
        null => this.supportedAudioQuality,
      },
      supportsSmartShuffleMode: switch (supportsSmartShuffleMode) {
        final value? => value,
        null => this.supportsSmartShuffleMode,
      },
      supportsRemoteSleepTimer: switch (supportsRemoteSleepTimer) {
        final value? => value,
        null => this.supportsRemoteSleepTimer,
      },
      supportsPingRequest: switch (supportsPingRequest) {
        final value? => value,
        null => this.supportsPingRequest,
      },
      supportsPlaylistMixing: switch (supportsPlaylistMixing) {
        final value? => value,
        null => this.supportsPlaylistMixing,
      },
      supportsRemoteAudioQualityControl: switch (supportsRemoteAudioQualityControl) {
        final value? => value,
        null => this.supportsRemoteAudioQualityControl,
      },
      supportsZephyr: switch (supportsZephyr) {
        final value? => value,
        null => this.supportsZephyr,
      },
      supportsGapless: switch (supportsGapless) {
        final value? => value,
        null => this.supportsGapless,
      },
      supportsCrossfade: switch (supportsCrossfade) {
        final value? => value,
        null => this.supportsCrossfade,
      },
    );
  }

  @override
  List<Object?> get props => [
        canBePlayer,
        restrictToLocal,
        gaiaEqConnectId,
        supportsLogout,
        isObservable,
        volumeSteps,
        supportedTypes,
        commandAcks,
        supportsRename,
        hidden,
        disableVolume,
        connectDisabled,
        supportsPlaylistV2,
        isControllable,
        supportsExternalEpisodes,
        supportsSetBackendMetadata,
        supportsTransferCommand,
        supportsCommandRequest,
        isVoiceEnabled,
        needsFullPlayerState,
        supportsGzipPushes,
        supportsSetOptionsCommand,
        supportsHifi,
        connectCapabilities,
        supportsRooms,
        supportsDj,
        supportedAudioQuality,
        supportsSmartShuffleMode,
        supportsRemoteSleepTimer,
        supportsPingRequest,
        supportsPlaylistMixing,
        supportsRemoteAudioQualityControl,
        supportsZephyr,
        supportsGapless,
        supportsCrossfade,
      ];
}
