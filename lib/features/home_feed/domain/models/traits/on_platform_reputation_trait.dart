import 'trait.dart';

/// ExtensionKind 185 (ON_PLATFORM_REPUTATION_TRAIT).
/// Equivalent to Spotify Android's `aip0`.
class OnPlatformReputationTrait extends Trait {
  final int monthlyListeners;
  final int totalPlays;
  final int totalEstablishedUserRelationships;
  final bool isVerified;
  final bool isRegistered;

  const OnPlatformReputationTrait({
    this.monthlyListeners = 0,
    this.totalPlays = 0,
    this.totalEstablishedUserRelationships = 0,
    this.isVerified = false,
    this.isRegistered = false,
  });

  @override
  Map<String, dynamic> toJson() => {
    'monthlyListeners': monthlyListeners,
    'totalPlays': totalPlays,
    'totalEstablishedUserRelationships': totalEstablishedUserRelationships,
    'isVerified': isVerified,
    'isRegistered': isRegistered,
  };

  factory OnPlatformReputationTrait.fromJson(Map<String, dynamic> json) =>
      OnPlatformReputationTrait(
        monthlyListeners: json['monthlyListeners'] as int? ?? 0,
        totalPlays: json['totalPlays'] as int? ?? 0,
        totalEstablishedUserRelationships:
            json['totalEstablishedUserRelationships'] as int? ?? 0,
        isVerified: json['isVerified'] as bool? ?? false,
        isRegistered: json['isRegistered'] as bool? ?? false,
      );
}
