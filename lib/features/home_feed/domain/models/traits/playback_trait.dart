import 'trait.dart';

/// Represents a single decoded audio stream candidate inside [PlaybackTrait].
/// 1:1 equivalent to Spotify Android's `xi7` / `ap7` / `bp7` audio stream descriptors.
class PlaybackAudioTrack {
  final int formatNumber;
  final String fileIdHex;
  final String reportingUri;
  final String cdnUrl;
  final int averageBitrate;
  final int startOffsetMs;
  final int endOffsetMs;

  const PlaybackAudioTrack({
    this.formatNumber = -1,
    this.fileIdHex = '',
    this.reportingUri = '',
    this.cdnUrl = '',
    this.averageBitrate = 0,
    this.startOffsetMs = 0,
    this.endOffsetMs = 0,
  });

  Map<String, dynamic> toJson() => {
    'formatNumber': formatNumber,
    'fileIdHex': fileIdHex,
    'reportingUri': reportingUri,
    'cdnUrl': cdnUrl,
    'averageBitrate': averageBitrate,
    'startOffsetMs': startOffsetMs,
    'endOffsetMs': endOffsetMs,
  };

  factory PlaybackAudioTrack.fromJson(Map<String, dynamic> json) {
    final formatNumberVal = json['formatNumber'];
    final fileIdVal = json['fileIdHex'];
    final reportingUriVal = json['reportingUri'];
    final cdnUrlVal = json['cdnUrl'];
    final averageBitrateVal = json['averageBitrate'];
    final startOffsetMsVal = json['startOffsetMs'];
    final endOffsetMsVal = json['endOffsetMs'];

    return PlaybackAudioTrack(
      formatNumber: formatNumberVal is int ? formatNumberVal : -1,
      fileIdHex: fileIdVal is String ? fileIdVal : '',
      reportingUri: reportingUriVal is String ? reportingUriVal : '',
      cdnUrl: cdnUrlVal is String ? cdnUrlVal : '',
      averageBitrate: averageBitrateVal is int ? averageBitrateVal : 0,
      startOffsetMs: startOffsetMsVal is int ? startOffsetMsVal : 0,
      endOffsetMs: endOffsetMsVal is int ? endOffsetMsVal : 0,
    );
  }
}

/// Content-agnostic playback trait (ExtensionKind 212).
/// Direct 1:1 equivalent to Spotify Android's `p.yjs0` (decoded from `PlaybackTrait.java`).
///
/// Encapsulates all available audio file IDs (hosted files, pass-through CDN streams,
/// bitrates, and head chunk URLs) for a track or playable entity.
class PlaybackTrait extends Trait {
  final List<PlaybackAudioTrack> audioTracks;
  final String primaryFileIdHex;
  final String headUrl;
  final String passThroughCdnUrl;

  const PlaybackTrait({
    this.audioTracks = const [],
    this.primaryFileIdHex = '',
    this.headUrl = '',
    this.passThroughCdnUrl = '',
  });

  bool get hasAudio => primaryFileIdHex.isNotEmpty || passThroughCdnUrl.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {
    'audioTracks': audioTracks.map((t) => t.toJson()).toList(),
    'primaryFileIdHex': primaryFileIdHex,
    'headUrl': headUrl,
    'passThroughCdnUrl': passThroughCdnUrl,
  };

  factory PlaybackTrait.fromJson(Map<String, dynamic> json) {
    final rawTracks = json['audioTracks'];
    final tracks = <PlaybackAudioTrack>[];
    if (rawTracks is List) {
      for (final item in rawTracks) {
        if (item is Map<String, dynamic>) {
          tracks.add(PlaybackAudioTrack.fromJson(item));
        }
      }
    }

    final primaryVal = json['primaryFileIdHex'];
    final headVal = json['headUrl'];
    final cdnVal = json['passThroughCdnUrl'];

    return PlaybackTrait(
      audioTracks: List.unmodifiable(tracks),
      primaryFileIdHex: primaryVal is String ? primaryVal : '',
      headUrl: headVal is String ? headVal : '',
      passThroughCdnUrl: cdnVal is String ? cdnVal : '',
    );
  }
}
