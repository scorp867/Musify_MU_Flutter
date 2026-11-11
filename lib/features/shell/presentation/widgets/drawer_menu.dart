import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/application/auth_event.dart';
import 'package:musify_mu/features/auth/domain/entities/auth_state.dart';
import 'package:musify_mu/features/player/presentation/screens/debug_now_playing_screen.dart';
import 'package:musify_mu/features/vault/application/coordinator/vault_coordinator.dart';
import 'package:musify_mu/features/vault/application/gesture/gesture_engine_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
import 'package:musify_mu/features/vault/data/services/gesture_recognizer_service.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/states/settings_mutation_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/presentation/widgets/stealth_gesture_pad.dart';

class DrawerMenu extends StatefulWidget {
  final VoidCallback? onVaultGestureMatched;
  final IGestureRecognizer? gestureRecognizer;
  final GestureTemplate? gestureTemplate;
  final GestureSensitivityTierEnum gestureSensitivityTier;
  final GestureVisibilityPolicyEnum gestureVisibilityPolicy;
  final VaultSessionBloc? vaultSessionBloc;
  final GestureEngineCubit? gestureEngineCubit;
  final SettingsMutationCubit? settingsMutationCubit;
  final VaultCoordinator? vaultCoordinator;

  static final IGestureRecognizer _sharedRecognizer =
      GestureRecognizerService();

