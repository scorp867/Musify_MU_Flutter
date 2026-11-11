import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/application/setup/vault_setup_cubit.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/policies/keypad_layout_policy.dart';
import 'package:musify_mu/features/vault/domain/states/pin_pad_state.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_setup_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';

/// Dedicated full-screen route for first-time vault provisioning.
///
/// Manages a two-phase PIN creation flow:
///   Phase 1 (Create): User chooses a 6-digit master PIN.
///   Phase 2 (Confirm): User re-enters the PIN to confirm.
///   Enrollment: Provisions MVK, wraps Slot 1 via PBKDF2, stores canonical gesture.
///   Auto-auth: Authenticates with the new PIN and transitions to VaultUnlockedState.
///
/// Invariants:
/// - Strictly full-screen [Scaffold]; NO bottom sheets, NO popup alert dialogs.
/// - Composes [VaultSetupCubit] (sealed state machine) with [PinPadCubit] (digit entry).
/// - Zero loose boolean flags for phase tracking (driven by [VaultSetupState]).
/// - 6 geometric PIN digit indicator boxes with 1px tone-on-tone borders.
/// - 3x4 keypad supporting standard layout.
/// - 400ms horizontal shake animation on mismatch with haptic feedback.
/// - Strict design system: 8px geometric radius, Poppins typography, zero purple gradients,
///   zero pill buttons, zero emojis, zero em dashes.
class VaultSetupScreen extends StatefulWidget {
  /// Vault authentication service for credential enrollment and auto-auth.
  final IVaultAuthService authService;

  /// Monotonic clock for PinPadCubit.
  final IMonotonicClock monotonicClock;

  /// Unlock use case for PinPadCubit construction.
  final UnlockVaultUseCase unlockVaultUseCase;

  /// Optional completion callback invoked when setup finishes (true) or is canceled (false).
  final ValueChanged<bool>? onSetupComplete;

  const VaultSetupScreen({
    required this.authService,
    required this.monotonicClock,
    required this.unlockVaultUseCase,
    this.onSetupComplete,
    super.key,
  });

  @override
  State<VaultSetupScreen> createState() => _VaultSetupScreenState();
}

