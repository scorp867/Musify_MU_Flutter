import '../../domain/models/spotify_audio_file.dart';
import '../../domain/models/spotify_audio_format.dart';
import '../services/spotify_hex_utils.dart';

/// 1:1 replica of Spotify's audio file mapper and selector (`p199p/xjj.java` & `p199p/a1a.java`).
///
/// Converts protobuf/raw metadata structures into strongly-typed [SpotifyAudioFile] instances
/// and selects optimal stream candidates according to Spotify's client bitrate preferences.
abstract final class SpotifyAudioFileMapper {
  /// Default format for Chunk 0 Head files in Spotify: 160 kbps Ogg Vorbis.
  static const SpotifyAudioFormat defaultHeadFormat = SpotifyAudioFormat.oggVorbis160;

  /// Default format for the full track stream: 128 kbps AAC in MP4 container.
  static const SpotifyAudioFormat defaultFullTrackFormat = SpotifyAudioFormat.mp4128;

  /// 1:1 replica of `xjj.m91477c(Metadata$AudioFile)`.
  ///
  /// Maps raw byte array and protobuf format integer to [SpotifyAudioFile].
  static SpotifyAudioFile? mapFromRaw({
    required List<int>? fileIdBytes,
    required int formatNumber,
  }) {
    final String fileIdHex = SpotifyHexUtils.formatFileId(fileIdBytes);
    if (fileIdHex.isEmpty || fileIdHex.length != 40) {
      return null;
    }

    final SpotifyAudioFormat? format = SpotifyAudioFormat.fromNumber(formatNumber);
    if (format == null) {
      return null;
    }

    return SpotifyAudioFile(
      fileIdHex: fileIdHex,
      format: format,
    );
  }

  /// Maps a 40-character hex string and format enum to [SpotifyAudioFile].
  static SpotifyAudioFile? fromHex({
    required String? fileIdHex,
    required SpotifyAudioFormat format,
  }) {
    if (fileIdHex == null || fileIdHex.length != 40) {
      return null;
    }
    return SpotifyAudioFile(
      fileIdHex: fileIdHex.toLowerCase(),
      format: format,
    );
  }

  /// Infers the SpotifyAudioFormat from average bitrate in bps for contentagnostic.v2.PlaybackTrait.
  ///
  /// In Spotify's contentagnostic.v2 schema, `AudioHosted.files` specifies the average bitrate in bps:
  /// - ~24 kbps (20,000 - 35,000 bps) -> AAC_24 (CBR preview)
  /// - ~96 kbps (90,000 - 115,000 bps):
  ///   - 96,800 - 97,000 bps -> MP3_96 (CBR preview, no head file)
  ///   - other (92k - 105k VBR) -> OGG_VORBIS_96 (VBR Vorbis, has head file)
  /// - ~128 kbps (125,000 - 140,000 bps) -> MP4_128 (AAC in MP4, full track stream, no head file)
  /// - ~160 kbps (145,000 - 195,000 bps) -> OGG_VORBIS_160 (VBR Vorbis, standard head file)
  /// - ~256 kbps (250,000 - 280,000 bps) -> MP4_256 (AAC in MP4, full track stream, no head file)
  /// - ~320 kbps (300,000 - 500,000 bps) -> OGG_VORBIS_320 (VBR Vorbis, high-bitrate head file)
  /// - > 700,000 bps -> FLAC_FLAC (Lossless)
  static SpotifyAudioFormat mapFromBitrate(int averageBitrate) {
    if (averageBitrate >= 145000 && averageBitrate <= 195000) {
      return SpotifyAudioFormat.oggVorbis160;
    }
    if (averageBitrate >= 300000 && averageBitrate <= 500000) {
      return SpotifyAudioFormat.oggVorbis320;
    }
    if (averageBitrate >= 90000 && averageBitrate <= 115000) {
      if (averageBitrate >= 96800 && averageBitrate <= 97000) {
        return SpotifyAudioFormat.mp396;
      }
      return SpotifyAudioFormat.oggVorbis96;
    }
    if (averageBitrate >= 125000 && averageBitrate <= 140000) {
      return SpotifyAudioFormat.mp4128;
    }
    if (averageBitrate >= 250000 && averageBitrate <= 280000) {
      return SpotifyAudioFormat.mp4256;
    }
    if (averageBitrate >= 20000 && averageBitrate <= 35000) {
      return SpotifyAudioFormat.aac24;
    }
    if (averageBitrate > 700000) {
      return SpotifyAudioFormat.flacFlac;
    }
    return SpotifyAudioFormat.mp4128;
  }

