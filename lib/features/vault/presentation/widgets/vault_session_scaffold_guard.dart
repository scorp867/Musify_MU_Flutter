import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_auth_screen.dart';
import 'package:musify_mu/features/vault/presentation/widgets/reauth_blur_overlay.dart';

/// Architectural presentation scaffold guard governing all protected Secure Vault views.
///
/// Invariants:
/// 1. Universal Security Gating: Listens to [VaultSessionBloc] and automatically pops the
///    entire route stack back to the root route (`route.isFirst`) whenever the session transitions
///    out of [VaultActiveSessionState] (i.e. to [VaultLockedState], [VaultLockoutCooldownState],
///    or [VaultUninitializedState]).
/// 2. Non-Destructive Frosted Glass Shield: Wraps [child] in [ReauthBlurOverlay] to display
///    a sigma 12.0 frosted glass blur shield with touch absorption whenever the session
///    is in [VaultPendingReauthState] or [VaultLockoutCooldownState].
/// 3. Step-Up Re-Authentication Flow: Provides a default step-up modal transition or delegates
///    to an optional [onReauthRequested] callback.
class VaultSessionScaffoldGuard extends StatelessWidget {
  /// The underlying protected vault screen view to wrap and guard.
  final Widget child;

  /// Optional scoped [VaultSessionBloc] instance for testing or dependency override.
  final VaultSessionBloc? sessionBlocOverride;

  /// Optional custom callback invoked when re-authentication is tapped on the frosted shield.
  final VoidCallback? onReauthRequested;

  const VaultSessionScaffoldGuard({
    required this.child,
    this.sessionBlocOverride,
    this.onReauthRequested,
    super.key,
  });

  void _handleDefaultReauth(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => const VaultAuthScreen(
          mode: VaultAuthScreenMode.stepUp,
        ),
      ),
    );
  }

  VaultSessionBloc? _resolveSessionBloc(BuildContext context) {
    if (sessionBlocOverride case final bloc?) {
      return bloc;
    }
    try {
      return context.read<VaultSessionBloc>();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionBloc = _resolveSessionBloc(context);

    final guardedContent = ReauthBlurOverlay(
      onReauthRequested: switch (onReauthRequested) {
        final callback? => callback,
        null => () => _handleDefaultReauth(context),
      },
      child: child,
    );

    if (sessionBloc == null) {
      return guardedContent;
    }

    return BlocListener<VaultSessionBloc, VaultSessionState>(
      bloc: sessionBloc,
      listenWhen: (previous, current) => current is! VaultActiveSessionState,
      listener: (context, state) {
        if (context.mounted) {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.popUntil((route) => route.isFirst);
          }
        }
      },
      child: guardedContent,
    );
  }
}
