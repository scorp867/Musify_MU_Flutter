import 'dart:collection';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Immutable domain entity representing an isolated private playlist.
@immutable
final class PrivatePlaylist extends Equatable {
  final String id;
  final String name;
  final String? description;
  final List<String> trackUris;
  final int trackCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  PrivatePlaylist({
    required this.id,
    required this.name,
    this.description,
    required List<String> trackUris,
    required this.createdAt,
    required this.updatedAt,
  })  : trackUris = UnmodifiableListView(trackUris),
        trackCount = trackUris.length {
    if (id.trim().isEmpty) {
      throw const FormatException('PrivatePlaylist id cannot be empty');
    }
    if (name.trim().isEmpty) {
      throw const FormatException('PrivatePlaylist name cannot be empty');
    }
  }

  PrivatePlaylist copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? trackUris,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrivatePlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      trackUris: trackUris ?? this.trackUris,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PrivatePlaylist.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    if (idRaw is! String || idRaw.trim().isEmpty) {
      throw const FormatException('Missing or invalid id in PrivatePlaylist JSON');
    }

    final nameRaw = json['name'];
    if (nameRaw is! String || nameRaw.trim().isEmpty) {
      throw const FormatException('Missing or invalid name in PrivatePlaylist JSON');
    }

    final descriptionRaw = json['description'];
    final String? description = descriptionRaw is String ? descriptionRaw : null;

    final trackUrisRaw = json['trackUris'];
    if (trackUrisRaw is! List) {
      throw const FormatException('Missing or invalid trackUris in PrivatePlaylist JSON');
    }

    final tracks = <String>[];
    for (final item in trackUrisRaw) {
      if (item is String && item.isNotEmpty) {
        tracks.add(item);
      } else {
        throw const FormatException('Invalid trackUri entry in PrivatePlaylist track list');
      }
    }

    final createdAtRaw = json['createdAt'];
    if (createdAtRaw is! String) {
      throw const FormatException('Missing or invalid createdAt timestamp in PrivatePlaylist');
    }
    final createdAt = DateTime.tryParse(createdAtRaw);
    if (createdAt == null) {
      throw FormatException('Malformed createdAt ISO-8601 string: $createdAtRaw');
    }

    final updatedAtRaw = json['updatedAt'];
    if (updatedAtRaw is! String) {
      throw const FormatException('Missing or invalid updatedAt timestamp in PrivatePlaylist');
    }
    final updatedAt = DateTime.tryParse(updatedAtRaw);
    if (updatedAt == null) {
      throw FormatException('Malformed updatedAt ISO-8601 string: $updatedAtRaw');
    }

    return PrivatePlaylist(
      id: idRaw,
      name: nameRaw,
      description: description,
      trackUris: tracks,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'trackUris': trackUris,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        trackUris,
        trackCount,
        createdAt,
        updatedAt,
      ];
}
