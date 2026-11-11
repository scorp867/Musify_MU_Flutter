import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:musify_mu/features/vault/application/session/vault_session_bloc.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/data/services/vault_audio_playback_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_monotonic_clock.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_auth_service.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:musify_mu/features/vault/domain/policies/vault_theme_palette_policy.dart';
import 'package:musify_mu/features/vault/domain/states/settings_mutation_state.dart';
import 'package:musify_mu/features/vault/domain/states/vault_session_state.dart';
import 'package:musify_mu/features/vault/domain/usecases/purge_vault_data_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/rotate_pin_use_case.dart';
import 'package:musify_mu/features/vault/domain/usecases/unlock_vault_use_case.dart';
import 'package:musify_mu/features/vault/presentation/screens/gesture_enrollment_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/private_playlist_detail_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/private_vault_dashboard_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_auth_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_settings_screen.dart';
import 'package:musify_mu/features/vault/presentation/screens/vault_setup_screen.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';

/// Centralized route generator and route name constants for the Secure Vault module.
///
/// Enforces David Harel Statechart Region A security gating:
/// Direct navigation to any protected vault route while [VaultSessionBloc.state] is
/// not [VaultActiveSessionState] is intercepted and rendered as [VaultAuthScreen]
/// in [VaultAuthScreenMode.unlock] mode.
abstract final class VaultRoutes {
  static const String auth = '/vault/auth';
  static const String setup = '/vault/setup';
  static const String dashboard = '/vault/dashboard';
  static const String settings = '/vault/settings';
  static const String settingsAppearance = '/vault/settings/appearance';
  static const String settingsSecurity = '/vault/settings/security';
  static const String settingsPrivacy = '/vault/settings/privacy';
  static const String settingsGesture = '/vault/settings/gesture';
  static const String settingsDanger = '/vault/settings/danger';
  static const String enrollment = '/vault/enrollment';
  static const String playlistPrefix = '/vault/playlist/';
  static const String playlist = '/vault/playlist';

  /// Set of all canonical vault route names.
  static const Set<String> allRoutes = {
    auth,
    setup,
    dashboard,
    settings,
    settingsAppearance,
    settingsSecurity,
    settingsPrivacy,
    settingsGesture,
    settingsDanger,
    enrollment,
    playlist,
  };

  /// Set of protected vault route names that require an active unlocked session.
  /// Direct navigation without [VaultActiveSessionState] must be intercepted/redirected.
  static const Set<String> protectedRoutes = {
    dashboard,
    settings,
    settingsAppearance,
    settingsSecurity,
    settingsPrivacy,
    settingsGesture,
    settingsDanger,
    enrollment,
    playlist,
  };

  /// Returns whether [routeName] is a protected vault route requiring active session.
  /// All routes under `/vault` except `/vault/auth` and `/vault/setup` are protected.
  static bool isProtectedRoute(String routeName) {
    if (routeName == auth || routeName == setup) {
      return false;
    }
    if (protectedRoutes.contains(routeName)) {
      return true;
    }
    return routeName.startsWith(playlistPrefix) ||
        routeName.startsWith('/vault/settings/') ||
        routeName == '/vault';
  }

  /// Factory generator producing [MaterialPageRoute] for any `/vault` route.
  /// Returns `null` if the route is not a vault route.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name;
    if (name == null || (!name.startsWith('/vault') && !allRoutes.contains(name))) {
      return null;
    }

    final Widget? targetScreen = _resolveScreen(name, settings.arguments);
    if (targetScreen == null) return null;

