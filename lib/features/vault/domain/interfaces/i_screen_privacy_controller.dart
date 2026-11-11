import 'dart:async';

import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';

/// Pure abstract interface defining Android WindowManager.LayoutParams.FLAG_SECURE window
/// protection control (Harel Region C: Window Privacy Controller).
///
/// Encapsulates native platform communication to engage or release window screenshot,
/// screen recording, and recent-app thumbnail protection.
abstract interface class IScreenPrivacyController {
  /// Engages Android native `FLAG_SECURE` on the current window, blocking screenshots
  /// and blacking out recent-app thumbnails.
  Future<void> enableSecureFlag();

  /// Releases Android native `FLAG_SECURE` from the current window, restoring standard
  /// capture capabilities on public screens.
  Future<void> disableSecureFlag();

  /// Current synchronous [ScreenPrivacyStateEnum] value.
  ScreenPrivacyStateEnum get currentState;

  /// Reactive stream emitting [ScreenPrivacyStateEnum] transitions across route navigation
  /// and app lifecycle changes.
  Stream<ScreenPrivacyStateEnum> get stateStream;
}
