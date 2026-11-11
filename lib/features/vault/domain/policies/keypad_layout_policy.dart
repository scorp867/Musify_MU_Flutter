/// Policy controlling the arrangement of numeric digits on the 6-digit PIN authentication pad.
///
/// Designed to defeat shoulder-surfing and touchscreen smudge/fingerprint residue analysis.
enum KeypadLayoutPolicyEnum {
  /// Standard fixed ascending keypad arrangement: [1, 2, 3, 4, 5, 6, 7, 8, 9, 0].
  standardOrdered(
    id: 'STANDARD_ORDERED',
    displayName: 'Standard Ordered (1-9, 0)',
    description: 'Fixed telephone numeric arrangement.',
  ),

  /// Digits 0 through 9 are dynamically shuffled on each presentation or retry attempt.
  randomizedPerAttempt(
    id: 'RANDOMIZED_PER_ATTEMPT',
    displayName: 'Randomized per Attempt',
    description: 'Shuffle digit positions on every PIN entry attempt to defeat smudge attacks.',
  );

  /// Standard unmodifiable digit ordering.
  static const List<int> standardDigits = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0];

  /// Canonical serialization identifier.
  final String id;

  /// User-facing display title.
  final String displayName;

  /// Policy description for settings screens.
  final String description;

  const KeypadLayoutPolicyEnum({
    required this.id,
    required this.displayName,
    required this.description,
  });

  /// Evaluates whether keypad digits should be shuffled per attempt.
  bool get isRandomized => this == KeypadLayoutPolicyEnum.randomizedPerAttempt;

  /// Resolves the digit sequence to display on the keypad.
  ///
  /// If [this] is [standardOrdered], unconditionally returns [standardDigits].
  /// If [this] is [randomizedPerAttempt], validates and returns [shuffledDigits].
  ///
  /// Throws [ArgumentError] if [randomizedPerAttempt] is selected but [shuffledDigits]
  /// is null, does not contain exactly 10 digits, or contains duplicates.
  List<int> resolveDigits({List<int>? shuffledDigits}) {
    switch (this) {
      case KeypadLayoutPolicyEnum.standardOrdered:
        return standardDigits;
      case KeypadLayoutPolicyEnum.randomizedPerAttempt:
        if (shuffledDigits == null) {
          throw ArgumentError(
            'shuffledDigits must be provided when KeypadLayoutPolicyEnum is randomizedPerAttempt',
          );
        }
        if (shuffledDigits.length != 10) {
          throw ArgumentError(
            'shuffledDigits must contain exactly 10 digits, got ${shuffledDigits.length}',
          );
        }
        final set = shuffledDigits.toSet();
        if (set.length != 10 || !set.containsAll(standardDigits)) {
          throw ArgumentError(
            'shuffledDigits must contain all digits 0-9 without omission or duplicates',
          );
        }
        return List<int>.unmodifiable(shuffledDigits);
    }
  }

  /// Serializes the policy to its unique identifier string.
  String toJson() => id;

  /// Deserializes a string identifier into [KeypadLayoutPolicyEnum].
  ///
  /// Throws [FormatException] if [id] does not match any variant.
  static KeypadLayoutPolicyEnum fromId(String id) {
    for (final layout in KeypadLayoutPolicyEnum.values) {
      if (layout.id == id || layout.name == id) {
        return layout;
      }
    }
    throw FormatException(
      'Invalid KeypadLayoutPolicyEnum identifier: "$id". '
      'Valid options are: ${KeypadLayoutPolicyEnum.values.map((v) => v.id).join(', ')}.',
    );
  }

  /// Alias for [fromId] supporting JSON decoding pipelines.
  static KeypadLayoutPolicyEnum fromJson(String json) => fromId(json);
}
