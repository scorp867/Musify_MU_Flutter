import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';

/// Data Transfer Object for serializing auxiliary track reference metadata into JSON.
///
/// Encapsulates fields not stored as top-level table columns: [trackUri], [sourceType],
/// and [addedAtEpochMs].
@immutable
final class VaultTrackMetadataDto extends Equatable {
  /// Canonical playback URI (e.g. `spotify:track:...` or file URI).
  final String trackUri;

  /// Origin classification (Spotify streaming vs local isolated sandbox).
  final TrackSourceTypeEnum sourceType;

  /// Epoch timestamp in milliseconds when the track was added to the playlist.
  final int addedAtEpochMs;

  /// Constructs a validated [VaultTrackMetadataDto].
  const VaultTrackMetadataDto({
    required this.trackUri,
    required this.sourceType,
    required this.addedAtEpochMs,
  });

  /// Serializes this DTO to a JSON-compatible Map.
  Map<String, Object> toJson() {
    return <String, Object>{
      'trackUri': trackUri,
      'sourceType': sourceType.id,
      'addedAtEpochMs': addedAtEpochMs,
    };
  }

  /// Deserializes a JSON Map into a validated [VaultTrackMetadataDto] instance.
  ///
  /// Throws [FormatException] if [json] is not a Map or if required fields are missing/invalid.
  factory VaultTrackMetadataDto.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Expected JSON Map for VaultTrackMetadataDto.');
    }

    final trackUriRaw = json['trackUri'];
    if (trackUriRaw is! String || trackUriRaw.trim().isEmpty) {
      throw const FormatException('Missing or invalid "trackUri" in VaultTrackMetadataDto.');
    }

    final sourceTypeRaw = json['sourceType'];
    if (sourceTypeRaw is! String) {
      throw const FormatException('Missing or invalid "sourceType" in VaultTrackMetadataDto.');
    }

    final addedAtEpochMsRaw = json['addedAtEpochMs'];
    if (addedAtEpochMsRaw is! int || addedAtEpochMsRaw <= 0) {
      throw const FormatException('Missing or invalid "addedAtEpochMs" in VaultTrackMetadataDto.');
    }

    return VaultTrackMetadataDto(
      trackUri: trackUriRaw,
      sourceType: TrackSourceTypeEnum.fromId(sourceTypeRaw),
      addedAtEpochMs: addedAtEpochMsRaw,
    );
  }

  @override
  List<Object?> get props => [trackUri, sourceType, addedAtEpochMs];
}
