import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:musify_mu/features/private_vault/domain/services/i_vault_auth_service.dart';

export 'package:musify_mu/features/private_vault/domain/services/i_vault_auth_service.dart';

/// Production implementation wrapping local_auth with Android BiometricPrompt and Device PIN fallback.
final class VaultAuthService implements IVaultAuthService {
  final LocalAuthentication _localAuth;

  VaultAuthService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  @override
  Future<bool> isBiometricAvailable() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) {
        return false;
      }
      final canCheck = await _localAuth.canCheckBiometrics;
      return canCheck;
    } on LocalAuthException {
      return false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<BiometricAuthStatus> authenticate({required String localizedReason}) async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) {
        return BiometricAuthStatus.notAvailableOrEnrolled;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: false,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );

      if (authenticated) {
        return BiometricAuthStatus.success;
      }
      return BiometricAuthStatus.canceled;
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.timeout:
          return BiometricAuthStatus.canceled;

        case LocalAuthExceptionCode.noCredentialsSet:
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          return BiometricAuthStatus.notAvailableOrEnrolled;

        case LocalAuthExceptionCode.authInProgress:
          return BiometricAuthStatus.authenticating;

        case LocalAuthExceptionCode.uiUnavailable:
        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
        case LocalAuthExceptionCode.userRequestedFallback:
        case LocalAuthExceptionCode.deviceError:
        case LocalAuthExceptionCode.unknownError:
          return BiometricAuthStatus.failed;
      }
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable' ||
          e.code == 'PasscodeNotSet' ||
          e.code == 'NotEnrolled') {
        return BiometricAuthStatus.notAvailableOrEnrolled;
      }
      return BiometricAuthStatus.failed;
    } catch (_) {
      return BiometricAuthStatus.failed;
    }
  }
}
