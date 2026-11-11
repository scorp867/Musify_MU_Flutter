import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_screen_privacy_controller.dart';
import 'package:musify_mu/features/vault/domain/policies/screen_security_policy.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';

class FakeMonotonicClock implements IMonotonicClock {
  int timeMs = 1000;

  @override
  int get currentMonotonicMs => timeMs;

  @override
  int get elapsedMilliseconds => timeMs;

  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class FakeScreenPrivacyController implements IScreenPrivacyController {
  ScreenPrivacyStateEnum _state = ScreenPrivacyStateEnum.publicUnrestricted;
  final StreamController<ScreenPrivacyStateEnum> _streamController =
      StreamController<ScreenPrivacyStateEnum>.broadcast();

  int enableCallCount = 0;
  int disableCallCount = 0;
  bool shouldThrowOnEnable = false;
  bool shouldThrowOnDisable = false;

  @override
  ScreenPrivacyStateEnum get currentState => _state;

  @override
  Stream<ScreenPrivacyStateEnum> get stateStream => _streamController.stream;

  @override
  Future<void> enableSecureFlag() async {
    enableCallCount++;
    if (shouldThrowOnEnable) {
      throw Exception('Platform MethodChannel failure on enableSecureFlag');
    }
    _state = ScreenPrivacyStateEnum.secureFlagEngaged;
    _streamController.add(_state);
  }

  @override
  Future<void> disableSecureFlag() async {
    disableCallCount++;
    if (shouldThrowOnDisable) {
      throw Exception('Platform MethodChannel failure on disableSecureFlag');
    }
    _state = ScreenPrivacyStateEnum.publicUnrestricted;
    _streamController.add(_state);
  }
}

void main() {
  late FakeScreenPrivacyController fakeController;
  late FakeMonotonicClock fakeClock;
  late ScreenPrivacyCubit cubit;

  setUp(() {
    fakeController = FakeScreenPrivacyController();
    fakeClock = FakeMonotonicClock();
    cubit = ScreenPrivacyCubit(
      privacyController: fakeController,
      monotonicClock: fakeClock,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  group('ScreenPrivacyCubit Lifecycle & Invariants', () {
    test('initial state is ScreenPrivacyPublicUnrestrictedState with zero active reasons', () {
      expect(cubit.state, isA<ScreenPrivacyPublicUnrestrictedState>());
      expect(cubit.activeReasons.isEmpty, isTrue);
      expect(cubit.isSecureFlagEngaged, isFalse);
    });

    test('engageSecureFlag engages FLAG_SECURE and records reason', () async {
      await cubit.engageSecureFlag(
        reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
      );

      expect(cubit.state, isA<ScreenPrivacySecureFlagEngagedState>());
      final engaged = cubit.state as ScreenPrivacySecureFlagEngagedState;
      expect(engaged.reason, equals(ScreenPrivacyEngageReasonEnum.vaultRouteActive));
      expect(cubit.activeReasons.contains(ScreenPrivacyEngageReasonEnum.vaultRouteActive), isTrue);
      expect(fakeController.enableCallCount, equals(1));
    });

    test('multi-reason reference registry prevents premature flag release', () async {
      // Reason 1: vault route
      await cubit.engageSecureFlag(
        reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
      );

      // Reason 2: reauth overlay
      await cubit.engageSecureFlag(
        reason: ScreenPrivacyEngageReasonEnum.reauthOverlayPresented,
      );

      expect(cubit.activeReasons.length, equals(2));

      // Release Reason 1: Reason 2 is still active!
      await cubit.releaseSecureFlag(
        reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
      );

      expect(cubit.state, isA<ScreenPrivacySecureFlagEngagedState>());
      expect(cubit.activeReasons.length, equals(1));
      expect(cubit.activeReasons.first, equals(ScreenPrivacyEngageReasonEnum.reauthOverlayPresented));
      expect(fakeController.disableCallCount, equals(0)); // Still engaged!

      // Release Reason 2: now empty, flag is released
      await cubit.releaseSecureFlag(
        reason: ScreenPrivacyEngageReasonEnum.reauthOverlayPresented,
      );

      expect(cubit.state, isA<ScreenPrivacyPublicUnrestrictedState>());
      expect(cubit.activeReasons.isEmpty, isTrue);
      expect(fakeController.disableCallCount, equals(1));
    });
  });

  group('Policy Dynamism (allowCapture vs blockScreenshotsAndRecents)', () {
    test('when policy is allowCapture, engageSecureFlag does not engage platform flag', () async {
      final allowCaptureCubit = ScreenPrivacyCubit(
        privacyController: fakeController,
        monotonicClock: fakeClock,
        initialPolicy: ScreenSecurityPolicyEnum.allowCapture,
      );

      await allowCaptureCubit.engageSecureFlag(
        reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
      );

      expect(allowCaptureCubit.state, isA<ScreenPrivacyPublicUnrestrictedState>());
      expect(fakeController.enableCallCount, equals(0));
      expect(allowCaptureCubit.activeReasons.contains(ScreenPrivacyEngageReasonEnum.vaultRouteActive), isTrue);

      await allowCaptureCubit.close();
    });

    test('updateSecurityPolicy toggling to allowCapture releases active flag', () async {
      await cubit.engageSecureFlag(
        reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
      );
      expect(cubit.state, isA<ScreenPrivacySecureFlagEngagedState>());

      await cubit.updateSecurityPolicy(ScreenSecurityPolicyEnum.allowCapture);

      expect(cubit.state, isA<ScreenPrivacyPublicUnrestrictedState>());
      expect(fakeController.disableCallCount, equals(1));
    });

    test('updateSecurityPolicy toggling to blockScreenshots re-engages flag if reasons active', () async {
      final allowCaptureCubit = ScreenPrivacyCubit(
        privacyController: fakeController,
        monotonicClock: fakeClock,
        initialPolicy: ScreenSecurityPolicyEnum.allowCapture,
      );

      await allowCaptureCubit.engageSecureFlag(
        reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
      );

      await allowCaptureCubit.updateSecurityPolicy(
        ScreenSecurityPolicyEnum.blockScreenshotsAndRecents,
      );

      expect(allowCaptureCubit.state, isA<ScreenPrivacySecureFlagEngagedState>());
      expect(fakeController.enableCallCount, equals(1));

      await allowCaptureCubit.close();
    });
  });

  group('Platform Failure Fault Tolerance', () {
    test('catches platform error on enableSecureFlag and safely falls back to unrestricted', () async {
      fakeController.shouldThrowOnEnable = true;

      await cubit.engageSecureFlag(
        reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
      );

      expect(cubit.state, isA<ScreenPrivacyPublicUnrestrictedState>());
    });

    test('catches platform error on disableSecureFlag and safely falls back to unrestricted', () async {
      await cubit.engageSecureFlag(
        reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
      );

      fakeController.shouldThrowOnDisable = true;

      await cubit.releaseSecureFlag(
        reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
      );

      expect(cubit.state, isA<ScreenPrivacyPublicUnrestrictedState>());
    });
  });

  group('Lifecycle Hooks & VaultRouteObserver', () {
    test('lifecycle hooks engage and release expected reasons', () async {
      await cubit.onVaultRoutePushed();
      expect(cubit.activeReasons.contains(ScreenPrivacyEngageReasonEnum.vaultRouteActive), isTrue);
      await cubit.onVaultRoutePopped();
      expect(cubit.activeReasons.isEmpty, isTrue);

      await cubit.onAuthSheetPresented();
      expect(cubit.activeReasons.contains(ScreenPrivacyEngageReasonEnum.authSheetPresented), isTrue);
      await cubit.onAuthSheetDismissed();
      expect(cubit.activeReasons.isEmpty, isTrue);

      await cubit.onReauthOverlayPresented();
      expect(cubit.activeReasons.contains(ScreenPrivacyEngageReasonEnum.reauthOverlayPresented), isTrue);
      await cubit.onReauthOverlayDismissed();
      expect(cubit.activeReasons.isEmpty, isTrue);

      await cubit.onAppPaused(hasVaultDataLoaded: true);
      expect(cubit.activeReasons.contains(ScreenPrivacyEngageReasonEnum.appBackgroundWithVaultLoaded), isTrue);
      await cubit.onAppResumed();
      expect(cubit.activeReasons.isEmpty, isTrue);

      // onAppPaused with false does not engage
      await cubit.onAppPaused(hasVaultDataLoaded: false);
      expect(cubit.activeReasons.isEmpty, isTrue);
    });

    test('VaultRouteObserver observes vault push and pop', () {
      final observer = VaultRouteObserver(privacyCubit: cubit);

      final vaultRoute = PageRouteBuilder<void>(
        settings: const RouteSettings(name: '/vault/dashboard'),
        pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
      );

      final publicRoute = PageRouteBuilder<void>(
        settings: const RouteSettings(name: '/home'),
        pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
      );

      // Push vault route
      observer.didPush(vaultRoute, publicRoute);
      expect(cubit.activeReasons.contains(ScreenPrivacyEngageReasonEnum.vaultRouteActive), isTrue);

      // Pop vault route
      observer.didPop(vaultRoute, publicRoute);
      expect(cubit.activeReasons.isEmpty, isTrue);
    });
  });
}
