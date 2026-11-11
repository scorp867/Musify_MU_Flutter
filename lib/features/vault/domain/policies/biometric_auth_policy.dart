/// Policy controlling biometric authentication availability in the Secure Vault.
///
/// Determines whether Android KeyStore Class 3 (Strong) biometrics are authorized
/// for master key unwrapping alongside the mandatory 6-digit PIN.
enum BiometricAuthPolicyEnum {
  /// User must authenticate strictly using the fixed 6-digit PIN.
  /// Biometric prompt is not shown and biometric keys remain disengaged.
  pinOnly(
    id: 'PIN_ONLY',
    displayName: 'PIN Only',
    description: 'Require fixed 6-digit PIN for all vault unlock and authorization events.',
  ),

  /// Biometrics (Fingerprint/Face Class 3) are active alongside the 6-digit PIN.
  /// KeyStore BiometricPrompt.CryptoObject is utilized for fast unlocking.
  pinAndBiometricStrong(
    id: 'PIN_AND_BIOMETRIC_STRONG',
    displayName: 'PIN & Strong Biometrics',
    description: 'Allow Android KeyStore Class 3 biometrics with guaranteed PIN fallback.',
  );

  /// Canonical serialization identifier.
  final String id;

  /// User-facing display title.
  final String displayName;

  /// Policy description for settings screens.
  final String description;

  const BiometricAuthPolicyEnum({
    required this.id,
    required this.displayName,
    required this.description,
  });

  /// Evaluates whether biometrics are authorized under this policy.
  bool get allowsBiometrics => this == BiometricAuthPolicyEnum.pinAndBiometricStrong;

  /// Evaluates whether authentication requires PIN only under this policy.
  bool get requiresPinOnly => this == BiometricAuthPolicyEnum.pinOnly;

  /// Serializes the policy to its unique identifier string.
  String toJson() => id;

  /// Deserializes a string identifier into [BiometricAuthPolicyEnum].
  ///
  /// Throws [FormatException] if [id] does not match any variant.
  static BiometricAuthPolicyEnum fromId(String id) {
    for (final policy in BiometricAuthPolicyEnum.values) {
      if (policy.id == id || policy.name == id) {
        return policy;
      }
    }
    throw FormatException(
      'Invalid BiometricAuthPolicyEnum identifier: "$id". '
      'Valid options are: ${BiometricAuthPolicyEnum.values.map((v) => v.id).join(', ')}.',
    );
  }

  /// Alias for [fromId] supporting JSON decoding pipelines.
  static BiometricAuthPolicyEnum fromJson(String json) => fromId(json);
}
