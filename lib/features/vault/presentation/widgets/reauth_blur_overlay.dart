import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';

/// Frosted glass non-destructive re-authentication overlay.
///
/// Displayed over active vault views (e.g. Dashboard, Playlist Detail, Settings)
/// when [VaultSessionBloc] transitions to [VaultPendingReauthState] or [VaultLockoutCooldownState].
///
/// Invariants:
/// 1. Non-destructive: [child] remains continuously mounted at [Stack] index 0,
///    preserving all scroll offsets, text controllers, focus nodes, and view state.
/// 2. Audio Continuity: Purely presentational; does not interrupt active audio playback.
/// 3. Frosted Blur: Applies [BackdropFilter] with exact sigma 12.0 bounded by [ClipRect].
/// 4. Touch Shielding: Wraps [child] in [AbsorbPointer] and absorbs touches on the shield.
/// 5. Musify Design System:
///    - 8px geometric radius ([BorderRadius.circular(8.0)]).
///    - 1px tone-on-tone borders.
///    - Poppins typography.
///    - Zero purple/violet gradients, zero emojis, zero em dashes.
/// 6. Dual Palette Support: Adapts reactively to active [VaultThemeData].
class ReauthBlurOverlay extends StatelessWidget {
  /// The underlying vault view to protect with frosted glass mid-session.
  final Widget child;

  /// Callback invoked when the user requests re-authentication.
  final VoidCallback onReauthRequested;

  /// Optional explicit blur control for testing or manual overrides.
  /// When null, defaults to inspecting [VaultSessionBloc] state for [VaultPendingReauthState] or [VaultLockoutCooldownState].
  final bool? isBlurActive;

  /// Optional explicit palette policy override for testing.
  /// When null, resolves from ancestor [VaultTheme].
  final VaultThemePalettePolicyEnum? paletteOverride;

  const ReauthBlurOverlay({
    required this.child,
    required this.onReauthRequested,
    this.isBlurActive,
    this.paletteOverride,
    super.key,
  });

  static bool _isShieldState(VaultSessionState state) {
    return state is VaultPendingReauthState || state is VaultLockoutCooldownState;
  }

  @override
  Widget build(BuildContext context) {
    if (isBlurActive case final explicitActive?) {
      return _buildStack(
        context: context,
        isPendingReauth: explicitActive,
        isLockout: false,
      );
    }

    final hasSessionBloc = _isSessionBlocAvailable(context);
    if (!hasSessionBloc) {
      return _buildStack(
        context: context,
        isPendingReauth: false,
        isLockout: false,
      );
    }

    return BlocListener<VaultSessionBloc, VaultSessionState>(
      listenWhen: (previous, current) =>
          _isShieldState(previous) != _isShieldState(current),
      listener: (context, state) {
        if (_isScreenPrivacyAvailable(context)) {
          final privacyCubit = context.read<ScreenPrivacyCubit>();
          if (_isShieldState(state)) {
            privacyCubit.engageSecureFlag(
              reason: ScreenPrivacyEngageReasonEnum.reauthOverlayPresented,
            );
          } else {
            privacyCubit.releaseSecureFlag(
              reason: ScreenPrivacyEngageReasonEnum.reauthOverlayPresented,
            );
          }
        }
      },
      child: BlocBuilder<VaultSessionBloc, VaultSessionState>(
        builder: (context, state) {
          final isPendingReauth = _isShieldState(state);
          final isLockout = state is VaultLockoutCooldownState;
          return _buildStack(
            context: context,
            isPendingReauth: isPendingReauth,
            isLockout: isLockout,
          );
        },
      ),
    );
  }

  Widget _buildStack({
    required BuildContext context,
    required bool isPendingReauth,
    required bool isLockout,
  }) {
    final vaultTheme = _resolveVaultTheme(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 0: Continuous underlying view (preserves scroll & input state)
        AbsorbPointer(
          key: const ValueKey('reauth_absorb_pointer'),
          absorbing: isPendingReauth,
          child: child,
        ),

        // Layer 1: Frosted glass security shield
        if (isPendingReauth)
          Positioned.fill(
            child: _ReauthFrostedShield(
              vaultTheme: vaultTheme,
              onReauthRequested: onReauthRequested,
              isLockout: isLockout,
            ),
          ),
      ],
    );
  }

  VaultThemeData _resolveVaultTheme(BuildContext context) {
    if (paletteOverride case final palette?) {
      return VaultThemeData.fromPalette(palette);
    }
    return VaultTheme.of(context);
  }

  static bool _isSessionBlocAvailable(BuildContext context) {
    try {
      context.read<VaultSessionBloc>();
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _isScreenPrivacyAvailable(BuildContext context) {
    try {
      context.read<ScreenPrivacyCubit>();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Internal frosted glass shield with exact sigma 12 blur, touch absorption, and re-auth trigger.
class _ReauthFrostedShield extends StatefulWidget {
  final VaultThemeData vaultTheme;
  final VoidCallback onReauthRequested;
  final bool isLockout;

  const _ReauthFrostedShield({
    required this.vaultTheme,
    required this.onReauthRequested,
    this.isLockout = false,
  });

  @override
  State<_ReauthFrostedShield> createState() => _ReauthFrostedShieldState();
}

class _ReauthFrostedShieldState extends State<_ReauthFrostedShield> {
  bool _isNavigating = false;

  void _handleTap() {
    if (_isNavigating || widget.isLockout) return;
    setState(() {
      _isNavigating = true;
    });
    widget.onReauthRequested();
    // Allow re-enabling after route transition completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vaultTheme = widget.vaultTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // Absorbs taps on the background so they do not penetrate to child
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            color: vaultTheme.overlayTint,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Card(
                color: vaultTheme.surface,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: VaultTheme.borderRadius8,
                  side: BorderSide(
                    color: vaultTheme.border,
                    width: VaultTheme.borderWidth,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52.0,
                        height: 52.0,
                        decoration: BoxDecoration(
                          color: vaultTheme.surfaceSubtle,
                          borderRadius: VaultTheme.borderRadius8,
                          border: Border.all(
                            color: vaultTheme.border,
                            width: VaultTheme.borderWidth,
                          ),
                        ),
                        child: Icon(
                          widget.isLockout
                              ? Icons.lock_clock
                              : Icons.lock_clock_outlined,
                          size: 28.0,
                          color: vaultTheme.textHighSalience,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        widget.isLockout
                            ? 'Security Lockout Active'
                            : 'Session Timed Out',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600,
                          color: vaultTheme.textHighSalience,
                          letterSpacing: 0.15,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        widget.isLockout
                            ? 'Multiple failed authentication attempts triggered brute-force cooldown.'
                            : 'Your vault session has timed out. Re-authenticate to access private playlists.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w400,
                          color: vaultTheme.textMediumSalience,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      if (!widget.isLockout)
                        Material(
                          color: vaultTheme.surfaceHighlight,
                          borderRadius: VaultTheme.borderRadius8,
                          child: InkWell(
                            onTap: _handleTap,
                            borderRadius: VaultTheme.borderRadius8,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14.0),
                              decoration: BoxDecoration(
                                borderRadius: VaultTheme.borderRadius8,
                                border: Border.all(
                                  color: vaultTheme.border,
                                  width: VaultTheme.borderWidth,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_open_outlined,
                                    size: 18.0,
                                    color: vaultTheme.textHighSalience,
                                  ),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    'Re-authenticate',
                                    style: TextStyle(
                                      fontFamily: VaultTheme.fontFamily,
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w600,
                                      color: vaultTheme.textHighSalience,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
