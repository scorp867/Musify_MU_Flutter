import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_media_masking_strategy.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';

/// Concrete strategy projecting user-configured decoy persona metadata to public surfaces
/// (OS MediaSession, notification shade, lockscreen, Android Auto, and Bluetooth AVRCP).
///
/// Replaces sensitive title, artist, and album fields with [VaultConfig.decoyTitle],
/// [VaultConfig.decoyArtist], and [VaultConfig.decoyAlbum], while stripping artwork image URLs
/// to prevent shoulder-surfing and notification inspection.
class DecoyMediaMaskingStrategy implements IMediaMaskingStrategy {
  /// Default const constructor.
  const DecoyMediaMaskingStrategy();

  @override
  MetadataVisibilityPolicyEnum get policy =>
      MetadataVisibilityPolicyEnum.maskWithPlaceholder;

  @override
  Map<String, String> maskMetadata({
    required Map<String, String> originalMetadata,
    required VaultConfig config,
  }) {
    final sanitized = Map<String, String>.from(originalMetadata);

    sanitized[ContextTrackMetadata.keyTitle] = config.decoyTitle;
    sanitized[ContextTrackMetadata.keyArtistName] = config.decoyArtist;
    sanitized[ContextTrackMetadata.keyAlbumArtistName] = config.decoyArtist;
    sanitized[ContextTrackMetadata.keyAlbumTitle] = config.decoyAlbum;

    sanitized.remove(ContextTrackMetadata.keyImageUrl);
    sanitized.remove(ContextTrackMetadata.keyImageSmallUrl);
    sanitized.remove(ContextTrackMetadata.keyImageLargeUrl);
    sanitized.remove(ContextTrackMetadata.keyImageXlargeUrl);
    sanitized.remove(ContextTrackMetadata.keyThumbnailImageUrl);

    sanitized['musify_vault_masked'] = 'true';

    return Map<String, String>.unmodifiable(sanitized);
  }

  @override
  ContextTrack projectTrack({
    required ContextTrack originalTrack,
    required VaultConfig config,
  }) {
    return ContextTrack(
      uri: originalTrack.uri,
      uid: originalTrack.uid,
      metadata: maskMetadata(
        originalMetadata: originalTrack.metadata,
        config: config,
      ),
      provider: originalTrack.provider,
    );
  }
}
