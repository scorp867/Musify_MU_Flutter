import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    final mutationCubit = mutationCubitOverride ??
        _resolveContextDependency<SettingsMutationCubit>(context);
    final sessionBloc = sessionBlocOverride ??
        _resolveContextDependency<VaultSessionBloc>(context);
    final screenPrivacyCubit = screenPrivacyCubitOverride ??
        _resolveContextDependency<ScreenPrivacyCubit>(context);

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
    _screenPrivacyCubit ??= _resolveScreenPrivacyCubit();
  }

  void _engageScreenPrivacy() {
    _screenPrivacyCubit ??= _resolveScreenPrivacyCubit();
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

  void _navigateToSection(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vaultTheme = VaultTheme.of(context);
    final settingsCubit = _resolveSettingsCubit();

    final content = Scaffold(
      key: const ValueKey('vault_settings_scaffold'),
      backgroundColor: vaultTheme.scaffold,
      appBar: AppBar(
        backgroundColor: vaultTheme.scaffold,
        elevation: 0,
        leading: IconButton(
          key: const ValueKey('vault_settings_back_button'),
          icon: Icon(
            Icons.arrow_back,
            color: vaultTheme.textHighSalience,
          ),
          onPressed: () {
            widget.onBack?.call();
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'Vault Settings',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            color: vaultTheme.textHighSalience,
          ),
        ),
        actions: [
          Container(
            key: const ValueKey('vault_settings_status_badge'),
            margin: const EdgeInsets.symmetric(vertical: 14.0),
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: vaultTheme.surfaceSubtle,
              borderRadius: VaultTheme.borderRadius8,
              border: Border.all(
                color: vaultTheme.border,
                width: VaultTheme.borderWidth,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.0,
                  height: 6.0,
                  decoration: BoxDecoration(
                    color: vaultTheme.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6.0),
                Text(
                  'Active Session',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w500,
                    color: vaultTheme.accent,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('vault_settings_quick_lock_button'),
            icon: Icon(
              Icons.lock_outline,
              size: 20.0,
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
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildNavCard(
              key: const ValueKey('nav_tile_appearance'),
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: 'Theme palette, blur intensity, and lock preview',
              vaultTheme: vaultTheme,
              onTap: () => _navigateToSection(
                VaultAppearanceSettingsScreen(
                  settingsMutationCubit: widget.settingsMutationCubit,
                  screenPrivacyCubit: widget.screenPrivacyCubit,
                ),
              ),
            ),
            const SizedBox(height: 12.0),
            _buildNavCard(
              key: const ValueKey('nav_tile_security'),
              icon: Icons.security_outlined,
              title: 'Security & Authentication',
              subtitle:
                  'Biometrics, grace timeout, re-auth interval, keypad, and PIN',
              vaultTheme: vaultTheme,
              onTap: () => _navigateToSection(
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
            const SizedBox(height: 12.0),
            _buildNavCard(
              key: const ValueKey('nav_tile_privacy'),
              icon: Icons.privacy_tip_outlined,
              title: 'Playback & Privacy',
              subtitle:
                  'Screen security, metadata masking, decoy persona, auto-lock',
              vaultTheme: vaultTheme,
              onTap: () => _navigateToSection(
                VaultPrivacySettingsScreen(
                  settingsMutationCubit: widget.settingsMutationCubit,
                  screenPrivacyCubit: widget.screenPrivacyCubit,
                ),
              ),
            ),
            const SizedBox(height: 12.0),
            _buildNavCard(
              key: const ValueKey('nav_tile_gestures'),
              icon: Icons.gesture_outlined,
              title: 'Gesture Controls',
              subtitle:
                  'Stealth sensor, sensitivity, ink visibility, re-enrollment',
              vaultTheme: vaultTheme,
              onTap: () => _navigateToSection(
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
            const SizedBox(height: 12.0),
            _buildNavCard(
              key: const ValueKey('nav_tile_danger_zone'),
              icon: Icons.warning_amber_rounded,
              title: 'Danger Zone',
              subtitle: 'Irreversible vault reset and cryptographic media purge',
              vaultTheme: vaultTheme,
              isDanger: true,
              onTap: () => _navigateToSection(
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: vaultTheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: VaultTheme.borderRadius8,
                    side: BorderSide(
                      color: vaultTheme.danger,
                      width: VaultTheme.borderWidth,
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    rejectionReason,
                    style: TextStyle(
                      fontFamily: VaultTheme.fontFamily,
                      color: vaultTheme.danger,
                    ),
                  ),
                ),
              );
          }
        },
        builder: (context, state) => content,
      );
    }

    return content;
  }

  Widget _buildNavCard({
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
    required VaultThemeData vaultTheme,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final borderColor = isDanger ? vaultTheme.danger : vaultTheme.border;
    final iconColor = isDanger ? vaultTheme.danger : vaultTheme.accent;
    final titleColor =
        isDanger ? vaultTheme.danger : vaultTheme.textHighSalience;

    return Container(
      key: key,
      decoration: BoxDecoration(
        color: vaultTheme.surfaceSubtle,
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: borderColor,
          width: VaultTheme.borderWidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: VaultTheme.borderRadius8,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: vaultTheme.surfaceHighlight,
                    borderRadius: VaultTheme.borderRadius8,
                    border: Border.all(
                      color: borderColor.withValues(alpha: 0.5),
                      width: VaultTheme.borderWidth,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 22.0,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 3.0),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 12.0,
                          color: vaultTheme.textMediumSalience,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20.0,
                  color: vaultTheme.textMediumSalience,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 1. DEDICATED SCREEN: APPEARANCE
// =============================================================================

/// Dedicated full-screen route for Vault Appearance & Theme settings.
class VaultAppearanceSettingsScreen extends StatefulWidget {
  final SettingsMutationCubit? settingsMutationCubit;
  final ScreenPrivacyCubit? screenPrivacyCubit;

  const VaultAppearanceSettingsScreen({
    this.settingsMutationCubit,
    this.screenPrivacyCubit,
    super.key,
  });

  @override
  State<VaultAppearanceSettingsScreen> createState() =>
      _VaultAppearanceSettingsScreenState();
}

class _VaultAppearanceSettingsScreenState
    extends State<VaultAppearanceSettingsScreen> {
  double _previewBlurSigma = 12.0;
  ScreenPrivacyCubit? _screenPrivacyCubit;

  @override
  void initState() {
    super.initState();
    _engageScreenPrivacy();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenPrivacyCubit ??= _resolveScreenPrivacyCubit();
  }

  void _engageScreenPrivacy() {
    _screenPrivacyCubit ??= _resolveScreenPrivacyCubit();
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

  @override
  void dispose() {
    _releaseScreenPrivacy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vaultTheme = VaultTheme.of(context);
    final cubit = _resolveSettingsCubit();
    final currentConfig = cubit?.currentConfig ?? const VaultConfig.constant();

    return Scaffold(
      key: const ValueKey('vault_appearance_screen'),
      backgroundColor: vaultTheme.scaffold,
      appBar: AppBar(
        backgroundColor: vaultTheme.scaffold,
        elevation: 0,
        leading: IconButton(
          key: const ValueKey('vault_appearance_back_button'),
          icon: Icon(
            Icons.arrow_back,
            color: vaultTheme.textHighSalience,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'Appearance',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            color: vaultTheme.textHighSalience,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionHeader(
              title: 'Theme Palette',
              subtitle: 'Choose tone-on-tone color system for vault screens',
              vaultTheme: vaultTheme,
            ),
            const SizedBox(height: 12.0),
            _buildPaletteSelector(currentConfig, cubit, vaultTheme),
            const SizedBox(height: 24.0),
            _buildSectionHeader(
              title: 'Frosted Glass Blur Calibration',
              subtitle:
                  'Adjust privacy blur intensity applied to hidden album art and session re-auth overlays',
              vaultTheme: vaultTheme,
            ),
            const SizedBox(height: 12.0),
            _buildBlurSlider(vaultTheme),
            const SizedBox(height: 16.0),
            _buildBlurPreviewMockup(vaultTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required VaultThemeData vaultTheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: vaultTheme.textHighSalience,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 12.0,
            color: vaultTheme.textMediumSalience,
          ),
        ),
      ],
    );
  }

  Widget _buildPaletteSelector(
    VaultConfig currentConfig,
    SettingsMutationCubit? cubit,
    VaultThemeData vaultTheme,
  ) {
    return Column(
      children: [
        _buildPaletteCard(
          key: const ValueKey('palette_warm_espresso'),
          palette: VaultThemePalettePolicyEnum.warmEspresso,
          title: 'Warm Espresso',
          description: 'Deep dark roast and warm bronze tones',
          colors: const [
            Color(0xFF1A120E),
            Color(0xFF3A2418),
            Color(0xFF6B4A2E),
            Color(0xFFA88462),
            Color(0xFFD4B08C),
          ],
          isSelected: currentConfig.themePalette ==
              VaultThemePalettePolicyEnum.warmEspresso,
          vaultTheme: vaultTheme,
          onTap: () {
            cubit?.updateGeneralPolicy(
              currentConfig.copyWith(
                themePalette: VaultThemePalettePolicyEnum.warmEspresso,
              ),
            );
            setState(() {});
          },
        ),
        const SizedBox(height: 12.0),
        _buildPaletteCard(
          key: const ValueKey('palette_forest_noir'),
          palette: VaultThemePalettePolicyEnum.forestNoir,
          title: 'Forest Noir',
          description: 'Deep botanical emerald and slate tones',
          colors: const [
            Color(0xFF0F1F17),
            Color(0xFF1E3A2E),
            Color(0xFF3E5A3F),
            Color(0xFF6B7F67),
            Color(0xFF9EB29A),
          ],
          isSelected: currentConfig.themePalette ==
              VaultThemePalettePolicyEnum.forestNoir,
          vaultTheme: vaultTheme,
          onTap: () {
            cubit?.updateGeneralPolicy(
              currentConfig.copyWith(
                themePalette: VaultThemePalettePolicyEnum.forestNoir,
              ),
            );
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildPaletteCard({
    required Key key,
    required VaultThemePalettePolicyEnum palette,
    required String title,
    required String description,
    required List<Color> colors,
    required bool isSelected,
    required VaultThemeData vaultTheme,
    required VoidCallback onTap,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: isSelected ? vaultTheme.surfaceHighlight : vaultTheme.surfaceSubtle,
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: isSelected ? vaultTheme.accent : vaultTheme.border,
          width: isSelected ? 1.5 : VaultTheme.borderWidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: VaultTheme.borderRadius8,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 18.0,
                      height: 18.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? vaultTheme.accent
                              : vaultTheme.borderSubtle,
                          width: 2.0,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 8.0,
                                height: 8.0,
                                decoration: BoxDecoration(
                                  color: vaultTheme.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10.0),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: VaultTheme.fontFamily,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: vaultTheme.textHighSalience,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 12.0,
                    color: vaultTheme.textMediumSalience,
                  ),
                ),
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    for (final color in colors) ...[
                      Container(
                        width: 22.0,
                        height: 22.0,
                        margin: const EdgeInsets.only(right: 6.0),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: vaultTheme.borderSubtle,
                            width: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlurSlider(VaultThemeData vaultTheme) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: vaultTheme.surfaceSubtle,
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: vaultTheme.border,
          width: VaultTheme.borderWidth,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Blur Intensity',
                style: TextStyle(
                  fontFamily: VaultTheme.fontFamily,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                  color: vaultTheme.textHighSalience,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: vaultTheme.surfaceHighlight,
                  borderRadius: VaultTheme.borderRadius8,
                  border: Border.all(
                    color: vaultTheme.border,
                    width: VaultTheme.borderWidth,
                  ),
                ),
                child: Text(
                  '${_previewBlurSigma.toStringAsFixed(1)} px sigma',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: vaultTheme.accent,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            key: const ValueKey('blur_slider'),
            value: _previewBlurSigma,
            min: 4.0,
            max: 24.0,
            activeColor: vaultTheme.accent,
            inactiveColor: vaultTheme.border,
            onChanged: (val) {
              setState(() {
                _previewBlurSigma = val;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBlurPreviewMockup(VaultThemeData vaultTheme) {
    return Container(
      key: const ValueKey('blur_preview_container'),
      height: 130.0,
      decoration: BoxDecoration(
        color: vaultTheme.surfaceSubtle,
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: vaultTheme.border,
          width: VaultTheme.borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: VaultTheme.borderRadius8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background grid mimicking private tracks
            Column(
              children: [
                for (int i = 0; i < 3; i++)
                  Expanded(
                    child: Row(
                      children: [
                        for (int j = 0; j < 4; j++)
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(4.0),
                              decoration: BoxDecoration(
                                color: (i + j) % 2 == 0
                                    ? vaultTheme.surfaceHighlight
                                    : vaultTheme.surface,
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            // Blur overlay
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _previewBlurSigma,
                sigmaY: _previewBlurSigma,
              ),
              child: Container(
                color: vaultTheme.overlayTint,
              ),
            ),
            // Centered lock indicator
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: vaultTheme.surfaceSubtle,
                    borderRadius: VaultTheme.borderRadius8,
                    border: Border.all(
                      color: vaultTheme.border,
                      width: VaultTheme.borderWidth,
                    ),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 18.0,
                    color: vaultTheme.accent,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Private Media Protected',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: vaultTheme.textHighSalience,
                  ),
                ),
              ],
            ),
          ],
        ),
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
    _screenPrivacyCubit ??= _resolveScreenPrivacyCubit();
  }

  void _engageScreenPrivacy() {
    _screenPrivacyCubit ??= _resolveScreenPrivacyCubit();
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
        final updated = cubit.currentConfig.copyWith(biometricAuth: newPolicy);
        // Persist directly to storage when confirmed
        try {
          final storage = context.read<IVaultStorageRepository>();
          await storage.saveVaultConfig(updated);
        } on ProviderNotFoundException {
          // Handled via cubit reload
        }
      },
    );
    setState(() {});
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

    if (!mounted) return;
    final step1Success = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VaultAuthScreen(
          mode: VaultAuthScreenMode.verifyOldPin,
          pinPadCubit: verifyOldPinCubit,
          sessionBloc: _resolveSessionBloc(),
          screenPrivacyCubit: _resolveScreenPrivacyCubit(),
        ),
      ),
    );

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

    if (!mounted) return;
    final step2Success = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VaultAuthScreen(
          mode: VaultAuthScreenMode.stepUp,
          titleOverride: 'Enter New PIN',
          pinPadCubit: enterNewPinCubit,
          sessionBloc: _resolveSessionBloc(),
          screenPrivacyCubit: _resolveScreenPrivacyCubit(),
        ),
      ),
    );

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

    if (!mounted) return;
    final step3Success = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VaultAuthScreen(
          mode: VaultAuthScreenMode.stepUp,
          titleOverride: 'Confirm New PIN',
          pinPadCubit: confirmNewPinCubit,
          sessionBloc: _resolveSessionBloc(),
          screenPrivacyCubit: _resolveScreenPrivacyCubit(),
        ),
      ),
    );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Master PIN updated successfully',
            style: TextStyle(
              fontFamily: VaultTheme.fontFamily,
              color: vaultTheme.accent,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: vaultTheme.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: VaultTheme.borderRadius8,
            side: BorderSide(
              color: vaultTheme.border,
              width: VaultTheme.borderWidth,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultTheme = VaultTheme.of(context);
    final cubit = _resolveSettingsCubit();
    final currentConfig = cubit?.currentConfig ?? const VaultConfig.constant();

    return Scaffold(
      key: const ValueKey('vault_security_screen'),
      backgroundColor: vaultTheme.scaffold,
      appBar: AppBar(
        backgroundColor: vaultTheme.scaffold,
        elevation: 0,
        leading: IconButton(
          key: const ValueKey('vault_security_back_button'),
          icon: Icon(
            Icons.arrow_back,
            color: vaultTheme.textHighSalience,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'Security & Authentication',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            color: vaultTheme.textHighSalience,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildBiometricTile(currentConfig, vaultTheme),
            const SizedBox(height: 20.0),
            _buildGraceTimeoutSection(currentConfig, cubit, vaultTheme),
            const SizedBox(height: 20.0),
            _buildReauthIntervalSection(currentConfig, cubit, vaultTheme),
            const SizedBox(height: 20.0),
            _buildKeypadLayoutSection(currentConfig, cubit, vaultTheme),
            const SizedBox(height: 20.0),
            _buildPinRotationTile(vaultTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricTile(
    VaultConfig config,
    VaultThemeData vaultTheme,
  ) {
    final isEnabled =
        config.biometricAuth == BiometricAuthPolicyEnum.pinAndBiometricStrong;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: vaultTheme.surfaceSubtle,
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: vaultTheme.border,
          width: VaultTheme.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.fingerprint,
            size: 26.0,
            color: vaultTheme.textHighSalience,
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biometric Authentication',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: vaultTheme.textHighSalience,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Authorize KeyStore biometrics (fingerprint/face) with PIN fallback.',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 12.0,
                    color: vaultTheme.textMediumSalience,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            key: const ValueKey('biometric_auth_switch'),
            value: isEnabled,
            activeTrackColor: vaultTheme.accent,
            onChanged: (val) => _handleBiometricToggle(val),
          ),
        ],
      ),
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
        'Locks instantly upon backgrounding',
        const ValueKey('grace_timeout_immediate'),
      ),
      (
        BackgroundGraceTimeoutEnum.thirtySeconds,
        '30 Seconds',
        'Standard grace window',
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
        'Maximum grace window',
        const ValueKey('grace_timeout_five_minutes'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Background Grace Period',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: vaultTheme.textHighSalience,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          'Duration the vault remains unlocked when switching apps or locking device.',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 12.0,
            color: vaultTheme.textMediumSalience,
          ),
        ),
        const SizedBox(height: 10.0),
        for (final opt in options) ...[
          _buildSelectorOption(
            key: opt.$4,
            title: opt.$2,
            subtitle: opt.$3,
            isSelected: config.backgroundGraceTimeout == opt.$1,
            vaultTheme: vaultTheme,
            onTap: () {
              cubit?.updateGeneralPolicy(
                config.copyWith(backgroundGraceTimeout: opt.$1),
              );
              setState(() {});
            },
          ),
          const SizedBox(height: 8.0),
        ],
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
        'Enforce frequent verification',
        const ValueKey('reauth_interval_5_min'),
      ),
      (
        ActiveReauthIntervalEnum.every15Minutes,
        'Every 15 Minutes',
        'Balanced inactivity interval',
        const ValueKey('reauth_interval_15_min'),
      ),
      (
        ActiveReauthIntervalEnum.every30Minutes,
        'Every 30 Minutes',
        'Extended session duration',
        const ValueKey('reauth_interval_30_min'),
      ),
      (
        ActiveReauthIntervalEnum.never,
        'Never',
        'Keep unlocked until app backgrounded',
        const ValueKey('reauth_interval_never'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Session Inactivity Re-Auth',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: vaultTheme.textHighSalience,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          'Enforce periodic PIN verification while continuously browsing the vault.',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 12.0,
            color: vaultTheme.textMediumSalience,
          ),
        ),
        const SizedBox(height: 10.0),
        for (final opt in options) ...[
          _buildSelectorOption(
            key: opt.$4,
            title: opt.$2,
            subtitle: opt.$3,
            isSelected: config.activeReauthInterval == opt.$1,
            vaultTheme: vaultTheme,
            onTap: () {
              cubit?.updateGeneralPolicy(
                config.copyWith(activeReauthInterval: opt.$1),
              );
              setState(() {});
            },
          ),
          const SizedBox(height: 8.0),
        ],
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
        'Fixed 1-9, 0 phone arrangement',
        const ValueKey('keypad_layout_standard'),
      ),
      (
        KeypadLayoutPolicyEnum.randomizedPerAttempt,
        'Randomized per Attempt',
        'Shuffles digits on each presentation to prevent smudge attacks',
        const ValueKey('keypad_layout_randomized'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keypad Layout Arrangement',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: vaultTheme.textHighSalience,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          'Configure PIN pad digit arrangement to defeat smudge residue and shoulder surfing.',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 12.0,
            color: vaultTheme.textMediumSalience,
          ),
        ),
        const SizedBox(height: 10.0),
        for (final opt in options) ...[
          _buildSelectorOption(
            key: opt.$4,
            title: opt.$2,
            subtitle: opt.$3,
            isSelected: config.keypadLayout == opt.$1,
            vaultTheme: vaultTheme,
            onTap: () {
              cubit?.updateGeneralPolicy(
                config.copyWith(keypadLayout: opt.$1),
              );
              setState(() {});
            },
          ),
          const SizedBox(height: 8.0),
        ],
      ],
    );
  }

  Widget _buildSelectorOption({
    required Key key,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VaultThemeData vaultTheme,
    required VoidCallback onTap,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: isSelected ? vaultTheme.surfaceHighlight : vaultTheme.surfaceSubtle,
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: isSelected ? vaultTheme.accent : vaultTheme.border,
          width: isSelected ? 1.5 : VaultTheme.borderWidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: VaultTheme.borderRadius8,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Row(
              children: [
                Container(
                  width: 18.0,
                  height: 18.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? vaultTheme.accent
                          : vaultTheme.borderSubtle,
                      width: 2.0,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 8.0,
                            height: 8.0,
                            decoration: BoxDecoration(
                              color: vaultTheme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: vaultTheme.textHighSalience,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 11.0,
                          color: vaultTheme.textMediumSalience,
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
    );
  }

  Widget _buildPinRotationTile(VaultThemeData vaultTheme) {
    return Container(
      key: const ValueKey('tile_pin_rotation'),
      decoration: BoxDecoration(
        color: vaultTheme.surfaceSubtle,
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: vaultTheme.border,
          width: VaultTheme.borderWidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: VaultTheme.borderRadius8,
          onTap: _startPinRotationFlow,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Icon(
                  Icons.pin_outlined,
                  size: 22.0,
                  color: vaultTheme.textHighSalience,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Master 6-Digit PIN',
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: vaultTheme.textHighSalience,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        'Verify current PIN and derive new master PBKDF2 credentials.',
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 12.0,
                          color: vaultTheme.textMediumSalience,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20.0,
                  color: vaultTheme.textMediumSalience,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 3. DEDICATED SCREEN: PLAYBACK & PRIVACY
// =============================================================================

/// Dedicated full-screen route for Vault Playback & Privacy settings.
class VaultPrivacySettingsScreen extends StatefulWidget {
  final SettingsMutationCubit? settingsMutationCubit;
  final ScreenPrivacyCubit? screenPrivacyCubit;

  const VaultPrivacySettingsScreen({
    this.settingsMutationCubit,
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

  @override
  void initState() {
    super.initState();
    final config = _resolveSettingsCubit()?.currentConfig ??
        const VaultConfig.constant();

    _titleController = TextEditingController(text: config.decoyTitle);
    _artistController = TextEditingController(text: config.decoyArtist);
    _albumController = TextEditingController(text: config.decoyAlbum);

    _titleFocus = FocusNode()..addListener(_onFocusChange);
    _artistFocus = FocusNode()..addListener(_onFocusChange);
    _albumFocus = FocusNode()..addListener(_onFocusChange);

    _engageScreenPrivacy();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenPrivacyCubit ??= _resolveScreenPrivacyCubit();
  }

  void _onFocusChange() {
    if (!_titleFocus.hasFocus &&
        !_artistFocus.hasFocus &&
        !_albumFocus.hasFocus) {
      _resolveSettingsCubit()?.flushDecoyPersonaImmediately();
    }
  }

  void _engageScreenPrivacy() {
    _screenPrivacyCubit ??= _resolveScreenPrivacyCubit();
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
    final vaultTheme = VaultTheme.of(context);
    final cubit = _resolveSettingsCubit();
    final currentConfig = cubit?.currentConfig ?? const VaultConfig.constant();

    return Scaffold(
      key: const ValueKey('vault_privacy_screen'),
      backgroundColor: vaultTheme.scaffold,
      appBar: AppBar(
        backgroundColor: vaultTheme.scaffold,
        elevation: 0,
        leading: IconButton(
          key: const ValueKey('vault_privacy_back_button'),
          icon: Icon(
            Icons.arrow_back,
            color: vaultTheme.textHighSalience,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'Playback & Privacy',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            color: vaultTheme.textHighSalience,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildScreenSecurityTile(currentConfig, cubit, vaultTheme),
            const SizedBox(height: 14.0),
            _buildMetadataMaskingTile(currentConfig, cubit, vaultTheme),
            const SizedBox(height: 20.0),
            _buildDecoyPersonaSection(cubit, vaultTheme),
            const SizedBox(height: 20.0),
            _buildLockPlaybackSection(currentConfig, cubit, vaultTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenSecurityTile(
    VaultConfig config,
    SettingsMutationCubit? cubit,
    VaultThemeData vaultTheme,
  ) {
    final isBlocked = config.screenSecurity ==
        ScreenSecurityPolicyEnum.blockScreenshotsAndRecents;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: vaultTheme.surfaceSubtle,
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: vaultTheme.border,
          width: VaultTheme.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.screen_lock_portrait_outlined,
            size: 24.0,
            color: vaultTheme.textHighSalience,
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Screen Privacy (FLAG_SECURE)',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: vaultTheme.textHighSalience,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Block screenshots, screen recordings, and blank out app preview in Android Recents.',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 12.0,
                    color: vaultTheme.textMediumSalience,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            key: const ValueKey('screen_privacy_switch'),
            value: isBlocked,
            activeTrackColor: vaultTheme.accent,
            onChanged: (val) {
              final newPolicy = val
                  ? ScreenSecurityPolicyEnum.blockScreenshotsAndRecents
                  : ScreenSecurityPolicyEnum.allowCapture;
              cubit?.updateGeneralPolicy(
                config.copyWith(screenSecurity: newPolicy),
              );
              _resolveScreenPrivacyCubit()?.updateSecurityPolicy(newPolicy);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataMaskingTile(
    VaultConfig config,
    SettingsMutationCubit? cubit,
    VaultThemeData vaultTheme,
  ) {
    final isMasked = config.metadataVisibility ==
        MetadataVisibilityPolicyEnum.maskWithPlaceholder;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: vaultTheme.surfaceSubtle,
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: vaultTheme.border,
          width: VaultTheme.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.visibility_off_outlined,
            size: 24.0,
            color: vaultTheme.textHighSalience,
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Public Metadata Masking',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: vaultTheme.textHighSalience,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Replace real track details with custom decoy persona on lockscreen, Bluetooth, and Auto.',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 12.0,
                    color: vaultTheme.textMediumSalience,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            key: const ValueKey('metadata_masking_switch'),
            value: isMasked,
            activeTrackColor: vaultTheme.accent,
            onChanged: (val) {
              final newPolicy = val
                  ? MetadataVisibilityPolicyEnum.maskWithPlaceholder
                  : MetadataVisibilityPolicyEnum.showActualMetadata;
              cubit?.updateGeneralPolicy(
                config.copyWith(metadataVisibility: newPolicy),
              );
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDecoyPersonaSection(
    SettingsMutationCubit? cubit,
    VaultThemeData vaultTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: vaultTheme.surfaceSubtle,
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: vaultTheme.border,
          width: VaultTheme.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Decoy Persona Configuration',
            style: TextStyle(
              fontFamily: VaultTheme.fontFamily,
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              color: vaultTheme.textHighSalience,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            'Metadata projected to OS media notifications when masking is enabled.',
            style: TextStyle(
              fontFamily: VaultTheme.fontFamily,
              fontSize: 12.0,
              color: vaultTheme.textMediumSalience,
            ),
          ),
          const SizedBox(height: 12.0),
          _buildTextField(
            key: const ValueKey('decoy_title_field'),
            controller: _titleController,
            focusNode: _titleFocus,
            labelText: 'Decoy Track Title',
            vaultTheme: vaultTheme,
            onChanged: (val) {
              cubit?.updateDecoyPersonaDebounced(title: val);
            },
          ),
          const SizedBox(height: 10.0),
          _buildTextField(
            key: const ValueKey('decoy_artist_field'),
            controller: _artistController,
            focusNode: _artistFocus,
            labelText: 'Decoy Artist Name',
            vaultTheme: vaultTheme,
            onChanged: (val) {
              cubit?.updateDecoyPersonaDebounced(artist: val);
            },
          ),
          const SizedBox(height: 10.0),
          _buildTextField(
            key: const ValueKey('decoy_album_field'),
            controller: _albumController,
            focusNode: _albumFocus,
            labelText: 'Decoy Album Name',
            vaultTheme: vaultTheme,
            onChanged: (val) {
              cubit?.updateDecoyPersonaDebounced(album: val);
            },
          ),
        ],
      ),
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
        fontSize: 13.0,
        color: vaultTheme.textHighSalience,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          fontFamily: VaultTheme.fontFamily,
          fontSize: 12.0,
          color: vaultTheme.textMediumSalience,
        ),
        filled: true,
        fillColor: vaultTheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
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
        'Halts playback instantly and clears private RAM queue',
        const ValueKey('lock_playback_stop'),
      ),
      (
        LockPlaybackBehaviorEnum.finishCurrentTrack,
        'Finish Current Track',
        'Allows active track to complete, then stops',
        const ValueKey('lock_playback_finish_track'),
      ),
      (
        LockPlaybackBehaviorEnum.continueMaskedInBackground,
        'Continue Masked',
        'Plays continuously in background with decoy metadata',
        const ValueKey('lock_playback_continue_masked'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Behavior on Vault Auto-Lock',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: vaultTheme.textHighSalience,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          'Determines audio playback action when vault locks mid-song.',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 12.0,
            color: vaultTheme.textMediumSalience,
          ),
        ),
        const SizedBox(height: 10.0),
        for (final opt in options) ...[
          Container(
            key: opt.$4,
            decoration: BoxDecoration(
              color: config.lockPlaybackBehavior == opt.$1
                  ? vaultTheme.surfaceHighlight
                  : vaultTheme.surfaceSubtle,
              borderRadius: VaultTheme.borderRadius8,
              border: Border.all(
                color: config.lockPlaybackBehavior == opt.$1
                    ? vaultTheme.accent
                    : vaultTheme.border,
                width: config.lockPlaybackBehavior == opt.$1
                    ? 1.5
                    : VaultTheme.borderWidth,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: VaultTheme.borderRadius8,
                onTap: () {
                  cubit?.updateGeneralPolicy(
                    config.copyWith(lockPlaybackBehavior: opt.$1),
                  );
                  setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 18.0,
                        height: 18.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: config.lockPlaybackBehavior == opt.$1
                                ? vaultTheme.accent
                                : vaultTheme.borderSubtle,
                            width: 2.0,
                          ),
                        ),
                        child: config.lockPlaybackBehavior == opt.$1
                            ? Center(
                                child: Container(
                                  width: 8.0,
                                  height: 8.0,
                                  decoration: BoxDecoration(
                                    color: vaultTheme.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.$2,
                              style: TextStyle(
                                fontFamily: VaultTheme.fontFamily,
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                                color: vaultTheme.textHighSalience,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              opt.$3,
                              style: TextStyle(
                                fontFamily: VaultTheme.fontFamily,
                                fontSize: 11.0,
                                color: vaultTheme.textMediumSalience,
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
          ),
          const SizedBox(height: 8.0),
        ],
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
    _screenPrivacyCubit ??= _resolveScreenPrivacyCubit();
  }

  void _engageScreenPrivacy() {
    _screenPrivacyCubit ??= _resolveScreenPrivacyCubit();
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
    final vaultTheme = VaultTheme.of(context);
    final cubit = _resolveSettingsCubit();
    final currentConfig = cubit?.currentConfig ?? const VaultConfig.constant();

    return Scaffold(
      key: const ValueKey('vault_gesture_screen'),
      backgroundColor: vaultTheme.scaffold,
      appBar: AppBar(
        backgroundColor: vaultTheme.scaffold,
        elevation: 0,
        leading: IconButton(
          key: const ValueKey('vault_gesture_back_button'),
          icon: Icon(
            Icons.arrow_back,
            color: vaultTheme.textHighSalience,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'Gesture Controls',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            color: vaultTheme.textHighSalience,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildStatusCard(vaultTheme),
            const SizedBox(height: 20.0),
            _buildSensitivitySection(currentConfig, cubit, vaultTheme),
            const SizedBox(height: 20.0),
            _buildInkVisibilityTile(currentConfig, cubit, vaultTheme),
            const SizedBox(height: 24.0),
            _buildReEnrollButton(vaultTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(VaultThemeData vaultTheme) {
    return Container(
      key: const ValueKey('gesture_status_card'),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: vaultTheme.surfaceSubtle,
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: vaultTheme.border,
          width: VaultTheme.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.gesture_outlined,
                size: 22.0,
                color: vaultTheme.accent,
              ),
              const SizedBox(width: 10.0),
              Text(
                'Stealth Gesture Gateway',
                style: TextStyle(
                  fontFamily: VaultTheme.fontFamily,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: vaultTheme.textHighSalience,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: vaultTheme.surfaceHighlight,
                  borderRadius: VaultTheme.borderRadius8,
                  border: Border.all(
                    color: vaultTheme.accent.withValues(alpha: 0.5),
                    width: VaultTheme.borderWidth,
                  ),
                ),
                child: Text(
                  'Active & Armed',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w600,
                    color: vaultTheme.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            'Single-stroke touch path drawn on the drawer sensor pad to unlock the vault.',
            style: TextStyle(
              fontFamily: VaultTheme.fontFamily,
              fontSize: 12.0,
              color: vaultTheme.textMediumSalience,
            ),
          ),
          const SizedBox(height: 12.0),
          Divider(color: vaultTheme.borderSubtle, height: 1.0),
          const SizedBox(height: 12.0),
          _buildTelemetryRow(
            label: 'Classifiers',
            value: '3-Stage Ensemble (\$1-B + FastDTW + 7D Rubine)',
            vaultTheme: vaultTheme,
          ),
          const SizedBox(height: 6.0),
          _buildTelemetryRow(
            label: 'Execution',
            value: 'Off-thread Background Isolate (latency <= 35ms, 0 jank)',
            vaultTheme: vaultTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryRow({
    required String label,
    required String value,
    required VaultThemeData vaultTheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 11.0,
            fontWeight: FontWeight.w600,
            color: vaultTheme.textMediumSalience,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: VaultTheme.fontFamily,
              fontSize: 11.0,
              color: vaultTheme.textHighSalience,
            ),
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
        'Strict (92%)',
        'High security; requires high geometric fidelity (S_ensemble >= 0.88)',
        const ValueKey('gesture_sensitivity_strict'),
      ),
      (
        GestureSensitivityTierEnum.balanced84Percent,
        'Balanced (84%)',
        'Recommended; balances security and natural motor variance (S_ensemble >= 0.78)',
        const ValueKey('gesture_sensitivity_balanced'),
      ),
      (
        GestureSensitivityTierEnum.relaxed76Percent,
        'Relaxed (76%)',
        'Accommodates motor tremor and drawing speed variations (S_ensemble >= 0.68)',
        const ValueKey('gesture_sensitivity_relaxed'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ensemble Matching Sensitivity',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: vaultTheme.textHighSalience,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          'Minimum consensus score required to trigger vault unlock.',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 12.0,
            color: vaultTheme.textMediumSalience,
          ),
        ),
        const SizedBox(height: 10.0),
        for (final opt in options) ...[
          Container(
            key: opt.$4,
            decoration: BoxDecoration(
              color: config.gestureSensitivity == opt.$1
                  ? vaultTheme.surfaceHighlight
                  : vaultTheme.surfaceSubtle,
              borderRadius: VaultTheme.borderRadius8,
              border: Border.all(
                color: config.gestureSensitivity == opt.$1
                    ? vaultTheme.accent
                    : vaultTheme.border,
                width: config.gestureSensitivity == opt.$1
                    ? 1.5
                    : VaultTheme.borderWidth,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: VaultTheme.borderRadius8,
                onTap: () {
                  cubit?.updateGeneralPolicy(
                    config.copyWith(gestureSensitivity: opt.$1),
                  );
                  _resolveGestureEngineCubit()?.updateSensitivityTier(opt.$1);
                  setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 18.0,
                        height: 18.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: config.gestureSensitivity == opt.$1
                                ? vaultTheme.accent
                                : vaultTheme.borderSubtle,
                            width: 2.0,
                          ),
                        ),
                        child: config.gestureSensitivity == opt.$1
                            ? Center(
                                child: Container(
                                  width: 8.0,
                                  height: 8.0,
                                  decoration: BoxDecoration(
                                    color: vaultTheme.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.$2,
                              style: TextStyle(
                                fontFamily: VaultTheme.fontFamily,
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                                color: vaultTheme.textHighSalience,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              opt.$3,
                              style: TextStyle(
                                fontFamily: VaultTheme.fontFamily,
                                fontSize: 11.0,
                                color: vaultTheme.textMediumSalience,
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
          ),
          const SizedBox(height: 8.0),
        ],
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

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: vaultTheme.surfaceSubtle,
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: vaultTheme.border,
          width: VaultTheme.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.draw_outlined,
            size: 24.0,
            color: vaultTheme.textHighSalience,
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sensor Pad Ink Visibility',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: vaultTheme.textHighSalience,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  isVisible
                      ? 'Faint Dissipating Hairline: 1px subtle trail fading in 150-280ms'
                      : 'Invisible Stealth: 0 ink rendered; maximum plausible deniability',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 12.0,
                    color: vaultTheme.textMediumSalience,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            key: const ValueKey('gesture_ink_visibility_switch'),
            value: isVisible,
            activeTrackColor: vaultTheme.accent,
            onChanged: (val) {
              final newPolicy = val
                  ? GestureVisibilityPolicyEnum.faintDissipatingHairline
                  : GestureVisibilityPolicyEnum.invisibleStealth;
              cubit?.updateGeneralPolicy(
                config.copyWith(gestureVisibility: newPolicy),
              );
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReEnrollButton(VaultThemeData vaultTheme) {
    return Container(
      key: const ValueKey('re_enroll_gesture_button'),
      decoration: BoxDecoration(
        color: vaultTheme.surface,
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: vaultTheme.border,
          width: VaultTheme.borderWidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: VaultTheme.borderRadius8,
          onTap: _handleReEnrollment,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.refresh,
                  size: 22.0,
                  color: vaultTheme.accent,
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Re-Enroll Stealth Gesture',
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: vaultTheme.textHighSalience,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        'Record 3 new matching single-stroke samples in the guided wizard.',
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 12.0,
                          color: vaultTheme.textMediumSalience,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20.0,
                  color: vaultTheme.textMediumSalience,
                ),
              ],
            ),
          ),
        ),
      ),
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
    _screenPrivacyCubit ??= _resolveScreenPrivacyCubit();
  }

  void _engageScreenPrivacy() {
    _screenPrivacyCubit ??= _resolveScreenPrivacyCubit();
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

    if (!mounted) return;
    final purgeSuccess = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VaultAuthScreen(
          mode: VaultAuthScreenMode.purgeConfirmation,
          pinPadCubit: purgePinPadCubit,
          sessionBloc: _resolveSessionBloc(),
          screenPrivacyCubit: _resolveScreenPrivacyCubit(),
        ),
      ),
    );

    if (purgeSuccess == true) {
      await cubit.confirmSensitiveMutation(
        mutationType: SensitiveSettingMutationEnum.vaultDataPurge,
        onExecute: () async {},
      );

      final sessionBloc = _resolveSessionBloc();
      sessionBloc?.add(const VaultPurged());

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vault and all private media have been securely deleted.',
              style: TextStyle(fontFamily: VaultTheme.fontFamily),
            ),
            behavior: SnackBarBehavior.floating,
          ),
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
    final vaultTheme = VaultTheme.of(context);

    return Scaffold(
      key: const ValueKey('vault_danger_zone_screen'),
      backgroundColor: vaultTheme.scaffold,
      appBar: AppBar(
        backgroundColor: vaultTheme.scaffold,
        elevation: 0,
        leading: IconButton(
          key: const ValueKey('vault_danger_zone_back_button'),
          icon: Icon(
            Icons.arrow_back,
            color: vaultTheme.textHighSalience,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'Danger Zone',
          style: TextStyle(
            fontFamily: VaultTheme.fontFamily,
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            color: vaultTheme.danger,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWarningCard(vaultTheme),
              const Spacer(),
              ElevatedButton(
                key: const ValueKey('purge_vault_button'),
                onPressed: _handlePurge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: vaultTheme.danger,
                  foregroundColor: Colors.white,
                  shape: VaultTheme.shape8,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                ),
                child: const Text(
                  'Purge All Vault Data',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningCard(VaultThemeData vaultTheme) {
    final consequences = [
      'Cryptographic Shredding: Master Vault Key and AES-256-GCM wrapping keys permanently destroyed from memory and secure storage.',
      'Database Wipe: All private playlists, track references, custom configuration, gesture templates, and lockout deadlines deleted from SQLite.',
      '64KB Zero-Overwriting: Every isolated media file under .nomedia overwritten with zeroes in 64KB blocks within a background isolate before unlinking.',
      'RAM Zeroization: Cryptographic session keys immediately cleared from memory buffers.',
      'Irreversible Action: Once confirmed, vault state resets to uninitialized. This action cannot be undone.',
    ];

    return Container(
      key: const ValueKey('danger_zone_warning_card'),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: vaultTheme.danger.withValues(alpha: 0.12),
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: vaultTheme.danger.withValues(alpha: 0.50),
          width: VaultTheme.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 26.0,
                color: vaultTheme.danger,
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  'Destructive Vault Purge',
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: vaultTheme.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            'Warning: Actions in this section are irreversible and will permanently destroy all vault data.',
            style: TextStyle(
              fontFamily: VaultTheme.fontFamily,
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
              color: vaultTheme.danger,
            ),
          ),
          const SizedBox(height: 12.0),
          for (final item in consequences) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '* ',
                    style: TextStyle(
                      fontFamily: VaultTheme.fontFamily,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: vaultTheme.danger,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontFamily: VaultTheme.fontFamily,
                        fontSize: 11.0,
                        color: vaultTheme.textHighSalience,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
