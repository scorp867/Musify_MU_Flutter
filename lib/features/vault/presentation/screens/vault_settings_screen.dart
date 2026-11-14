// ignore_for_file: prefer_conditional_assignment

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/app/routes/vault_routes.dart';
import 'package:musify_mu/features/vault/application/gesture/gesture_engine_cubit.dart';
import 'package:musify_mu/features/vault/application/pin_pad/pin_pad_cubit.dart';
import 'package:musify_mu/features/vault/application/screen_privacy/screen_privacy_cubit.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/active_reauth_interval.dart';
import 'package:musify_mu/features/vault/domain/policies/background_grace_timeout.dart';
import 'package:musify_mu/features/vault/domain/policies/biometric_auth_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/keypad_layout_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/lock_playback_behavior.dart';
import 'package:musify_mu/features/vault/domain/policies/metadata_visibility_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/screen_security_policy.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/screen_privacy_state.dart';
import 'package:musify_mu/features/vault/domain/states/settings_mutation_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/purge_vault_data_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/rotate_pin_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';
import 'package:musify_mu/features/vault/presentation/screens/gesture_enrollment_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_auth_screen.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';
import 'package:musify_mu/features/vault/presentation/widgets/vault_settings_components.dart';
import 'package:musify_mu/features/vault/presentation/widgets/vault_session_scaffold_guard.dart';

