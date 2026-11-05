import 'package:flutter/foundation.dart';

/// Private data-layer model encapsulating low-level stream transport details
/// (file IDs, CDN URLs, DRM licenses) away from Spotify's canonical domain models.
@immutable
class TrackStreamInfo {
  final String? fileId;
  final String? aacFileId;
  final String? headUrl;
  final String? cdnUrl;
  final String? licenseServerUrl;
  final String? drmAuthHeader;
  final int? handoffPositionMs;
  final String? previewOggUrl;
  final String? localPath;

  const TrackStreamInfo({
    this.fileId,
    this.aacFileId,
    this.headUrl,
    this.cdnUrl,
    this.licenseServerUrl,
    this.drmAuthHeader,
    this.handoffPositionMs,
    this.previewOggUrl,
    this.localPath,
  });

  TrackStreamInfo copyWith({
    String? fileId,
    String? aacFileId,
    String? headUrl,
    String? cdnUrl,
    String? licenseServerUrl,
    String? drmAuthHeader,
    int? handoffPositionMs,
    String? previewOggUrl,
    String? localPath,
  }) {
    return TrackStreamInfo(
      fileId: switch (fileId) {
        final val? => val,
        _ => this.fileId,
      },
      aacFileId: switch (aacFileId) {
        final val? => val,
        _ => this.aacFileId,
      },
      headUrl: switch (headUrl) {
        final val? => val,
        _ => this.headUrl,
      },
      cdnUrl: switch (cdnUrl) {
        final val? => val,
        _ => this.cdnUrl,
      },
      licenseServerUrl: switch (licenseServerUrl) {
        final val? => val,
        _ => this.licenseServerUrl,
      },
      drmAuthHeader: switch (drmAuthHeader) {
        final val? => val,
        _ => this.drmAuthHeader,
      },
      handoffPositionMs: switch (handoffPositionMs) {
        final val? => val,
        _ => this.handoffPositionMs,
      },
      previewOggUrl: switch (previewOggUrl) {
        final val? => val,
        _ => this.previewOggUrl,
      },
      localPath: switch (localPath) {
        final val? => val,
        _ => this.localPath,
      },
    );
  }

  TrackStreamInfo mergeWith(TrackStreamInfo other) {
    return TrackStreamInfo(
      fileId: switch (other.fileId) {
        final val? => val,
        _ => fileId,
      },
      aacFileId: switch (other.aacFileId) {
        final val? => val,
        _ => aacFileId,
      },
      headUrl: switch (other.headUrl) {
        final val? => val,
        _ => headUrl,
      },
      cdnUrl: switch (other.cdnUrl) {
        final val? => val,
        _ => cdnUrl,
      },
      licenseServerUrl: switch (other.licenseServerUrl) {
        final val? => val,
        _ => licenseServerUrl,
      },
      drmAuthHeader: switch (other.drmAuthHeader) {
        final val? => val,
        _ => drmAuthHeader,
      },
      handoffPositionMs: switch (other.handoffPositionMs) {
        final val? => val,
        _ => handoffPositionMs,
      },
      previewOggUrl: switch (other.previewOggUrl) {
        final val? => val,
        _ => previewOggUrl,
      },
      localPath: switch (other.localPath) {
        final val? => val,
        _ => localPath,
      },
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackStreamInfo &&
          other.fileId == fileId &&
          other.aacFileId == aacFileId &&
          other.headUrl == headUrl &&
          other.cdnUrl == cdnUrl &&
          other.licenseServerUrl == licenseServerUrl &&
          other.drmAuthHeader == drmAuthHeader &&
          other.handoffPositionMs == handoffPositionMs &&
          other.previewOggUrl == previewOggUrl &&
          other.localPath == localPath);

  @override
  int get hashCode => Object.hash(
        fileId,
        aacFileId,
        headUrl,
        cdnUrl,
        licenseServerUrl,
        drmAuthHeader,
        handoffPositionMs,
        previewOggUrl,
        localPath,
      );
}

/// Private registry for internal audio stream transport information.
/// Decouples raw streaming URLs, file IDs, and DRM headers from Spotify's
/// canonical domain models (ContextTrack, ContextPage, Queue).
class SpotifyAudioStreamRegistry {
  SpotifyAudioStreamRegistry._();
  static final SpotifyAudioStreamRegistry instance = SpotifyAudioStreamRegistry._();

  final Map<String, TrackStreamInfo> _cache = <String, TrackStreamInfo>{};

  void register(String uri, TrackStreamInfo info) {
    if (uri.isEmpty) return;
    final existing = _cache[uri];
    if (existing != null) {
      _cache[uri] = existing.mergeWith(info);
    } else {
      _cache[uri] = info;
    }
  }

  TrackStreamInfo? get(String uri) {
    if (uri.isEmpty) return null;
    return _cache[uri];
  }

  void updateSecondaryStream(
    String uri, {
    required String cdnUrl,
    String? licenseServerUrl,
    String? drmAuthHeader,
  }) {
    if (uri.isEmpty) return;
    final existing = _cache[uri];
    if (existing != null) {
      _cache[uri] = existing.copyWith(
        cdnUrl: cdnUrl,
        licenseServerUrl: licenseServerUrl,
        drmAuthHeader: drmAuthHeader,
      );
    } else {
      _cache[uri] = TrackStreamInfo(
        cdnUrl: cdnUrl,
        licenseServerUrl: licenseServerUrl,
        drmAuthHeader: drmAuthHeader,
      );
    }
  }

  void clear() {
    _cache.clear();
  }
}
