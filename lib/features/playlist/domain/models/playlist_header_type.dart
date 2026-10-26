library;

/// Represents Spotify's 2 distinct playlist header layout styles
/// (`pu40.java`, `hzm.java`, `b7r.java`, `u0n.java`).
enum PlaylistHeaderType {
  /// 1. Editorial / Curated Playlist Header (`b7r.java`, `image_header_content.xml`):
  /// - Full-bleed background artwork canvas with downward ambient gradient
  /// - Large bold TitleLarge typography (32sp)
  /// - Long-form editorial description excerpt
  /// - Official Spotify avatar with verified creator badge
  /// - Aggregate social telemetry: formatted follower / save counter + total duration
  /// - Save to Library (+) button in action row
  /// - Zero curation chips row
  editorial,

  /// 2. User-Owned / Personal Playlist Header (`u0n.java`, `expanded_header.xml`):
  /// - Centered square artwork card with scroll scale-down and opacity fade
  /// - TitleMedium typography (24sp)
  /// - Custom user description (if provided)
  /// - User avatar + collaborator (+) button + user display name
  /// - Telemetry displays pure duration only (no public saves count)
  /// - No "Save to Library" button in action row (user is already owner)
  /// - Full curation chips row: Add, Edit, Name & details, Sort
  userOwned,

  /// 3. Followed / 3rd-Party User Playlist:
  /// - Centered square artwork card
  /// - TitleMedium typography (24sp)
  /// - Creator avatar + creator display name
  /// - Telemetry displays duration and saves (if available)
  /// - Save to Library (+) button in action row
  /// - Curation chips row displays Sort only
  followed,
}
