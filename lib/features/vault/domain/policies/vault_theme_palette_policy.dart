/// Visual theme palette policy for the Musify Secure Vault.
///
/// Pure Dart domain model: does not import Flutter UI libraries or dart:ui.
/// Colors are defined as 32-bit ARGB integer values and hexadecimal strings.
enum VaultThemePalettePolicyEnum {
  /// Palette 1: Warm Espresso.
  ///
  /// - Scaffold: #1A120E (0xFF1A120E)
  /// - Background: #3A2418 (0xFF3A2418)
  /// - Cards / Surfaces: #6B4A2E (0xFF6B4A2E)
  /// - Text & High-Salience Elements: #A88462 (0xFFA88462)
  warmEspresso(
    id: 'WARM_ESPRESSO',
    displayName: 'Warm Espresso',
    scaffoldColorValue: 0xFF1A120E,
    backgroundColorValue: 0xFF3A2418,
    surfaceColorValue: 0xFF6B4A2E,
    textHighSalienceColorValue: 0xFFA88462,
    scaffoldHex: '#1A120E',
    backgroundHex: '#3A2418',
    surfaceHex: '#6B4A2E',
    textHighSalienceHex: '#A88462',
  ),

  /// Palette 2: Forest Noir.
  ///
  /// - Scaffold: #0F1F17 (0xFF0F1F17)
  /// - Background: #1E3A2E (0xFF1E3A2E)
  /// - Cards / Surfaces: #3E5A3F (0xFF3E5A3F)
  /// - Text & High-Salience Elements: #6B7F67 (0xFF6B7F67)
  forestNoir(
    id: 'FOREST_NOIR',
    displayName: 'Forest Noir',
    scaffoldColorValue: 0xFF0F1F17,
    backgroundColorValue: 0xFF1E3A2E,
    surfaceColorValue: 0xFF3E5A3F,
    textHighSalienceColorValue: 0xFF6B7F67,
    scaffoldHex: '#0F1F17',
    backgroundHex: '#1E3A2E',
    surfaceHex: '#3E5A3F',
    textHighSalienceHex: '#6B7F67',
  );

  /// Canonical serialization identifier.
  final String id;

  /// User-facing display title.
  final String displayName;

  /// Scaffold background color as 32-bit ARGB integer.
  final int scaffoldColorValue;

  /// Primary background color as 32-bit ARGB integer.
  final int backgroundColorValue;

  /// Surface and card container color as 32-bit ARGB integer.
  final int surfaceColorValue;

  /// High-salience typography and highlight color as 32-bit ARGB integer.
  final int textHighSalienceColorValue;

  /// Hexadecimal string for scaffold (#RRGGBB).
  final String scaffoldHex;

  /// Hexadecimal string for background (#RRGGBB).
  final String backgroundHex;

  /// Hexadecimal string for surface (#RRGGBB).
  final String surfaceHex;

  /// Hexadecimal string for high-salience text (#RRGGBB).
  final String textHighSalienceHex;

  const VaultThemePalettePolicyEnum({
    required this.id,
    required this.displayName,
    required this.scaffoldColorValue,
    required this.backgroundColorValue,
    required this.surfaceColorValue,
    required this.textHighSalienceColorValue,
    required this.scaffoldHex,
    required this.backgroundHex,
    required this.surfaceHex,
    required this.textHighSalienceHex,
  });

  /// Serializes the policy to its unique identifier string.
  String toJson() => id;

  /// Deserializes a string identifier into [VaultThemePalettePolicyEnum].
  ///
  /// Throws [FormatException] if [id] is empty or does not match any variant.
  static VaultThemePalettePolicyEnum fromId(String id) {
    for (final palette in VaultThemePalettePolicyEnum.values) {
      if (palette.id == id || palette.name == id) {
        return palette;
      }
    }
    throw FormatException(
      'Invalid VaultThemePalettePolicyEnum identifier: "$id". '
      'Valid options are: ${VaultThemePalettePolicyEnum.values.map((v) => v.id).join(', ')}.',
    );
  }

  /// Alias for [fromId] supporting JSON decoding pipelines.
  static VaultThemePalettePolicyEnum fromJson(String json) => fromId(json);
}
