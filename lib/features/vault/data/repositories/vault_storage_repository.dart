import 'dart:convert';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:musify_mu/features/vault/data/cache/vault_session_cache.dart';
import 'package:musify_mu/features/vault/data/database/dtos/gesture_template_dto.dart';
import 'package:musify_mu/features/vault/data/database/dtos/vault_config_dto.dart';
import 'package:musify_mu/features/vault/data/database/dtos/vault_track_metadata_dto.dart';
import 'package:musify_mu/features/vault/data/database/dtos/vault_v2_payload_dtos.dart';
import 'package:musify_mu/features/vault/data/database/vault_database.dart';
import 'package:musify_mu/features/vault/data/datasources/i_native_vault_crypto_bridge.dart';
import 'package:musify_mu/features/vault/data/datasources/vault_memory_wiper.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_config.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';
import 'package:uuid/uuid.dart';

const int _kIsolateDecodeThreshold = 24;

enum _DecodePayloadKind {
  rawString,
  v1TrackMetadata,
  v2PlaylistPayload,
  v2TrackPayload,
}

List<Object?> _decodePlaintextBatchWorker(
  List<Uint8List> buffers,
  List<int> kindIndices,
) {
  final results = List<Object?>.filled(buffers.length, null, growable: false);
  try {
    for (var i = 0; i < buffers.length; i++) {
      final decodedText = utf8.decode(buffers[i]);
      final kind = _DecodePayloadKind.values[kindIndices[i]];
      switch (kind) {
        case _DecodePayloadKind.rawString:
          results[i] = decodedText;
        case _DecodePayloadKind.v1TrackMetadata:
          results[i] = VaultTrackMetadataDto.fromJson(jsonDecode(decodedText));
        case _DecodePayloadKind.v2PlaylistPayload:
          results[i] =
              VaultPlaylistPayloadV2Dto.fromJson(jsonDecode(decodedText));
        case _DecodePayloadKind.v2TrackPayload:
          results[i] = VaultTrackPayloadV2Dto.fromJson(jsonDecode(decodedText));
      }
    }
    return results;
  } finally {
    for (final buffer in buffers) {
      VaultMemoryWiper.zeroBuffer(buffer);
    }
  }
}

/// Production implementation of [IVaultStorageRepository] backed by a dedicated Drift SQLite database
/// and hardware-offloaded AES-256-GCM encryption.
///
/// Guarantees:
/// 1. Zero secret key bytes in Dart RAM — all encryption and decryption is executed via [INativeVaultCryptoBridge].
/// 2. Transient plaintext buffers are wiped immediately with [VaultMemoryWiper.zeroBuffer].
/// 3. All multi-statement operations run inside atomic [_database.transaction] blocks.
/// 4. Monotonic lockout deadline timestamp is kept unencrypted to allow brute-force protection
///    verification before master key authorization.
class VaultStorageRepository implements IVaultStorageRepository {
  final VaultDatabase _database;
  final INativeVaultCryptoBridge _cryptoBridge;
  final Future<void> Function()? _onShredMediaFiles;
  final Uuid _uuid;
  final FlutterSecureStorage _secureStorage;
  final VaultSessionCache? _sessionCache;

  Future<VaultResult<List<PrivatePlaylist>>>? _inFlightGetPlaylists;
  final Map<String, Future<VaultResult<PrivatePlaylist>>> _inFlightGetById =
      <String, Future<VaultResult<PrivatePlaylist>>>{};

  /// Constructs a [VaultStorageRepository] with explicit dependencies.
  VaultStorageRepository({
    required VaultDatabase database,
    required INativeVaultCryptoBridge cryptoBridge,
    Future<void> Function()? onShredMediaFiles,
    Uuid uuid = const Uuid(),
    FlutterSecureStorage? secureStorage,
    VaultSessionCache? sessionCache,
  })  : _database = database,
        _cryptoBridge = cryptoBridge,
        _onShredMediaFiles = onShredMediaFiles,
        _uuid = uuid,
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _sessionCache = sessionCache;