/// Reusable Step-Up Authentication Guard enforcing full-screen [VaultAuthScreen] verification
/// for sensitive configuration mutations (biometrics, PIN rotation, gesture re-enrollment, vault purge).
///
/// Strictly bans modal bottom sheets and popup alert dialogs.
class StepUpAuthGuard {
  static Future<bool> executeWithGuard({
    required BuildContext context,
    required SensitiveSettingMutationEnum mutationType,
    required Future<void> Function() onAuthorized,
    String? customTitle,
    SettingsMutationCubit? mutationCubitOverride,
    VaultSessionBloc? sessionBlocOverride,
    ScreenPrivacyCubit? screenPrivacyCubitOverride,
  }) async {
    final mutationCubit = switch (mutationCubitOverride) {
      final cubit? => cubit,
      null => _resolveContextDependency<SettingsMutationCubit>(context),
    };
    final sessionBloc = switch (sessionBlocOverride) {
      final bloc? => bloc,
      null => _resolveContextDependency<VaultSessionBloc>(context),
    };
    final screenPrivacyCubit = switch (screenPrivacyCubitOverride) {
      final cubit? => cubit,
      null => _resolveContextDependency<ScreenPrivacyCubit>(context),
    };

    if (mutationCubit == null) {
      return false;
    }

    await mutationCubit.requestSensitiveMutation(mutationType: mutationType);

    final mode = switch (mutationType) {
      SensitiveSettingMutationEnum.vaultDataPurge =>
        VaultAuthScreenMode.purgeConfirmation,
      SensitiveSettingMutationEnum.pinRotation =>
        VaultAuthScreenMode.verifyOldPin,
      SensitiveSettingMutationEnum.biometricPolicyChange =>
        VaultAuthScreenMode.stepUp,
      SensitiveSettingMutationEnum.gestureReEnrollment =>
        VaultAuthScreenMode.stepUp,
      SensitiveSettingMutationEnum.securityTimeoutChange =>
        VaultAuthScreenMode.stepUp,
      SensitiveSettingMutationEnum.generalConfigUpdate =>
        VaultAuthScreenMode.stepUp,
    };

    if (!context.mounted) {
      mutationCubit.cancelSensitiveMutation(mutationType: mutationType);
      return false;
    }

    final authSuccess = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VaultAuthScreen(
          mode: mode,
          titleOverride: customTitle,
          sessionBloc: sessionBloc,
          screenPrivacyCubit: screenPrivacyCubit,
        ),
      ),
    );

    if (authSuccess == true) {
      await mutationCubit.confirmSensitiveMutation(
        mutationType: mutationType,
        onExecute: onAuthorized,
      );
      return true;
    } else {
      mutationCubit.cancelSensitiveMutation(mutationType: mutationType);
      return false;
    }
  }

  static T? _resolveContextDependency<T extends Object>(BuildContext context) {
    try {
      return context.read<T>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}

/// Central Hub Screen for Musify Secure Vault Settings.
///
/// Per the architectural directive:
/// Instead of tabbed views in a single screen, every section has its own dedicated
/// full-screen [Scaffold] route:
/// 1. [VaultAppearanceSettingsScreen]
/// 2. [VaultSecuritySettingsScreen]
/// 3. [VaultPrivacySettingsScreen]
/// 4. [VaultGestureSettingsScreen]
/// 5. [VaultDangerZoneScreen]
///
/// Features:
/// - Top bar with back navigation, status badge, and quick-lock button.
/// - 5 stylized section navigation cards with tone-on-tone borders and 8px geometric radius.
/// - Full-screen FLAG_SECURE window protection.
class VaultSettingsScreen extends StatefulWidget {
  final SettingsMutationCubit? settingsMutationCubit;
  final VaultSessionBloc? sessionBloc;
  final ScreenPrivacyCubit? screenPrivacyCubit;
  final GestureEngineCubit? gestureEngineCubit;
  final IVaultStorageRepository? storageRepository;
  final IVaultAuthService? authService;
  final RotatePinUseCase? rotatePinUseCase;
  final PurgeVaultDataUseCase? purgeVaultDataUseCase;
  final UnlockVaultUseCase? unlockVaultUseCase;
  final IMonotonicClock? monotonicClock;
  final VoidCallback? onBack;
  final VoidCallback? onGestureReEnrollmentPressed;
  final VoidCallback? onPinRotationPressed;
  final VoidCallback? onPurgePressed;

  const VaultSettingsScreen({
    this.settingsMutationCubit,
    this.sessionBloc,
    this.screenPrivacyCubit,
    this.gestureEngineCubit,
    this.storageRepository,
    this.authService,
    this.rotatePinUseCase,
    this.purgeVaultDataUseCase,
    this.unlockVaultUseCase,
    this.monotonicClock,
    this.onBack,
    this.onGestureReEnrollmentPressed,
    this.onPinRotationPressed,
    this.onPurgePressed,
    super.key,
  });

  @override
  State<VaultSettingsScreen> createState() => _VaultSettingsScreenState();
}

class _VaultSettingsScreenState extends State<VaultSettingsScreen> {
  ScreenPrivacyCubit? _screenPrivacyCubit;

  @override
  void initState() {
    super.initState();
    _engageScreenPrivacy();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_screenPrivacyCubit == null) {
      _screenPrivacyCubit = _resolveScreenPrivacyCubit();
    }
  }

  void _engageScreenPrivacy() {
    if (_screenPrivacyCubit == null) {
      _screenPrivacyCubit = _resolveScreenPrivacyCubit();
    }
    _screenPrivacyCubit?.engageSecureFlag(
      reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
    );
  }

  void _releaseScreenPrivacy() {
    final cubit = _screenPrivacyCubit;
    if (cubit != null && !cubit.isClosed) {
      cubit.releaseSecureFlag(
        reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
      );
    }
  }

  ScreenPrivacyCubit? _resolveScreenPrivacyCubit() {
    if (widget.screenPrivacyCubit case final cubit?) {
      return cubit;
    }
    if (!mounted) return _screenPrivacyCubit;
    try {
      return context.read<ScreenPrivacyCubit>();
    } catch (_) {
      return _screenPrivacyCubit;
    }
  }

  SettingsMutationCubit? _resolveSettingsCubit() {
    if (widget.settingsMutationCubit case final cubit?) {
      return cubit;
    }
    if (!mounted) return null;
    try {
      return context.read<SettingsMutationCubit>();
    } catch (_) {
      return null;
    }
  }

  VaultSessionBloc? _resolveSessionBloc() {
    if (widget.sessionBloc case final bloc?) {
      return bloc;
    }
    if (!mounted) return null;
    try {
      return context.read<VaultSessionBloc>();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _releaseScreenPrivacy();
    super.dispose();
  }

  void _handleQuickLock() {
    final sessionBloc = _resolveSessionBloc();
    sessionBloc?.add(
      const VaultQuickLockRequested(reason: 'Settings Quick Lock'),
    );
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _navigateToSection(String routeName, Widget fallbackScreen) {
    final nav = Navigator.of(context);
    try {
      nav.pushNamed(routeName);
    } catch (_) {
      final cubit = _resolveSettingsCubit();
      final theme = VaultTheme.of(context);
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) {
            if (cubit != null) {
              return BlocBuilder<SettingsMutationCubit, SettingsMutationState>(
                bloc: cubit,
                builder: (context, _) {
                  return VaultTheme(
                    data: VaultThemeData.fromConfig(cubit.currentConfig),
                    child: fallbackScreen,
                  );
                },
              );
            }
            return VaultTheme(
              data: theme,
              child: fallbackScreen,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultTheme = VaultTheme.of(context);
    final settingsCubit = _resolveSettingsCubit();

    final content = Scaffold(
      key: const ValueKey('vault_settings_scaffold'),
      backgroundColor: vaultTheme.scaffold,
      appBar: buildVaultSettingsAppBar(
        vaultTheme: vaultTheme,
        title: 'Vault Settings',
        backButtonKey: const ValueKey('vault_settings_back_button'),
        onBackPressed: () {
          widget.onBack?.call();
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        actions: [
          IconButton(
            key: const ValueKey('vault_settings_quick_lock_button'),
            icon: Icon(
              Icons.lock_outline_rounded,
              size: 21.0,
              color: vaultTheme.textHighSalience,
            ),
            tooltip: 'Lock Vault Now',
            onPressed: _handleQuickLock,
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 32.0),
          children: [
            VaultSettingsSectionHeader(
              title: 'Preferences',
              vaultTheme: vaultTheme,
            ),
            VaultSettingsGroup(
              vaultTheme: vaultTheme,
              dividerInset: 64.0,
              children: [
                VaultSettingsNavRow(
                  key: const ValueKey('nav_tile_appearance'),
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  subtitle: 'Theme palette and blur intensity',
                  vaultTheme: vaultTheme,
                  onTap: () => _navigateToSection(
                    VaultRoutes.settingsAppearance,
                    VaultAppearanceSettingsScreen(
                      settingsMutationCubit: widget.settingsMutationCubit,
                      sessionBloc: widget.sessionBloc,
                      screenPrivacyCubit: widget.screenPrivacyCubit,
                    ),
                  ),
                ),
                VaultSettingsNavRow(
                  key: const ValueKey('nav_tile_security'),
                  icon: Icons.shield_outlined,
                  title: 'Security & Authentication',
                  subtitle: 'Biometrics, lock timers, keypad, and PIN',
                  vaultTheme: vaultTheme,
                  onTap: () => _navigateToSection(
                    VaultRoutes.settingsSecurity,
                    VaultSecuritySettingsScreen(
                      settingsMutationCubit: widget.settingsMutationCubit,
                      sessionBloc: widget.sessionBloc,
                      screenPrivacyCubit: widget.screenPrivacyCubit,
                      authService: widget.authService,
                      rotatePinUseCase: widget.rotatePinUseCase,
                      unlockVaultUseCase: widget.unlockVaultUseCase,
                      monotonicClock: widget.monotonicClock,
                      onPinRotationPressed: widget.onPinRotationPressed,
                    ),
                  ),
                ),
                VaultSettingsNavRow(
                  key: const ValueKey('nav_tile_privacy'),
                  icon: Icons.visibility_off_outlined,
                  title: 'Playback & Privacy',
                  subtitle:
                      'Screen capture blocking, masking, and decoy track',
                  vaultTheme: vaultTheme,
                  onTap: () => _navigateToSection(
                    VaultRoutes.settingsPrivacy,
                    VaultPrivacySettingsScreen(
                      settingsMutationCubit: widget.settingsMutationCubit,
                      sessionBloc: widget.sessionBloc,
                      screenPrivacyCubit: widget.screenPrivacyCubit,
                    ),
                  ),
                ),
                VaultSettingsNavRow(
                  key: const ValueKey('nav_tile_gestures'),
                  icon: Icons.gesture_rounded,
                  title: 'Gesture Controls',
                  subtitle: 'Recognition sensitivity, stroke trail, and reset',
                  vaultTheme: vaultTheme,
                  onTap: () => _navigateToSection(
                    VaultRoutes.settingsGesture,
                    VaultGestureSettingsScreen(
                      settingsMutationCubit: widget.settingsMutationCubit,
                      sessionBloc: widget.sessionBloc,
                      screenPrivacyCubit: widget.screenPrivacyCubit,
                      gestureEngineCubit: widget.gestureEngineCubit,
                      onGestureReEnrollmentPressed:
                          widget.onGestureReEnrollmentPressed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            VaultSettingsSectionHeader(
              title: 'Data & Recovery',
              vaultTheme: vaultTheme,
            ),
            VaultSettingsGroup(
              vaultTheme: vaultTheme,
              borderColor: vaultTheme.danger.withValues(alpha: 0.45),
              children: [
                VaultSettingsNavRow(
                  key: const ValueKey('nav_tile_danger_zone'),
                  icon: Icons.delete_forever_outlined,
                  title: 'Danger Zone',
                  subtitle: 'Erase encryption keys and delete stored media',
                  vaultTheme: vaultTheme,
                  isDanger: true,
                  onTap: () => _navigateToSection(
                    VaultRoutes.settingsDanger,
                    VaultDangerZoneScreen(
                      settingsMutationCubit: widget.settingsMutationCubit,
                      sessionBloc: widget.sessionBloc,
                      screenPrivacyCubit: widget.screenPrivacyCubit,
                      purgeVaultDataUseCase: widget.purgeVaultDataUseCase,
                      unlockVaultUseCase: widget.unlockVaultUseCase,
                      authService: widget.authService,
                      monotonicClock: widget.monotonicClock,
                      onPurgePressed: widget.onPurgePressed,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (settingsCubit != null) {
      return BlocConsumer<SettingsMutationCubit, SettingsMutationState>(
        bloc: settingsCubit,
        listener: (context, state) {
          switch (state) {
            case SettingsMutationSyncedIdleState():
              break;
            case SettingsMutationAwaitingStepUpAuthState():
              break;
            case SettingsMutationPersistingConfigState():
              break;
            case SettingsMutationMutationRejectedState(:final rejectionReason):
              showVaultSettingsSnackBar(
                context,
                vaultTheme,
                message: rejectionReason,
                isError: true,
              );
          }
        },
        builder: (context, state) => VaultSessionScaffoldGuard(
          sessionBlocOverride: _resolveSessionBloc(),
          child: content,
        ),
      );
    }

    return VaultSessionScaffoldGuard(
      sessionBlocOverride: _resolveSessionBloc(),
      child: content,
    );
  }
}

// =============================================================================
// 1. DEDICATED SCREEN: APPEARANCE
// =============================================================================

/// Dedicated full-screen route for Vault Appearance & Theme settings.
class VaultAppearanceSettingsScreen extends StatefulWidget {
  final SettingsMutationCubit? settingsMutationCubit;
  final VaultSessionBloc? sessionBloc;
  final ScreenPrivacyCubit? screenPrivacyCubit;

  const VaultAppearanceSettingsScreen({
    this.settingsMutationCubit,
    this.sessionBloc,
    this.screenPrivacyCubit,
    super.key,
  });

  @override
  State<VaultAppearanceSettingsScreen> createState() =>
      _VaultAppearanceSettingsScreenState();
}

class _VaultAppearanceSettingsScreenState
    extends State<VaultAppearanceSettingsScreen> {
  double _previewBlurSigma = VaultConfig.defaultFrostedBlurSigma;
  bool _isDraggingBlur = false;
  double? _pendingPersistedBlur;
  StreamSubscription<VaultConfig>? _configSub;
  SettingsMutationCubit? _boundSettingsCubit;
  ScreenPrivacyCubit? _screenPrivacyCubit;

  @override
  void initState() {
    super.initState();
    _engageScreenPrivacy();
    _syncSettingsCubit(widget.settingsMutationCubit);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_screenPrivacyCubit == null) {
      _screenPrivacyCubit = _resolveScreenPrivacyCubit();
    }
    _syncSettingsCubit(_resolveSettingsCubit());
  }

  @override
  void didUpdateWidget(covariant VaultAppearanceSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settingsMutationCubit != widget.settingsMutationCubit) {
      _syncSettingsCubit(_resolveSettingsCubit());
    }
  }

  void _syncSettingsCubit(SettingsMutationCubit? cubit) {
    if (identical(_boundSettingsCubit, cubit)) return;
    _configSub?.cancel();
    _configSub = null;
    _boundSettingsCubit = cubit;
    if (cubit != null) {
      _previewBlurSigma = cubit.currentConfig.frostedBlurSigma;
      _configSub = cubit.configStream.listen((config) {
        if (!mounted) return;
        final pending = _pendingPersistedBlur;
        if (pending != null && (config.frostedBlurSigma - pending).abs() < 0.01) {
          setState(() {
            _pendingPersistedBlur = null;
            _previewBlurSigma = config.frostedBlurSigma;
          });
          return;
        }
        if (!_isDraggingBlur &&
            _pendingPersistedBlur == null &&
            config.frostedBlurSigma != _previewBlurSigma) {
          setState(() {
            _previewBlurSigma = config.frostedBlurSigma;
          });
        }
      });
    }
  }

  void _engageScreenPrivacy() {
    if (_screenPrivacyCubit == null) {
      _screenPrivacyCubit = _resolveScreenPrivacyCubit();
    }
    _screenPrivacyCubit?.engageSecureFlag(
      reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
    );
  }

  void _releaseScreenPrivacy() {
    final cubit = _screenPrivacyCubit;
    if (cubit != null && !cubit.isClosed) {
      cubit.releaseSecureFlag(
        reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
      );
    }
  }

  ScreenPrivacyCubit? _resolveScreenPrivacyCubit() {
    if (widget.screenPrivacyCubit case final cubit?) {
      return cubit;
    }
    if (!mounted) return _screenPrivacyCubit;
    try {
      return context.read<ScreenPrivacyCubit>();
    } catch (_) {
      return _screenPrivacyCubit;
    }
  }

  SettingsMutationCubit? _resolveSettingsCubit() {
    if (widget.settingsMutationCubit case final cubit?) {
      return cubit;
    }
    if (!mounted) return null;
    try {
      return context.read<SettingsMutationCubit>();
    } catch (_) {
      return null;
    }
  }

  VaultSessionBloc? _resolveSessionBloc() {
    if (widget.sessionBloc case final bloc?) {
      return bloc;
    }
    if (!mounted) return null;
    try {
      return context.read<VaultSessionBloc>();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _configSub?.cancel();
    _configSub = null;
    _releaseScreenPrivacy();
    super.dispose();
  }

  Future<void> _commitBlurSigma(
    SettingsMutationCubit? cubit,
    double targetSigma,
  ) async {
    final clamped = _boundBlurSigma(targetSigma);
    setState(() {
      _isDraggingBlur = false;
      _previewBlurSigma = clamped;
      if (cubit != null) {
        _pendingPersistedBlur = clamped;
      }
    });
    if (cubit == null) return;
    final ok = await cubit.mutatePolicy(
      (c) => c.copyWith(frostedBlurSigma: clamped),
    );
    if (!mounted) return;
    setState(() {
      _pendingPersistedBlur = null;
      _previewBlurSigma = ok ? clamped : cubit.currentConfig.frostedBlurSigma;
    });
  }

  double _boundBlurSigma(double value) {
    if (value < VaultConfig.minFrostedBlurSigma) {
      return VaultConfig.minFrostedBlurSigma;
    }
    if (value > VaultConfig.maxFrostedBlurSigma) {
      return VaultConfig.maxFrostedBlurSigma;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _resolveSettingsCubit();

    Widget buildScaffold(BuildContext context, VaultConfig currentConfig) {
      final vaultTheme = VaultTheme.of(context);
      final activeBlurSigma = (_isDraggingBlur ||
              _pendingPersistedBlur != null ||
              cubit == null)
          ? _previewBlurSigma
          : currentConfig.frostedBlurSigma;

      return VaultSessionScaffoldGuard(
        sessionBlocOverride: _resolveSessionBloc(),
        child: Scaffold(
          key: const ValueKey('vault_appearance_screen'),
          backgroundColor: vaultTheme.scaffold,
          appBar: buildVaultSettingsAppBar(
            vaultTheme: vaultTheme,
            title: 'Appearance',
            backButtonKey: const ValueKey('vault_appearance_back_button'),
            onBackPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 32.0),
              children: [
                VaultSettingsSectionHeader(
                  title: 'Theme Palette',
                  vaultTheme: vaultTheme,
                ),
                _buildPaletteSelector(currentConfig, cubit, vaultTheme),
                VaultSettingsFootnote(
                  text: 'Applied across every private vault screen and overlay.',
                  vaultTheme: vaultTheme,
                ),
                const SizedBox(height: 24.0),
                VaultSettingsSectionHeader(
                  title: 'Privacy Overlay',
                  vaultTheme: vaultTheme,
                ),
                VaultSettingsGroup(
                  vaultTheme: vaultTheme,
                  dividerInset: 0.0,
                  children: [
                    _buildBlurPreviewMockup(vaultTheme, activeBlurSigma),
                    _buildBlurSlider(cubit, vaultTheme, activeBlurSigma),
                  ],
                ),
                VaultSettingsFootnote(
                  text:
                      'Adjusts background blur intensity behind album artwork previews and session lock shields.',
                  vaultTheme: vaultTheme,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (cubit != null) {
      return StreamBuilder<VaultConfig>(
        stream: cubit.configStream,
        initialData: cubit.currentConfig,
        builder: (context, snapshot) {
          final config = switch (snapshot.data) {
            final c? => c,
            null => cubit.currentConfig,
          };
          final themeData = VaultThemeData.fromConfig(config);
          return VaultTheme(
            data: themeData,
            child: Builder(
              builder: (innerCtx) => buildScaffold(innerCtx, config),
            ),
          );
        },
      );
    }

    return buildScaffold(context, const VaultConfig.constant());
  }

  Widget _buildPaletteSelector(
    VaultConfig currentConfig,
    SettingsMutationCubit? cubit,
    VaultThemeData vaultTheme,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildPaletteCard(
            key: const ValueKey('palette_warm_espresso'),
            previewTheme: VaultThemeData.fromPalette(
              VaultThemePalettePolicyEnum.warmEspresso,
            ),
            title: 'Warm Espresso',
            subtitle: 'Roasted umber & sand',
            swatches: const [
              Color(0xFF120E0C),
              Color(0xFF231C18),
              Color(0xFFD6B48E),
              Color(0xFFECE6E0),
            ],
            isSelected: currentConfig.themePalette ==
                VaultThemePalettePolicyEnum.warmEspresso,
            activeTheme: vaultTheme,
            onTap: () {
              cubit?.mutatePolicy(
                (current) => current.copyWith(
                  themePalette: VaultThemePalettePolicyEnum.warmEspresso,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: _buildPaletteCard(
            key: const ValueKey('palette_forest_noir'),
            previewTheme: VaultThemeData.fromPalette(
              VaultThemePalettePolicyEnum.forestNoir,
            ),
            title: 'Forest Noir',
            subtitle: 'Deep pine & sage',
            swatches: const [
              Color(0xFF0B120E),
              Color(0xFF1A2821),
              Color(0xFF9BC2AA),
              Color(0xFFE3EBE6),
            ],
            isSelected: currentConfig.themePalette ==
                VaultThemePalettePolicyEnum.forestNoir,
            activeTheme: vaultTheme,
            onTap: () {
              cubit?.mutatePolicy(
                (current) => current.copyWith(
                  themePalette: VaultThemePalettePolicyEnum.forestNoir,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaletteCard({
    required Key key,
    required VaultThemeData previewTheme,
    required String title,
    required String subtitle,
    required List<Color> swatches,
    required bool isSelected,
    required VaultThemeData activeTheme,
    required VoidCallback onTap,
  }) {
    return DecoratedBox(
      key: key,
      decoration: BoxDecoration(
        color: isSelected
            ? activeTheme.surfaceHighlight.withValues(alpha: 0.7)
            : activeTheme.surfaceSubtle,
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: isSelected ? activeTheme.accent : activeTheme.border,
          width: isSelected ? 1.5 : VaultTheme.borderWidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: VaultTheme.borderRadius8,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mini live UI canvas preview for the candidate theme
                Container(
                  height: 76.0,
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: previewTheme.scaffold,
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: previewTheme.borderSubtle,
                      width: VaultTheme.borderWidth,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 18.0,
                            height: 4.0,
                            decoration: BoxDecoration(
                              color: previewTheme.textHighSalience,
                              borderRadius: BorderRadius.circular(2.0),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 6.0,
                            height: 6.0,
                            decoration: BoxDecoration(
                              color: previewTheme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(6.0),
                        decoration: BoxDecoration(
                          color: previewTheme.surface,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 14.0,
                              height: 14.0,
                              decoration: BoxDecoration(
                                color: previewTheme.surfaceHighlight,
                                borderRadius: BorderRadius.circular(3.0),
                              ),
                            ),
                            const SizedBox(width: 6.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 3.5,
                                    width: 44.0,
                                    decoration: BoxDecoration(
                                      color: previewTheme.textHighSalience,
                                      borderRadius: BorderRadius.circular(2.0),
                                    ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Container(
                                    height: 3.0,
                                    width: 28.0,
                                    decoration: BoxDecoration(
                                      color: previewTheme.textMediumSalience,
                                      borderRadius: BorderRadius.circular(2.0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 13.5,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? activeTheme.accent
                              : activeTheme.textHighSalience,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Container(
                      width: 18.0,
                      height: 18.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? activeTheme.accent
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? activeTheme.accent
                              : activeTheme.textLowSalience,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              size: 12.0,
                              color: activeTheme.scaffold,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 2.0),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 11.5,
                    color: activeTheme.textMediumSalience,
                  ),
                ),
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    for (final color in swatches)
                      Container(
                        width: 16.0,
                        height: 16.0,
                        margin: const EdgeInsets.only(right: 5.0),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: activeTheme.border,
                            width: VaultTheme.borderWidth,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlurSlider(
    SettingsMutationCubit? cubit,
    VaultThemeData vaultTheme,
    double activeBlurSigma,
  ) {
    final boundedValue = _boundBlurSigma(activeBlurSigma);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14.0, 14.0, 14.0, 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Blur Intensity',
                style: TextStyle(
                  fontFamily: VaultTheme.fontFamily,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  color: vaultTheme.textHighSalience,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: vaultTheme.surfaceHighlight,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  '${boundedValue.toStringAsFixed(1)} px',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: vaultTheme.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
              activeTrackColor: vaultTheme.accent,
              inactiveTrackColor: vaultTheme.surfaceHighlight,
              thumbColor: vaultTheme.accent,
              overlayColor: vaultTheme.accent.withValues(alpha: 0.16),
            ),
            child: Slider(
              key: const ValueKey('blur_slider'),
              value: boundedValue,
              min: VaultConfig.minFrostedBlurSigma,
              max: VaultConfig.maxFrostedBlurSigma,
              onChanged: (val) {
                setState(() {
                  _isDraggingBlur = true;
                  _previewBlurSigma = val;
                });
              },
              onChangeEnd: (val) => _commitBlurSigma(cubit, val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurPreviewMockup(
    VaultThemeData vaultTheme,
    double activeBlurSigma,
  ) {
    return SizedBox(
      key: const ValueKey('blur_preview_container'),
      height: 144.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(
            child: ColoredBox(color: Colors.transparent),
          ),
          Positioned.fill(
            child: ColoredBox(color: vaultTheme.background),
          ),
          RepaintBoundary(
            child: ImageFiltered(
              enabled: activeBlurSigma > 0.0,
              imageFilter: ImageFilter.blur(
                sigmaX: activeBlurSigma,
                sigmaY: activeBlurSigma,
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Container(
                      width: 56.0,
                      height: 56.0,
                      decoration: BoxDecoration(
                        color: vaultTheme.surfaceHighlight,
                        borderRadius: VaultTheme.borderRadius8,
                      ),
                      child: Icon(
                        Icons.music_note_rounded,
                        color: vaultTheme.accent.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 10.0,
                            width: 132.0,
                            decoration: BoxDecoration(
                              color: vaultTheme.textHighSalience
                                  .withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Container(
                            height: 8.0,
                            width: 88.0,
                            decoration: BoxDecoration(
                              color: vaultTheme.accent.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(color: vaultTheme.overlayTint),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38.0,
                height: 38.0,
                decoration: BoxDecoration(
                  color: vaultTheme.surface,
                  borderRadius: VaultTheme.borderRadius8,
                  border: Border.all(
                    color: vaultTheme.border,
                    width: VaultTheme.borderWidth,
                  ),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 19.0,
                  color: vaultTheme.accent,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Private Media Shielded',
                style: TextStyle(
                  fontFamily: VaultTheme.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: vaultTheme.textHighSalience,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2. DEDICATED SCREEN: SECURITY & AUTHENTICATION
// =============================================================================

/// Dedicated full-screen route for Vault Security & Authentication settings.
class VaultSecuritySettingsScreen extends StatefulWidget {
  final SettingsMutationCubit? settingsMutationCubit;
  final VaultSessionBloc? sessionBloc;
  final ScreenPrivacyCubit? screenPrivacyCubit;
  final IVaultAuthService? authService;
  final RotatePinUseCase? rotatePinUseCase;
  final UnlockVaultUseCase? unlockVaultUseCase;
  final IMonotonicClock? monotonicClock;
  final VoidCallback? onPinRotationPressed;

  const VaultSecuritySettingsScreen({
    this.settingsMutationCubit,
    this.sessionBloc,
    this.screenPrivacyCubit,
    this.authService,
    this.rotatePinUseCase,
    this.unlockVaultUseCase,
    this.monotonicClock,
    this.onPinRotationPressed,
    super.key,
  });

  @override
  State<VaultSecuritySettingsScreen> createState() =>
      _VaultSecuritySettingsScreenState();
}

class _VaultSecuritySettingsScreenState
    extends State<VaultSecuritySettingsScreen> {
  ScreenPrivacyCubit? _screenPrivacyCubit;

  @override
  void initState() {
    super.initState();
    _engageScreenPrivacy();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_screenPrivacyCubit == null) {
      _screenPrivacyCubit = _resolveScreenPrivacyCubit();
    }
  }

  void _engageScreenPrivacy() {
    if (_screenPrivacyCubit == null) {
      _screenPrivacyCubit = _resolveScreenPrivacyCubit();
    }
    _screenPrivacyCubit?.engageSecureFlag(
      reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
    );
  }

  void _releaseScreenPrivacy() {
    final cubit = _screenPrivacyCubit;
    if (cubit != null && !cubit.isClosed) {
      cubit.releaseSecureFlag(
        reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
      );
    }
  }

  ScreenPrivacyCubit? _resolveScreenPrivacyCubit() {
    if (widget.screenPrivacyCubit case final cubit?) {
      return cubit;
    }
    if (!mounted) return _screenPrivacyCubit;
    try {
      return context.read<ScreenPrivacyCubit>();
    } catch (_) {
      return _screenPrivacyCubit;
    }
  }

  SettingsMutationCubit? _resolveSettingsCubit() {
    if (widget.settingsMutationCubit case final cubit?) {
      return cubit;
    }
    if (!mounted) return null;
    try {
      return context.read<SettingsMutationCubit>();
    } catch (_) {
      return null;
    }
  }

  VaultSessionBloc? _resolveSessionBloc() {
    if (widget.sessionBloc case final bloc?) {
      return bloc;
    }
    if (!mounted) return null;
    try {
      return context.read<VaultSessionBloc>();
    } catch (_) {
      return null;
    }
  }

  IVaultAuthService? _resolveAuthService() {
    if (widget.authService case final s?) {
      return s;
    }
    if (!mounted) return null;
    try {
      return context.read<IVaultAuthService>();
    } catch (_) {
      return null;
    }
  }

  RotatePinUseCase? _resolveRotatePinUseCase() {
    if (widget.rotatePinUseCase case final uc?) {
      return uc;
    }
    if (!mounted) return null;
    try {
      return context.read<RotatePinUseCase>();
    } catch (_) {
      return null;
    }
  }

  UnlockVaultUseCase? _resolveUnlockVaultUseCase() {
    if (widget.unlockVaultUseCase case final uc?) {
      return uc;
    }
    if (!mounted) return null;
    try {
      return context.read<UnlockVaultUseCase>();
    } catch (_) {
      return null;
    }
  }

  IMonotonicClock? _resolveMonotonicClock() {
    if (widget.monotonicClock case final c?) {
      return c;
    }
    if (!mounted) return null;
    try {
      return context.read<IMonotonicClock>();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _releaseScreenPrivacy();
    super.dispose();
  }

  Future<void> _handleBiometricToggle(bool enable) async {
    final cubit = _resolveSettingsCubit();
    if (cubit == null) return;

    await StepUpAuthGuard.executeWithGuard(
      context: context,
      mutationType: SensitiveSettingMutationEnum.biometricPolicyChange,
      customTitle: 'Authorize Biometrics',
      mutationCubitOverride: widget.settingsMutationCubit,
      sessionBlocOverride: widget.sessionBloc,
      screenPrivacyCubitOverride: widget.screenPrivacyCubit,
      onAuthorized: () async {
        final newPolicy = enable
            ? BiometricAuthPolicyEnum.pinAndBiometricStrong
            : BiometricAuthPolicyEnum.pinOnly;
        await cubit.applyBiometricPolicy(newPolicy);
      },
    );
  }

  Future<void> _startPinRotationFlow() async {
    if (widget.onPinRotationPressed case final callback?) {
      callback();
      return;
    }

    final cubit = _resolveSettingsCubit();
    final authService = _resolveAuthService();
    final rotatePinUseCase = _resolveRotatePinUseCase();
    final unlockUseCase = _resolveUnlockVaultUseCase();
    final monotonicClock = _resolveMonotonicClock();

    if (cubit == null ||
        authService == null ||
        rotatePinUseCase == null ||
        unlockUseCase == null ||
        monotonicClock == null) {
      return;
    }

    await cubit.requestSensitiveMutation(
      mutationType: SensitiveSettingMutationEnum.pinRotation,
    );

    // Step 1: Verify current PIN
    String? verifiedOldPin;
    final verifyOldPinCubit = PinPadCubit(
      unlockVaultUseCase: unlockUseCase,
      authService: authService,
      monotonicClock: monotonicClock,
      initialLayout: cubit.currentConfig.keypadLayout,
      customPinSubmitter: (enteredPin) async {
        final authResult = await authService.authenticateWithPin(pin: enteredPin);
        if (authResult is VaultSuccess) {
          verifiedOldPin = enteredPin;
        }
        return authResult;
      },
    );

    bool? step1Success;
    try {
      if (!mounted) return;
      step1Success = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => VaultAuthScreen(
            mode: VaultAuthScreenMode.verifyOldPin,
            pinPadCubit: verifyOldPinCubit,
            sessionBloc: _resolveSessionBloc(),
            screenPrivacyCubit: _resolveScreenPrivacyCubit(),
            biometricPolicy: BiometricAuthPolicyEnum.pinOnly,
          ),
        ),
      );
    } finally {
      await verifyOldPinCubit.close();
    }

    if (step1Success != true || verifiedOldPin == null) {
      cubit.cancelSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.pinRotation,
      );
      return;
    }

    // Step 2: Enter new PIN
    String? proposedNewPin;
    final enterNewPinCubit = PinPadCubit(
      unlockVaultUseCase: unlockUseCase,
      authService: authService,
      monotonicClock: monotonicClock,
      initialLayout: cubit.currentConfig.keypadLayout,
      customPinSubmitter: (enteredPin) async {
        if (enteredPin == verifiedOldPin) {
          return const VaultResult.failure(
            VaultValidationFailure('New PIN must differ from current PIN.'),
          );
        }
        proposedNewPin = enteredPin;
        return const VaultResult.success(null);
      },
    );

    bool? step2Success;
    try {
      if (!mounted) return;
      step2Success = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => VaultAuthScreen(
            mode: VaultAuthScreenMode.rotatePin,
            titleOverride: 'New PIN',
            pinPadCubit: enterNewPinCubit,
            sessionBloc: _resolveSessionBloc(),
            screenPrivacyCubit: _resolveScreenPrivacyCubit(),
            biometricPolicy: BiometricAuthPolicyEnum.pinOnly,
          ),
        ),
      );
    } finally {
      await enterNewPinCubit.close();
    }

    if (step2Success != true || proposedNewPin == null) {
      cubit.cancelSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.pinRotation,
      );
      return;
    }

    // Step 3: Confirm new PIN
    String? confirmedNewPin;
    final confirmNewPinCubit = PinPadCubit(
      unlockVaultUseCase: unlockUseCase,
      authService: authService,
      monotonicClock: monotonicClock,
      initialLayout: cubit.currentConfig.keypadLayout,
      customPinSubmitter: (enteredPin) async {
        if (enteredPin != proposedNewPin) {
          return const VaultResult.failure(
            VaultValidationFailure('PINs do not match. Please re-enter.'),
          );
        }
        confirmedNewPin = enteredPin;
        return const VaultResult.success(null);
      },
    );

    bool? step3Success;
    try {
      if (!mounted) return;
      step3Success = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => VaultAuthScreen(
            mode: VaultAuthScreenMode.rotatePin,
            titleOverride: 'Confirm New PIN',
            pinPadCubit: confirmNewPinCubit,
            sessionBloc: _resolveSessionBloc(),
            screenPrivacyCubit: _resolveScreenPrivacyCubit(),
            biometricPolicy: BiometricAuthPolicyEnum.pinOnly,
          ),
        ),
      );
    } finally {
      await confirmNewPinCubit.close();
    }

    if (step3Success != true || confirmedNewPin == null) {
      cubit.cancelSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.pinRotation,
      );
      return;
    }

    // Step 4: Execute Key Rotation
    final oldPinSafe = verifiedOldPin;
    final newPinSafe = confirmedNewPin;

    if (oldPinSafe == null || newPinSafe == null) {
      cubit.cancelSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.pinRotation,
      );
      return;
    }

    await cubit.confirmSensitiveMutation(
      mutationType: SensitiveSettingMutationEnum.pinRotation,
      onExecute: () async {
        final rotateResult = await rotatePinUseCase.execute(
          RotatePinParams(
            oldPin: oldPinSafe,
            newPin: newPinSafe,
          ),
        );
        switch (rotateResult) {
          case VaultSuccess<void>():
            break;
          case final VaultFailureResult<void> failure:
            throw Exception(failure.failure.message);
        }
      },
    );

    if (mounted) {
      final vaultTheme = VaultTheme.of(context);
      showVaultSettingsSnackBar(
        context,
        vaultTheme,
        message: 'Master PIN updated successfully',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _resolveSettingsCubit();

    Widget buildScaffold(BuildContext context, VaultConfig currentConfig) {
      final vaultTheme = VaultTheme.of(context);
      return VaultSessionScaffoldGuard(
        sessionBlocOverride: _resolveSessionBloc(),
        child: Scaffold(
          key: const ValueKey('vault_security_screen'),
          backgroundColor: vaultTheme.scaffold,
          appBar: buildVaultSettingsAppBar(
            vaultTheme: vaultTheme,
            title: 'Security & Authentication',
            backButtonKey: const ValueKey('vault_security_back_button'),
            onBackPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 32.0),
              children: [
                VaultSettingsSectionHeader(
                  title: 'Authentication',
                  vaultTheme: vaultTheme,
                ),
                VaultSettingsGroup(
                  vaultTheme: vaultTheme,
                  dividerInset: 64.0,
                  children: [
                    _buildBiometricTile(currentConfig, vaultTheme),
                    _buildPinRotationTile(vaultTheme),
                  ],
                ),
                const SizedBox(height: 24.0),
                _buildGraceTimeoutSection(currentConfig, cubit, vaultTheme),
                const SizedBox(height: 24.0),
                _buildReauthIntervalSection(currentConfig, cubit, vaultTheme),
                const SizedBox(height: 24.0),
                _buildKeypadLayoutSection(currentConfig, cubit, vaultTheme),
              ],
            ),
          ),
        ),
      );
    }

    if (cubit != null) {
      return StreamBuilder<VaultConfig>(
        stream: cubit.configStream,
        initialData: cubit.currentConfig,
        builder: (context, snapshot) {
          final config = switch (snapshot.data) {
            final c? => c,
            null => cubit.currentConfig,
          };
          final themeData = VaultThemeData.fromConfig(config);
          return VaultTheme(
            data: themeData,
            child: Builder(
              builder: (innerCtx) => buildScaffold(innerCtx, config),
            ),
          );
        },
      );
    }

    return buildScaffold(context, const VaultConfig.constant());
  }

  Widget _buildBiometricTile(
    VaultConfig config,
    VaultThemeData vaultTheme,
  ) {
    final isEnabled =
        config.biometricAuth == BiometricAuthPolicyEnum.pinAndBiometricStrong;

    return VaultSettingsToggleRow(
      switchKey: const ValueKey('biometric_auth_switch'),
      icon: Icons.fingerprint_rounded,
      title: 'Biometric Unlock',
      subtitle: 'Allow fingerprint or face unlock alongside your PIN',
      value: isEnabled,
      vaultTheme: vaultTheme,
      onChanged: (val) => _handleBiometricToggle(val),
    );
  }

  Widget _buildPinRotationTile(VaultThemeData vaultTheme) {
    return VaultSettingsNavRow(
      key: const ValueKey('tile_pin_rotation'),
      icon: Icons.pin_outlined,
      title: 'Change Master PIN',
      subtitle: 'Verify your current PIN to set a new 6-digit code',
      vaultTheme: vaultTheme,
      onTap: _startPinRotationFlow,
    );
  }

  Widget _buildGraceTimeoutSection(
    VaultConfig config,
    SettingsMutationCubit? cubit,
    VaultThemeData vaultTheme,
  ) {
    final options = [
      (
        BackgroundGraceTimeoutEnum.immediate,
        'Immediate',
        'Locks as soon as you leave the app',
        const ValueKey('grace_timeout_immediate'),
      ),
      (
        BackgroundGraceTimeoutEnum.thirtySeconds,
        '30 Seconds',
        'Brief grace window before locking',
        const ValueKey('grace_timeout_thirty_seconds'),
      ),
      (
        BackgroundGraceTimeoutEnum.oneMinute,
        '1 Minute',
        'Extended grace window',
        const ValueKey('grace_timeout_one_minute'),
      ),
      (
        BackgroundGraceTimeoutEnum.fiveMinutes,
        '5 Minutes',
        'Longest grace window',
        const ValueKey('grace_timeout_five_minutes'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VaultSettingsSectionHeader(
          title: 'Background Lock Delay',
          vaultTheme: vaultTheme,
        ),
        VaultSettingsGroup(
          vaultTheme: vaultTheme,
          children: [
            for (final opt in options)
              VaultSettingsRadioRow(
                optionKey: opt.$4,
                title: opt.$2,
                subtitle: opt.$3,
                isSelected: config.backgroundGraceTimeout == opt.$1,
                vaultTheme: vaultTheme,
                onTap: () {
                  cubit?.mutatePolicy(
                    (current) =>
                        current.copyWith(backgroundGraceTimeout: opt.$1),
                  );
                },
              ),
          ],
        ),
        VaultSettingsFootnote(
          text:
              'Controls how long the vault remains unlocked when switching apps or turning off the screen.',
          vaultTheme: vaultTheme,
        ),
      ],
    );
  }

  Widget _buildReauthIntervalSection(
    VaultConfig config,
    SettingsMutationCubit? cubit,
    VaultThemeData vaultTheme,
  ) {
    final options = [
      (
        ActiveReauthIntervalEnum.every5Minutes,
        'Every 5 Minutes',
        'Strict verification cadence',
        const ValueKey('reauth_interval_5_min'),
      ),
      (
        ActiveReauthIntervalEnum.every15Minutes,
        'Every 15 Minutes',
        'Balanced verification cadence',
        const ValueKey('reauth_interval_15_min'),
      ),
      (
        ActiveReauthIntervalEnum.every30Minutes,
        'Every 30 Minutes',
        'Extended browsing window',
        const ValueKey('reauth_interval_30_min'),
      ),
      (
        ActiveReauthIntervalEnum.never,
        'Never',
        'Keep unlocked until locked or backgrounded',
        const ValueKey('reauth_interval_never'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VaultSettingsSectionHeader(
          title: 'Inactivity Re-Authentication',
          vaultTheme: vaultTheme,
        ),
        VaultSettingsGroup(
          vaultTheme: vaultTheme,
          children: [
            for (final opt in options)
              VaultSettingsRadioRow(
                optionKey: opt.$4,
                title: opt.$2,
                subtitle: opt.$3,
                isSelected: config.activeReauthInterval == opt.$1,
                vaultTheme: vaultTheme,
                onTap: () {
                  cubit?.mutatePolicy(
                    (current) =>
                        current.copyWith(activeReauthInterval: opt.$1),
                  );
                },
              ),
          ],
        ),
        VaultSettingsFootnote(
          text:
              'Prompts for verification periodically while actively browsing inside the vault.',
          vaultTheme: vaultTheme,
        ),
      ],
    );
  }

  Widget _buildKeypadLayoutSection(
    VaultConfig config,
    SettingsMutationCubit? cubit,
    VaultThemeData vaultTheme,
  ) {
    final options = [
      (
        KeypadLayoutPolicyEnum.standardOrdered,
        'Standard Ordered',
        'Fixed 1 to 9, 0 phone dial arrangement',
        const ValueKey('keypad_layout_standard'),
      ),
      (
        KeypadLayoutPolicyEnum.randomizedPerAttempt,
        'Randomized Per Attempt',
        'Shuffles keypad digits on every unlock screen',
        const ValueKey('keypad_layout_randomized'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VaultSettingsSectionHeader(
          title: 'Keypad Layout',
          vaultTheme: vaultTheme,
        ),
        VaultSettingsGroup(
          vaultTheme: vaultTheme,
          children: [
            for (final opt in options)
              VaultSettingsRadioRow(
                optionKey: opt.$4,
                title: opt.$2,
                subtitle: opt.$3,
                isSelected: config.keypadLayout == opt.$1,
                vaultTheme: vaultTheme,
                onTap: () {
                  cubit?.mutatePolicy(
                    (current) => current.copyWith(keypadLayout: opt.$1),
                  );
                },
              ),
          ],
        ),
        VaultSettingsFootnote(
          text:
              'Randomizing digits helps prevent screen smudge tracing and shoulder surfing.',
          vaultTheme: vaultTheme,
        ),
      ],
    );
  }
}

// =============================================================================
// 3. DEDICATED SCREEN: PLAYBACK & PRIVACY
// =============================================================================

/// Dedicated full-screen route for Vault Playback & Privacy settings.
class VaultPrivacySettingsScreen extends StatefulWidget {
  final SettingsMutationCubit? settingsMutationCubit;
  final VaultSessionBloc? sessionBloc;
  final ScreenPrivacyCubit? screenPrivacyCubit;

  const VaultPrivacySettingsScreen({
    this.settingsMutationCubit,
    this.sessionBloc,
    this.screenPrivacyCubit,
    super.key,
  });

  @override
  State<VaultPrivacySettingsScreen> createState() =>
      _VaultPrivacySettingsScreenState();
}

class _VaultPrivacySettingsScreenState
    extends State<VaultPrivacySettingsScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late final TextEditingController _albumController;
  late final FocusNode _titleFocus;
  late final FocusNode _artistFocus;
  late final FocusNode _albumFocus;
  ScreenPrivacyCubit? _screenPrivacyCubit;
  SettingsMutationCubit? _settingsMutationCubit;
  String? _decoyValidationError;
  bool _isSavingDecoy = false;

  @override
  void initState() {
    super.initState();
    final config = switch (_resolveSettingsCubit()?.currentConfig) {
      final c? => c,
      null => const VaultConfig.constant(),
    };

    _titleController = TextEditingController(text: config.decoyTitle);
    _artistController = TextEditingController(text: config.decoyArtist);
    _albumController = TextEditingController(text: config.decoyAlbum);

    _titleFocus = FocusNode();
    _artistFocus = FocusNode();
    _albumFocus = FocusNode();

    _engageScreenPrivacy();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_screenPrivacyCubit == null) {
      _screenPrivacyCubit = _resolveScreenPrivacyCubit();
    }
    if (_settingsMutationCubit == null) {
      _settingsMutationCubit = _resolveSettingsCubit();
    }
  }

  bool _hasUnsavedDecoyChanges(VaultConfig config) {
    return _titleController.text.trim() != config.decoyTitle ||
        _artistController.text.trim() != config.decoyArtist ||
        _albumController.text.trim() != config.decoyAlbum;
  }

  Future<void> _saveDecoyPersona(SettingsMutationCubit? cubit) async {
    final title = _titleController.text.trim();
    final artist = _artistController.text.trim();
    final album = _albumController.text.trim();

    if (title.isEmpty || artist.isEmpty || album.isEmpty) {
      setState(() {
        _decoyValidationError =
            'Title, artist, and album must not be empty.';
      });
      return;
    }

    if (cubit == null || _isSavingDecoy) {
      return;
    }

    setState(() {
      _decoyValidationError = null;
      _isSavingDecoy = true;
    });

    try {
      final saved = await cubit.saveDecoyPersona(
        title: title,
        artist: artist,
        album: album,
      );
      if (!mounted) return;
      if (saved) {
        _titleController.text = title;
        _artistController.text = artist;
        _albumController.text = album;
        FocusScope.of(context).unfocus();
        showVaultSettingsSnackBar(
          context,
          VaultThemeData.fromConfig(cubit.currentConfig),
          message: 'Decoy persona saved and applied to active playback.',
        );
      } else {
        setState(() {
          _decoyValidationError = 'Unable to save decoy persona.';
        });
      }
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _decoyValidationError = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingDecoy = false;
        });
      }
    }
  }

  void _engageScreenPrivacy() {
    if (_screenPrivacyCubit == null) {
      _screenPrivacyCubit = _resolveScreenPrivacyCubit();
    }
    _screenPrivacyCubit?.engageSecureFlag(
      reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
    );
  }

  void _releaseScreenPrivacy() {
    final cubit = _screenPrivacyCubit;
    if (cubit != null && !cubit.isClosed) {
      cubit.releaseSecureFlag(
        reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
      );
    }
  }

  ScreenPrivacyCubit? _resolveScreenPrivacyCubit() {
    if (widget.screenPrivacyCubit case final cubit?) {
      return cubit;
    }
    if (!mounted) return _screenPrivacyCubit;
    try {
      return context.read<ScreenPrivacyCubit>();
    } catch (_) {
      return _screenPrivacyCubit;
    }
  }

  SettingsMutationCubit? _resolveSettingsCubit() {
    if (widget.settingsMutationCubit case final cubit?) {
      return cubit;
    }
    if (!mounted) return null;
    try {
      return context.read<SettingsMutationCubit>();
    } catch (_) {
      return null;
    }
  }

  VaultSessionBloc? _resolveSessionBloc() {
    if (widget.sessionBloc case final bloc?) {
      return bloc;
    }
    if (!mounted) return null;
    try {
      return context.read<VaultSessionBloc>();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _releaseScreenPrivacy();
    _titleFocus.dispose();
    _artistFocus.dispose();
    _albumFocus.dispose();
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _resolveSettingsCubit();

    Widget buildScaffold(BuildContext context, VaultConfig currentConfig) {
      final vaultTheme = VaultTheme.of(context);
      return VaultSessionScaffoldGuard(
        sessionBlocOverride: _resolveSessionBloc(),
        child: Scaffold(
          key: const ValueKey('vault_privacy_screen'),
          backgroundColor: vaultTheme.scaffold,
          appBar: buildVaultSettingsAppBar(
            vaultTheme: vaultTheme,
            title: 'Playback & Privacy',
            backButtonKey: const ValueKey('vault_privacy_back_button'),
            onBackPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 32.0),
              children: [
                VaultSettingsSectionHeader(
                  title: 'Protection',
                  vaultTheme: vaultTheme,
                ),
                VaultSettingsGroup(
                  vaultTheme: vaultTheme,
                  dividerInset: 64.0,
                  children: [
                    _buildScreenSecurityTile(currentConfig, cubit, vaultTheme),
                    _buildMetadataMaskingTile(currentConfig, cubit, vaultTheme),
                  ],
                ),
                const SizedBox(height: 24.0),
                _buildLockPlaybackSection(currentConfig, cubit, vaultTheme),
                const SizedBox(height: 24.0),
                _buildDecoyPersonaSection(currentConfig, cubit, vaultTheme),
              ],
            ),
          ),
        ),
      );
    }

    if (cubit != null) {
      return StreamBuilder<VaultConfig>(
        stream: cubit.configStream,
        initialData: cubit.currentConfig,
        builder: (context, snapshot) {
          final config = switch (snapshot.data) {
            final c? => c,
            null => cubit.currentConfig,
          };
          final themeData = VaultThemeData.fromConfig(config);
          return VaultTheme(
            data: themeData,
            child: Builder(
              builder: (innerCtx) => buildScaffold(innerCtx, config),
            ),
          );
        },
      );
    }

    return buildScaffold(context, const VaultConfig.constant());
  }

  Widget _buildScreenSecurityTile(
    VaultConfig config,
    SettingsMutationCubit? cubit,
    VaultThemeData vaultTheme,
  ) {
    final isBlocked = config.screenSecurity ==
        ScreenSecurityPolicyEnum.blockScreenshotsAndRecents;

    return VaultSettingsToggleRow(
      switchKey: const ValueKey('screen_privacy_switch'),
      icon: Icons.screen_lock_portrait_outlined,
      title: 'Screen Capture Blocking',
      subtitle:
          'Prevent screenshots, screen recording, and app switcher previews',
      value: isBlocked,
      vaultTheme: vaultTheme,
      onChanged: (val) {
        final newPolicy = val
            ? ScreenSecurityPolicyEnum.blockScreenshotsAndRecents
            : ScreenSecurityPolicyEnum.allowCapture;
        cubit?.mutatePolicy(
          (current) => current.copyWith(screenSecurity: newPolicy),
        );
        _resolveScreenPrivacyCubit()?.updateSecurityPolicy(newPolicy);
      },
    );
  }

  Widget _buildMetadataMaskingTile(
    VaultConfig config,
    SettingsMutationCubit? cubit,
    VaultThemeData vaultTheme,
  ) {
    final isMasked = config.metadataVisibility ==
        MetadataVisibilityPolicyEnum.maskWithPlaceholder;

    return VaultSettingsToggleRow(
      switchKey: const ValueKey('metadata_masking_switch'),
      icon: Icons.visibility_off_outlined,
      title: 'Mask Track Metadata',
      subtitle:
          'Show decoy track info on the lock screen, Bluetooth, and notifications',
      value: isMasked,
      vaultTheme: vaultTheme,
      onChanged: (val) {
        final newPolicy = val
            ? MetadataVisibilityPolicyEnum.maskWithPlaceholder
            : MetadataVisibilityPolicyEnum.showActualMetadata;
        cubit?.mutatePolicy(
          (current) => current.copyWith(metadataVisibility: newPolicy),
        );
      },
    );
  }

  Widget _buildDecoyPersonaSection(
    VaultConfig currentConfig,
    SettingsMutationCubit? cubit,
    VaultThemeData vaultTheme,
  ) {
    final hasChanges = _hasUnsavedDecoyChanges(currentConfig);
    final dangerInk = vaultDangerInk(vaultTheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VaultSettingsSectionHeader(
          title: 'Decoy Track Info',
          vaultTheme: vaultTheme,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: vaultTheme.surfaceSubtle,
            borderRadius: VaultTheme.borderRadius8,
            border: Border.all(
              color: vaultTheme.border,
              width: VaultTheme.borderWidth,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  key: const ValueKey('decoy_title_field'),
                  controller: _titleController,
                  focusNode: _titleFocus,
                  labelText: 'Track Title',
                  vaultTheme: vaultTheme,
                  onChanged: (_) {
                    setState(() {
                      _decoyValidationError = null;
                    });
                  },
                ),
                const SizedBox(height: 12.0),
                _buildTextField(
                  key: const ValueKey('decoy_artist_field'),
                  controller: _artistController,
                  focusNode: _artistFocus,
                  labelText: 'Artist Name',
                  vaultTheme: vaultTheme,
                  onChanged: (_) {
                    setState(() {
                      _decoyValidationError = null;
                    });
                  },
                ),
                const SizedBox(height: 12.0),
                _buildTextField(
                  key: const ValueKey('decoy_album_field'),
                  controller: _albumController,
                  focusNode: _albumFocus,
                  labelText: 'Album Title',
                  vaultTheme: vaultTheme,
                  onChanged: (_) {
                    setState(() {
                      _decoyValidationError = null;
                    });
                  },
                ),
                if (_decoyValidationError case final errorText?) ...[
                  const SizedBox(height: 12.0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 10.0,
                    ),
                    decoration: BoxDecoration(
                      color: vaultTheme.danger.withValues(alpha: 0.14),
                      borderRadius: VaultTheme.borderRadius8,
                      border: Border.all(
                        color: vaultTheme.danger.withValues(alpha: 0.45),
                        width: VaultTheme.borderWidth,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 16.0,
                          color: dangerInk,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            errorText,
                            key: const ValueKey('decoy_validation_error'),
                            style: TextStyle(
                              fontFamily: VaultTheme.fontFamily,
                              fontSize: 12.5,
                              color: dangerInk,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16.0),
                SizedBox(
                  height: 48.0,
                  child: ElevatedButton(
                    key: const ValueKey('decoy_save_button'),
                    onPressed: (hasChanges && !_isSavingDecoy)
                        ? () => _saveDecoyPersona(cubit)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: vaultTheme.accent,
                      foregroundColor: vaultTheme.scaffold,
                      disabledBackgroundColor: vaultTheme.surfaceHighlight,
                      disabledForegroundColor: vaultTheme.textLowSalience,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: VaultTheme.borderRadius8,
                      ),
                    ),
                    child: Text(
                      _isSavingDecoy ? 'Saving...' : 'Save Decoy Info',
                      style: const TextStyle(
                        fontFamily: VaultTheme.fontFamily,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        VaultSettingsFootnote(
          text:
              'Shown in system media controls whenever metadata masking is active.',
          vaultTheme: vaultTheme,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required Key key,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    required VaultThemeData vaultTheme,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: TextStyle(
        fontFamily: VaultTheme.fontFamily,
        fontSize: 14.0,
        color: vaultTheme.textHighSalience,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          fontFamily: VaultTheme.fontFamily,
          fontSize: 12.5,
          color: vaultTheme.textMediumSalience,
        ),
        filled: true,
        fillColor: vaultTheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14.0,
          vertical: 14.0,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: VaultTheme.borderRadius8,
          borderSide: BorderSide(
            color: vaultTheme.border,
            width: VaultTheme.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: VaultTheme.borderRadius8,
          borderSide: BorderSide(
            color: vaultTheme.accent,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLockPlaybackSection(
    VaultConfig config,
    SettingsMutationCubit? cubit,
    VaultThemeData vaultTheme,
  ) {
    final options = [
      (
        LockPlaybackBehaviorEnum.stopImmediately,
        'Stop Immediately',
        'Pause audio and clear active queue on lock',
        const ValueKey('lock_playback_stop'),
      ),
      (
        LockPlaybackBehaviorEnum.finishCurrentTrack,
        'Finish Current Track',
        'Allow the current song to finish before stopping',
        const ValueKey('lock_playback_finish_track'),
      ),
      (
        LockPlaybackBehaviorEnum.continueMaskedInBackground,
        'Continue Masked',
        'Keep playing silently behind decoy metadata',
        const ValueKey('lock_playback_continue_masked'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VaultSettingsSectionHeader(
          title: 'When Vault Locks',
          vaultTheme: vaultTheme,
        ),
        VaultSettingsGroup(
          vaultTheme: vaultTheme,
          children: [
            for (final opt in options)
              VaultSettingsRadioRow(
                optionKey: opt.$4,
                title: opt.$2,
                subtitle: opt.$3,
                isSelected: config.lockPlaybackBehavior == opt.$1,
                vaultTheme: vaultTheme,
                onTap: () {
                  cubit?.mutatePolicy(
                    (current) => current.copyWith(lockPlaybackBehavior: opt.$1),
                  );
                },
              ),
          ],
        ),
        VaultSettingsFootnote(
          text:
              'Chooses how private audio behaves whenever the vault locks mid-track.',
          vaultTheme: vaultTheme,
        ),
      ],
    );
  }
}

// =============================================================================
// 4. DEDICATED SCREEN: GESTURE CONTROLS
// =============================================================================

/// Dedicated full-screen route for Stealth Gesture Controls & Enrollment settings.
class VaultGestureSettingsScreen extends StatefulWidget {
  final SettingsMutationCubit? settingsMutationCubit;
  final VaultSessionBloc? sessionBloc;
  final ScreenPrivacyCubit? screenPrivacyCubit;
  final GestureEngineCubit? gestureEngineCubit;
  final VoidCallback? onGestureReEnrollmentPressed;

  const VaultGestureSettingsScreen({
    this.settingsMutationCubit,
    this.sessionBloc,
    this.screenPrivacyCubit,
    this.gestureEngineCubit,
    this.onGestureReEnrollmentPressed,
    super.key,
  });

  @override
  State<VaultGestureSettingsScreen> createState() =>
      _VaultGestureSettingsScreenState();
}

class _VaultGestureSettingsScreenState
    extends State<VaultGestureSettingsScreen> {
  ScreenPrivacyCubit? _screenPrivacyCubit;

  @override
  void initState() {
    super.initState();
    _engageScreenPrivacy();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_screenPrivacyCubit == null) {
      _screenPrivacyCubit = _resolveScreenPrivacyCubit();
    }
  }

  void _engageScreenPrivacy() {
    if (_screenPrivacyCubit == null) {
      _screenPrivacyCubit = _resolveScreenPrivacyCubit();
    }
    _screenPrivacyCubit?.engageSecureFlag(
      reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
    );
  }

  void _releaseScreenPrivacy() {
    final cubit = _screenPrivacyCubit;
    if (cubit != null && !cubit.isClosed) {
      cubit.releaseSecureFlag(
        reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
      );
    }
  }

  ScreenPrivacyCubit? _resolveScreenPrivacyCubit() {
    if (widget.screenPrivacyCubit case final cubit?) {
      return cubit;
    }
    if (!mounted) return _screenPrivacyCubit;
    try {
      return context.read<ScreenPrivacyCubit>();
    } catch (_) {
      return _screenPrivacyCubit;
    }
  }

  SettingsMutationCubit? _resolveSettingsCubit() {
    if (widget.settingsMutationCubit case final cubit?) {
      return cubit;
    }
    if (!mounted) return null;
    try {
      return context.read<SettingsMutationCubit>();
    } catch (_) {
      return null;
    }
  }

  GestureEngineCubit? _resolveGestureEngineCubit() {
    if (widget.gestureEngineCubit case final cubit?) {
      return cubit;
    }
    if (!mounted) return null;
    try {
      return context.read<GestureEngineCubit>();
    } catch (_) {
      return null;
    }
  }

  VaultSessionBloc? _resolveSessionBloc() {
    if (widget.sessionBloc case final bloc?) {
      return bloc;
    }
    if (!mounted) return null;
    try {
      return context.read<VaultSessionBloc>();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _releaseScreenPrivacy();
    super.dispose();
  }

  Future<void> _handleReEnrollment() async {
    if (widget.onGestureReEnrollmentPressed case final callback?) {
      callback();
      return;
    }

    final cubit = _resolveSettingsCubit();
    if (cubit == null) return;

    await StepUpAuthGuard.executeWithGuard(
      context: context,
      mutationType: SensitiveSettingMutationEnum.gestureReEnrollment,
      customTitle: 'Authorize Gesture Re-Enrollment',
      mutationCubitOverride: widget.settingsMutationCubit,
      sessionBlocOverride: widget.sessionBloc,
      screenPrivacyCubitOverride: widget.screenPrivacyCubit,
      onAuthorized: () async {
        if (!mounted) return;
        final enrolled = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => GestureEnrollmentScreen(
              gestureEngineCubit: _resolveGestureEngineCubit(),
              screenPrivacyCubit: _resolveScreenPrivacyCubit(),
              sessionBloc: _resolveSessionBloc(),
            ),
          ),
        );
        if (enrolled != true) {
          throw Exception('Gesture enrollment cancelled or failed.');
        }
      },
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _resolveSettingsCubit();

    Widget buildScaffold(BuildContext context, VaultConfig currentConfig) {
      final vaultTheme = VaultTheme.of(context);
      return VaultSessionScaffoldGuard(
        sessionBlocOverride: _resolveSessionBloc(),
        child: Scaffold(
          key: const ValueKey('vault_gesture_screen'),
          backgroundColor: vaultTheme.scaffold,
          appBar: buildVaultSettingsAppBar(
            vaultTheme: vaultTheme,
            title: 'Gesture Controls',
            backButtonKey: const ValueKey('vault_gesture_back_button'),
            onBackPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 32.0),
              children: [
                _buildStatusCard(vaultTheme),
                const SizedBox(height: 24.0),
                _buildSensitivitySection(currentConfig, cubit, vaultTheme),
                const SizedBox(height: 24.0),
                VaultSettingsSectionHeader(
                  title: 'Pattern & Drawing',
                  vaultTheme: vaultTheme,
                ),
                VaultSettingsGroup(
                  vaultTheme: vaultTheme,
                  dividerInset: 64.0,
                  children: [
                    _buildInkVisibilityTile(currentConfig, cubit, vaultTheme),
                    _buildReEnrollButton(vaultTheme),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (cubit != null) {
      return StreamBuilder<VaultConfig>(
        stream: cubit.configStream,
        initialData: cubit.currentConfig,
        builder: (context, snapshot) {
          final config = switch (snapshot.data) {
            final c? => c,
            null => cubit.currentConfig,
          };
          final themeData = VaultThemeData.fromConfig(config);
          return VaultTheme(
            data: themeData,
            child: Builder(
              builder: (innerCtx) => buildScaffold(innerCtx, config),
            ),
          );
        },
      );
    }

    return buildScaffold(context, const VaultConfig.constant());
  }

  Widget _buildStatusCard(VaultThemeData vaultTheme) {
    return VaultSettingsGroup(
      key: const ValueKey('gesture_status_card'),
      vaultTheme: vaultTheme,
      dividerInset: 16.0,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: vaultTheme.surfaceHighlight,
                  borderRadius: VaultTheme.borderRadius8,
                ),
                child: Icon(
                  Icons.gesture_rounded,
                  size: 21.0,
                  color: vaultTheme.accent,
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Stealth Gesture Unlock',
                          style: TextStyle(
                            fontFamily: VaultTheme.fontFamily,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w600,
                            color: vaultTheme.textHighSalience,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 7.0,
                          height: 7.0,
                          decoration: BoxDecoration(
                            color: vaultTheme.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          'Armed',
                          style: TextStyle(
                            fontFamily: VaultTheme.fontFamily,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: vaultTheme.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      'Draw your saved single-stroke pattern on the menu drawer pad to open the vault.',
                      style: TextStyle(
                        fontFamily: VaultTheme.fontFamily,
                        fontSize: 12.5,
                        height: 1.38,
                        color: vaultTheme.textMediumSalience,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              _buildSummaryDetailRow(
                label: 'Recognizer',
                value: 'On-Device Private Engine',
                vaultTheme: vaultTheme,
              ),
              const SizedBox(height: 6.0),
              _buildSummaryDetailRow(
                label: 'Execution',
                value: 'Isolated Background Thread',
                vaultTheme: vaultTheme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryDetailRow({
    required String label,
    required String value,
    required VaultThemeData vaultTheme,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: vaultTheme.textMediumSalience,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: vaultTheme.textHighSalience,
          ),
        ),
      ],
    );
  }

  Widget _buildSensitivitySection(
    VaultConfig config,
    SettingsMutationCubit? cubit,
    VaultThemeData vaultTheme,
  ) {
    final options = [
      (
        GestureSensitivityTierEnum.strict92Percent,
        'Strict',
        'Requires close stroke precision for maximum security',
        const ValueKey('gesture_sensitivity_strict'),
      ),
      (
        GestureSensitivityTierEnum.balanced84Percent,
        'Balanced',
        'Recommended balance of security and everyday speed',
        const ValueKey('gesture_sensitivity_balanced'),
      ),
      (
        GestureSensitivityTierEnum.relaxed76Percent,
        'Relaxed',
        'Allows natural curve variation and drawing speed changes',
        const ValueKey('gesture_sensitivity_relaxed'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VaultSettingsSectionHeader(
          title: 'Matching Sensitivity',
          vaultTheme: vaultTheme,
        ),
        VaultSettingsGroup(
          vaultTheme: vaultTheme,
          children: [
            for (final opt in options)
              VaultSettingsRadioRow(
                optionKey: opt.$4,
                title: opt.$2,
                subtitle: opt.$3,
                isSelected: config.gestureSensitivity == opt.$1,
                vaultTheme: vaultTheme,
                onTap: () {
                  cubit?.mutatePolicy(
                    (current) => current.copyWith(gestureSensitivity: opt.$1),
                  );
                  _resolveGestureEngineCubit()?.updateSensitivityTier(opt.$1);
                },
              ),
          ],
        ),
        VaultSettingsFootnote(
          text:
              'Adjusts how closely a drawn stroke must match your enrolled gesture pattern.',
          vaultTheme: vaultTheme,
        ),
      ],
    );
  }

  Widget _buildInkVisibilityTile(
    VaultConfig config,
    SettingsMutationCubit? cubit,
    VaultThemeData vaultTheme,
  ) {
    final isVisible = config.gestureVisibility ==
        GestureVisibilityPolicyEnum.faintDissipatingHairline;

    return VaultSettingsToggleRow(
      switchKey: const ValueKey('gesture_ink_visibility_switch'),
      icon: Icons.draw_outlined,
      title: 'Visible Stroke Trail',
      subtitle: isVisible
          ? 'Shows a faint line that fades away after lifting your finger'
          : 'Keeps strokes completely invisible for discreet entry',
      value: isVisible,
      vaultTheme: vaultTheme,
      onChanged: (val) {
        final newPolicy = val
            ? GestureVisibilityPolicyEnum.faintDissipatingHairline
            : GestureVisibilityPolicyEnum.invisibleStealth;
        cubit?.mutatePolicy(
          (current) => current.copyWith(gestureVisibility: newPolicy),
        );
      },
    );
  }

  Widget _buildReEnrollButton(VaultThemeData vaultTheme) {
    return VaultSettingsNavRow(
      key: const ValueKey('re_enroll_gesture_button'),
      icon: Icons.refresh_rounded,
      title: 'Re-Enroll Gesture',
      subtitle: 'Draw 3 new samples to update your unlock pattern',
      vaultTheme: vaultTheme,
      onTap: _handleReEnrollment,
    );
  }
}

// =============================================================================
// 5. DEDICATED SCREEN: DANGER ZONE
// =============================================================================

/// Dedicated full-screen route for Danger Zone & Destructive Vault Purge.
class VaultDangerZoneScreen extends StatefulWidget {
  final SettingsMutationCubit? settingsMutationCubit;
  final VaultSessionBloc? sessionBloc;
  final ScreenPrivacyCubit? screenPrivacyCubit;
  final PurgeVaultDataUseCase? purgeVaultDataUseCase;
  final UnlockVaultUseCase? unlockVaultUseCase;
  final IVaultAuthService? authService;
  final IMonotonicClock? monotonicClock;
  final VoidCallback? onPurgePressed;

  const VaultDangerZoneScreen({
    this.settingsMutationCubit,
    this.sessionBloc,
    this.screenPrivacyCubit,
    this.purgeVaultDataUseCase,
    this.unlockVaultUseCase,
    this.authService,
    this.monotonicClock,
    this.onPurgePressed,
    super.key,
  });

  @override
  State<VaultDangerZoneScreen> createState() => _VaultDangerZoneScreenState();
}

class _VaultDangerZoneScreenState extends State<VaultDangerZoneScreen> {
  ScreenPrivacyCubit? _screenPrivacyCubit;

  @override
  void initState() {
    super.initState();
    _engageScreenPrivacy();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_screenPrivacyCubit == null) {
      _screenPrivacyCubit = _resolveScreenPrivacyCubit();
    }
  }

  void _engageScreenPrivacy() {
    if (_screenPrivacyCubit == null) {
      _screenPrivacyCubit = _resolveScreenPrivacyCubit();
    }
    _screenPrivacyCubit?.engageSecureFlag(
      reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
    );
  }

  void _releaseScreenPrivacy() {
    final cubit = _screenPrivacyCubit;
    if (cubit != null && !cubit.isClosed) {
      cubit.releaseSecureFlag(
        reason: ScreenPrivacyEngageReasonEnum.vaultRouteActive,
      );
    }
  }

  ScreenPrivacyCubit? _resolveScreenPrivacyCubit() {
    if (widget.screenPrivacyCubit case final cubit?) {
      return cubit;
    }
    if (!mounted) return _screenPrivacyCubit;
    try {
      return context.read<ScreenPrivacyCubit>();
    } catch (_) {
      return _screenPrivacyCubit;
    }
  }

  SettingsMutationCubit? _resolveSettingsCubit() {
    if (widget.settingsMutationCubit case final cubit?) {
      return cubit;
    }
    if (!mounted) return null;
    try {
      return context.read<SettingsMutationCubit>();
    } catch (_) {
      return null;
    }
  }

  VaultSessionBloc? _resolveSessionBloc() {
    if (widget.sessionBloc case final bloc?) {
      return bloc;
    }
    if (!mounted) return null;
    try {
      return context.read<VaultSessionBloc>();
    } catch (_) {
      return null;
    }
  }

  PurgeVaultDataUseCase? _resolvePurgeUseCase() {
    if (widget.purgeVaultDataUseCase case final uc?) {
      return uc;
    }
    if (!mounted) return null;
    try {
      return context.read<PurgeVaultDataUseCase>();
    } catch (_) {
      return null;
    }
  }

  UnlockVaultUseCase? _resolveUnlockUseCase() {
    if (widget.unlockVaultUseCase case final uc?) {
      return uc;
    }
    if (!mounted) return null;
    try {
      return context.read<UnlockVaultUseCase>();
    } catch (_) {
      return null;
    }
  }

  IVaultAuthService? _resolveAuthService() {
    if (widget.authService case final s?) {
      return s;
    }
    if (!mounted) return null;
    try {
      return context.read<IVaultAuthService>();
    } catch (_) {
      return null;
    }
  }

  IMonotonicClock? _resolveMonotonicClock() {
    if (widget.monotonicClock case final c?) {
      return c;
    }
    if (!mounted) return null;
    try {
      return context.read<IMonotonicClock>();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _releaseScreenPrivacy();
    super.dispose();
  }

  Future<void> _handlePurge() async {
    if (widget.onPurgePressed case final callback?) {
      callback();
      return;
    }

    final cubit = _resolveSettingsCubit();
    final purgeUseCase = _resolvePurgeUseCase();
    final unlockUseCase = _resolveUnlockUseCase();
    final authService = _resolveAuthService();
    final monotonicClock = _resolveMonotonicClock();

    if (cubit == null ||
        purgeUseCase == null ||
        unlockUseCase == null ||
        authService == null ||
        monotonicClock == null) {
      return;
    }

    await cubit.requestSensitiveMutation(
      mutationType: SensitiveSettingMutationEnum.vaultDataPurge,
    );

    final purgePinPadCubit = PinPadCubit(
      unlockVaultUseCase: unlockUseCase,
      authService: authService,
      monotonicClock: monotonicClock,
      initialLayout: cubit.currentConfig.keypadLayout,
      customPinSubmitter: (enteredPin) async {
        return await purgeUseCase.execute(
          PurgeVaultDataParams(confirmationPin: enteredPin),
        );
      },
    );

    bool? purgeSuccess;
    try {
      if (!mounted) return;
      purgeSuccess = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => VaultAuthScreen(
            mode: VaultAuthScreenMode.purgeConfirmation,
            pinPadCubit: purgePinPadCubit,
            sessionBloc: _resolveSessionBloc(),
            screenPrivacyCubit: _resolveScreenPrivacyCubit(),
          ),
        ),
      );
    } finally {
      await purgePinPadCubit.close();
    }

    if (purgeSuccess == true) {
      await cubit.confirmSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.vaultDataPurge,
        onExecute: () async {},
      );

      final sessionBloc = _resolveSessionBloc();
      sessionBloc?.add(const VaultPurged());

      if (mounted) {
        final theme = VaultThemeData.fromConfig(cubit.currentConfig);
        Navigator.of(context).popUntil((route) => route.isFirst);
        showVaultSettingsSnackBar(
          context,
          theme,
          message: 'Vault and all private media have been securely deleted.',
        );
      }
    } else {
      cubit.cancelSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.vaultDataPurge,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _resolveSettingsCubit();

    Widget buildScaffold(BuildContext context) {
      final vaultTheme = VaultTheme.of(context);
      return VaultSessionScaffoldGuard(
        sessionBlocOverride: _resolveSessionBloc(),
        child: Scaffold(
          key: const ValueKey('vault_danger_zone_screen'),
          backgroundColor: vaultTheme.scaffold,
          appBar: buildVaultSettingsAppBar(
            vaultTheme: vaultTheme,
            title: 'Danger Zone',
            backButtonKey: const ValueKey('vault_danger_zone_back_button'),
            onBackPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 24.0),
                    children: [
                      VaultSettingsSectionHeader(
                        title: 'Permanent Erase',
                        vaultTheme: vaultTheme,
                      ),
                      _buildWarningCard(vaultTheme),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 16.0),
                  decoration: BoxDecoration(
                    color: vaultTheme.scaffold,
                    border: Border(
                      top: BorderSide(
                        color: vaultTheme.borderSubtle,
                        width: VaultTheme.borderWidth,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48.0,
                    child: ElevatedButton(
                      key: const ValueKey('purge_vault_button'),
                      onPressed: _handlePurge,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vaultTheme.danger,
                        foregroundColor: vaultTheme.textHighSalience,
                        elevation: 0,
                        shape: VaultTheme.shape8,
                      ),
                      child: const Text(
                        'Erase Vault Data',
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (cubit != null) {
      return StreamBuilder<VaultConfig>(
        stream: cubit.configStream,
        initialData: cubit.currentConfig,
        builder: (context, snapshot) {
          final config = switch (snapshot.data) {
            final c? => c,
            null => cubit.currentConfig,
          };
          final themeData = VaultThemeData.fromConfig(config);
          return VaultTheme(
            data: themeData,
            child: Builder(
              builder: (innerCtx) => buildScaffold(innerCtx),
            ),
          );
        },
      );
    }

    return buildScaffold(context);
  }

  Widget _buildWarningCard(VaultThemeData vaultTheme) {
    final dangerInk = vaultDangerInk(vaultTheme);
    final dangerBorder = vaultTheme.danger.withValues(alpha: 0.42);
    final dangerSurface = vaultTheme.danger.withValues(alpha: 0.10);

    final consequences = [
      (
        Icons.vpn_key_off_outlined,
        'Encryption Keys Destroyed',
        'Your vault master key and unlock secrets are permanently erased from storage.',
      ),
      (
        Icons.library_music_outlined,
        'Private Media Deleted',
        'All hidden tracks, playlists, and cached artwork are wiped cleanly.',
      ),
      (
        Icons.fingerprint_rounded,
        'Credentials Cleared',
        'Saved PIN hashes, gesture patterns, and active memory keys are removed.',
      ),
      (
        Icons.lock_reset_rounded,
        'Cannot Be Undone',
        'After PIN confirmation, the vault resets cleanly with no recovery backup.',
      ),
    ];

    return VaultSettingsGroup(
      key: const ValueKey('danger_zone_warning_card'),
      vaultTheme: vaultTheme,
      backgroundColor: dangerSurface,
      borderColor: dangerBorder,
      dividerColor: vaultTheme.danger.withValues(alpha: 0.22),
      dividerInset: 64.0,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: vaultTheme.danger.withValues(alpha: 0.18),
                  borderRadius: VaultTheme.borderRadius8,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 22.0,
                  color: dangerInk,
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Erase Private Vault',
                      style: TextStyle(
                        fontFamily: VaultTheme.fontFamily,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: vaultTheme.textHighSalience,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      'This permanently removes every encrypted file and resets vault settings.',
                      style: TextStyle(
                        fontFamily: VaultTheme.fontFamily,
                        fontSize: 12.5,
                        height: 1.4,
                        color: vaultTheme.textMediumSalience,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (final item in consequences)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34.0,
                  height: 34.0,
                  decoration: BoxDecoration(
                    color: vaultTheme.danger.withValues(alpha: 0.14),
                    borderRadius: VaultTheme.borderRadius8,
                  ),
                  child: Icon(item.$1, size: 18.0, color: dangerInk),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$2,
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                          color: vaultTheme.textHighSalience,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        item.$3,
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 12.5,
                          height: 1.38,
                          color: vaultTheme.textMediumSalience,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
