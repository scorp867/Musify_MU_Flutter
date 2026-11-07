/// Exhaustive enumeration of available color themes for the Private Vault.
enum VaultTheme {
  /// Set 1: Deep forest, pine, moss, sage, pale ash stone.
  deepMoss,

  /// Set 2: Pitch dark, charcoal, stone grey, warm ivory.
  obsidianCream;

  /// Serializes the theme to a string representation.
  String toJson() => name;

  /// Deserializes a string into a [VaultTheme] with fail-fast validation.
  static VaultTheme fromJson(String value) {
    return switch (value) {
      'deepMoss' => VaultTheme.deepMoss,
      'obsidianCream' => VaultTheme.obsidianCream,
      _ => throw FormatException('Unknown VaultTheme: $value'),
    };
  }
}
