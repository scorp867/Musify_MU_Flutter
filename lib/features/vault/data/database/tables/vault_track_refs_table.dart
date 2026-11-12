import 'package:drift/drift.dart';
import 'package:musify_mu/features/vault/data/database/tables/vault_playlists_table.dart';

/// Drift table schema for encrypted private track references.
@DataClassName('VaultTrackRefEntry')
class VaultTrackRefsTable extends Table {
  @override
  String get tableName => 'vault_track_refs';

  /// Unique track reference identifier.
  TextColumn get id => text()();

  /// Foreign key referencing the parent playlist with cascade delete.
  TextColumn get playlistId => text().references(
        VaultPlaylistsTable,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// Zero-based contiguous sequence index within the playlist.
  IntColumn get trackIndex => integer()();

  /// Encrypted JSON payload holding auxiliary metadata (trackUri, sourceType, addedAtEpochMs).
  BlobColumn get encryptedTrackMetadata => blob().nullable()();

  /// Sandbox relative file path for isolated local tracks (e.g. `vault_media/.nomedia/<track_id>.mp3`).
  TextColumn get isolatedMediaFileName => text().nullable()();

  /// AES-256-GCM encrypted track title.
  BlobColumn get encryptedTitle => blob()();

  /// AES-256-GCM encrypted artist name.
  BlobColumn get encryptedArtist => blob()();

  /// AES-256-GCM encrypted album title.
  BlobColumn get encryptedAlbum => blob()();

  /// Unencrypted track duration in milliseconds.
  IntColumn get durationMs => integer()();

  /// Schema row payload version (`1` = legacy per-field blobs, `2` = single consolidated track blob).
  IntColumn get payloadVersion => integer().withDefault(const Constant(1))();

  /// Consolidated v2 AES-256-GCM encrypted track JSON containing title, artist, album, and metadata.
  BlobColumn get encryptedTrackPayload => blob().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
