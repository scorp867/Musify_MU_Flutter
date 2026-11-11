import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_screen_privacy_controller.dart';
import 'package:musify_mu/features/vault/domain/policies/screen_security_policy.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';

/// David Harel Statechart Region C Window Privacy Controller.
///
/// Coordinates native Android WindowManager.LayoutParams.FLAG_SECURE application
/// across active vault routes, modal authentication screens, re-auth overlays,
/// and background transitions, honoring user ScreenSecurityPolicyEnum.
class ScreenPrivacyCubit extends Cubit<ScreenPrivacyState> {
  final IScreenPrivacyController _privacyController;
  final IMonotonicClock _monotonicClock;
  ScreenSecurityPolicyEnum _securityPolicy;

  /// Multi-reason reference registry ensuring safe flag management without race conditions.
  final Set<ScreenPrivacyEngageReasonEnum> _activeReasons;

  /// Serialized FIFO execution chain preventing out-of-order platform channel calls.
  Future<void>? _pendingOperation;

  ScreenPrivacyCubit({
    required IScreenPrivacyController privacyController,
    required IMonotonicClock monotonicClock,
    ScreenSecurityPolicyEnum initialPolicy = ScreenSecurityPolicyEnum.blockScreenshotsAndRecents,
    ScreenPrivacyState initialState = const ScreenPrivacyPublicUnrestrictedState(),
  })  : _privacyController = privacyController,
        _monotonicClock = monotonicClock,
        _securityPolicy = initialPolicy,
        _activeReasons = <ScreenPrivacyEngageReasonEnum>{},
        super(initialState);

  /// Active set of security reasons currently holding FLAG_SECURE protection.
  Set<ScreenPrivacyEngageReasonEnum> get activeReasons => Set.unmodifiable(_activeReasons);

  /// Current active screen security policy.
  ScreenSecurityPolicyEnum get securityPolicy => _securityPolicy;

  /// Synchronous boolean indicator of engaged protection.
  bool get isSecureFlagEngaged => state is ScreenPrivacySecureFlagEngagedState;

  Future<void> _enqueueOperation(Future<void> Function() action) {
    final prev = _pendingOperation;
    final completer = Completer<void>();
    _pendingOperation = completer.future;

    void run() async {
      try {
        await action();
        completer.complete();
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        if (_pendingOperation == completer.future) {
          _pendingOperation = null;
        }
      }
    }

    if (prev == null) {
      run();
    } else {
      prev.whenComplete(run);
    }

    return completer.future;
  }

  /// Engages native FLAG_SECURE for the specified [reason].
  Future<void> engageSecureFlag({required ScreenPrivacyEngageReasonEnum reason}) {
    if (isClosed) return Future<void>.value();
    _activeReasons.add(reason);

    return _enqueueOperation(() async {
      if (isClosed) return;

      if (!_securityPolicy.requiresSecureFlag) {
        if (state is! ScreenPrivacyPublicUnrestrictedState) {
          if (!isClosed) emit(const ScreenPrivacyPublicUnrestrictedState());
        }
        return;
      }

      if (state is ScreenPrivacySecureFlagEngagedState &&
          (state as ScreenPrivacySecureFlagEngagedState).reason == reason) {
        return;
      }

      final requestedAtMs = _monotonicClock.currentMonotonicMs;
      if (!isClosed) {
        emit(
          ScreenPrivacyPlatformSyncPendingState(
            targetState: ScreenPrivacyStateEnum.secureFlagEngaged,
            requestedAtMonotonicMs: requestedAtMs,
          ),
        );
      }

      try {
        await _privacyController.enableSecureFlag();
        if (!isClosed) {
          emit(ScreenPrivacySecureFlagEngagedState(reason: reason));
        }
      } catch (e, st) {
        dev.log(
          'Failed to engage FLAG_SECURE on platform: $e',
          name: 'ScreenPrivacyCubit',
          error: e,
          stackTrace: st,
        );
        if (!isClosed) {
          emit(const ScreenPrivacyPublicUnrestrictedState());
        }
      }
    });
  }

  /// Releases native FLAG_SECURE for the specified [reason].
  Future<void> releaseSecureFlag({required ScreenPrivacyEngageReasonEnum reason}) {
    if (isClosed) return Future<void>.value();
    _activeReasons.remove(reason);

    return _enqueueOperation(() async {
      if (isClosed) return;

      if (_activeReasons.isNotEmpty && _securityPolicy.requiresSecureFlag) {
        final remainingReason = _activeReasons.first;
        if (state is! ScreenPrivacySecureFlagEngagedState ||
            (state as ScreenPrivacySecureFlagEngagedState).reason != remainingReason) {
          if (!isClosed) {
            emit(ScreenPrivacySecureFlagEngagedState(reason: remainingReason));
          }
        }
        return;
      }

      if (state is ScreenPrivacyPublicUnrestrictedState) {
        return;
      }

      final requestedAtMs = _monotonicClock.currentMonotonicMs;
      if (!isClosed) {
        emit(
          ScreenPrivacyPlatformSyncPendingState(
            targetState: ScreenPrivacyStateEnum.publicUnrestricted,
            requestedAtMonotonicMs: requestedAtMs,
          ),
        );
      }

      try {
        await _privacyController.disableSecureFlag();
        if (!isClosed) {
          emit(const ScreenPrivacyPublicUnrestrictedState());
        }
      } catch (e, st) {
        dev.log(
          'Failed to release FLAG_SECURE on platform: $e',
          name: 'ScreenPrivacyCubit',
          error: e,
          stackTrace: st,
        );
        if (!isClosed) {
          emit(const ScreenPrivacyPublicUnrestrictedState());
        }
      }
    });
  }

