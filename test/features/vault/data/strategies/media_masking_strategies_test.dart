import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/vault/data/strategies/decoy_media_masking_strategy.dart';
import 'package:musify_mu/features/vault/data/strategies/passthrough_media_masking_strategy.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';

void main() {
  group('DecoyMediaMaskingStrategy Unit Tests', () {
    const strategy = DecoyMediaMaskingStrategy();

    test('policy matches maskWithPlaceholder', () {
      expect(strategy.policy, MetadataVisibilityPolicyEnum.maskWithPlaceholder);
    });

    test('maskMetadata replaces sensitive display strings with config decoy persona', () {
      final config = VaultConfig(
        decoyTitle: 'Decoy Title X',
        decoyArtist: 'Decoy Artist Y',
        decoyAlbum: 'Decoy Album Z',
      );

      final originalMetadata = <String, String>{
        ContextTrackMetadata.keyTitle: 'Super Secret Song',
        ContextTrackMetadata.keyArtistName: 'Sensitive Artist',
        ContextTrackMetadata.keyAlbumArtistName: 'Sensitive Artist',
        ContextTrackMetadata.keyAlbumTitle: 'Private Confidential Album',
        ContextTrackMetadata.keyDuration: '240000',
        ContextTrackMetadata.keyIsLocal: 'true',
        ContextTrackMetadata.keyLocalFilePath:
            '/data/user/0/app/vault_media/.nomedia/track_1.mp3',
        ContextTrackMetadata.keyIsQueued: 'false',
        'is_vault_track': 'true',
        'vault_track_id': 'track_1',
      };

      final masked = strategy.maskMetadata(
        originalMetadata: originalMetadata,
        config: config,
      );

      expect(masked[ContextTrackMetadata.keyTitle], 'Decoy Title X');
      expect(masked[ContextTrackMetadata.keyArtistName], 'Decoy Artist Y');
      expect(masked[ContextTrackMetadata.keyAlbumArtistName], 'Decoy Artist Y');
      expect(masked[ContextTrackMetadata.keyAlbumTitle], 'Decoy Album Z');
      expect(masked[ContextTrackMetadata.keyDuration], '240000');
      expect(masked[ContextTrackMetadata.keyIsLocal], 'true');
      expect(
        masked[ContextTrackMetadata.keyLocalFilePath],
        '/data/user/0/app/vault_media/.nomedia/track_1.mp3',
      );
      expect(masked['is_vault_track'], 'true');
      expect(masked['vault_track_id'], 'track_1');
      expect(masked['musify_vault_masked'], 'true');
    });

    test('maskMetadata strips all artwork URLs to prevent shoulder surfing', () {
      final config = VaultConfig.constant();

      final originalMetadata = <String, String>{
        ContextTrackMetadata.keyTitle: 'Private Song',
        ContextTrackMetadata.keyImageUrl: 'https://example.com/art.jpg',
        ContextTrackMetadata.keyImageSmallUrl: 'https://example.com/art_sm.jpg',
        ContextTrackMetadata.keyImageLargeUrl: 'https://example.com/art_lg.jpg',
        ContextTrackMetadata.keyImageXlargeUrl: 'https://example.com/art_xl.jpg',
        ContextTrackMetadata.keyThumbnailImageUrl: 'https://example.com/thumb.jpg',
      };

      final masked = strategy.maskMetadata(
        originalMetadata: originalMetadata,
        config: config,
      );

      expect(masked.containsKey(ContextTrackMetadata.keyImageUrl), isFalse);
      expect(masked.containsKey(ContextTrackMetadata.keyImageSmallUrl), isFalse);
      expect(masked.containsKey(ContextTrackMetadata.keyImageLargeUrl), isFalse);
      expect(masked.containsKey(ContextTrackMetadata.keyImageXlargeUrl), isFalse);
      expect(masked.containsKey(ContextTrackMetadata.keyThumbnailImageUrl), isFalse);
    });

    test('maskMetadata returns an unmodifiable map', () {
      final config = VaultConfig.constant();
      final masked = strategy.maskMetadata(
        originalMetadata: const {'test': 'value'},
        config: config,
      );

      expect(() => masked['test'] = 'new_value', throwsUnsupportedError);
    });

    test('projectTrack creates a new sanitized ContextTrack preserving identity', () {
      final config = VaultConfig(
        decoyTitle: 'Masked Title',
        decoyArtist: 'Masked Artist',
        decoyAlbum: 'Masked Album',
      );

      const originalTrack = ContextTrack(
        uri: 'file:///vault/track_123.mp3',
        uid: 'vault_track_123',
        provider: 'musify_vault',
        metadata: {
          ContextTrackMetadata.keyTitle: 'Sensitive Melody',
          ContextTrackMetadata.keyArtistName: 'Secret Singer',
          ContextTrackMetadata.keyImageUrl: 'https://secret.com/art.png',
        },
      );

      final projected = strategy.projectTrack(
        originalTrack: originalTrack,
        config: config,
      );

      expect(projected.uri, originalTrack.uri);
      expect(projected.uid, originalTrack.uid);
      expect(projected.provider, originalTrack.provider);
      expect(projected.metadata[ContextTrackMetadata.keyTitle], 'Masked Title');
      expect(projected.metadata[ContextTrackMetadata.keyArtistName], 'Masked Artist');
      expect(projected.metadata[ContextTrackMetadata.keyAlbumTitle], 'Masked Album');
      expect(projected.metadata.containsKey(ContextTrackMetadata.keyImageUrl), isFalse);
      expect(projected.metadata['musify_vault_masked'], 'true');
    });
  });

  group('PassthroughMediaMaskingStrategy Unit Tests', () {
    const strategy = PassthroughMediaMaskingStrategy();

    test('policy matches showActualMetadata', () {
      expect(strategy.policy, MetadataVisibilityPolicyEnum.showActualMetadata);
    });

    test('maskMetadata retains all original metadata without modification', () {
      final config = VaultConfig.constant();

      final originalMetadata = <String, String>{
        ContextTrackMetadata.keyTitle: 'Real Title',
        ContextTrackMetadata.keyArtistName: 'Real Artist',
        ContextTrackMetadata.keyAlbumTitle: 'Real Album',
        ContextTrackMetadata.keyImageUrl: 'https://real.com/cover.jpg',
      };

      final masked = strategy.maskMetadata(
        originalMetadata: originalMetadata,
        config: config,
      );

      expect(masked[ContextTrackMetadata.keyTitle], 'Real Title');
      expect(masked[ContextTrackMetadata.keyArtistName], 'Real Artist');
      expect(masked[ContextTrackMetadata.keyAlbumTitle], 'Real Album');
      expect(masked[ContextTrackMetadata.keyImageUrl], 'https://real.com/cover.jpg');
      expect(masked.length, originalMetadata.length);
      expect(() => masked['key'] = 'val', throwsUnsupportedError);
    });

    test('projectTrack returns the original track instance directly', () {
      final config = VaultConfig.constant();
      const originalTrack = ContextTrack(
        uri: 'file:///real/track.mp3',
        uid: 'vault_999',
        provider: 'musify_vault',
        metadata: {'title': 'Real'},
      );

      final projected = strategy.projectTrack(
        originalTrack: originalTrack,
        config: config,
      );

      expect(identical(projected, originalTrack), isTrue);
    });
  });
}
