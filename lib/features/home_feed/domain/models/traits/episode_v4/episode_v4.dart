import 'dart:collection';
import 'package:flutter/foundation.dart';

import '../cover_image.dart';
import '../trait.dart';
import 'episode_content_rating.dart';
import 'episode_publish_date.dart';
import 'episode_show.dart';
import 'episode_type.dart';

/// 1:1 replica of Spotify Android's `p199p/key.java` (`EpisodeV4`, ExtensionKind 12).
/// Audio and video stream file IDs are resolved exclusively in native C++.
@immutable
final class EpisodeV4 extends Trait {
  final String uri;
  final String id;
  final String name;
  final EpisodeShow? show;
  final CoverImage coverImage;
  final bool isExplicit;
  final EpisodeType type;
  final bool isMusicAndTalk;
  final bool isAudiobookChapter;
  final String description;
  final int duration;
  final EpisodePublishDate publishTime;
  final UnmodifiableListView<EpisodeContentRating> contentRatings;
  final String externalUrl;
  final String language;

  EpisodeV4({
    required this.uri,
    required this.id,
    required this.name,
    this.show,
    this.coverImage = const CoverImage(),
    this.isExplicit = false,
    this.type = EpisodeType.full,
    this.isMusicAndTalk = false,
    this.isAudiobookChapter = false,
    this.description = '',
    this.duration = 0,
    this.publishTime = const EpisodePublishDate(),
    List<EpisodeContentRating> contentRatings = const [],
    this.externalUrl = '',
    this.language = '',
  }) : contentRatings = UnmodifiableListView<EpisodeContentRating>(
         List<EpisodeContentRating>.of(contentRatings),
       );

  /// 1:1 replica of `key.m57178a()` (`contentRatingTags`).
  Set<String> get contentRatingTags {
    final result = <String>{};
    for (final rating in contentRatings) {
      result.addAll(rating.tags);
    }
    return Set<String>.unmodifiable(result);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EpisodeV4 &&
        other.uri == uri &&
        other.id == id &&
        other.name == name &&
        other.show == show &&
        other.coverImage == coverImage &&
        other.isExplicit == isExplicit &&
        other.type == type &&
        other.isMusicAndTalk == isMusicAndTalk &&
        other.isAudiobookChapter == isAudiobookChapter &&
        other.description == description &&
        other.duration == duration &&
        other.publishTime == publishTime &&
        listEquals(other.contentRatings, contentRatings) &&
        other.externalUrl == externalUrl &&
        other.language == language;
  }

  @override
  int get hashCode => Object.hashAll([
    uri,
    id,
    name,
    show,
    coverImage,
    isExplicit,
    type,
    isMusicAndTalk,
    isAudiobookChapter,
    description,
    duration,
    publishTime,
    Object.hashAll(contentRatings),
    externalUrl,
    language,
  ]);
}
