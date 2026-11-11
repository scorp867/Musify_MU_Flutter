import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/domain/policies/biometric_auth_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/keypad_layout_policy.dart';
import 'package:musify_mu/features/vault/domain/states/pin_pad_state.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';

/// Operational mode governing authentication context, copy, and completion actions.
enum VaultAuthScreenMode {
  /// Primary vault entry point from stealth gesture pad or lock screen.
  unlock,

  /// Step-up authentication guard for sensitive security setting modifications.
  stepUp,

  /// Step 1 of PIN rotation flow verifying active credentials before new PIN entry.
  verifyOldPin,

  /// Critical authorization for irreversible vault deletion and media wipe.
  purgeConfirmation;

  /// Returns whether this mode executes destructive operations.
  bool get isDestructive => this == VaultAuthScreenMode.purgeConfirmation;

  /// Returns whether this mode operates within an existing active session.
  bool get isSubSessionMode =>
      this == VaultAuthScreenMode.stepUp ||
      this == VaultAuthScreenMode.verifyOldPin ||
      this == VaultAuthScreenMode.purgeConfirmation;
}

/// Dedicated full-screen route for Secure Vault authentication.
///
/// Invariants:
/// - Strictly full-screen [Scaffold]; NO bottom sheets, NO popup alert dialogs.
/// - Reused across all 4 [VaultAuthScreenMode] contexts without code duplication.
/// - Integrates with [PinPadCubit] (Sub-Service 6) and [VaultSessionBloc] (Region A).
/// - 6 geometric PIN digit indicator boxes with 1px tone-on-tone borders.
/// - 3x4 keypad supporting standard and randomized per-attempt layouts.
/// - 400ms horizontal shake animation on failure with haptic feedback.
/// - Monotonic lockout cooldown countdown (MM:SS) when locked out.
/// - Strict design system: 8px geometric radius, Poppins typography, zero purple gradients,
///   zero pill buttons, zero emojis, zero em dashes.
class VaultAuthScreen extends StatelessWidget {
  /// Active operational authentication mode.
  final VaultAuthScreenMode mode;

  /// Optional custom title overriding default mode copy.
  final String? titleOverride;

  /// Optional completion callback invoked with authentication outcome.
  final ValueChanged<bool>? onAuthComplete;

  /// Optional scoped [PinPadCubit] instance. When omitted, resolves from ancestor context.
  final PinPadCubit? pinPadCubit;

  /// Optional scoped [VaultSessionBloc] instance. When omitted, resolves from ancestor context.
  final VaultSessionBloc? sessionBloc;

  /// Optional scoped [ScreenPrivacyCubit] instance. When omitted, resolves from ancestor context.
  final ScreenPrivacyCubit? screenPrivacyCubit;

  /// Active biometric auth policy governing fingerprint button visibility.
  /// When null, defaults to [BiometricAuthPolicyEnum.pinOnly] (fingerprint hidden).
  final BiometricAuthPolicyEnum? biometricPolicy;

  const VaultAuthScreen({
    required this.mode,
    this.titleOverride,
    this.onAuthComplete,
    this.pinPadCubit,
    this.sessionBloc,
    this.screenPrivacyCubit,
    this.biometricPolicy,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (pinPadCubit case final cubit?) {
      return BlocProvider<PinPadCubit>.value(
        value: cubit,
        child: _VaultAuthScreenView(
          mode: mode,
          titleOverride: titleOverride,
          onAuthComplete: onAuthComplete,
          sessionBlocOverride: sessionBloc,
          screenPrivacyCubitOverride: screenPrivacyCubit,
          biometricPolicy: biometricPolicy,
        ),
      );
    }

    return _VaultAuthScreenView(
      mode: mode,
      titleOverride: titleOverride,
      onAuthComplete: onAuthComplete,
      sessionBlocOverride: sessionBloc,
      screenPrivacyCubitOverride: screenPrivacyCubit,
      biometricPolicy: biometricPolicy,
    );
  }
}

class _VaultAuthScreenView extends StatefulWidget {
  final VaultAuthScreenMode mode;
  final String? titleOverride;
  final ValueChanged<bool>? onAuthComplete;
  final VaultSessionBloc? sessionBlocOverride;
  final ScreenPrivacyCubit? screenPrivacyCubitOverride;
  final BiometricAuthPolicyEnum? biometricPolicy;

  const _VaultAuthScreenView({
    required this.mode,
    required this.titleOverride,
    required this.onAuthComplete,
    required this.sessionBlocOverride,
    required this.screenPrivacyCubitOverride,
    required this.biometricPolicy,
  });

  @override
  State<_VaultAuthScreenView> createState() => _VaultAuthScreenViewState();
}

class _VaultAuthScreenViewState extends State<_VaultAuthScreenView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
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

