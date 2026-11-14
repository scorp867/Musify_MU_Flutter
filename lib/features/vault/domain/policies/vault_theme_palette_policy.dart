/// Visual theme palette policy for the Musify Secure Vault.
///
/// Pure Dart domain model: does not import Flutter UI libraries or dart:ui.
/// Colors are defined as 32-bit ARGB integer values and hexadecimal strings.
enum VaultThemePalettePolicyEnum {
  /// Palette 1: Warm Espresso.
  ///
  /// - Scaffold: #120E0C (0xFF120E0C)
  /// - Background: #1E1814 (0xFF1E1814)
  /// - Cards / Surfaces: #231C18 (0xFF231C18)
  /// - Text & High-Salience Elements: #ECE6E0 (0xFFECE6E0)
  warmEspresso(
    id: 'WARM_ESPRESSO',
    displayName: 'Warm Espresso',
    scaffoldColorValue: 0xFF120E0C,
    backgroundColorValue: 0xFF1E1814,
    surfaceColorValue: 0xFF231C18,
    textHighSalienceColorValue: 0xFFECE6E0,
    scaffoldHex: '#120E0C',
    backgroundHex: '#1E1814',
    surfaceHex: '#231C18',
    textHighSalienceHex: '#ECE6E0',
  ),

  /// Palette 2: Forest Noir.
  ///
  /// - Scaffold: #0B120E (0xFF0B120E)
  /// - Background: #15221B (0xFF15221B)
  /// - Cards / Surfaces: #1A2821 (0xFF1A2821)
  /// - Text & High-Salience Elements: #E3EBE6 (0xFFE3EBE6)
  forestNoir(
    id: 'FOREST_NOIR',
    displayName: 'Forest Noir',
    scaffoldColorValue: 0xFF0B120E,
    backgroundColorValue: 0xFF15221B,
    surfaceColorValue: 0xFF1A2821,
    textHighSalienceColorValue: 0xFFE3EBE6,
    scaffoldHex: '#0B120E',
    backgroundHex: '#15221B',
    surfaceHex: '#1A2821',
    textHighSalienceHex: '#E3EBE6',
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
