// 1:1 replica of p199p/u450.java (lines 4–38),
// com/spotify/connect/esperanto/proto/ConnectMessages$StateResponse.java (StateResponse.Hifi),
// and protos/spotify/connect/devices.proto (CapabilitySupportDetails, lines 87–91).

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Connect device HiFi / lossless eligibility and support details matching
/// `p199p/u450.java`.
///
/// Named [ConnectHifiStatus] to avoid symbol collisions with
/// `com.spotify.player.model.HiFiStatus` in
/// `lib/features/player/domain/models/hifi_status.dart`.
@immutable
final class ConnectHifiStatus extends Equatable {
  /// Whether HiFi is fully supported by both user and device (`u450.f236854a`).
  final bool fullySupported;

  /// Whether the current user account is eligible for HiFi (`u450.f236855b`).
  final bool userEligible;

  /// Whether the target Connect device hardware supports HiFi (`u450.f236856c`).
  final bool deviceSupported;

  const ConnectHifiStatus({
    required this.fullySupported,
    required this.userEligible,
    required this.deviceSupported,
  });

  ConnectHifiStatus copyWith({
    bool? fullySupported,
    bool? userEligible,
    bool? deviceSupported,
  }) {
    return ConnectHifiStatus(
      fullySupported: switch (fullySupported) {
        final value? => value,
        null => this.fullySupported,
      },
      userEligible: switch (userEligible) {
        final value? => value,
        null => this.userEligible,
      },
      deviceSupported: switch (deviceSupported) {
        final value? => value,
        null => this.deviceSupported,
      },
    );
  }

  @override
  List<Object?> get props => [fullySupported, userEligible, deviceSupported];
}