    _engageScreenPrivacy();
  }

  void _engageScreenPrivacy() {
    final cubit = _resolveScreenPrivacyCubit();
    cubit?.engageSecureFlag(reason: ScreenPrivacyEngageReasonEnum.authSheetPresented);
  }

  void _releaseScreenPrivacy() {
    final cubit = _resolveScreenPrivacyCubit();
    cubit?.releaseSecureFlag(reason: ScreenPrivacyEngageReasonEnum.authSheetPresented);
  }

  ScreenPrivacyCubit? _resolveScreenPrivacyCubit() {
    if (widget.screenPrivacyCubitOverride case final cubit?) {
      return cubit;
    }
    try {
      return context.read<ScreenPrivacyCubit>();
    } catch (_) {
      return null;
    }
  }

  VaultSessionBloc? _resolveSessionBloc() {
    if (widget.sessionBlocOverride case final bloc?) {
      return bloc;
    }
    try {
      return context.read<VaultSessionBloc>();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _releaseScreenPrivacy();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleBackNavigation() {
    if (_hasCompleted) return;
    _hasCompleted = true;

    final sessionBloc = _resolveSessionBloc();
    if (widget.mode == VaultAuthScreenMode.unlock) {
      sessionBloc?.add(const VaultAuthCanceled());
    } else {
      sessionBloc?.add(const VaultStepUpAuthCanceled());
    }

    widget.onAuthComplete?.call(false);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(false);
    }
  }

  void _handleSuccess() {
    if (_hasCompleted) return;
    _hasCompleted = true;

    HapticFeedback.mediumImpact();
    widget.onAuthComplete?.call(true);

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultTheme = VaultTheme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: BlocListener<PinPadCubit, PinPadState>(
        listener: (context, state) {
          switch (state) {
            case PinPadIdleInputState():
              break;
            case PinPadEvaluatingState():
              break;
            case PinPadSuccessState():
              _handleSuccess();
            case PinPadFailureShakeState():
              HapticFeedback.heavyImpact();
              _shakeController.forward(from: 0.0).then((_) {
                if (mounted) {
                  context.read<PinPadCubit>().resetToIdle();
                }
              });
            case PinPadLockedOutState():
              HapticFeedback.heavyImpact();
          }
        },
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
              onPressed: _handleBackNavigation,
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
                              _buildModeHeader(vaultTheme),
                              if (widget.mode.isDestructive) ...[
                                const SizedBox(height: 16.0),
                                _buildDestructiveWarningCard(vaultTheme),
                              ],
                              const SizedBox(height: 24.0),
                              AnimatedBuilder(
                                animation: _shakeAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    key: const ValueKey('pin_shake_container'),
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
    );
  }

  Widget _buildModeHeader(VaultThemeData vaultTheme) {
    final IconData modeIcon;
    final String modeTitle;
    final String modeSubtitle;

    switch (widget.mode) {
      case VaultAuthScreenMode.unlock:
        modeIcon = Icons.lock_outline;
        modeTitle = 'Enter Master PIN';
        modeSubtitle = 'Enter 6-digit master PIN to unlock';
      case VaultAuthScreenMode.stepUp:
        modeIcon = Icons.security_outlined;
        modeTitle = 'Step-Up Verification';
        modeSubtitle = 'Enter master PIN to authorize changes';
      case VaultAuthScreenMode.verifyOldPin:
        modeIcon = Icons.pin_outlined;
        modeTitle = 'Verify Current PIN';
        modeSubtitle = 'Enter current 6-digit PIN to continue';
      case VaultAuthScreenMode.purgeConfirmation:
        modeIcon = Icons.warning_amber_rounded;
        modeTitle = 'Confirm Vault Purge';
        modeSubtitle = 'Warning: Irrevocable action. Enter master PIN to destroy vault.';
    }

    final displayTitle = widget.titleOverride ?? modeTitle;

    return Column(
      children: [
        Container(
          width: 56.0,
          height: 56.0,
          decoration: BoxDecoration(
            color: widget.mode.isDestructive
                ? vaultTheme.danger.withValues(alpha: 0.15)
                : vaultTheme.surfaceSubtle,
            borderRadius: VaultTheme.borderRadius8,
            border: Border.all(
              color: widget.mode.isDestructive
                  ? vaultTheme.danger
                  : vaultTheme.border,
              width: VaultTheme.borderWidth,
            ),
          ),
          child: Icon(
            modeIcon,
            size: 28.0,
            color: widget.mode.isDestructive
                ? vaultTheme.danger
                : vaultTheme.textHighSalience,
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          displayTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 22.0,
            fontWeight: FontWeight.w600,
            color: widget.mode.isDestructive
                ? vaultTheme.danger
                : vaultTheme.textHighSalience,
            letterSpacing: 0.15,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          modeSubtitle,
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
  }

  Widget _buildDestructiveWarningCard(VaultThemeData vaultTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: vaultTheme.danger.withValues(alpha: 0.12),
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: vaultTheme.danger.withValues(alpha: 0.50),
          width: VaultTheme.borderWidth,
        ),
      ),
      child: Text(
        'Warning: This action permanently shreds encryption keys in RAM and disk, deletes database records, and unlinks media files. This action cannot be reversed.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: VaultTheme.fontFamily,
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
          color: vaultTheme.danger,
          height: 1.4,
        ),
      ),
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
              key: ValueKey('pin_dot_slot_$index'),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                key: isFilled
                    ? const ValueKey('pin_dot_filled')
                    : ValueKey('pin_dot_empty_$index'),
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
    return BlocBuilder<PinPadCubit, PinPadState>(
      builder: (context, state) {
        switch (state) {
          case PinPadIdleInputState():
            return const SizedBox(height: 24.0);
          case PinPadEvaluatingState():
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
                  'Verifying PIN...',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                    color: vaultTheme.textHighSalience,
                  ),
                ),
              ],
            );
          case PinPadFailureShakeState(:final remainingAttemptsBeforeCooldown):
            return Text(
              'Incorrect PIN. $remainingAttemptsBeforeCooldown attempts remaining.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
                color: vaultTheme.danger,
              ),
            );
          case PinPadSuccessState():
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
                  'Verified',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: vaultTheme.accent,
                  ),
                ),
              ],
            );
          case PinPadLockedOutState(:final cooldownRemainingSeconds):
            final minutes = (cooldownRemainingSeconds ~/ 60).toString().padLeft(2, '0');
            final seconds = (cooldownRemainingSeconds % 60).toString().padLeft(2, '0');
            return Column(
              children: [
                Text(
                  'Vault Locked',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                    color: vaultTheme.danger,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '$minutes:$seconds',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 28.0,
                    fontWeight: FontWeight.w700,
                    color: vaultTheme.danger,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Too many consecutive failed attempts. Please wait for cooldown to expire.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 12.0,
                    color: vaultTheme.textMediumSalience,
                  ),
                ),
              ],
            );
        }
      },
    );
  }

  Widget _buildKeypadSection(VaultThemeData vaultTheme) {
    return BlocBuilder<PinPadCubit, PinPadState>(
      builder: (context, state) {
        final cubit = context.read<PinPadCubit>();
        final isLockedOut = state is PinPadLockedOutState;
        final isEvaluating = state is PinPadEvaluatingState;
        final isDisabled = isLockedOut || isEvaluating;

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
                  _buildKeypadRow(
                    vaultTheme: vaultTheme,
                    cubit: cubit,
                    digits: [digits[0], digits[1], digits[2]],
                  ),
                  const SizedBox(height: 12.0),
                  _buildKeypadRow(
                    vaultTheme: vaultTheme,
                    cubit: cubit,
                    digits: [digits[3], digits[4], digits[5]],
                  ),
                  const SizedBox(height: 12.0),
                  _buildKeypadRow(
                    vaultTheme: vaultTheme,
                    cubit: cubit,
                    digits: [digits[6], digits[7], digits[8]],
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBiometricOrEmptyButton(vaultTheme),
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

  void _handleBackspaceTap(PinPadCubit cubit) {
    HapticFeedback.lightImpact();
    cubit.onBackspace();
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
        onTap: () => _handleBackspaceTap(cubit),
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

  /// Biometric fingerprint button is shown ONLY when ALL conditions are met:
  /// 1. Mode supports biometric auth (unlock or stepUp)
  /// 2. Biometric policy is explicitly [BiometricAuthPolicyEnum.pinAndBiometricStrong]
  ///
  /// On an uninitialized vault or when biometrics are not configured,
  /// an empty spacer is rendered instead.
  Widget _buildBiometricOrEmptyButton(VaultThemeData vaultTheme) {
    final modeAllowsBiometric = widget.mode == VaultAuthScreenMode.unlock ||
        widget.mode == VaultAuthScreenMode.stepUp;
    final policyAllowsBiometric =
        widget.biometricPolicy?.allowsBiometrics ?? false;

    if (!modeAllowsBiometric || !policyAllowsBiometric) {
      return const SizedBox(width: 80.0, height: 64.0);
    }

    return Material(
      color: vaultTheme.surfaceSubtle,
      borderRadius: VaultTheme.borderRadius8,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          // Biometric challenge trigger
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
            Icons.fingerprint,
            size: 28.0,
            color: vaultTheme.textHighSalience,
          ),
        ),
      ),
    );
  }
}