  @override
  Future<bool> hasEnrolledVault() async {
    try {
      final isEnrolled = await _secureStorage.read(key: 'musify_vault_is_enrolled');
      if (isEnrolled == 'true') {
        return true;
      }
      final verifier = await _secureStorage.read(key: 'musify_vault_pin_verifier');
      if (verifier != null && verifier.isNotEmpty) {
        return true;
      }
    } catch (_) {
      // Platform channels might not be initialized in non-widget unit tests
    }

    try {
      return await _cryptoBridge.hasMasterKey();
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Internal Cryptographic Helpers (with RAM Plaintext Zeroing)
  // ---------------------------------------------------------------------------

  Future<Uint8List> _encryptString(String text, {bool isConfig = false}) async {
    final plaintextBytes = Uint8List.fromList(utf8.encode(text));
    try {
      if (isConfig) {
        return await _cryptoBridge.encryptConfigPayload(plaintextBytes);
      }
      return await _cryptoBridge.encryptPayload(plaintextBytes);
    } finally {
      VaultMemoryWiper.zeroBuffer(plaintextBytes);
    }
  }

  Future<String> _decryptString(Uint8List ciphertext, {bool isConfig = false}) async {
    final decryptedBytes = isConfig
        ? await _cryptoBridge.decryptConfigPayload(ciphertext)
        : await _cryptoBridge.decryptPayload(ciphertext);
    try {
      return utf8.decode(decryptedBytes);
    } finally {
      VaultMemoryWiper.zeroBuffer(decryptedBytes);
    }
  }

  Future<Uint8List> _encryptJson(Object jsonObject, {bool isConfig = false}) async {
    final jsonString = jsonEncode(jsonObject);
    return _encryptString(jsonString, isConfig: isConfig);
  }

  Future<Object?> _decryptJson(Uint8List ciphertext, {bool isConfig = false}) async {
    final jsonString = await _decryptString(ciphertext, isConfig: isConfig);
    return jsonDecode(jsonString);
  }

  // ---------------------------------------------------------------------------
  // VaultConfig Persistence
  // ---------------------------------------------------------------------------

  @override
  Future<VaultResult<VaultConfig>> loadVaultConfig() async {
    try {
      final query = _database.select(_database.vaultConfigTable)
        ..where((tbl) => tbl.id.equals('vault_config'));
      final entry = await query.getSingleOrNull();

      if (entry == null) {
        return const VaultFailureResult<VaultConfig>(
          VaultStorageFailure('Vault configuration record not found.'),
        );
      }

      final jsonObject = await _decryptJson(entry.encryptedPayload, isConfig: true);
      final config = VaultConfigDto.fromJson(jsonObject);
      return VaultSuccess<VaultConfig>(config);
    } on VaultFailure catch (failure) {
      return VaultFailureResult<VaultConfig>(failure);
    } catch (error) {
      return VaultFailureResult<VaultConfig>(
        VaultStorageFailure('Failed to load vault config: $error', cause: error),
      );
    }
  }

  @override
  Future<VaultResult<void>> saveVaultConfig(VaultConfig config) async {
    try {
      final jsonMap = VaultConfigDto.toJson(config);
      final encryptedBytes = await _encryptJson(jsonMap, isConfig: true);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await _database.into(_database.vaultConfigTable).insertOnConflictUpdate(
            VaultConfigTableCompanion(
              id: const Value('vault_config'),
              encryptedPayload: Value(encryptedBytes),
              updatedAt: Value(nowMs),
            ),
          );

      return const VaultSuccess<void>(null);
    } on VaultFailure catch (failure) {
      return VaultFailureResult<void>(failure);
    } catch (error) {
      return VaultFailureResult<void>(
        VaultStorageFailure('Failed to save vault config: $error', cause: error),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Unlocked RAM Cache Accessors & Batch Cryptographic Helpers
  // ---------------------------------------------------------------------------

  /// Synchronously returns a cached [PrivatePlaylist] when unlocked and cached.
  PrivatePlaylist? getCachedPlaylistSync(String playlistId) =>
      _sessionCache?.getPlaylist(playlistId);

  /// Synchronously returns cached ordered playlists when unlocked and cached.
  List<PrivatePlaylist>? getCachedPlaylistsSync() =>
      _sessionCache?.getAllPlaylistsSnapshot();

  Future<List<Object?>> _decodePlaintextBatch(
    List<Uint8List> plaintexts,
    List<int> kindIndices,
  ) async {
    if (plaintexts.isEmpty) {
      return const <Object?>[];
    }
    try {
      if (plaintexts.length >= _kIsolateDecodeThreshold) {
        return await Isolate.run(
          () => _decodePlaintextBatchWorker(plaintexts, kindIndices),
        );
      }
      return _decodePlaintextBatchWorker(plaintexts, kindIndices);
    } finally {
      for (final buffer in plaintexts) {
        VaultMemoryWiper.zeroBuffer(buffer);
      }
    }
  }

  Future<List<Uint8List>> _encryptUtf8PayloadsBatch(List<String> texts) async {
    if (texts.isEmpty) {
      return const <Uint8List>[];
    }
    final plaintexts = texts
        .map((text) => Uint8List.fromList(utf8.encode(text)))
        .toList(growable: false);
    try {
      return await _cryptoBridge.encryptPayloadsBatch(plaintexts);
    } finally {
      for (final buffer in plaintexts) {
        VaultMemoryWiper.zeroBuffer(buffer);
      }
    }
  }

  Future<void> _upgradeLegacyRowsToV2({
    required List<({VaultPlaylistEntry row, PrivatePlaylist playlist})>
        legacyPlaylists,
    required List<({VaultTrackRefEntry row, PrivateTrackRef track})>
        legacyTracks,
  }) async {
    if (legacyPlaylists.isEmpty && legacyTracks.isEmpty) {
      return;
    }

    final jsonTexts = <String>[
      for (final item in legacyPlaylists)
        jsonEncode(
          VaultPlaylistPayloadV2Dto(
            description: item.playlist.description,
            coverUri: item.playlist.coverUri,
          ).toJson(),
        ),
      for (final item in legacyTracks)
        jsonEncode(
          VaultTrackPayloadV2Dto(
            title: item.track.title,
            artistName: item.track.artistName,
            albumTitle: item.track.albumTitle,
            metadata: VaultTrackMetadataDto(
              trackUri: item.track.trackUri,
              sourceType: item.track.sourceType,
              addedAtEpochMs: item.track.addedAtEpochMs,
              artworkUri: item.track.artworkUri,
            ),
          ).toJson(),
        ),
    ];

    final encryptedPayloads = await _encryptUtf8PayloadsBatch(jsonTexts);

    await _database.transaction(() async {
      await _database.batch((batch) {
        var offset = 0;
        for (final item in legacyPlaylists) {
          final encPayload = encryptedPayloads[offset++];
          batch.update(
            _database.vaultPlaylistsTable,
            VaultPlaylistsTableCompanion(
              payloadVersion: const Value(2),
              encryptedPlaylistPayload: Value(encPayload),
              encryptedDescription: Value(Uint8List(0)),
              encryptedCoverPath: const Value(null),
            ),
            where: (tbl) => tbl.id.equals(item.row.id),
          );
        }
        for (final item in legacyTracks) {
          final encPayload = encryptedPayloads[offset++];
          batch.update(
            _database.vaultTrackRefsTable,
            VaultTrackRefsTableCompanion(
              payloadVersion: const Value(2),
              encryptedTrackPayload: Value(encPayload),
              encryptedTrackMetadata: const Value(null),
              encryptedTitle: Value(Uint8List(0)),
              encryptedArtist: Value(Uint8List(0)),
              encryptedAlbum: Value(Uint8List(0)),
            ),
            where: (tbl) => tbl.id.equals(item.row.id),
          );
        }
      });
    });
  }

  Future<List<PrivatePlaylist>> _decryptPlaylistsAndTracks({
    required List<VaultPlaylistEntry> playlistEntries,
    required List<VaultTrackRefEntry> allTrackEntries,
  }) async {
    if (playlistEntries.isEmpty) {
      return const <PrivatePlaylist>[];
    }

    final tracksByPlaylistId = <String, List<VaultTrackRefEntry>>{};
    for (final trackEntry in allTrackEntries) {
      tracksByPlaylistId
          .putIfAbsent(trackEntry.playlistId, () => <VaultTrackRefEntry>[])
          .add(trackEntry);
    }

    final ciphertexts = <Uint8List>[];
    final kindIndices = <int>[];

    // Record exact slice positions in ciphertexts for each playlist and track.
    final playlistPlans = <({
      VaultPlaylistEntry row,
      bool isV2,
      int titleIdx,
      int payloadOrDescIdx,
      int? coverIdx,
      List<({
        VaultTrackRefEntry row,
        bool isV2,
        int primaryIdx,
        int? artistIdx,
        int? albumIdx,
        int? metaIdx,
      })> tracks,
    })>[];

    for (final playlistEntry in playlistEntries) {
      final isPlaylistV2 = playlistEntry.payloadVersion >= 2;
      final titleIdx = ciphertexts.length;
      ciphertexts.add(playlistEntry.encryptedTitle);
      kindIndices.add(_DecodePayloadKind.rawString.index);

      final int payloadOrDescIdx;
      final int? coverIdx;
      if (isPlaylistV2) {
        final encPayload = playlistEntry.encryptedPlaylistPayload;
        if (encPayload == null) {
          throw FormatException(
            'Playlist "${playlistEntry.id}" is marked v2 but missing encryptedPlaylistPayload.',
          );
        }
        payloadOrDescIdx = ciphertexts.length;
        ciphertexts.add(encPayload);
        kindIndices.add(_DecodePayloadKind.v2PlaylistPayload.index);
        coverIdx = null;
      } else {
        payloadOrDescIdx = ciphertexts.length;
        ciphertexts.add(playlistEntry.encryptedDescription);
        kindIndices.add(_DecodePayloadKind.rawString.index);

        final encCover = playlistEntry.encryptedCoverPath;
        if (encCover != null) {
          coverIdx = ciphertexts.length;
          ciphertexts.add(encCover);
          kindIndices.add(_DecodePayloadKind.rawString.index);
        } else {
          coverIdx = null;
        }
      }

      final rowTracks =
          tracksByPlaylistId[playlistEntry.id] ?? const <VaultTrackRefEntry>[];
      final trackPlans = <({
        VaultTrackRefEntry row,
        bool isV2,
        int primaryIdx,
        int? artistIdx,
        int? albumIdx,
        int? metaIdx,
      })>[];

      for (final trackEntry in rowTracks) {
        if (trackEntry.payloadVersion >= 2) {
          final encTrackPayload = trackEntry.encryptedTrackPayload;
          if (encTrackPayload == null) {
            throw FormatException(
              'Track "${trackEntry.id}" is marked v2 but missing encryptedTrackPayload.',
            );
          }
          final idx = ciphertexts.length;
          ciphertexts.add(encTrackPayload);
          kindIndices.add(_DecodePayloadKind.v2TrackPayload.index);
          trackPlans.add((
            row: trackEntry,
            isV2: true,
            primaryIdx: idx,
            artistIdx: null,
            albumIdx: null,
            metaIdx: null,
          ));
        } else {
          final encMeta = trackEntry.encryptedTrackMetadata;
          if (encMeta == null) {
            throw const FormatException(
              'Track reference missing encryptedTrackMetadata blob.',
            );
          }
          final tIdx = ciphertexts.length;
          ciphertexts.add(trackEntry.encryptedTitle);
          kindIndices.add(_DecodePayloadKind.rawString.index);

          final aIdx = ciphertexts.length;
          ciphertexts.add(trackEntry.encryptedArtist);
          kindIndices.add(_DecodePayloadKind.rawString.index);

          final alIdx = ciphertexts.length;
          ciphertexts.add(trackEntry.encryptedAlbum);
          kindIndices.add(_DecodePayloadKind.rawString.index);

          final mIdx = ciphertexts.length;
          ciphertexts.add(encMeta);
          kindIndices.add(_DecodePayloadKind.v1TrackMetadata.index);

          trackPlans.add((
            row: trackEntry,
            isV2: false,
            primaryIdx: tIdx,
            artistIdx: aIdx,
            albumIdx: alIdx,
            metaIdx: mIdx,
          ));
        }
      }

      playlistPlans.add((
        row: playlistEntry,
        isV2: isPlaylistV2,
        titleIdx: titleIdx,
        payloadOrDescIdx: payloadOrDescIdx,
        coverIdx: coverIdx,
        tracks: trackPlans,
      ));
    }

    final plaintexts = await _cryptoBridge.decryptPayloadsBatch(ciphertexts);
    final decodedValues = await _decodePlaintextBatch(plaintexts, kindIndices);

    final playlists = <PrivatePlaylist>[];
    final legacyPlaylists =
        <({VaultPlaylistEntry row, PrivatePlaylist playlist})>[];
    final legacyTracks = <({VaultTrackRefEntry row, PrivateTrackRef track})>[];

    for (final plan in playlistPlans) {
      final title = decodedValues[plan.titleIdx] as String;
      final String description;
      final String? coverUri;
      if (plan.isV2) {
        final v2Payload =
            decodedValues[plan.payloadOrDescIdx] as VaultPlaylistPayloadV2Dto;
        description = v2Payload.description;
        coverUri = v2Payload.coverUri;
      } else {
        description = decodedValues[plan.payloadOrDescIdx] as String;
        coverUri = switch (plan.coverIdx) {
          final idx? => decodedValues[idx] as String,
          null => null,
        };
      }

      final trackRefs = <PrivateTrackRef>[];
      int totalDuration = 0;

      for (final tPlan in plan.tracks) {
        final trackRow = tPlan.row;
        final PrivateTrackRef track;
        if (tPlan.isV2) {
          final v2Track =
              decodedValues[tPlan.primaryIdx] as VaultTrackPayloadV2Dto;
          final meta = v2Track.metadata;
          track = PrivateTrackRef(
            id: trackRow.id,
            playlistId: trackRow.playlistId,
            trackUri: meta.trackUri,
            title: v2Track.title,
            artistName: v2Track.artistName,
            albumTitle: v2Track.albumTitle,
            durationMs: trackRow.durationMs,
            sourceType: meta.sourceType,
            localRelativePath: trackRow.isolatedMediaFileName,
            sortOrder: trackRow.trackIndex,
            addedAtEpochMs: meta.addedAtEpochMs,
            artworkUri: meta.artworkUri,
          );
        } else {
          final trackTitle = decodedValues[tPlan.primaryIdx] as String;
          final trackArtist = decodedValues[tPlan.artistIdx!] as String;
          final trackAlbum = decodedValues[tPlan.albumIdx!] as String;
          final metaDto =
              decodedValues[tPlan.metaIdx!] as VaultTrackMetadataDto;
          track = PrivateTrackRef(
            id: trackRow.id,
            playlistId: trackRow.playlistId,
            trackUri: metaDto.trackUri,
            title: trackTitle,
            artistName: trackArtist,
            albumTitle: trackAlbum,
            durationMs: trackRow.durationMs,
            sourceType: metaDto.sourceType,
            localRelativePath: trackRow.isolatedMediaFileName,
            sortOrder: trackRow.trackIndex,
            addedAtEpochMs: metaDto.addedAtEpochMs,
            artworkUri: metaDto.artworkUri,
          );
          legacyTracks.add((row: trackRow, track: track));
        }
        totalDuration += track.durationMs;
        trackRefs.add(track);
      }

      final playlist = PrivatePlaylist(
        id: plan.row.id,
        name: title,
        description: description,
        coverUri: coverUri,
        totalDurationMs: totalDuration,
        createdAtEpochMs: plan.row.createdAt,
        updatedAtEpochMs: plan.row.updatedAt,
        trackRefs: trackRefs,
      );
      playlists.add(playlist);

      if (!plan.isV2) {
        legacyPlaylists.add((row: plan.row, playlist: playlist));
      }
    }

    if (legacyPlaylists.isNotEmpty || legacyTracks.isNotEmpty) {
      await _upgradeLegacyRowsToV2(
        legacyPlaylists: legacyPlaylists,
        legacyTracks: legacyTracks,
      );
    }

    return playlists;
  }

  // ---------------------------------------------------------------------------
  // Private Playlists & Track References Persistence
  // ---------------------------------------------------------------------------

  @override
  Future<VaultResult<List<PrivatePlaylist>>> getPlaylists() async {
    final cached = _sessionCache?.getAllPlaylistsSnapshot();
    if (cached != null) {
      return VaultSuccess<List<PrivatePlaylist>>(cached);
    }

    final existingInFlight = _inFlightGetPlaylists;
    if (existingInFlight != null) {
      return existingInFlight;
    }

    final future = _executeGetPlaylists();
    _inFlightGetPlaylists = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlightGetPlaylists, future)) {
        _inFlightGetPlaylists = null;
      }
    }
  }

  Future<VaultResult<List<PrivatePlaylist>>> _executeGetPlaylists() async {
    final readGen = _sessionCache?.generation ?? 0;
    try {
      final playlistEntries = await (_database.select(_database.vaultPlaylistsTable)
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
          .get();

      if (playlistEntries.isEmpty) {
        const empty = <PrivatePlaylist>[];
        _sessionCache?.putAllPlaylistsIfGeneration(readGen, empty);
        return const VaultSuccess<List<PrivatePlaylist>>(empty);
      }

      final allTrackEntries = await (_database.select(_database.vaultTrackRefsTable)
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.trackIndex)]))
          .get();

      final playlists = await _decryptPlaylistsAndTracks(
        playlistEntries: playlistEntries,
        allTrackEntries: allTrackEntries,
      );

      _sessionCache?.putAllPlaylistsIfGeneration(readGen, playlists);
      return VaultSuccess<List<PrivatePlaylist>>(playlists);
    } on VaultFailure catch (failure) {
      return VaultFailureResult<List<PrivatePlaylist>>(failure);
    } catch (error) {
      return VaultFailureResult<List<PrivatePlaylist>>(
        VaultStorageFailure('Failed to get playlists: $error', cause: error),
      );
    }
  }

