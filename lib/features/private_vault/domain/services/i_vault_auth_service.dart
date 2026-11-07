/// Exhaustive domain status representing the result of a biometric verification attempt.
enum BiometricAuthStatus {
  notRequested,
  authenticating,
  success,
  canceled,
  failed,
  notAvailableOrEnrolled,
}

/// Pure domain abstraction for device biometric and payment-grade lockscreen verification.
abstract interface class IVaultAuthService {
  Future<bool> isBiometricAvailable();
  Future<BiometricAuthStatus> authenticate({required String localizedReason});
}
