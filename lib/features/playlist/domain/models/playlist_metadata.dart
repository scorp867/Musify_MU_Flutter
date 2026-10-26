library;

import 'package:flutter/foundation.dart';

/// 1:1 replica of Spotify's `xcx.java` playlist metadata model.
@immutable
class PlaylistMetadata {
  final String uri;
  final String name;
  final String description;
  final String ownerUsername;
  final String ownerName;
  final String ownerAvatarUrl;
  final bool isCollaborative;
  final bool isFollowed;
  final bool isPublished;
  final bool canEdit;
  final bool canReport;
  final bool canAnnotate;
  final bool canDelete;
  final int totalDurationMs;
  final int followersCount;
  final String picture;
  final Map<String, String> customAttributes;

  const PlaylistMetadata({
    required this.uri,
    required this.name,
    this.description = '',
    this.ownerUsername = '',
    this.ownerName = '',
    this.ownerAvatarUrl = '',
    this.isCollaborative = false,
    this.isFollowed = false,
    this.isPublished = false,
    this.canEdit = false,
    this.canReport = false,
    this.canAnnotate = false,
    this.canDelete = false,
    this.totalDurationMs = 0,
    this.followersCount = 0,
    this.picture = '',
    this.customAttributes = const {},
  });

  PlaylistMetadata copyWith({
    String? uri,
    String? name,
    String? description,
    String? ownerUsername,
    String? ownerName,
    String? ownerAvatarUrl,
    bool? isCollaborative,
    bool? isFollowed,
    bool? isPublished,
    bool? canEdit,
    bool? canReport,
    bool? canAnnotate,
    bool? canDelete,
    int? totalDurationMs,
    int? followersCount,
    String? picture,
    Map<String, String>? customAttributes,
  }) {
    return PlaylistMetadata(
      uri: uri ?? this.uri,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      ownerName: ownerName ?? this.ownerName,
      ownerAvatarUrl: ownerAvatarUrl ?? this.ownerAvatarUrl,
      isCollaborative: isCollaborative ?? this.isCollaborative,
      isFollowed: isFollowed ?? this.isFollowed,
      isPublished: isPublished ?? this.isPublished,
      canEdit: canEdit ?? this.canEdit,
      canReport: canReport ?? this.canReport,
      canAnnotate: canAnnotate ?? this.canAnnotate,
      canDelete: canDelete ?? this.canDelete,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      followersCount: followersCount ?? this.followersCount,
      picture: picture ?? this.picture,
      customAttributes: customAttributes ?? this.customAttributes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistMetadata &&
          runtimeType == other.runtimeType &&
          uri == other.uri &&
          name == other.name &&
          description == other.description &&
          ownerUsername == other.ownerUsername &&
          ownerName == other.ownerName &&
          ownerAvatarUrl == other.ownerAvatarUrl &&
          isCollaborative == other.isCollaborative &&
          isFollowed == other.isFollowed &&
          isPublished == other.isPublished &&
          canEdit == other.canEdit &&
          canReport == other.canReport &&
          canAnnotate == other.canAnnotate &&
          canDelete == other.canDelete &&
          totalDurationMs == other.totalDurationMs &&
          followersCount == other.followersCount &&
          picture == other.picture &&
          mapEquals(customAttributes, other.customAttributes));

  @override
  int get hashCode => Object.hash(
        uri,
        name,
        description,
        ownerUsername,
        ownerName,
        ownerAvatarUrl,
        isCollaborative,
        isFollowed,
        isPublished,
        canEdit,
        canReport,
        canAnnotate,
        canDelete,
        totalDurationMs,
        followersCount,
        picture,
        Object.hashAll(customAttributes.entries.map((e) => Object.hash(e.key, e.value))),
      );

  @override
  String toString() =>
      'PlaylistMetadata(uri: $uri, name: $name, owner: $ownerUsername, followers: $followersCount)';
}