  /// Updates the user's screen security preference dynamically at runtime.
  Future<void> updateSecurityPolicy(ScreenSecurityPolicyEnum newPolicy) {
    if (isClosed) return Future<void>.value();
    _securityPolicy = newPolicy;

    if (!newPolicy.requiresSecureFlag) {
      if (state is ScreenPrivacyPublicUnrestrictedState) {
        return Future<void>.value();
      }
      return _enqueueOperation(() async {
        if (isClosed || state is ScreenPrivacyPublicUnrestrictedState) return;
        final requestedAtMs = _monotonicClock.currentMonotonicMs;
        emit(
          ScreenPrivacyPlatformSyncPendingState(
            targetState: ScreenPrivacyStateEnum.publicUnrestricted,
            requestedAtMonotonicMs: requestedAtMs,
          ),
        );
        try {
          await _privacyController.disableSecureFlag();
        } catch (e, st) {
          dev.log(
            'Failed to release FLAG_SECURE on platform during policy update: $e',
            name: 'ScreenPrivacyCubit',
            error: e,
            stackTrace: st,
          );
        }
        if (!isClosed) {
          emit(const ScreenPrivacyPublicUnrestrictedState());
        }
      });
    } else {
      if (_activeReasons.isEmpty || state is ScreenPrivacySecureFlagEngagedState) {
        return Future<void>.value();
      }
      final reason = _activeReasons.first;
      return _enqueueOperation(() async {
        if (isClosed || _activeReasons.isEmpty || state is ScreenPrivacySecureFlagEngagedState) return;
        final requestedAtMs = _monotonicClock.currentMonotonicMs;
        emit(
          ScreenPrivacyPlatformSyncPendingState(
            targetState: ScreenPrivacyStateEnum.secureFlagEngaged,
            requestedAtMonotonicMs: requestedAtMs,
          ),
        );
        try {
          await _privacyController.enableSecureFlag();
          if (!isClosed) {
            emit(ScreenPrivacySecureFlagEngagedState(reason: reason));
          }
        } catch (e, st) {
          dev.log(
            'Failed to engage FLAG_SECURE on platform during policy update: $e',
            name: 'ScreenPrivacyCubit',
            error: e,
            stackTrace: st,
          );
          if (!isClosed) {
            emit(const ScreenPrivacyPublicUnrestrictedState());
          }
        }
      });
    }
  }

  /// Alias for [updateSecurityPolicy] for coordinator integration.
  Future<void> updatePolicy(ScreenSecurityPolicyEnum newPolicy) =>
      updateSecurityPolicy(newPolicy);

  Future<void> onVaultRoutePushed() =>
      engageSecureFlag(reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive);

  Future<void> onVaultRoutePopped() =>
      releaseSecureFlag(reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive);

  Future<void> onAuthSheetPresented() =>
      engageSecureFlag(reason: ScreenPrivacyEngageReasonEnum.authSheetPresented);

  Future<void> onAuthSheetDismissed() =>
      releaseSecureFlag(reason: ScreenPrivacyEngageReasonEnum.authSheetPresented);

  Future<void> onReauthOverlayPresented() =>
      engageSecureFlag(reason: ScreenPrivacyEngageReasonEnum.reauthOverlayPresented);

  Future<void> onReauthOverlayDismissed() =>
      releaseSecureFlag(reason: ScreenPrivacyEngageReasonEnum.reauthOverlayPresented);

  Future<void> onAppPaused({required bool hasVaultDataLoaded}) async {
    if (hasVaultDataLoaded) {
      await engageSecureFlag(reason: ScreenPrivacyEngageReasonEnum.appBackgroundWithVaultLoaded);
    }
  }

  Future<void> onAppResumed() =>
      releaseSecureFlag(reason: ScreenPrivacyEngageReasonEnum.appBackgroundWithVaultLoaded);
}

/// Navigator observer listening to route navigation to engage and release FLAG_SECURE.
class VaultRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final ScreenPrivacyCubit _privacyCubit;

  /// Known path prefixes or route names designating dedicated vault screens.
  static const Set<String> vaultRouteNames = {
    '/vault',
    '/vault/dashboard',
    '/vault/playlist',
    '/vault/settings',
    '/vault/enrollment',
    '/vault/auth',
  };

  VaultRouteObserver({
    required ScreenPrivacyCubit privacyCubit,
  }) : _privacyCubit = privacyCubit;

  bool _isVaultRoute(Route<dynamic>? route) {
    if (route is PageRoute) {
      final name = route.settings.name;
      if (name != null) {
        return vaultRouteNames.contains(name) || name.startsWith('/vault');
      }
    }
    return false;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (_isVaultRoute(route)) {
      _privacyCubit.onVaultRoutePushed();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (_isVaultRoute(route)) {
      _privacyCubit.onVaultRoutePopped();
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (_isVaultRoute(oldRoute) && !_isVaultRoute(newRoute)) {
      _privacyCubit.onVaultRoutePopped();
    } else if (!_isVaultRoute(oldRoute) && _isVaultRoute(newRoute)) {
      _privacyCubit.onVaultRoutePushed();
    }
  }
}