  /// 1:1 replica of Spotify's head file selection logic (`a1a.java` lines 237-258).
  ///
  /// Selects the ideal chunk 0 head file from the available audio files,
  /// preferring `OGG_VORBIS_160` for instant TTFA (< 30ms).
  /// If 160 kbps is unavailable, falls back to the next closest Vorbis bitrate (320, then 96).
  ///
  /// Spotify's Head CDN host (`heads-fa-tls13.spotifycdn.com/head/{fileId}`) ONLY serves
  /// 128 KiB chunk 0 headers for Vorbis streams. If no Vorbis format is present, this returns
  /// null to signal the player to bypass head file loading and stream directly.
  static SpotifyAudioFile? selectHeadFile(
    List<SpotifyAudioFile> files, {
    SpotifyAudioFormat preferredFormat = defaultHeadFormat,
  }) {
    if (files.isEmpty) {
      return null;
    }

    // 1. Exact preferred Vorbis match (OGG_VORBIS_160)
    for (final SpotifyAudioFile file in files) {
      if (file.format == preferredFormat && file.format.isVorbis) {
        return file;
      }
    }

    // 2. Fall back to next closest Vorbis bitrate (320 -> 96)
    const List<SpotifyAudioFormat> vorbisBitrateOrder = <SpotifyAudioFormat>[
      SpotifyAudioFormat.oggVorbis160,
      SpotifyAudioFormat.oggVorbis320,
      SpotifyAudioFormat.oggVorbis96,
    ];
    for (final SpotifyAudioFormat fallback in vorbisBitrateOrder) {
      for (final SpotifyAudioFile file in files) {
        if (file.format == fallback) {
          return file;
        }
      }
    }

    // 3. Any Vorbis format
    for (final SpotifyAudioFile file in files) {
      if (file.format.isVorbis) {
        return file;
      }
    }

    // Strict rule: Never fall back to non-Vorbis formats (e.g. MP4/AAC or MP3 preview).
    // The Spotify head CDN returns 404 for non-Vorbis file IDs.
    return null;
  }

  /// 1:1 replica of Spotify's full track stream selection logic (`AudioFileSelection.proto` & `a1a.java`).
  ///
  /// Selects the primary audio stream candidate from the track's file list,
  /// defaulting to `MP4_128` (AAC) according to client settings.
  static SpotifyAudioFile? selectFullTrackFile(
    List<SpotifyAudioFile> trackFiles, {
    SpotifyAudioFormat preferredFormat = defaultFullTrackFormat,
  }) {
    if (trackFiles.isEmpty) {
      return null;
    }

    // 1. Exact preferred match (MP4_128)
    for (final SpotifyAudioFile file in trackFiles) {
      if (file.format == preferredFormat) {
        return file;
      }
    }

    // 2. Hierarchy fallback for MP4/AAC:
    const List<SpotifyAudioFormat> aacHierarchy = <SpotifyAudioFormat>[
      SpotifyAudioFormat.mp4256,
      SpotifyAudioFormat.mp4128Dual,
      SpotifyAudioFormat.mp4256Dual,
      SpotifyAudioFormat.mp4128Cbcs,
      SpotifyAudioFormat.mp4256Cbcs,
      SpotifyAudioFormat.aac48,
      SpotifyAudioFormat.aac24,
      SpotifyAudioFormat.oggVorbis320,
      SpotifyAudioFormat.oggVorbis160,
      SpotifyAudioFormat.oggVorbis96,
    ];

    for (final SpotifyAudioFormat fallback in aacHierarchy) {
      for (final SpotifyAudioFile file in trackFiles) {
        if (file.format == fallback) {
          return file;
        }
      }
    }

    // 3. First available file
    return trackFiles.firstOrNull;
  }
}
