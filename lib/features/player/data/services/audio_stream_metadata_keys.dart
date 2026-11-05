// Preserved audio streaming, CDN, and DRM metadata keys used across private audio transport pipelines.

abstract final class AudioStreamMetadataKeys {
  static const String keyPreviewOggUrl = 'preview_ogg_url';
  static const String keyHeadFileUrl = 'head_file_url';
  static const String keyFileId = 'file_id';
  static const String keyAacFileId = 'aac_file_id';
  static const String keyCdnAacUrl = 'cdn_aac_url';
  static const String keyLicenseServerUrl = 'license_server_url';
  static const String keyDrmAuthHeader = 'drm_auth_header';
  static const String keyHandoffPositionMs = 'handoff_position_ms';
}

typedef TrackPlaybackMetadataKeys = AudioStreamMetadataKeys;