  const DrawerMenu({
    super.key,
    this.onVaultGestureMatched,
    this.gestureRecognizer,
    this.gestureTemplate,
    this.gestureSensitivityTier = GestureSensitivityTierEnum.balanced84Percent,
    this.gestureVisibilityPolicy = GestureVisibilityPolicyEnum.invisibleStealth,
    this.vaultSessionBloc,
    this.gestureEngineCubit,
    this.settingsMutationCubit,
    this.vaultCoordinator,
  });

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
          builder: (context, authState) {
            final user =
                authState is Authenticated ? authState.user : null;
            final displayName = user?.displayName ?? 'Musify';
            final handle = user != null ? '@${user.id}' : 'Offline Mode';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(user?.avatarUrl, displayName),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  handle,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 48),
                const _DrawerMenuItem(
                    icon: Icons.person, title: 'Profile'),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DebugNowPlayingScreen(),
                      ),
                    );
                  },
                  child: const _DrawerMenuItem(
                      icon: Icons.bug_report, title: 'Debug: NowPlaying'),
                ),
                const _DrawerMenuItem(
                    icon: Icons.history,
                    title: 'Listening History'),
                const _DrawerMenuItem(
                    icon: Icons.headset, title: 'Equalizer'),
                Expanded(
                  child: _buildStealthGesturePad(context),
                ),
                if (user != null)
                  GestureDetector(
                    onTap: () => context
                        .read<AuthBloc>()
                        .add(const AuthLogoutRequested()),
                    child: const _DrawerMenuItem(
                      icon: Icons.logout,
                      title: 'Log Out',
                      color: Color(0xFFF97316),
                    ),
                  )
                else
                  const _DrawerMenuItem(
                    icon: Icons.login,
                    title: 'Connect Spotify',
                    color: Color(0xFF1DB954),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStealthGesturePad(BuildContext context) {
    final gestureEngine = _resolveGestureEngine(context);
    final settingsCubit = _resolveSettingsMutation(context);

    // If both cubits are in context, rebuild dynamically on configuration mutations.
    if (settingsCubit != null) {
      return BlocBuilder<SettingsMutationCubit, SettingsMutationState>(
        bloc: settingsCubit,
        builder: (context, _) {
          return _buildConfiguredPad(context, gestureEngine, settingsCubit);
        },
      );
    }

    return _buildConfiguredPad(context, gestureEngine, settingsCubit);
  }

  Widget _buildConfiguredPad(
    BuildContext context,
    GestureEngineCubit? gestureEngine,
    SettingsMutationCubit? settingsCubit,
  ) {
    final activeConfig = settingsCubit?.currentConfig;

    final template = widget.gestureTemplate ??
        gestureEngine?.activeTemplate ??
        DefaultGestureTemplate.canonicalVShape;

    final sensitivity = widget.gestureSensitivityTier != GestureSensitivityTierEnum.balanced84Percent
        ? widget.gestureSensitivityTier
        : (gestureEngine?.sensitivityTier ??
            activeConfig?.gestureSensitivity ??
            GestureSensitivityTierEnum.balanced84Percent);

    final visibility = widget.gestureVisibilityPolicy != GestureVisibilityPolicyEnum.invisibleStealth
        ? widget.gestureVisibilityPolicy
        : (activeConfig?.gestureVisibility ??
            GestureVisibilityPolicyEnum.invisibleStealth);

    final recognizer = widget.gestureRecognizer ??
        (GetIt.I.isRegistered<IGestureRecognizer>()
            ? GetIt.I<IGestureRecognizer>()
            : DrawerMenu._sharedRecognizer);

    return StealthGesturePad(
      onGestureMatched: () => _handleVaultGestureMatched(context),
      recognizer: recognizer,
      activeTemplate: template,
      sensitivityTier: sensitivity,
      visibilityPolicy: visibility,
    );
  }

  Widget _buildAvatar(String? avatarUrl, String displayName) {
    if (avatarUrl != null) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: const Color(0xFF1E293B),
        backgroundImage: CachedNetworkImageProvider(
          avatarUrl,
          maxWidth: 160,
          maxHeight: 160,
        ),
      );
    }

    return CircleAvatar(
      radius: 40,
      backgroundColor: const Color(0xFF3B82F6),
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
      ),
    );
  }

  VaultSessionBloc? _resolveVaultSessionBloc(BuildContext context) {
    if (widget.vaultSessionBloc != null) {
      return widget.vaultSessionBloc;
    }
    try {
      return context.read<VaultSessionBloc>();
    } catch (_) {
      return null;
    }
  }

  GestureEngineCubit? _resolveGestureEngine(BuildContext context) {
    if (widget.gestureEngineCubit != null) {
      return widget.gestureEngineCubit;
    }
    try {
      return context.read<GestureEngineCubit>();
    } catch (_) {
      return null;
    }
  }

  SettingsMutationCubit? _resolveSettingsMutation(BuildContext context) {
    if (widget.settingsMutationCubit != null) {
      return widget.settingsMutationCubit;
    }
    try {
      return context.read<SettingsMutationCubit>();
    } catch (_) {
      return null;
    }
  }

  VaultCoordinator? _resolveVaultCoordinator(BuildContext context) {
    if (widget.vaultCoordinator != null) {
      return widget.vaultCoordinator;
    }
    try {
      return context.read<VaultCoordinator>();
    } catch (_) {
      return null;
    }
  }

  void _handleVaultGestureMatched(BuildContext context) {
    if (widget.onVaultGestureMatched != null) {
      widget.onVaultGestureMatched!();
      return;
    }

    if (_isNavigating) {
      return;
    }

    _isNavigating = true;

    // Delegate navigation strictly to the VaultCoordinator SSOT when available.
    final coordinator = _resolveVaultCoordinator(context);
    if (coordinator != null) {
      coordinator.onStealthGestureTriggered(context);
      _isNavigating = false;
      return;
    }

    final sessionBloc = _resolveVaultSessionBloc(context);
    final currentState = sessionBloc?.state;
    final navigator = Navigator.of(context, rootNavigator: true);

    try {
      if (currentState is VaultActiveSessionState) {
        // Session already active: go directly to dashboard.
        navigator.pushNamed<dynamic>('/vault/dashboard').whenComplete(() {
          if (mounted) {
            setState(() {
              _isNavigating = false;
            });
          }
        });
      } else if (currentState is VaultUninitializedState) {
        // No vault provisioned: route to first-time setup, then dashboard.
        sessionBloc?.add(const VaultSetupRequested());
        navigator.pushNamed<dynamic>('/vault/setup').then((setupResult) {
          if (setupResult == true && mounted) {
            navigator
                .pushNamed<dynamic>('/vault/dashboard')
                .whenComplete(() {
              if (mounted) {
                setState(() {
                  _isNavigating = false;
                });
              }
            });
          } else {
            if (mounted) {
              setState(() {
                _isNavigating = false;
              });
            }
          }
        }).catchError((_) {
          if (mounted) {
            setState(() {
              _isNavigating = false;
            });
          }
        });
      } else {
        // Vault is locked (or authenticating/lockout): route to auth, then dashboard.
        navigator.pushNamed<dynamic>('/vault/auth').then((unlocked) {
          if (unlocked == true && mounted) {
            navigator
                .pushNamed<dynamic>('/vault/dashboard')
                .whenComplete(() {
              if (mounted) {
                setState(() {
                  _isNavigating = false;
                });
              }
            });
          } else {
            if (mounted) {
              setState(() {
                _isNavigating = false;
              });
            }
          }
        }).catchError((_) {
          if (mounted) {
            setState(() {
              _isNavigating = false;
            });
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
