import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/data/database/dtos/vault_track_metadata_dto.dart';

/// Data Transfer Object for consolidated SQLite v2 playlist payload fields.
///
/// Encrypts playlist [description] and optional [coverUri] inside a single
/// AEAD envelope while [VaultPlaylistsTable.encryptedTitle] preserves title
/// ciphertext integrity verification.
@immutable
final class VaultPlaylistPayloadV2Dto extends Equatable {
  /// Plaintext playlist description (empty string allowed).
  final String description;

  /// Optional playlist cover artwork URI.
  final String? coverUri;

  /// Constructs a validated [VaultPlaylistPayloadV2Dto].
  const VaultPlaylistPayloadV2Dto({
    required this.description,
    this.coverUri,
  });

  /// Serializes this DTO into a JSON-compatible Map.
  Map<String, Object> toJson() {
    return <String, Object>{
      'description': description,
      if (coverUri case final cover? when cover.trim().isNotEmpty)
        'coverUri': cover.trim(),
    };
  }

  /// Deserializes [json] with fail-fast schema validation.
  ///
  /// Throws [FormatException] when required fields are missing or malformed.
  factory VaultPlaylistPayloadV2Dto.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException(
        'Expected JSON Map for VaultPlaylistPayloadV2Dto.',
      );
    }

    final rawDesc = json['description'];
    if (rawDesc is! String) {
      throw const FormatException(
        'Missing or invalid "description" in VaultPlaylistPayloadV2Dto.',
      );
    }

    String? coverUri;
    if (json.containsKey('coverUri') && json['coverUri'] != null) {
      final rawCover = json['coverUri'];
      if (rawCover is! String || rawCover.trim().isEmpty) {
        throw const FormatException(
          'Invalid "coverUri" in VaultPlaylistPayloadV2Dto.',
        );
      }
      coverUri = rawCover.trim();
    }

    return VaultPlaylistPayloadV2Dto(
      description: rawDesc,
      coverUri: coverUri,
    );
  }

  @override
  List<Object?> get props => [description, coverUri];
}

/// Data Transfer Object for consolidated SQLite v2 track reference payloads.
///
/// Consolidates [title], [artistName], [albumTitle], and [metadata] into one
/// JSON envelope so each track requires only a single AEAD encrypt/decrypt pass.
@immutable
final class VaultTrackPayloadV2Dto extends Equatable {
  /// Track title.
  final String title;

  /// Track artist name.
  final String artistName;

  /// Album title.
  final String albumTitle;

  /// Validated auxiliary track metadata.
  final VaultTrackMetadataDto metadata;

  /// Constructs a validated [VaultTrackPayloadV2Dto].
  const VaultTrackPayloadV2Dto({
    required this.title,
    required this.artistName,
    required this.albumTitle,
    required this.metadata,
  });

  /// Serializes all track fields into a single JSON Map.
  Map<String, Object> toJson() {
    return <String, Object>{
      ...metadata.toJson(),
      'title': title,
      'artistName': artistName,
      'albumTitle': albumTitle,
    };
  }

  /// Deserializes [json] with fail-fast validation across all required fields.
  factory VaultTrackPayloadV2Dto.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException(
        'Expected JSON Map for VaultTrackPayloadV2Dto.',
      );
    }

    final metadata = VaultTrackMetadataDto.fromJson(json);

    final rawTitle = json['title'];
    if (rawTitle is! String) {
      throw const FormatException(
        'Missing or invalid "title" in VaultTrackPayloadV2Dto.',
      );
    }

    final rawArtist = json['artistName'];
    if (rawArtist is! String) {
      throw const FormatException(
        'Missing or invalid "artistName" in VaultTrackPayloadV2Dto.',
      );
    }

    final rawAlbum = json['albumTitle'];
    if (rawAlbum is! String) {
      throw const FormatException(
        'Missing or invalid "albumTitle" in VaultTrackPayloadV2Dto.',
      );
    }

    return VaultTrackPayloadV2Dto(
      title: rawTitle,
      artistName: rawArtist,
      albumTitle: rawAlbum,
      metadata: metadata,
    );
  }

  @override
  List<Object?> get props => [title, artistName, albumTitle, metadata];
}