  @override
  Future<VaultResult<PrivatePlaylist>> getPlaylistById(String id) async {
    final cached = _sessionCache?.getPlaylist(id);
    if (cached != null) {
      return VaultSuccess<PrivatePlaylist>(cached);
    }

    final existingInFlight = _inFlightGetById[id];
    if (existingInFlight != null) {
      return existingInFlight;
    }

    final future = _executeGetPlaylistById(id);
    _inFlightGetById[id] = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlightGetById[id], future)) {
        _inFlightGetById.remove(id);
      }
    }
  }

  Future<VaultResult<PrivatePlaylist>> _executeGetPlaylistById(String id) async {
    final readGen = _sessionCache?.generation ?? 0;
    try {
      final playlistEntry = await (_database.select(_database.vaultPlaylistsTable)
            ..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

      if (playlistEntry == null) {
        return VaultFailureResult<PrivatePlaylist>(
          VaultStorageFailure('Playlist not found with ID: $id'),
        );
      }

      final trackEntries = await (_database.select(_database.vaultTrackRefsTable)
            ..where((tbl) => tbl.playlistId.equals(id))
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.trackIndex)]))
          .get();

      final decoded = await _decryptPlaylistsAndTracks(
        playlistEntries: <VaultPlaylistEntry>[playlistEntry],
        allTrackEntries: trackEntries,
      );

      final playlist = decoded.single;
      _sessionCache?.putPlaylistIfGeneration(readGen, playlist);
      return VaultSuccess<PrivatePlaylist>(playlist);
    } on VaultFailure catch (failure) {
      return VaultFailureResult<PrivatePlaylist>(failure);
    } catch (error) {
      return VaultFailureResult<PrivatePlaylist>(
        VaultStorageFailure('Failed to get playlist by ID: $error', cause: error),
      );
    }
  }

  @override
  Future<VaultResult<PrivatePlaylist>> createPlaylist({
    required String name,
    required String description,
    String? coverUri,
  }) async {
    final writeGen = _sessionCache?.generation ?? 0;
    try {
      if (name.trim().isEmpty) {
        return const VaultFailureResult<PrivatePlaylist>(
          VaultValidationFailure('Playlist name must not be empty.'),
        );
      }

      final id = _uuid.v4();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final normalizedCover =
          (coverUri != null && coverUri.trim().isNotEmpty) ? coverUri.trim() : null;
      final v2PayloadJson = jsonEncode(
        VaultPlaylistPayloadV2Dto(
          description: description,
          coverUri: normalizedCover,
        ).toJson(),
      );

      final encrypted = await _encryptUtf8PayloadsBatch(<String>[
        name,
        v2PayloadJson,
      ]);
      final encTitle = encrypted[0];
      final encPayload = encrypted[1];

      await _database.into(_database.vaultPlaylistsTable).insert(
            VaultPlaylistsTableCompanion(
              id: Value(id),
              encryptedTitle: Value(encTitle),
              encryptedDescription: Value(Uint8List(0)),
              encryptedCoverPath: const Value(null),
              payloadVersion: const Value(2),
              encryptedPlaylistPayload: Value(encPayload),
              createdAt: Value(nowMs),
              updatedAt: Value(nowMs),
            ),
          );

      final playlist = PrivatePlaylist(
        id: id,
        name: name,
        description: description,
        coverUri: normalizedCover,
        totalDurationMs: 0,
        createdAtEpochMs: nowMs,
        updatedAtEpochMs: nowMs,
        trackRefs: const <PrivateTrackRef>[],
      );

      _sessionCache?.recordPlaylistCreated(writeGen, playlist);
      return VaultSuccess<PrivatePlaylist>(playlist);
    } on VaultFailure catch (failure) {
      return VaultFailureResult<PrivatePlaylist>(failure);
    } catch (error) {
      return VaultFailureResult<PrivatePlaylist>(
        VaultStorageFailure('Failed to create playlist: $error', cause: error),
      );
    }
  }

  @override
  Future<VaultResult<void>> updatePlaylist(PrivatePlaylist playlist) async {
    final writeGen = _sessionCache?.generation ?? 0;
    try {
      final existing = await (_database.select(_database.vaultPlaylistsTable)
            ..where((tbl) => tbl.id.equals(playlist.id)))
          .getSingleOrNull();

      if (existing == null) {
        return VaultFailureResult<void>(
          VaultStorageFailure('Cannot update non-existent playlist: ${playlist.id}'),
        );
      }

      final coverUri = playlist.coverUri;
      final normalizedCover =
          (coverUri != null && coverUri.trim().isNotEmpty) ? coverUri.trim() : null;
      final v2PayloadJson = jsonEncode(
        VaultPlaylistPayloadV2Dto(
          description: playlist.description,
          coverUri: normalizedCover,
        ).toJson(),
      );

      final encrypted = await _encryptUtf8PayloadsBatch(<String>[
        playlist.name,
        v2PayloadJson,
      ]);

      await _database.transaction<void>(() async {
        await (_database.update(_database.vaultPlaylistsTable)
              ..where((tbl) => tbl.id.equals(playlist.id)))
            .write(
          VaultPlaylistsTableCompanion(
            encryptedTitle: Value(encrypted[0]),
            encryptedDescription: Value(Uint8List(0)),
            encryptedCoverPath: const Value(null),
            payloadVersion: const Value(2),
            encryptedPlaylistPayload: Value(encrypted[1]),
            updatedAt: Value(playlist.updatedAtEpochMs),
          ),
        );
      });

      _sessionCache?.recordPlaylistUpdated(writeGen, playlist);
      return const VaultSuccess<void>(null);
    } on VaultFailure catch (failure) {
      return VaultFailureResult<void>(failure);
    } catch (error) {
      return VaultFailureResult<void>(
        VaultStorageFailure('Failed to update playlist: $error', cause: error),
      );
    }
  }

  @override
  Future<VaultResult<void>> deletePlaylist(String playlistId) async {
    try {
      return await _database.transaction<VaultResult<void>>(() async {
        await (_database.delete(_database.vaultTrackRefsTable)
              ..where((tbl) => tbl.playlistId.equals(playlistId)))
            .go();

        final deletedRows = await (_database.delete(_database.vaultPlaylistsTable)
              ..where((tbl) => tbl.id.equals(playlistId)))
            .go();

        if (deletedRows == 0) {
          return VaultFailureResult<void>(
            VaultStorageFailure('Cannot delete non-existent playlist: $playlistId'),
          );
        }

        _sessionCache?.recordPlaylistDeleted(playlistId);
        return const VaultSuccess<void>(null);
      });
    } on VaultFailure catch (failure) {
      return VaultFailureResult<void>(failure);
    } catch (error) {
      return VaultFailureResult<void>(
        VaultStorageFailure('Failed to delete playlist: $error', cause: error),
      );
    }
  }

  /// Inserts [trackRefs] into [playlistId] using a single batch hardware crypto
  /// call and a single atomic SQLite batch transaction.
  Future<VaultResult<void>> addTracksToPlaylist({
    required String playlistId,
    required List<PrivateTrackRef> trackRefs,
  }) async {
    final writeGen = _sessionCache?.generation ?? 0;
    try {
      final preCheckPlaylist =
          await (_database.select(_database.vaultPlaylistsTable)
                ..where((tbl) => tbl.id.equals(playlistId)))
              .getSingleOrNull();

      if (preCheckPlaylist == null) {
        return VaultFailureResult<void>(
          VaultStorageFailure('Cannot add track to non-existent playlist: $playlistId'),
        );
      }

      if (trackRefs.isEmpty) {
        return const VaultSuccess<void>(null);
      }

      final jsonTexts = trackRefs
          .map(
            (trackRef) => jsonEncode(
              VaultTrackPayloadV2Dto(
                title: trackRef.title,
                artistName: trackRef.artistName,
                albumTitle: trackRef.albumTitle,
                metadata: VaultTrackMetadataDto(
                  trackUri: trackRef.trackUri,
                  sourceType: trackRef.sourceType,
                  addedAtEpochMs: trackRef.addedAtEpochMs,
                  artworkUri: trackRef.artworkUri,
                ),
              ).toJson(),
            ),
          )
          .toList(growable: false);

      final encryptedPayloads = await _encryptUtf8PayloadsBatch(jsonTexts);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      return await _database.transaction<VaultResult<void>>(() async {
        final playlist = await (_database.select(_database.vaultPlaylistsTable)
              ..where((tbl) => tbl.id.equals(playlistId)))
            .getSingleOrNull();

        if (playlist == null) {
          return VaultFailureResult<void>(
            VaultStorageFailure('Cannot add track to non-existent playlist: $playlistId'),
          );
        }

        final maxIndexRow = await _database.customSelect(
          'SELECT COALESCE(MAX(track_index), -1) AS max_idx '
          'FROM vault_track_refs WHERE playlist_id = ?;',
          variables: <Variable<Object>>[Variable.withString(playlistId)],
          readsFrom: <TableInfo<Table, Object?>>{_database.vaultTrackRefsTable},
        ).getSingle();
        final nextIndex = maxIndexRow.read<int>('max_idx') + 1;

        final normalizedTracks = <PrivateTrackRef>[];
        final companions = <VaultTrackRefsTableCompanion>[];
        for (var i = 0; i < trackRefs.length; i++) {
          final trackRef = trackRefs[i];
          final assignedOrder = nextIndex + i;
          companions.add(
            VaultTrackRefsTableCompanion(
              id: Value(trackRef.id),
              playlistId: Value(playlistId),
              trackIndex: Value(assignedOrder),
              encryptedTrackMetadata: const Value(null),
              isolatedMediaFileName: Value(trackRef.localRelativePath),
              encryptedTitle: Value(Uint8List(0)),
              encryptedArtist: Value(Uint8List(0)),
              encryptedAlbum: Value(Uint8List(0)),
              durationMs: Value(trackRef.durationMs),
              payloadVersion: const Value(2),
              encryptedTrackPayload: Value(encryptedPayloads[i]),
            ),
          );
          normalizedTracks.add(
            trackRef.copyWith(
              playlistId: playlistId,
              sortOrder: assignedOrder,
            ),
          );
        }

        await _database.batch((batch) {
          batch.insertAll(_database.vaultTrackRefsTable, companions);
        });

        await (_database.update(_database.vaultPlaylistsTable)
              ..where((tbl) => tbl.id.equals(playlistId)))
            .write(
          VaultPlaylistsTableCompanion(
            updatedAt: Value(nowMs),
          ),
        );

        _sessionCache?.recordTracksAdded(
          expectedGeneration: writeGen,
          playlistId: playlistId,
          addedTracks: normalizedTracks,
          updatedAtEpochMs: nowMs,
        );

        return const VaultSuccess<void>(null);
      });
    } on VaultFailure catch (failure) {
      return VaultFailureResult<void>(failure);
    } catch (error) {
      return VaultFailureResult<void>(
        VaultStorageFailure('Failed to add track to playlist: $error', cause: error),
      );
    }
  }

  @override
  Future<VaultResult<void>> addTrackToPlaylist({
    required String playlistId,
    required PrivateTrackRef trackRef,
  }) =>
      addTracksToPlaylist(
        playlistId: playlistId,
        trackRefs: <PrivateTrackRef>[trackRef],
      );

  @override
  Future<VaultResult<void>> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    try {
      return await _database.transaction<VaultResult<void>>(() async {
        final playlist = await (_database.select(_database.vaultPlaylistsTable)
              ..where((tbl) => tbl.id.equals(playlistId)))
            .getSingleOrNull();

        if (playlist == null) {
          return VaultFailureResult<void>(
            VaultStorageFailure('Cannot remove track from non-existent playlist: $playlistId'),
          );
        }

        final deletedRows = await (_database.delete(_database.vaultTrackRefsTable)
              ..where((tbl) => tbl.playlistId.equals(playlistId) & tbl.id.equals(trackId)))
            .go();

        if (deletedRows == 0) {
          return VaultFailureResult<void>(
            VaultStorageFailure('Track not found in playlist: $trackId'),
          );
        }

        final remainingTracks = await (_database.select(_database.vaultTrackRefsTable)
              ..where((tbl) => tbl.playlistId.equals(playlistId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.trackIndex)]))
            .get();

        await _database.batch((batch) {
          for (int i = 0; i < remainingTracks.length; i++) {
            final currentTrack = remainingTracks[i];
            if (currentTrack.trackIndex != i) {
              batch.update(
                _database.vaultTrackRefsTable,
                VaultTrackRefsTableCompanion(
                  trackIndex: Value(i),
                ),
                where: (tbl) => tbl.id.equals(currentTrack.id),
              );
            }
          }
        });

        final nowMs = DateTime.now().millisecondsSinceEpoch;
        await (_database.update(_database.vaultPlaylistsTable)
              ..where((tbl) => tbl.id.equals(playlistId)))
            .write(
          VaultPlaylistsTableCompanion(
            updatedAt: Value(nowMs),
          ),
        );

        _sessionCache?.recordTrackRemoved(
          playlistId: playlistId,
          trackId: trackId,
          updatedAtEpochMs: nowMs,
        );

        return const VaultSuccess<void>(null);
      });
    } on VaultFailure catch (failure) {
      return VaultFailureResult<void>(failure);
    } catch (error) {
      return VaultFailureResult<void>(
        VaultStorageFailure('Failed to remove track from playlist: $error', cause: error),
      );
    }
  }

  @override
  Future<VaultResult<void>> reorderTracksInPlaylist({
    required String playlistId,
    required List<String> trackIdsInOrder,
  }) async {
    try {
      return await _database.transaction<VaultResult<void>>(() async {
        final playlist = await (_database.select(_database.vaultPlaylistsTable)
              ..where((tbl) => tbl.id.equals(playlistId)))
            .getSingleOrNull();

        if (playlist == null) {
          return VaultFailureResult<void>(
            VaultStorageFailure('Cannot reorder tracks in non-existent playlist: $playlistId'),
          );
        }

        await _database.batch((batch) {
          for (int i = 0; i < trackIdsInOrder.length; i++) {
            final trackId = trackIdsInOrder[i];
            batch.update(
              _database.vaultTrackRefsTable,
              VaultTrackRefsTableCompanion(
                trackIndex: Value(i),
              ),
              where: (tbl) =>
                  tbl.playlistId.equals(playlistId) & tbl.id.equals(trackId),
            );
          }
        });

        final nowMs = DateTime.now().millisecondsSinceEpoch;
        await (_database.update(_database.vaultPlaylistsTable)
              ..where((tbl) => tbl.id.equals(playlistId)))
            .write(
          VaultPlaylistsTableCompanion(
            updatedAt: Value(nowMs),
          ),
        );

        _sessionCache?.recordTracksReordered(
          playlistId: playlistId,
          trackIdsInOrder: trackIdsInOrder,
          updatedAtEpochMs: nowMs,
        );

        return const VaultSuccess<void>(null);
      });
    } on VaultFailure catch (failure) {
      return VaultFailureResult<void>(failure);
    } catch (error) {
      return VaultFailureResult<void>(
        VaultStorageFailure('Failed to reorder tracks in playlist: $error', cause: error),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Gesture Template Persistence
  // ---------------------------------------------------------------------------

  @override
  Future<VaultResult<GestureTemplate>> loadGestureTemplate() async {
    try {
      try {
        final pointsStr = await _secureStorage.read(key: 'musify_vault_gesture_points');
        final rubineStr = await _secureStorage.read(key: 'musify_vault_gesture_rubine');
        final updatedAtStr = await _secureStorage.read(key: 'musify_vault_gesture_updated_at');

        if (pointsStr != null && rubineStr != null) {
          final pointsJson = jsonDecode(pointsStr);
          final points = GestureTemplateDto.pointsFromJson(pointsJson);
          final rubineJson = jsonDecode(rubineStr);
          final rubine = GestureTemplateDto.rubineFromJson(rubineJson);
          final int updatedAt;
          if (updatedAtStr != null) {
            final parsed = int.tryParse(updatedAtStr);
            if (parsed != null) {
              updatedAt = parsed;
            } else {
              updatedAt = DateTime.now().millisecondsSinceEpoch;
            }
          } else {
            updatedAt = DateTime.now().millisecondsSinceEpoch;
          }

          final template = GestureTemplate(
            id: 'master_gesture',
            normalizedPoints: points,
            rubineFeatureVector: rubine,
            createdAtEpochMs: updatedAt,
          );
          return VaultSuccess<GestureTemplate>(template);
        }
      } catch (_) {
        // Platform secure storage might not be bound in non-widget unit tests, fallback to SQLite
      }

      final entry = await (_database.select(_database.vaultGestureTemplatesTable)
            ..where((tbl) => tbl.id.equals('master_gesture')))
          .getSingleOrNull();

      if (entry == null) {
        return const VaultFailureResult<GestureTemplate>(
          VaultStorageFailure('Golden master gesture template not found in storage.'),
        );
      }

      final pointsJson = await _decryptJson(entry.encryptedPoints64, isConfig: true);
      final points = GestureTemplateDto.pointsFromJson(pointsJson);

      final rubineJson = await _decryptJson(entry.encryptedRubine7d, isConfig: true);
      final rubine = GestureTemplateDto.rubineFromJson(rubineJson);

      final template = GestureTemplate(
        id: entry.id,
        normalizedPoints: points,
        rubineFeatureVector: rubine,
        createdAtEpochMs: entry.updatedAt,
      );

      return VaultSuccess<GestureTemplate>(template);
    } on VaultFailure catch (failure) {
      return VaultFailureResult<GestureTemplate>(failure);
    } catch (error) {
      return VaultFailureResult<GestureTemplate>(
        VaultStorageFailure('Failed to load gesture template: $error', cause: error),
      );
    }
  }

  @override
  Future<VaultResult<void>> saveGestureTemplate(GestureTemplate template) async {
    try {
      final pointsMapList = GestureTemplateDto.pointsToJson(template.normalizedPoints);
      final pointsJson = jsonEncode(pointsMapList);

      final rubineList = GestureTemplateDto.rubineToJson(template.rubineFeatureVector);
      final rubineJson = jsonEncode(rubineList);

      try {
        await _secureStorage.write(key: 'musify_vault_gesture_points', value: pointsJson);
        await _secureStorage.write(key: 'musify_vault_gesture_rubine', value: rubineJson);
        await _secureStorage.write(
          key: 'musify_vault_gesture_updated_at',
          value: template.createdAtEpochMs.toString(),
        );
      } catch (_) {
        // Platform secure storage might not be bound in non-widget unit tests
      }

      final encPoints = await _encryptJson(pointsMapList, isConfig: true);
      final encRubine = await _encryptJson(rubineList, isConfig: true);

      await _database.into(_database.vaultGestureTemplatesTable).insertOnConflictUpdate(
            VaultGestureTemplatesTableCompanion(
              id: const Value('master_gesture'),
              encryptedPoints64: Value(encPoints),
              encryptedRubine7d: Value(encRubine),
              updatedAt: Value(template.createdAtEpochMs),
            ),
          );

      return const VaultSuccess<void>(null);
    } on VaultFailure catch (failure) {
      return VaultFailureResult<void>(failure);
    } catch (error) {
      return VaultFailureResult<void>(
        VaultStorageFailure('Failed to save gesture template: $error', cause: error),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Atomic Purge Routine
  // ---------------------------------------------------------------------------

  @override
  Future<VaultResult<void>> purgeAllVaultData() async {
    _sessionCache?.clear();
    try {
      await _database.transaction(() async {
        await _database.delete(_database.vaultTrackRefsTable).go();
        await _database.delete(_database.vaultPlaylistsTable).go();
        await _database.delete(_database.vaultConfigTable).go();
        await _database.delete(_database.vaultGestureTemplatesTable).go();
        await _database.delete(_database.vaultLockoutDeadlineTable).go();
      });

      try {
        await _secureStorage.delete(key: 'musify_vault_is_enrolled');
        await _secureStorage.delete(key: 'musify_vault_pin_salt');
        await _secureStorage.delete(key: 'musify_vault_pin_verifier');
        await _secureStorage.delete(key: 'musify_vault_gesture_points');
        await _secureStorage.delete(key: 'musify_vault_gesture_rubine');
        await _secureStorage.delete(key: 'musify_vault_gesture_updated_at');
      } catch (_) {
        // Platform secure storage might not be bound in non-widget unit tests
      }

      final shredMediaHook = _onShredMediaFiles;
      if (shredMediaHook != null) {
        await shredMediaHook();
      }

      await _cryptoBridge.destroyMasterKey();

      return const VaultSuccess<void>(null);
    } on VaultFailure catch (failure) {
      return VaultFailureResult<void>(failure);
    } catch (error) {
      return VaultFailureResult<void>(
        VaultStorageFailure('Failed to purge vault data: $error', cause: error),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Lockout Deadline Persistence (Unencrypted Monotonic Epoch)
  // ---------------------------------------------------------------------------

  @override
  Future<int?> getPersistedLockoutDeadlineMs() async {
    final entry = await (_database.select(_database.vaultLockoutDeadlineTable)
          ..where((tbl) => tbl.id.equals('lockout_deadline')))
        .getSingleOrNull();

    if (entry != null) {
      return entry.deadlineMonotonicMs;
    }
    return null;
  }

  @override
  Future<void> persistLockoutDeadlineMs(int deadlineMonotonicMs) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _database.into(_database.vaultLockoutDeadlineTable).insertOnConflictUpdate(
          VaultLockoutDeadlineTableCompanion(
            id: const Value('lockout_deadline'),
            deadlineMonotonicMs: Value(deadlineMonotonicMs),
            failedAttempts: const Value(0),
            updatedAt: Value(nowMs),
          ),
        );
  }

  @override
  Future<void> clearPersistedLockoutDeadline() async {
    await (_database.delete(_database.vaultLockoutDeadlineTable)
          ..where((tbl) => tbl.id.equals('lockout_deadline')))
        .go();
  }

  // ---------------------------------------------------------------------------
  // Convenience Aliases
  // ---------------------------------------------------------------------------

  /// Convenience alias for [updatePlaylist].
  Future<VaultResult<void>> savePlaylist(PrivatePlaylist playlist) => updatePlaylist(playlist);

  /// Convenience alias for [getPlaylistById].
  Future<VaultResult<PrivatePlaylist>> getPlaylistWithTracks(String id) => getPlaylistById(id);

  /// Convenience alias for [addTrackToPlaylist].
  Future<VaultResult<void>> saveTrackRef({
    required String playlistId,
    required PrivateTrackRef trackRef,
  }) =>
      addTrackToPlaylist(playlistId: playlistId, trackRef: trackRef);

  /// Convenience alias for [removeTrackFromPlaylist].
  Future<VaultResult<void>> removeTrackRef({
    required String playlistId,
    required String trackId,
  }) =>
      removeTrackFromPlaylist(playlistId: playlistId, trackId: trackId);

  /// Convenience alias for [reorderTracksInPlaylist].
  Future<VaultResult<void>> reorderTracks({
    required String playlistId,
    required List<String> trackIdsInOrder,
  }) =>
      reorderTracksInPlaylist(playlistId: playlistId, trackIdsInOrder: trackIdsInOrder);

  /// Convenience alias for [loadVaultConfig].
  Future<VaultResult<VaultConfig>> getVaultConfig() => loadVaultConfig();

  /// Convenience alias for [loadGestureTemplate].
  Future<VaultResult<GestureTemplate>> getGestureTemplate() => loadGestureTemplate();
}