    final isProtected = isProtectedRoute(name);

    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (context) {
        final sessionBloc = _safeResolve<VaultSessionBloc>(context);
        final isSessionActive = sessionBloc?.state is VaultActiveSessionState;
        final settingsCubit = _safeResolve<SettingsMutationCubit>(context);

        final Widget effectiveScreen;
        if (isProtected && !isSessionActive) {
          final biometricPolicy = settingsCubit?.currentConfig.biometricAuth;
          effectiveScreen = VaultAuthScreen(
            mode: VaultAuthScreenMode.unlock,
            biometricPolicy: biometricPolicy,
            onAuthComplete: (success) {
              if (success && context.mounted) {
                final navigator = Navigator.of(context);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  navigator.pushNamed(name, arguments: settings.arguments);
                });
              }
            },
          );
        } else {
          effectiveScreen = targetScreen;
        }

        if (settingsCubit != null) {
          return BlocBuilder<SettingsMutationCubit, SettingsMutationState>(
            bloc: settingsCubit,
            builder: (context, _) {
              final palette = settingsCubit.currentConfig.themePalette;
              return VaultTheme(
                data: VaultThemeData.fromPalette(palette),
                child: effectiveScreen,
              );
            },
          );
        }

        final palette = switch (settingsCubit?.currentConfig.themePalette) {
          final p? => p,
          null => VaultThemePalettePolicyEnum.warmEspresso,
        };
        return VaultTheme(
          data: VaultThemeData.fromPalette(palette),
          child: effectiveScreen,
        );
      },
    );
  }

  static Widget? _resolveScreen(String name, Object? arguments) {
    if (name == auth) {
      if (arguments is VaultAuthScreenMode) {
        return VaultAuthScreen(mode: arguments);
      } else if (arguments is Map<String, dynamic>) {
        final mode = arguments['mode'] is VaultAuthScreenMode
            ? arguments['mode'] as VaultAuthScreenMode
            : VaultAuthScreenMode.unlock;
        final title = arguments['titleOverride'] as String?;
        final onComplete = arguments['onAuthComplete'] as ValueChanged<bool>?;
        return VaultAuthScreen(
          mode: mode,
          titleOverride: title,
          onAuthComplete: onComplete,
        );
      }
      return const VaultAuthScreen(mode: VaultAuthScreenMode.unlock);
    }

    if (name == setup) {
      final sl = GetIt.I;
      return VaultSetupScreen(
        authService: sl<IVaultAuthService>(),
        monotonicClock: sl<IMonotonicClock>(),
        unlockVaultUseCase: sl<UnlockVaultUseCase>(),
        onSetupComplete: arguments is ValueChanged<bool> ? arguments : null,
      );
    }

    if (name == dashboard || name == '/vault') {
      return const PrivateVaultDashboardScreen();
    }

    if (name == settings) {
      final sl = GetIt.I;
      return VaultSettingsScreen(
        authService: sl.isRegistered<IVaultAuthService>() ? sl<IVaultAuthService>() : null,
        monotonicClock: sl.isRegistered<IMonotonicClock>() ? sl<IMonotonicClock>() : null,
        unlockVaultUseCase: sl.isRegistered<UnlockVaultUseCase>() ? sl<UnlockVaultUseCase>() : null,
        rotatePinUseCase: sl.isRegistered<RotatePinUseCase>() ? sl<RotatePinUseCase>() : null,
        purgeVaultDataUseCase: sl.isRegistered<PurgeVaultDataUseCase>() ? sl<PurgeVaultDataUseCase>() : null,
      );
    }

    if (name == settingsAppearance) {
      return const VaultAppearanceSettingsScreen();
    }

    if (name == settingsSecurity) {
      final sl = GetIt.I;
      return VaultSecuritySettingsScreen(
        authService: sl.isRegistered<IVaultAuthService>() ? sl<IVaultAuthService>() : null,
        monotonicClock: sl.isRegistered<IMonotonicClock>() ? sl<IMonotonicClock>() : null,
        unlockVaultUseCase: sl.isRegistered<UnlockVaultUseCase>() ? sl<UnlockVaultUseCase>() : null,
        rotatePinUseCase: sl.isRegistered<RotatePinUseCase>() ? sl<RotatePinUseCase>() : null,
      );
    }

    if (name == settingsPrivacy) {
      return const VaultPrivacySettingsScreen();
    }

    if (name == settingsGesture) {
      return const VaultGestureSettingsScreen();
    }

    if (name == settingsDanger) {
      final sl = GetIt.I;
      return VaultDangerZoneScreen(
        authService: sl.isRegistered<IVaultAuthService>() ? sl<IVaultAuthService>() : null,
        monotonicClock: sl.isRegistered<IMonotonicClock>() ? sl<IMonotonicClock>() : null,
        unlockVaultUseCase: sl.isRegistered<UnlockVaultUseCase>() ? sl<UnlockVaultUseCase>() : null,
        purgeVaultDataUseCase: sl.isRegistered<PurgeVaultDataUseCase>() ? sl<PurgeVaultDataUseCase>() : null,
      );
    }

    if (name == enrollment) {
      if (arguments is VoidCallback) {
        return GestureEnrollmentScreen(onEnrollmentComplete: arguments);
      }
      return const GestureEnrollmentScreen();
    }

    if (name.startsWith(playlistPrefix)) {
      final playlistId = name.substring(playlistPrefix.length);
      final sl = GetIt.I;
      return PrivatePlaylistDetailScreen(
        playlistId: playlistId,
        storageRepository: sl.isRegistered<IVaultStorageRepository>() ? sl<IVaultStorageRepository>() : null,
        audioPlaybackService: sl.isRegistered<VaultAudioPlaybackService>() ? sl<VaultAudioPlaybackService>() : null,
      );
    }

    if (name == playlist) {
      if (arguments is String && arguments.isNotEmpty) {
        final sl = GetIt.I;
        return PrivatePlaylistDetailScreen(
          playlistId: arguments,
          storageRepository: sl.isRegistered<IVaultStorageRepository>() ? sl<IVaultStorageRepository>() : null,
          audioPlaybackService: sl.isRegistered<VaultAudioPlaybackService>() ? sl<VaultAudioPlaybackService>() : null,
        );
      }
      return null;
    }

    return null;
  }

  static T? _safeResolve<T extends Object>(BuildContext context) {
    try {
      return context.read<T>();
    } catch (_) {
      return null;
    }
  }
}
