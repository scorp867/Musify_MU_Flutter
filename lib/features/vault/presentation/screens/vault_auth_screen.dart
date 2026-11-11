import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/domain/entities/auth_session.dart';
import 'package:musify_mu/features/vault/domain/entities/lockout_cooldown_info.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/policies/biometric_auth_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/keypad_layout_policy.dart';
import 'package:musify_mu/features/vault/domain/states/pin_pad_state.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';

import '../../domain/states/vault_session_state.dart';

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
  /// When null, resolves dynamically from SettingsMutationCubit.
  final BiometricAuthPolicyEnum? biometricPolicy;

  /// Optional scoped [IVaultAuthService] instance. When omitted, resolves from ancestor context.
  final IVaultAuthService? authService;

  const VaultAuthScreen({
    required this.mode,
    this.titleOverride,
    this.onAuthComplete,
    this.pinPadCubit,
    this.sessionBloc,
    this.screenPrivacyCubit,
    this.biometricPolicy,
    this.authService,
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
          authServiceOverride: authService,
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
      authServiceOverride: authService,
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
  final IVaultAuthService? authServiceOverride;

  const _VaultAuthScreenView({
    required this.mode,
    required this.titleOverride,
    required this.onAuthComplete,
    required this.sessionBlocOverride,
    required this.screenPrivacyCubitOverride,
    required this.biometricPolicy,
    required this.authServiceOverride,
  });

  @override
  State<_VaultAuthScreenView> createState() => _VaultAuthScreenViewState();
}

class _VaultAuthScreenViewState extends State<_VaultAuthScreenView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  String? _biometricFeedbackMessage;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final pinPad = _resolvePinPadCubit();
        try {
          final settingsCubit = context.read<SettingsMutationCubit>();
          pinPad?.updateKeypadLayout(settingsCubit.currentConfig.keypadLayout);
        } catch (_) {}
        pinPad?.resetToIdle();
      }
    });
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

  PinPadCubit? _resolvePinPadCubit() {
    try {
      return context.read<PinPadCubit>();
    } catch (_) {
      return null;
    }
  }

  IVaultAuthService? _resolveAuthService() {
    if (widget.authServiceOverride case final s?) {
      return s;
    }
    try {
      return context.read<IVaultAuthService>();
    } catch (_) {
      return null;
    }
  }

  BiometricAuthPolicyEnum _resolveBiometricPolicy() {
    if (widget.biometricPolicy case final policy?) {
      return policy;
    }
    try {
      final cubit = context.read<SettingsMutationCubit>();
      return cubit.currentConfig.biometricAuth;
    } catch (_) {
      return BiometricAuthPolicyEnum.pinOnly;
    }
  }

  Future<void> _handleBiometricTap() async {
    HapticFeedback.lightImpact();
    final authService = _resolveAuthService();
    if (authService == null) return;

    final result = await authService.authenticateWithBiometrics();
    if (!mounted) return;

    switch (result) {
      case VaultSuccess<AuthSession>(:final data):
        final sessionBloc = _resolveSessionBloc();
        if (widget.mode == VaultAuthScreenMode.unlock) {
          sessionBloc?.add(VaultAuthSucceeded(session: data));
        } else if (widget.mode == VaultAuthScreenMode.stepUp) {
          sessionBloc?.add(VaultStepUpAuthSucceeded(session: data));
        }
        _handleSuccess();
      case VaultFailureResult<AuthSession>(:final failure):
        HapticFeedback.heavyImpact();
        if (failure is VaultLockoutFailure) {
          final sessionBloc = _resolveSessionBloc();
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          sessionBloc?.add(
            VaultLockoutTriggered(
              tier: failure.remainingCooldownSeconds > 30
                  ? LockoutCooldownTierEnum.tier2FiveMinutes
                  : LockoutCooldownTierEnum.tier1ThirtySeconds,
              cooldownStartedMonotonicMs: nowMs,
              durationMs: failure.remainingCooldownSeconds * 1000,
              deadlineMonotonicMs: failure.deadlineMonotonicMs,
              failedAttemptsCount: failure.remainingCooldownSeconds > 30 ? 10 : 5,
            ),
          );
          final pinPad = _resolvePinPadCubit();
          pinPad?.enterLockout(deadlineMonotonicMs: failure.deadlineMonotonicMs);
        } else {
          setState(() {
            _biometricFeedbackMessage = 'Biometric canceled or unavailable. Enter PIN.';
          });
        }
    }
  }

  @override
  void dispose() {
    _resolvePinPadCubit()?.resetToIdle();
    _releaseScreenPrivacy();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleBackNavigation() {
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
            case PinPadSuccessState(:final session):
              if (session != null) {
                final sessionBloc = _resolveSessionBloc();
                if (widget.mode == VaultAuthScreenMode.unlock) {
                  sessionBloc?.add(VaultAuthSucceeded(session: session));
                } else if (widget.mode == VaultAuthScreenMode.stepUp) {
                  sessionBloc?.add(VaultStepUpAuthSucceeded(session: session));
                }
              }
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
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            _buildHeader(vaultTheme),
                            const SizedBox(height: 32),
                            _buildPinIndicators(vaultTheme),
                            const SizedBox(height: 16),
                            _buildStatusMessage(vaultTheme),
                            const Spacer(),
                            _buildKeypad(vaultTheme),
                            const SizedBox(height: 24),
                          ],
                        ),
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

  Widget _buildHeader(VaultThemeData vaultTheme) {
    final title = widget.titleOverride ??
        switch (widget.mode) {
          VaultAuthScreenMode.unlock => 'Enter Vault PIN',
          VaultAuthScreenMode.stepUp => 'Confirm Your Identity',
          VaultAuthScreenMode.verifyOldPin => 'Enter Current PIN',
          VaultAuthScreenMode.purgeConfirmation => 'Authorize Vault Purge',
        };

    final subtitle = switch (widget.mode) {
      VaultAuthScreenMode.unlock => 'Enter your 6-digit PIN to access private media',
      VaultAuthScreenMode.stepUp => 'Authentication required to modify security settings',
      VaultAuthScreenMode.verifyOldPin => 'Verify your existing PIN before setting a new one',
      VaultAuthScreenMode.purgeConfirmation =>
      'Irreversible action: all private playlists and keys will be deleted',
    };

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: vaultTheme.textHighSalience,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: widget.mode.isDestructive
                ? vaultTheme.danger
                : vaultTheme.textMediumSalience,
          ),
        ),
      ],
    );
  }

  Widget _buildPinIndicators(VaultThemeData vaultTheme) {
    return BlocBuilder<PinPadCubit, PinPadState>(
      builder: (context, state) {
        final enteredCount = switch (state) {
          PinPadIdleInputState(:final enteredDigitsCount) => enteredDigitsCount,
          PinPadEvaluatingState() => 6,
          PinPadSuccessState() => 6,
          PinPadFailureShakeState() => 6,
          PinPadLockedOutState() => 0,
        };

        return AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              final isFilled = index < enteredCount;
              return Container(
                width: 44,
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: isFilled ? vaultTheme.surfaceSubtle : vaultTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isFilled
                        ? vaultTheme.accent
                        : vaultTheme.border,
                    width: 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: isFilled
                    ? Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: vaultTheme.accent,
                    shape: BoxShape.circle,
                  ),
                )
                    : null,
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildStatusMessage(VaultThemeData vaultTheme) {
    return BlocBuilder<PinPadCubit, PinPadState>(
      builder: (context, state) {
        switch (state) {
          case PinPadIdleInputState():
            if (_biometricFeedbackMessage case final msg?) {
              return Text(
                msg,
                style: TextStyle(
                  fontSize: 13,
                  color: vaultTheme.danger,
                ),
              );
            }
            return const SizedBox(height: 18);

          case PinPadEvaluatingState():
            return Text(
              'Verifying...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: vaultTheme.textMediumSalience,
              ),
            );

          case PinPadSuccessState():
            return Text(
              'Unlocked',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: vaultTheme.accent,
              ),
            );

          case PinPadFailureShakeState(:final remainingAttemptsBeforeCooldown):
            return Text(
              'Incorrect PIN. $remainingAttemptsBeforeCooldown attempts remaining.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: vaultTheme.danger,
              ),
            );

          case PinPadLockedOutState(:final cooldownRemainingSeconds):
            final minutes = (cooldownRemainingSeconds ~/ 60).toString().padLeft(2, '0');
            final seconds = (cooldownRemainingSeconds % 60).toString().padLeft(2, '0');
            return Text(
              'Lockout cooldown active: $minutes:$seconds',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: vaultTheme.danger,
              ),
            );
        }
      },
    );
  }

  Widget _buildKeypad(VaultThemeData vaultTheme) {
    return BlocBuilder<PinPadCubit, PinPadState>(
      builder: (context, state) {
        final isLockedOut = state is PinPadLockedOutState;
        final isEvaluating = state is PinPadEvaluatingState;
        final isDisabled = isLockedOut || isEvaluating;

        final cubit = context.read<PinPadCubit>();
        final digits = cubit.currentKeypadDigits;

        return Column(
          children: [
            for (var row = 0; row < 3; row++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var col = 0; col < 3; col++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: _buildDigitButton(
                          digit: digits[row * 3 + col],
                          vaultTheme: vaultTheme,
                          isDisabled: isDisabled,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            cubit.onDigitEntered(digits[row * 3 + col]);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: _buildBiometricOrEmptyButton(vaultTheme, isDisabled),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: _buildDigitButton(
                    digit: digits[9],
                    vaultTheme: vaultTheme,
                    isDisabled: isDisabled,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      cubit.onDigitEntered(digits[9]);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: _buildActionButton(
                    icon: Icons.backspace_outlined,
                    vaultTheme: vaultTheme,
                    isDisabled: isDisabled,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      cubit.onBackspace();
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDigitButton({
    required int digit,
    required VaultThemeData vaultTheme,
    required bool isDisabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: vaultTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: vaultTheme.border,
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          splashColor: vaultTheme.accent.withValues(alpha: 0.15),
          highlightColor: vaultTheme.accent.withValues(alpha: 0.08),
          child: Center(
            child: Text(
              '$digit',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: isDisabled
                    ? vaultTheme.textLowSalience
                    : vaultTheme.textHighSalience,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VaultThemeData vaultTheme,
    required bool isDisabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: vaultTheme.border,
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          splashColor: vaultTheme.accent.withValues(alpha: 0.15),
          highlightColor: vaultTheme.accent.withValues(alpha: 0.08),
          child: Center(
            child: Icon(
              icon,
              size: 24,
              color: isDisabled
                  ? vaultTheme.textLowSalience
                  : vaultTheme.textHighSalience,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricOrEmptyButton(
      VaultThemeData vaultTheme,
      bool isDisabled,
      ) {
    final policy = _resolveBiometricPolicy();
    final isBiometricEnabled = policy.allowsBiometrics &&
        widget.mode == VaultAuthScreenMode.unlock;

    if (!isBiometricEnabled) {
      return const SizedBox(width: 72, height: 72);
    }

    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: vaultTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: vaultTheme.border,
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isDisabled ? null : _handleBiometricTap,
          splashColor: vaultTheme.accent.withValues(alpha: 0.15),
          highlightColor: vaultTheme.accent.withValues(alpha: 0.08),
          child: Center(
            child: Icon(
              Icons.fingerprint,
              size: 30,
              color: isDisabled
                  ? vaultTheme.textLowSalience
                  : vaultTheme.accent,
            ),
          ),
        ),
      ),
    );
  }
}