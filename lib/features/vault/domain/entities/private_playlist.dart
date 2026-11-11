import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';

/// Deeply immutable aggregate root representing an encrypted private playlist in the Secure Vault.
///
/// Encapsulates playlist identity, descriptive metadata, cumulative duration, timestamps,
/// and an unmodifiable collection of [PrivateTrackRef] entities.
///
/// Strictly enforces the Zero Loose Booleans mandate: contains zero `bool isLoaded`, `bool isPrivate`,
/// or `bool isSyncing` flags.
@immutable
class PrivatePlaylist extends Equatable {
  /// Unique identifier of this private playlist.
  final String id;

  /// User-defined playlist title.
  final String name;

  /// User-defined playlist description.
  final String description;

  /// Optional URI to cover artwork (decrypted local file URI or network URI).
  final String? coverUri;

  /// Cumulative duration of all tracks contained within this playlist in milliseconds.
  final int totalDurationMs;

  /// Epoch timestamp in milliseconds when this playlist was created.
  final int createdAtEpochMs;

  /// Epoch timestamp in milliseconds of the latest playlist modification.
  final int updatedAtEpochMs;

  /// Unmodifiable sequence of track references contained within this playlist.
  final List<PrivateTrackRef> trackRefs;

  /// Constructs a validated [PrivatePlaylist] instance.
  ///
  /// Defensively wraps [trackRefs] into an unmodifiable collection.
  /// Throws [FormatException] if [id] or [name] is empty, [totalDurationMs] is negative,
  /// [createdAtEpochMs] is non-positive, or [updatedAtEpochMs] is earlier than [createdAtEpochMs].
  PrivatePlaylist({
    required this.id,
    required this.name,
    required this.description,
    this.coverUri,
    required this.totalDurationMs,
    required this.createdAtEpochMs,
    required this.updatedAtEpochMs,
    required List<PrivateTrackRef> trackRefs,
  }) : trackRefs = List.unmodifiable(trackRefs) {
    if (id.trim().isEmpty) {
      throw const FormatException('PrivatePlaylist id must not be empty.');
    }
    if (name.trim().isEmpty) {
      throw const FormatException('PrivatePlaylist name must not be empty.');
    }
    if (totalDurationMs < 0) {
      throw FormatException(
        'PrivatePlaylist totalDurationMs must be non-negative: $totalDurationMs',
      );
    }
    if (createdAtEpochMs <= 0) {
      throw FormatException(
        'PrivatePlaylist createdAtEpochMs must be positive: $createdAtEpochMs',
      );
    }
    if (updatedAtEpochMs < createdAtEpochMs) {
      throw FormatException(
        'PrivatePlaylist updatedAtEpochMs ($updatedAtEpochMs) cannot be earlier than createdAtEpochMs ($createdAtEpochMs)',
      );
    }
  }

  /// Total number of tracks contained in this playlist.
  int get trackCount => trackRefs.length;

  /// Creates a copy of this playlist with updated fields.
  PrivatePlaylist copyWith({
    String? id,
    String? name,
    String? description,
    String? coverUri,
    int? totalDurationMs,
    int? createdAtEpochMs,
    int? updatedAtEpochMs,
    List<PrivateTrackRef>? trackRefs,
  }) {
    return PrivatePlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUri: coverUri ?? this.coverUri,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      createdAtEpochMs: createdAtEpochMs ?? this.createdAtEpochMs,
      updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
      trackRefs: trackRefs ?? this.trackRefs,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        coverUri,
        totalDurationMs,
        createdAtEpochMs,
        updatedAtEpochMs,
        trackRefs,
      ];
}
