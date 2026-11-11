/// Policy controlling audio metadata visibility across public system surfaces.
///
/// Dictates whether outgoing ContextTrack metadata is masked with decoy values
/// when playing vault media on OS notifications, Bluetooth AVRCP, and lockscreens.
enum MetadataVisibilityPolicyEnum {
  /// Mask metadata with configurable decoy persona fields.
  ///
  /// Replaces real title, artist, and album with decoy placeholder values
  /// to preserve privacy from shoulder surfing and public media sessions.
  maskWithPlaceholder(
    id: 'MASK_WITH_PLACEHOLDER',
    displayName: 'Mask with Placeholder',
    description: 'Mask track details in OS notifications and lockscreen with decoy information.',
  ),

  /// Show actual track metadata decrypted from the vault.
  showActualMetadata(
    id: 'SHOW_ACTUAL_METADATA',
    displayName: 'Show Actual Metadata',
    description: 'Broadcast real track title and artist to OS media controls.',
  );

  /// Default decoy track title per specification §5.H.
  static const String defaultDecoyTitle = 'System Audio';

  /// Default decoy artist name per specification §5.H.
  static const String defaultDecoyArtist = 'Media Service';

  /// Default decoy album name per specification §5.H.
  static const String defaultDecoyAlbum = 'Internal Playback';

  /// Canonical serialization identifier.
  final String id;

  /// User-facing display title.
  final String displayName;

  /// Policy description for settings screens.
  final String description;

  const MetadataVisibilityPolicyEnum({
    required this.id,
    required this.displayName,
    required this.description,
  });

  /// Evaluates whether metadata must be masked under this policy.
  bool get isMasked => this == MetadataVisibilityPolicyEnum.maskWithPlaceholder;

  /// Evaluates whether real metadata is visible under this policy.
  bool get isActualMetadataVisible => this == MetadataVisibilityPolicyEnum.showActualMetadata;

  /// Serializes the policy to its unique identifier string.
  String toJson() => id;

  /// Deserializes a string identifier into [MetadataVisibilityPolicyEnum].
  ///
  /// Throws [FormatException] if [id] does not match any variant.
  static MetadataVisibilityPolicyEnum fromId(String id) {
    for (final policy in MetadataVisibilityPolicyEnum.values) {
      if (policy.id == id || policy.name == id) {
        return policy;
      }
    }
    throw FormatException(
      'Invalid MetadataVisibilityPolicyEnum identifier: "$id". '
      'Valid options are: ${MetadataVisibilityPolicyEnum.values.map((v) => v.id).join(', ')}.',
    );
  }

  /// Alias for [fromId] supporting JSON decoding pipelines.
  static MetadataVisibilityPolicyEnum fromJson(String json) => fromId(json);
}
