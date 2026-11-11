import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Governs Android WindowManager.LayoutParams.FLAG_SECURE window state via lifecycle and route observers.
enum ScreenPrivacyStateEnum {
  /// Standard window flags; screenshots and screen recordings allowed on public screens.
  publicUnrestricted,

  /// Native FLAG_SECURE active on window; blocks screenshots, recording, and blacks out recent apps thumbnail.
  secureFlagEngaged,

  /// Awaiting native Kotlin MethodChannel confirmation of window flag mutation.
  platformSyncPending;

  /// Returns whether window privacy protection is actively engaged.
  bool get isFlagEngaged => this == ScreenPrivacyStateEnum.secureFlagEngaged;

  /// Returns whether a platform channel synchronization is in flight.
  bool get isSyncPending => this == ScreenPrivacyStateEnum.platformSyncPending;

  /// Returns whether screenshots and recents previews are allowed.
  bool get allowsScreenCapture => this == ScreenPrivacyStateEnum.publicUnrestricted;
}

/// Identifies the specific reason why native FLAG_SECURE window protection was engaged.
enum ScreenPrivacyEngageReasonEnum {
  /// User navigated to a dedicated vault screen (Dashboard, PlaylistDetail, Settings, Enrollment).
  vaultRouteActive,

  /// VaultAuthSheet modal bottom sheet is currently presented.
  authSheetPresented,

  /// ReauthBlurOverlay is actively displayed over public UI.
  reauthOverlayPresented,

  /// Application paused or moved to background while vault data is loaded in RAM.
  appBackgroundWithVaultLoaded,

  /// Global ScreenSecurityPolicyEnum.blockScreenshotsAndRecents policy is enforced.
  policyEnforced,
}

/// Deeply immutable sealed state hierarchy for David Harel Statechart Region C (Window Privacy Controller).
@immutable
sealed class ScreenPrivacyState extends Equatable {
  const ScreenPrivacyState();

  /// The active privacy state discriminator.
  ScreenPrivacyStateEnum get stateEnum;

  @override
  List<Object?> get props => [];
}

/// Public screens; window is unrestricted and screenshots are permitted.
@immutable
final class ScreenPrivacyPublicUnrestrictedState extends ScreenPrivacyState {
  const ScreenPrivacyPublicUnrestrictedState();

  @override
  ScreenPrivacyStateEnum get stateEnum => ScreenPrivacyStateEnum.publicUnrestricted;
}

/// Native FLAG_SECURE is engaged on the Android window.
@immutable
final class ScreenPrivacySecureFlagEngagedState extends ScreenPrivacyState {
  const ScreenPrivacySecureFlagEngagedState({
    required this.reason,
  });

  /// The specific architectural trigger that engaged window protection.
  final ScreenPrivacyEngageReasonEnum reason;

  @override
  ScreenPrivacyStateEnum get stateEnum => ScreenPrivacyStateEnum.secureFlagEngaged;

  @override
  List<Object?> get props => [reason];
}

/// MethodChannel mutation in flight to native platform.
@immutable
final class ScreenPrivacyPlatformSyncPendingState extends ScreenPrivacyState {
  const ScreenPrivacyPlatformSyncPendingState({
    required this.targetState,
    required this.requestedAtMonotonicMs,
  }) : assert(
          requestedAtMonotonicMs >= 0,
          'requestedAtMonotonicMs must be non-negative',
        );

  /// The intended target state once the platform acknowledges the mutation.
  final ScreenPrivacyStateEnum targetState;

  /// Timestamp in monotonic milliseconds when the platform call was dispatched.
  final int requestedAtMonotonicMs;

  @override
  ScreenPrivacyStateEnum get stateEnum => ScreenPrivacyStateEnum.platformSyncPending;

  @override
  List<Object?> get props => [targetState, requestedAtMonotonicMs];
}
