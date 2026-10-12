import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/on_platform_reputation_trait.pb.dart'
    as oprt;
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Plugin for ExtensionKind 185 (ON_PLATFORM_REPUTATION_TRAIT).
/// Equivalent to Spotify Android's `aip0` decoder plugin.
class OnPlatformReputationTraitPlugin
    implements ExtendedMetadataPlugin<OnPlatformReputationTrait> {
  const OnPlatformReputationTraitPlugin();

  @override
  Type get traitType => OnPlatformReputationTrait;

  @override
  int get extensionKindValue => 185;

  @override
  ExtensionKind? get extensionKind =>
      ExtensionKind.ON_PLATFORM_REPUTATION_TRAIT;

  @override
  OnPlatformReputationTrait parse(Uint8List payload) {
    final trait = oprt.OnPlatformReputationTrait.fromBuffer(payload);
    return OnPlatformReputationTrait(
      monthlyListeners: trait.monthlyListeners.toInt(),
      totalPlays: trait.totalPlays.toInt(),
      totalEstablishedUserRelationships:
          trait.totalEstablishedUserRelationships.toInt(),
      isVerified:
          trait.hasVerification() ? trait.verification.isVerified : false,
      isRegistered:
          trait.hasVerification() ? trait.verification.isRegistered : false,
    );
  }
}
