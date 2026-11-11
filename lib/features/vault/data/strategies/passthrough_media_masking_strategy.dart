import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_media_masking_strategy.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';

/// Concrete strategy projecting original decrypted metadata to public surfaces
/// when [MetadataVisibilityPolicyEnum.showActualMetadata] is active.
///
/// Emits unmasked title, artist, album, and artwork to the OS MediaSession
/// and connected Bluetooth accessories during an authorized vault session.
class PassthroughMediaMaskingStrategy implements IMediaMaskingStrategy {
  /// Default const constructor.
  const PassthroughMediaMaskingStrategy();

  @override
  MetadataVisibilityPolicyEnum get policy =>
      MetadataVisibilityPolicyEnum.showActualMetadata;

  @override
  Map<String, String> maskMetadata({
    required Map<String, String> originalMetadata,
    required VaultConfig config,
  }) {
    return Map<String, String>.unmodifiable(originalMetadata);
  }

  @override
  ContextTrack projectTrack({
    required ContextTrack originalTrack,
    required VaultConfig config,
  }) {
    return originalTrack;
  }
}
