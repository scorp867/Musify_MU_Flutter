/// Policy controlling the visual rendering of the stealth touch pad ink trail.
///
/// Governs whether touch gestures on the DrawerMenu stealth canvas display
/// visual feedback or remain completely invisible.
enum GestureVisibilityPolicyEnum {
  /// Pure stealth mode: 0 ink rendered on screen.
  ///
  /// Touches are tracked by the gesture detector, but nothing is drawn.
  /// Default policy providing maximum plausible deniability.
  invisibleStealth(
    id: 'INVISIBLE_STEALTH',
    displayName: 'Invisible Stealth (0 Ink)',
    description: 'Do not render any ink trails; gestures remain completely invisible.',
  ),

  /// Subtle dissipating hairline ink trail.
  ///
  /// Draws a faint 1px hairline path that quickly dissipates behind the finger
  /// (150ms-280ms duration curve) to give subtle tactile confidence without leaving trails.
  faintDissipatingHairline(
    id: 'FAINT_DISSIPATING_HAIRLINE',
    displayName: 'Faint Dissipating Hairline',
    description: 'Render a faint, fast-dissolving stroke trail while drawing.',
  );

  /// Canonical serialization identifier.
  final String id;

  /// User-facing display title.
  final String displayName;

  /// Policy description for settings screens.
  final String description;

  const GestureVisibilityPolicyEnum({
    required this.id,
    required this.displayName,
    required this.description,
  });

  /// Evaluates whether ink trails must be rendered on the stealth pad.
  bool get isInkVisible => this == GestureVisibilityPolicyEnum.faintDissipatingHairline;

  /// Evaluates whether stealth mode is strictly invisible.
  bool get isInvisible => this == GestureVisibilityPolicyEnum.invisibleStealth;

  /// Serializes the policy to its unique identifier string.
  String toJson() => id;

  /// Deserializes a string identifier into [GestureVisibilityPolicyEnum].
  ///
  /// Throws [FormatException] if [id] does not match any variant.
  static GestureVisibilityPolicyEnum fromId(String id) {
    for (final policy in GestureVisibilityPolicyEnum.values) {
      if (policy.id == id || policy.name == id) {
        return policy;
      }
    }
    throw FormatException(
      'Invalid GestureVisibilityPolicyEnum identifier: "$id". '
      'Valid options are: ${GestureVisibilityPolicyEnum.values.map((v) => v.id).join(', ')}.',
    );
  }

  /// Alias for [fromId] supporting JSON decoding pipelines.
  static GestureVisibilityPolicyEnum fromJson(String json) => fromId(json);
}