class _VaultSetupScreenState extends State<VaultSetupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  late final VaultSetupCubit _setupCubit;
  late final PinPadCubit _pinPadCubit;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.easeInOut,
      ),
    );

    _setupCubit = VaultSetupCubit(authService: widget.authService);

    _pinPadCubit = PinPadCubit(
      unlockVaultUseCase: widget.unlockVaultUseCase,
      authService: widget.authService,
      monotonicClock: widget.monotonicClock,
      customPinSubmitter: (pin) => _setupCubit.handlePinSubmission(pin),
    );

    _engageScreenPrivacy();
  }

  void _engageScreenPrivacy() {
    try {
      context
          .read<ScreenPrivacyCubit>()
          .engageSecureFlag(reason: ScreenPrivacyEngageReasonEnum.authSheetPresented);
    } catch (_) {
      // ScreenPrivacyCubit not available in context
    }
  }

  void _releaseScreenPrivacy() {
    try {
      context
          .read<ScreenPrivacyCubit>()
          .releaseSecureFlag(reason: ScreenPrivacyEngageReasonEnum.authSheetPresented);
    } catch (_) {
      // ScreenPrivacyCubit not available in context
    }
  }

  @override
  void dispose() {
    _releaseScreenPrivacy();
    _pinPadCubit.close();
    _setupCubit.close();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleBackNavigation() {
    if (_hasCompleted) return;
    _hasCompleted = true;

    try {
      context.read<VaultSessionBloc>().add(const VaultSetupCanceled());
    } catch (_) {
      // VaultSessionBloc not available
    }

    widget.onSetupComplete?.call(false);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(false);
    } else {
      SystemNavigator.pop();
    }
  }

  /// After enrollment succeeds, auto-authenticate with the same PIN to obtain
  /// an [AuthSession], then dispatch [VaultAuthSucceeded] to transition
  /// the session FSM to [VaultUnlockedState].
  Future<void> _handleSetupComplete() async {
    if (_hasCompleted) return;
    _hasCompleted = true;

    HapticFeedback.mediumImpact();

    // Auto-authenticate to obtain a session after enrollment
    try {
      final sessionBloc = context.read<VaultSessionBloc>();

      // The PIN was just used for enrollment; re-authenticate to get session keys.
      final chosenPin = _setupCubit.lastEnrolledPin;
      if (chosenPin != null) {
        final authResult = await widget.authService.authenticateWithPin(pin: chosenPin);
        switch (authResult) {
          case VaultSuccess<AuthSession>(:final data):
            sessionBloc.add(VaultAuthSucceeded(session: data));
          case VaultFailureResult<AuthSession>():
            // Enrollment succeeded but auto-auth failed; fall through to locked state.
            // The user will need to unlock manually, which is acceptable.
            break;
        }
      }
    } catch (_) {
      // Bloc not available or auth failed; the vault is still provisioned
      // and the user can unlock normally.
    }

    widget.onSetupComplete?.call(true);
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultTheme = VaultTheme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<VaultSetupCubit>.value(value: _setupCubit),
        BlocProvider<PinPadCubit>.value(value: _pinPadCubit),
      ],
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            // If in confirm phase, go back to create phase instead of dismissing
            if (_setupCubit.state is SetupAwaitingConfirmationState) {
              _setupCubit.resetToNewPin();
              _pinPadCubit.resetToIdle();
              return;
            }
            _handleBackNavigation();
          }
        },
        child: MultiBlocListener(
          listeners: [
            BlocListener<PinPadCubit, PinPadState>(
              listener: (context, state) {
                switch (state) {
                  case PinPadIdleInputState():
                  case PinPadEvaluatingState():
                  case PinPadLockedOutState():
                    break;
                  case PinPadSuccessState():
                    // PinPadCubit emits success when customPinSubmitter returns VaultSuccess.
                    // For phase 1: setup cubit transitions to confirm phase.
                    // For phase 2: setup cubit transitions to enrolling then complete.
                    final setupState = _setupCubit.state;
                    switch (setupState) {
                      case SetupAwaitingConfirmationState():
                        // Phase 1 just succeeded; reset pin pad for confirmation entry.
                        Future.microtask(() {
                          if (mounted) {
                            _pinPadCubit.resetToIdle();
                          }
                        });
                      case SetupCompleteState():
                        _handleSetupComplete();
                      case SetupAwaitingNewPinState():
                      case SetupEnrollingCredentialsState():
                      case SetupPinMismatchState():
                      case SetupEnrollmentFailedState():
                        break;
                    }
                  case PinPadFailureShakeState():
                    HapticFeedback.heavyImpact();
                    _shakeController.forward(from: 0.0).then((_) {
                      if (mounted) {
                        _setupCubit.resetToNewPin();
                        _pinPadCubit.resetToIdle();
                      }
                    });
                }
              },
            ),
          ],
          child: Scaffold(
            backgroundColor: vaultTheme.scaffold,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: vaultTheme.textHighSalience,
                ),
                onPressed: () {
                  if (_setupCubit.state is SetupAwaitingConfirmationState) {
                    _setupCubit.resetToNewPin();
                    _pinPadCubit.resetToIdle();
                    return;
                  }
                  _handleBackNavigation();
                },
              ),
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                const SizedBox(height: 8.0),
                                _buildSetupHeader(vaultTheme),
                                const SizedBox(height: 24.0),
                                AnimatedBuilder(
                                  animation: _shakeAnimation,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      key: const ValueKey('setup_pin_shake_container'),
                                      offset: Offset(_shakeAnimation.value, 0),
                                      child: child,
                                    );
                                  },
                                  child: _buildPinDotsRow(vaultTheme),
                                ),
                                const SizedBox(height: 16.0),
                                _buildStatusFeedback(vaultTheme),
                              ],
                            ),
                            _buildKeypadSection(vaultTheme),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupHeader(VaultThemeData vaultTheme) {
    return BlocBuilder<VaultSetupCubit, VaultSetupState>(
      builder: (context, setupState) {
        final IconData headerIcon;
        final String headerTitle;
        final String headerSubtitle;

        switch (setupState) {
          case SetupAwaitingNewPinState():
          case SetupPinMismatchState():
          case SetupEnrollmentFailedState():
            headerIcon = Icons.lock_open_outlined;
            headerTitle = 'Create Master PIN';
            headerSubtitle = 'Choose a 6-digit PIN to protect your vault';
          case SetupAwaitingConfirmationState():
            headerIcon = Icons.lock_outline;
            headerTitle = 'Confirm Master PIN';
            headerSubtitle = 'Re-enter your 6-digit PIN to confirm';
          case SetupEnrollingCredentialsState():
            headerIcon = Icons.lock_outline;
            headerTitle = 'Setting Up Vault';
            headerSubtitle = 'Provisioning encryption keys...';
          case SetupCompleteState():
            headerIcon = Icons.check_circle_outline;
            headerTitle = 'Vault Created';
            headerSubtitle = 'Your private vault is ready';
        }

        return Column(
          children: [
            Container(
              width: 56.0,
              height: 56.0,
              decoration: BoxDecoration(
                color: vaultTheme.surfaceSubtle,
                borderRadius: VaultTheme.borderRadius8,
                border: Border.all(
                  color: vaultTheme.border,
                  width: VaultTheme.borderWidth,
                ),
              ),
              child: Icon(
                headerIcon,
                size: 28.0,
                color: setupState is SetupCompleteState
                    ? vaultTheme.accent
                    : vaultTheme.textHighSalience,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              headerTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                fontSize: 22.0,
                fontWeight: FontWeight.w600,
                color: vaultTheme.textHighSalience,
                letterSpacing: 0.15,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              headerSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                fontSize: 14.0,
                fontWeight: FontWeight.w400,
                color: vaultTheme.textMediumSalience,
                letterSpacing: 0.25,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPinDotsRow(VaultThemeData vaultTheme) {
    return BlocBuilder<PinPadCubit, PinPadState>(
      buildWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType ||
          (previous is PinPadIdleInputState &&
              current is PinPadIdleInputState &&
              previous.enteredDigitsCount != current.enteredDigitsCount),
      builder: (context, state) {
        final enteredCount = switch (state) {
          PinPadIdleInputState(:final enteredDigitsCount) => enteredDigitsCount,
          PinPadEvaluatingState() => 6,
          PinPadSuccessState() => 6,
          PinPadFailureShakeState() => 6,
          PinPadLockedOutState() => 0,
        };

        final isError = state is PinPadFailureShakeState;
        final isSuccess = state is PinPadSuccessState;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final isFilled = index < enteredCount;
            final Color fillColor;
            final Color borderColor;

            if (isError) {
              fillColor = vaultTheme.danger;
              borderColor = vaultTheme.danger;
            } else if (isSuccess) {
              fillColor = vaultTheme.accent;
              borderColor = vaultTheme.accent;
            } else if (isFilled) {
              fillColor = vaultTheme.textHighSalience;
              borderColor = vaultTheme.textHighSalience;
            } else {
              fillColor = vaultTheme.surfaceSubtle;
              borderColor = vaultTheme.border;
            }

            return Padding(
              key: ValueKey('setup_pin_dot_slot_$index'),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                width: 16.0,
                height: 16.0,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: VaultTheme.borderRadius8,
                  border: Border.all(
                    color: borderColor,
                    width: VaultTheme.borderWidth,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildStatusFeedback(VaultThemeData vaultTheme) {
    return BlocBuilder<VaultSetupCubit, VaultSetupState>(
      builder: (context, setupState) {
        switch (setupState) {
          case SetupAwaitingNewPinState():
          case SetupAwaitingConfirmationState():
            return const SizedBox(height: 24.0);
          case SetupEnrollingCredentialsState():
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16.0,
                  height: 16.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      vaultTheme.textHighSalience,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Provisioning vault...',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                    color: vaultTheme.textHighSalience,
                  ),
                ),
              ],
            );
          case SetupPinMismatchState():
            return Text(
              'PINs do not match. Please start over.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
                color: vaultTheme.danger,
              ),
            );
          case SetupCompleteState():
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16.0,
                  color: vaultTheme.accent,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Vault created successfully',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: vaultTheme.accent,
                  ),
                ),
              ],
            );
          case SetupEnrollmentFailedState(:final errorMessage):
            return Text(
              'Setup failed: $errorMessage',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
                color: vaultTheme.danger,
              ),
            );
        }
      },
    );
  }

  Widget _buildKeypadSection(VaultThemeData vaultTheme) {
    return BlocBuilder<PinPadCubit, PinPadState>(
      builder: (context, state) {
        final cubit = context.read<PinPadCubit>();
        final isEvaluating = state is PinPadEvaluatingState;
        final isDisabled = isEvaluating;

        final digits = cubit.currentKeypadDigits.isNotEmpty
            ? cubit.currentKeypadDigits
            : KeypadLayoutPolicyEnum.standardDigits;

        return AbsorbPointer(
          absorbing: isDisabled,
          child: Opacity(
            opacity: isDisabled ? 0.35 : 1.0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 12.0),
              child: Column(
                children: [
                  _buildKeypadRow(vaultTheme: vaultTheme, cubit: cubit, digits: [digits[0], digits[1], digits[2]]),
                  const SizedBox(height: 12.0),
                  _buildKeypadRow(vaultTheme: vaultTheme, cubit: cubit, digits: [digits[3], digits[4], digits[5]]),
                  const SizedBox(height: 12.0),
                  _buildKeypadRow(vaultTheme: vaultTheme, cubit: cubit, digits: [digits[6], digits[7], digits[8]]),
                  const SizedBox(height: 12.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // No biometric button during setup; empty spacer.
                      const SizedBox(width: 80.0, height: 64.0),
                      _buildKeypadButton(
                        vaultTheme: vaultTheme,
                        digit: digits[9],
                        onTap: () => _handleDigitTap(cubit, digits[9]),
                      ),
                      _buildBackspaceButton(vaultTheme, cubit),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeypadRow({
    required VaultThemeData vaultTheme,
    required PinPadCubit cubit,
    required List<int> digits,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) {
        return _buildKeypadButton(
          vaultTheme: vaultTheme,
          digit: digit,
          onTap: () => _handleDigitTap(cubit, digit),
        );
      }).toList(growable: false),
    );
  }

  void _handleDigitTap(PinPadCubit cubit, int digit) {
    HapticFeedback.lightImpact();
    cubit.onDigitEntered(digit);
  }

  Widget _buildKeypadButton({
    required VaultThemeData vaultTheme,
    required int digit,
    required VoidCallback onTap,
  }) {
    final letters = switch (digit) {
      1 => '',
      2 => 'ABC',
      3 => 'DEF',
      4 => 'GHI',
      5 => 'JKL',
      6 => 'MNO',
      7 => 'PQRS',
      8 => 'TUV',
      9 => 'WXYZ',
      0 => '+',
      _ => '',
    };

    return Material(
      color: vaultTheme.surfaceSubtle,
      borderRadius: VaultTheme.borderRadius8,
      child: InkWell(
        onTap: onTap,
        borderRadius: VaultTheme.borderRadius8,
        child: Container(
          width: 80.0,
          height: 64.0,
          decoration: BoxDecoration(
            borderRadius: VaultTheme.borderRadius8,
            border: Border.all(
              color: vaultTheme.border,
              width: VaultTheme.borderWidth,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$digit',
                style: TextStyle(
                  fontFamily: VaultTheme.fontFamily,
                  fontSize: 24.0,
                  fontWeight: FontWeight.w600,
                  color: vaultTheme.textHighSalience,
                ),
              ),
              if (letters.isNotEmpty)
                Text(
                  letters,
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 9.0,
                    fontWeight: FontWeight.w500,
                    color: vaultTheme.textMediumSalience,
                    letterSpacing: 1.2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(VaultThemeData vaultTheme, PinPadCubit cubit) {
    return Material(
      color: vaultTheme.surfaceSubtle,
      borderRadius: VaultTheme.borderRadius8,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          cubit.onBackspace();
        },
        borderRadius: VaultTheme.borderRadius8,
        child: Container(
          width: 80.0,
          height: 64.0,
          decoration: BoxDecoration(
            borderRadius: VaultTheme.borderRadius8,
            border: Border.all(
              color: vaultTheme.border,
              width: VaultTheme.borderWidth,
            ),
          ),
          child: Icon(
            Icons.backspace_outlined,
            size: 22.0,
            color: vaultTheme.textHighSalience,
          ),
        ),
      ),
    );
  }
}
