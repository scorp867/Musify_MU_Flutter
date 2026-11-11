/// Window privacy and screenshot prevention policy for the Secure Vault.
///
/// Controls native Android WindowManager.LayoutParams.FLAG_SECURE application.
enum ScreenSecurityPolicyEnum {
  /// Standard window behavior. Screenshots and task switcher thumbnails are allowed.
  allowCapture(
    id: 'ALLOW_CAPTURE',
    displayName: 'Allow Screen Capture',
    description: 'Permit screenshots and task previews of vault screens.',
  ),

  /// Android FLAG_SECURE is engaged.
  ///
  /// Blocks screenshots, screen capture/recording, and blanks out vault previews
  /// in the Android Recents task switcher.
  blockScreenshotsAndRecents(
    id: 'BLOCK_SCREENSHOTS_AND_RECENTS',
    displayName: 'Block Screenshots & Recents',
    description: 'Enforce Android FLAG_SECURE to block screen recording and hide recents thumbnail.',
  );

  /// Canonical serialization identifier.
  final String id;

  /// User-facing display title.
  final String displayName;

  /// Policy description for settings screens.
  final String description;

  const ScreenSecurityPolicyEnum({
    required this.id,
    required this.displayName,
    required this.description,
  });

  /// Evaluates whether the OS window must engage FLAG_SECURE under this policy.
  bool get requiresSecureFlag => this == ScreenSecurityPolicyEnum.blockScreenshotsAndRecents;

  /// Serializes the policy to its unique identifier string.
  String toJson() => id;

  /// Deserializes a string identifier into [ScreenSecurityPolicyEnum].
  ///
  /// Throws [FormatException] if [id] does not match any variant.
  static ScreenSecurityPolicyEnum fromId(String id) {
    for (final policy in ScreenSecurityPolicyEnum.values) {
      if (policy.id == id || policy.name == id) {
        return policy;
      }
    }
    throw FormatException(
      'Invalid ScreenSecurityPolicyEnum identifier: "$id". '
      'Valid options are: ${ScreenSecurityPolicyEnum.values.map((v) => v.id).join(', ')}.',
    );
  }

  /// Alias for [fromId] supporting JSON decoding pipelines.
  static ScreenSecurityPolicyEnum fromJson(String json) => fromId(json);
}
