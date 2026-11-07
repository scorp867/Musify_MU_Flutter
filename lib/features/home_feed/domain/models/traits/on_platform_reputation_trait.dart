import 'package:flutter/foundation.dart';

import 'trait.dart';

/// ExtensionKind 185 (`ON_PLATFORM_REPUTATION_TRAIT`).
/// Equivalent to Spotify Android's `aip0`.
@immutable
final class OnPlatformReputationTrait extends Trait {
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
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnPlatformReputationTrait &&
        other.monthlyListeners == monthlyListeners &&
        other.totalPlays == totalPlays &&
        other.totalEstablishedUserRelationships ==
            totalEstablishedUserRelationships &&
        other.isVerified == isVerified &&
        other.isRegistered == isRegistered;
  }

  @override
  int get hashCode => Object.hash(
    monthlyListeners,
    totalPlays,
    totalEstablishedUserRelationships,
    isVerified,
    isRegistered,
  );
}
