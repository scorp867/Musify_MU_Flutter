import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musify_mu/features/vault/application/gesture/gesture_engine_cubit.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/data/services/playback_privacy_proxy.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/policies/screen_security_policy.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';

/// Navigation request targets emitted by [VaultCoordinator].
enum VaultNavigationTarget {
  /// Navigate to dedicated full-screen authentication pad.
  unlockScreen,

  /// Navigate to private vault playlists dashboard.
  dashboardScreen,

  /// Re-authentication frosted glass overlay requested.
  reauthOverlay,
}

/// Central orchestrator coordinating David Harel's Statechart 4 concurrent orthogonal regions:
/// - Region A: [VaultSessionBloc]
/// - Region B: [PlaybackPrivacyProxy]
/// - Region C: [ScreenPrivacyCubit]
/// - Region D: [GestureEngineCubit]
/// - Sub-Service 5: [SettingsMutationCubit]
/// - Sub-Service 6: [PinPadCubit]
class VaultCoordinator {
  final VaultSessionBloc _sessionBloc;
  final PlaybackPrivacyProxy _playbackPrivacyProxy;
  final ScreenPrivacyCubit _screenPrivacyCubit;
  final GestureEngineCubit _gestureEngineCubit;
  final SettingsMutationCubit _settingsMutationCubit;
  final PinPadCubit _pinPadCubit;
  final IMonotonicClock _monotonicClock;

  final StreamController<VaultNavigationTarget> _navigationController;
  final List<StreamSubscription<Object?>> _subscriptions;

  bool _isDisposed = false;

  VaultCoordinator({
    required VaultSessionBloc sessionBloc,
    required PlaybackPrivacyProxy playbackPrivacyProxy,
    required ScreenPrivacyCubit screenPrivacyCubit,
    required GestureEngineCubit gestureEngineCubit,
    required SettingsMutationCubit settingsMutationCubit,
    required PinPadCubit pinPadCubit,
    required IMonotonicClock monotonicClock,
  })  : _sessionBloc = sessionBloc,
        _playbackPrivacyProxy = playbackPrivacyProxy,
        _screenPrivacyCubit = screenPrivacyCubit,
        _gestureEngineCubit = gestureEngineCubit,
        _settingsMutationCubit = settingsMutationCubit,
        _pinPadCubit = pinPadCubit,
        _monotonicClock = monotonicClock,
        _navigationController = StreamController<VaultNavigationTarget>.broadcast(),
        _subscriptions = <StreamSubscription<Object?>>[];

  /// Stream of reactive navigation directives.
  Stream<VaultNavigationTarget> get navigationStream =>
      _navigationController.stream;

  /// Whether the coordinator has been disposed.
  bool get isDisposed => _isDisposed;

  /// Initializes cross-subsystem stream bindings and event listeners.
  void initialize() {
    if (_isDisposed) return;

    // 1. Listen to Region A session state transitions
    _subscriptions.add(
      _sessionBloc.stream.listen(
        _handleSessionStateChange,
        onError: _handleError,
      ),
    );

    // 2. Listen to Region D verified gesture matches
    _subscriptions.add(
      _gestureEngineCubit.matchConfirmedStream.listen(
        (_) => _handleStealthGestureMatched(),
        onError: _handleError,
      ),
    );

    // 3. Listen to Sub-Service 5 configuration mutations
    _subscriptions.add(
      _settingsMutationCubit.configStream.listen(
        _applyUpdatedConfig,
        onError: _handleError,
      ),
    );
  }

  /// Callback executed when single-stroke gesture matches on StealthGesturePad.
  void onStealthGestureTriggered([BuildContext? context]) {
    _handleStealthGestureMatched();
  }

  void _handleStealthGestureMatched() {
    if (_isDisposed) return;
    HapticFeedback.mediumImpact();

    final sessionState = _sessionBloc.state;
    switch (sessionState) {
      case VaultUninitializedState():
      case VaultProvisioningState():
      case VaultLockedState():
      case VaultLockoutCooldownState():
      case VaultAuthenticatingState():
        _navigationController.add(VaultNavigationTarget.unlockScreen);
      case VaultActiveSessionState():
        _navigationController.add(VaultNavigationTarget.dashboardScreen);
    }
  }

  /// Forwards OS application lifecycle state transitions.
  void onAppLifecycleStateChanged(AppLifecycleState state) {
    if (_isDisposed) return;

    final monotonicNowMs = _monotonicClock.currentMonotonicMs;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _sessionBloc.add(
          VaultAppBackgrounded(pausedAtMonotonicMs: monotonicNowMs),
        );
        final config = _settingsMutationCubit.currentConfig;
        if (config.screenSecurity ==
            ScreenSecurityPolicyEnum.blockScreenshotsAndRecents) {
          _screenPrivacyCubit.engageSecureFlag(
            reason: ScreenPrivacyEngageReasonEnum.appBackgroundWithVaultLoaded,
          );
        }

      case AppLifecycleState.resumed:
        _sessionBloc.add(
          VaultAppForegrounded(resumedAtMonotonicMs: monotonicNowMs),
        );
        final config = _settingsMutationCubit.currentConfig;
        if (config.screenSecurity == ScreenSecurityPolicyEnum.allowCapture &&
            _sessionBloc.state is! VaultActiveSessionState) {
          _screenPrivacyCubit.releaseSecureFlag(
            reason: ScreenPrivacyEngageReasonEnum.appBackgroundWithVaultLoaded,
          );
        }

      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _sessionBloc.add(
          const VaultQuickLockRequested(reason: 'App detached/hidden'),
        );
    }
  }

  /// Manually triggers quick-lock across all regions.
  void requestQuickLock() {
    _sessionBloc.add(
      const VaultQuickLockRequested(reason: 'User manual quick-lock'),
    );
    _pinPadCubit.resetToIdle();
  }

  void _handleSessionStateChange(VaultSessionState state) {
    if (_isDisposed) return;

    switch (state) {
      case VaultUninitializedState():
      case VaultProvisioningState():
      case VaultLockedState():
        _pinPadCubit.resetToIdle();

      case VaultUnlockedState():
        break;

      case VaultBackgroundGraceState():
        break;

      case VaultPendingReauthState():
        _navigationController.add(VaultNavigationTarget.reauthOverlay);

      case VaultLockoutCooldownState(:final deadlineMonotonicMs):
        _pinPadCubit.enterLockout(deadlineMonotonicMs: deadlineMonotonicMs);

      case VaultAuthenticatingState():
        break;
    }
  }

  void _applyUpdatedConfig(VaultConfig config) {
    // 1. Update Region B PlaybackPrivacyProxy
    _playbackPrivacyProxy.updateConfig(config);

    // 2. Update Region C ScreenPrivacyCubit
    _screenPrivacyCubit.updateSecurityPolicy(config.screenSecurity);

    // 3. Update Region D GestureEngineCubit
    _gestureEngineCubit.updateSensitivityTier(config.gestureSensitivity);

    // 4. Update Region A VaultSessionBloc
    _sessionBloc.add(VaultConfigUpdated(config: config));
  }

  void _handleError(Object error, StackTrace stack) {
    dev.log(
      'VaultCoordinator stream error: $error',
      name: 'VaultCoordinator',
      error: error,
      stackTrace: stack,
    );
    if (!_navigationController.isClosed) {
      _navigationController.addError(error, stack);
    }
  }

  /// Cancels all cross-subsystem stream subscriptions and closes stream controllers.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    await _navigationController.close();
  }
}
