import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_screen_privacy_controller.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/screen_security_policy.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/verify_session_cool_off_use_case.dart';
import 'package:musify_mu/features/vault/presentation/widgets/reauth_blur_overlay.dart';

class FakeMonotonicClock implements IMonotonicClock {
  int timeMs = 10000;
  @override
  int get currentMonotonicMs => timeMs;
  @override
  int get elapsedMilliseconds => timeMs;
  @override
  Stopwatch createStopwatch() => Stopwatch();
}

class FakeVaultStorageRepository implements IVaultStorageRepository {
  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async =>
      VaultResult.success(const VaultConfig.constant());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVaultAuthService implements IVaultAuthService {
  final StreamController<VaultSessionState> controller =
      StreamController<VaultSessionState>.broadcast();
  Stream<VaultSessionState> get sessionStateStream => controller.stream;
  @override
  void clearSessionKeysFromRam() {}
  @override
  Future<void> resetFailedAttempts() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeScreenPrivacyController implements IScreenPrivacyController {
  ScreenPrivacyStateEnum _state = ScreenPrivacyStateEnum.publicUnrestricted;
  final StreamController<ScreenPrivacyStateEnum> _streamController =
      StreamController<ScreenPrivacyStateEnum>.broadcast();

  int enableCallCount = 0;
  int disableCallCount = 0;

  @override
  ScreenPrivacyStateEnum get currentState => _state;

  @override
  Stream<ScreenPrivacyStateEnum> get stateStream => _streamController.stream;

  @override
  Future<void> enableSecureFlag() async {
    enableCallCount++;
    _state = ScreenPrivacyStateEnum.secureFlagEngaged;
    _streamController.add(_state);
  }

  @override
  Future<void> disableSecureFlag() async {
    disableCallCount++;
    _state = ScreenPrivacyStateEnum.publicUnrestricted;
    _streamController.add(_state);
  }

  void dispose() {
    _streamController.close();
  }
}

class TestVaultSessionBloc extends VaultSessionBloc {
  TestVaultSessionBloc({
    required super.authService,
    required super.storageRepository,
    required super.monotonicClock,
    required super.verifyCoolOffUseCase,
    super.initialState = const VaultUninitializedState(),
  });

  void emitState(VaultSessionState state) {
    emit(state);
  }
}

void main() {
  group('ReauthBlurOverlay Adversarial Stress Tests', () {
    late FakeVaultAuthService fakeAuthService;
    late FakeMonotonicClock fakeClock;
    late FakeVaultStorageRepository fakeStorage;
    late VerifySessionCoolOffUseCase verifyCoolOff;
    late TestVaultSessionBloc sessionBloc;
    late FakeScreenPrivacyController fakePrivacyController;
    late ScreenPrivacyCubit privacyCubit;

    final testSession = AuthSession(
      sessionToken: 'test_token',
      sessionStartedEpochMs: 1000,
      lastActiveEpochMs: 1000,
      authMethod: AuthMethodEnum.pin,
    );

    final unlockedState = VaultUnlockedState(
      session: testSession,
      unlockedAtMonotonicMs: 1000,
      reauthDeadlineMonotonicMs: 60000,
    );

    final pendingReauthState = VaultPendingReauthState(
      session: testSession,
      reauthTriggeredAtMonotonicMs: 5000,
      remainingAttempts: 3,
    );

    setUp(() {
      fakeAuthService = FakeVaultAuthService();
      fakeClock = FakeMonotonicClock();
      fakeStorage = FakeVaultStorageRepository();
      verifyCoolOff = VerifySessionCoolOffUseCase(clock: fakeClock);
      sessionBloc = TestVaultSessionBloc(
        authService: fakeAuthService,
        storageRepository: fakeStorage,
        monotonicClock: fakeClock,
        verifyCoolOffUseCase: verifyCoolOff,
        initialState: unlockedState,
      );
      fakePrivacyController = FakeScreenPrivacyController();
      privacyCubit = ScreenPrivacyCubit(
        privacyController: fakePrivacyController,
        monotonicClock: fakeClock,
        initialPolicy: ScreenSecurityPolicyEnum.blockScreenshotsAndRecents,
      );
    });

    tearDown(() {
      sessionBloc.close();
      privacyCubit.close();
      fakePrivacyController.dispose();
      fakeAuthService.controller.close();
    });

    testWidgets(
      'Adversarial Test 1: Deep scroll offset (10,000px) and drag resistance under blur',
      (WidgetTester tester) async {
        final scrollController = ScrollController();
        int reauthCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<VaultSessionBloc>.value(value: sessionBloc),
                BlocProvider<ScreenPrivacyCubit>.value(value: privacyCubit),
              ],
              child: Scaffold(
                body: ReauthBlurOverlay(
                  onReauthRequested: () => reauthCount++,
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 1000,
                    itemExtent: 50.0,
                    itemBuilder: (context, index) => SizedBox(
                      height: 50.0,
                      child: Text('Item $index'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Scroll deeply to 10,000.0 px
        scrollController.jumpTo(10000.0);
        await tester.pumpAndSettle();
        expect(scrollController.offset, 10000.0);

        // Engage pending reauth
        sessionBloc.emitState(pendingReauthState);
        await tester.pumpAndSettle();

        expect(find.byType(BackdropFilter), findsOneWidget);
        expect(scrollController.offset, 10000.0);

        // Attempt to drag list down while blur is active
        await tester.drag(find.byType(BackdropFilter), const Offset(0.0, 300.0));
        await tester.pumpAndSettle();

        // INVARIANT: Scroll offset must not have changed at all
        expect(scrollController.offset, 10000.0);

        // Release blur by unlocking
        sessionBloc.emitState(unlockedState);
        await tester.pumpAndSettle();

        expect(find.byType(BackdropFilter), findsNothing);
        expect(scrollController.offset, 10000.0);

        scrollController.dispose();
      },
    );

    testWidgets(
      'Adversarial Test 2: Text editing selection and dirty state preserved across multiple blur flapping cycles',
      (WidgetTester tester) async {
        final textController = TextEditingController(
          text: 'SuperSensitiveTrackData_42_\u2764\ufe0f_\u00e9\u00e0\u00fc',
        );
        textController.selection = const TextSelection(baseOffset: 5, extentOffset: 15);
        int reauthCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<VaultSessionBloc>.value(value: sessionBloc),
                BlocProvider<ScreenPrivacyCubit>.value(value: privacyCubit),
              ],
              child: Scaffold(
                body: ReauthBlurOverlay(
                  onReauthRequested: () => reauthCount++,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: textController,
                      autofocus: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Flap 5 times between PendingReauth and Unlocked
        for (int i = 0; i < 5; i++) {
          sessionBloc.emitState(pendingReauthState);
          await tester.pumpAndSettle();
          expect(textController.text, 'SuperSensitiveTrackData_42_\u2764\ufe0f_\u00e9\u00e0\u00fc');
          expect(textController.selection.baseOffset, 5);
          expect(textController.selection.extentOffset, 15);

          sessionBloc.emitState(unlockedState);
          await tester.pumpAndSettle();
          expect(textController.text, 'SuperSensitiveTrackData_42_\u2764\ufe0f_\u00e9\u00e0\u00fc');
          expect(textController.selection.baseOffset, 5);
          expect(textController.selection.extentOffset, 15);
        }

        textController.dispose();
      },
    );

    testWidgets(
      'Adversarial Test 3: ScreenPrivacy integration engages secure flag on blur and releases on restore',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<VaultSessionBloc>.value(value: sessionBloc),
                BlocProvider<ScreenPrivacyCubit>.value(value: privacyCubit),
              ],
              child: Scaffold(
                body: ReauthBlurOverlay(
                  onReauthRequested: () {},
                  child: const Text('Sensitive Content'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially Unlocked with no reasons
        expect(privacyCubit.isSecureFlagEngaged, isFalse);

        // Transition to PendingReauth -> engages secure flag
        sessionBloc.emitState(pendingReauthState);
        await tester.pumpAndSettle();

        expect(privacyCubit.isSecureFlagEngaged, isTrue);
        expect(
          privacyCubit.activeReasons.contains(
            ScreenPrivacyEngageReasonEnum.reauthOverlayPresented,
          ),
          isTrue,
        );

        // Transition back to Unlocked -> releases secure flag
        sessionBloc.emitState(unlockedState);
        await tester.pumpAndSettle();

        expect(privacyCubit.isSecureFlagEngaged, isFalse);
        expect(
          privacyCubit.activeReasons.contains(
            ScreenPrivacyEngageReasonEnum.reauthOverlayPresented,
          ),
          isFalse,
        );
      },
    );
  });
}
