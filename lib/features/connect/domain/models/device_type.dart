// 1:1 replica of p199p/t3t.java (lines 6–91), p199p/tzl1.java (lines 187–206),
// and protos/spotify/connect/devices.proto (DeviceType, lines 14–34).

/// Connect device form-factor classification matching `p199p/t3t.java` in
/// exact ordinal order (0..16).
enum DeviceType {
  unknown, // 0: UNKNOWN
  computer, // 1: COMPUTER
  tablet, // 2: TABLET
  smartphone, // 3: SMARTPHONE
  speaker, // 4: SPEAKER
  tv, // 5: TV
  avr, // 6: AVR
  stb, // 7: STB
  audioDongle, // 8: AUDIO_DONGLE
  gameConsole, // 9: GAME_CONSOLE
  castVideo, // 10: CAST_VIDEO
  castAudio, // 11: CAST_AUDIO
  automobile, // 12: AUTOMOBILE
  smartwatch, // 13: SMARTWATCH
  chromebook, // 14: CHROMEBOOK
  unknownSpotifyHw, // 15: UNKNOWN_SPOTIFY_HW (devices.proto: UNKNOWN_SPOTIFY = 100)
  homeThing; // 16: HOMETHING (devices.proto: HOME_THING = 103)

  /// Resolves a wire/proto device type string to [DeviceType], matching
  /// `p199p/tzl1.m82887D` case-insensitive resolution plus `devices.proto`
  /// aliases (`UNKNOWN_SPOTIFY`, `HOME_THING`, `CAR_THING`, `OBSERVER`, `GLASSES`).
  ///
  /// Throws [FormatException] if [raw] is empty or whitespace-only.
  static DeviceType fromWireName(String raw) {
    final normalized = raw.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw FormatException(
        'DeviceType wire name must not be empty',
        raw,
      );
    }

    switch (normalized) {
      case 'UNKNOWN':
        return DeviceType.unknown;
      case 'COMPUTER':
        return DeviceType.computer;
      case 'TABLET':
        return DeviceType.tablet;
      case 'SMARTPHONE':
        return DeviceType.smartphone;
      case 'SPEAKER':
        return DeviceType.speaker;
      case 'TV':
        return DeviceType.tv;
      case 'AVR':
        return DeviceType.avr;
      case 'STB':
        return DeviceType.stb;
      case 'AUDIO_DONGLE':
        return DeviceType.audioDongle;
      case 'GAME_CONSOLE':
        return DeviceType.gameConsole;
      case 'CAST_VIDEO':
        return DeviceType.castVideo;
      case 'CAST_AUDIO':
        return DeviceType.castAudio;
      case 'AUTOMOBILE':
        return DeviceType.automobile;
      case 'SMARTWATCH':
        return DeviceType.smartwatch;
      case 'CHROMEBOOK':
        return DeviceType.chromebook;
      case 'UNKNOWN_SPOTIFY_HW':
      case 'UNKNOWN_SPOTIFY':
        return DeviceType.unknownSpotifyHw;
      case 'HOMETHING':
      case 'HOME_THING':
        return DeviceType.homeThing;
      case 'CAR_THING':
      case 'OBSERVER':
      case 'GLASSES':
      default:
        return DeviceType.unknown;
    }
  }

  /// Canonical `p199p/t3t.java` wire name for this enum constant.
  String get wireName {
    switch (this) {
      case DeviceType.unknown:
        return 'UNKNOWN';
      case DeviceType.computer:
        return 'COMPUTER';
      case DeviceType.tablet:
        return 'TABLET';
      case DeviceType.smartphone:
        return 'SMARTPHONE';
      case DeviceType.speaker:
        return 'SPEAKER';
      case DeviceType.tv:
        return 'TV';
      case DeviceType.avr:
        return 'AVR';
      case DeviceType.stb:
        return 'STB';
      case DeviceType.audioDongle:
        return 'AUDIO_DONGLE';
      case DeviceType.gameConsole:
        return 'GAME_CONSOLE';
      case DeviceType.castVideo:
        return 'CAST_VIDEO';
      case DeviceType.castAudio:
        return 'CAST_AUDIO';
      case DeviceType.automobile:
        return 'AUTOMOBILE';
      case DeviceType.smartwatch:
        return 'SMARTWATCH';
      case DeviceType.chromebook:
        return 'CHROMEBOOK';
      case DeviceType.unknownSpotifyHw:
        return 'UNKNOWN_SPOTIFY_HW';
      case DeviceType.homeThing:
        return 'HOMETHING';
    }
  }
}
