import 'dart:convert';
import 'dart:typed_data';

import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/protocol/generated/spotify/metadata.pb.dart'
    as meta_pb;
import 'package:musify_mu/core/utils/spotify_base62.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

import 'plugin_utils.dart';

/// Plugin for ExtensionKind 12 (`EPISODE_V4`).
/// 1:1 replica of Spotify Android's `p199p/xjj.java` returning [EpisodeV4].
class EpisodeV4Plugin implements ExtendedMetadataPlugin<EpisodeV4> {
  static const int _tagExternalUrl = 83;
  static const int _tagType = 87;
  static const int _tagMusicAndTalk = 91;
  static const int _tagContentRatings = 95;
  static const int _tagIsAudiobookChapter = 96;

  const EpisodeV4Plugin();

  @override
  Type get traitType => EpisodeV4;

  @override
  int get extensionKindValue => 12;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.EPISODE_V4;

  static String _encodeGidOrEmpty(List<int> bytes) {
    if (bytes.length != 16) return '';
    return SpotifyBase62.encode16ByteGid(Uint8List.fromList(bytes));
  }

  static EpisodeType _parseEpisodeType(int raw) {
    return switch (raw) {
      1 => EpisodeType.trailer,
      2 => EpisodeType.bonus,
      _ => EpisodeType.full,
    };
  }

  @override
  EpisodeV4 parse(Uint8List payload) {
    final ep = meta_pb.Episode.fromBuffer(payload);
    final id = _encodeGidOrEmpty(ep.gid);
    final uri = id.isNotEmpty ? 'spotify:episode:$id' : '';

    EpisodeShow? show;
    if (ep.hasShow()) {
      final showId = _encodeGidOrEmpty(ep.show.gid);
      show = EpisodeShow(
        name: ep.show.name,
        uri: showId.isNotEmpty ? 'spotify:show:$showId' : '',
      );
    }

    final coverImage = decodeCoverImageGroup(
      ep.hasCoverImage() && ep.coverImage.image.isNotEmpty
          ? ep.coverImage
          : null,
    );

    final publishTime = ep.hasPublishTime()
        ? EpisodePublishDate(
            year: ep.publishTime.year,
            month: ep.publishTime.month,
            day: ep.publishTime.day,
            hour: ep.publishTime.hour,
            minute: ep.publishTime.minute,
          )
        : const EpisodePublishDate();

    final unknown = ep.unknownFields;

    String externalUrl = '';
    if (unknown.getField(_tagExternalUrl) case final extField?
        when extField.lengthDelimited.isNotEmpty) {
      externalUrl = utf8.decode(
        extField.lengthDelimited.last,
        allowMalformed: true,
      );
    }

    EpisodeType episodeType = EpisodeType.full;
    if (unknown.getField(_tagType) case final typeField?
        when typeField.varints.isNotEmpty) {
      episodeType = _parseEpisodeType(typeField.varints.last.toInt());
    }

    bool isMusicAndTalk = false;
    if (unknown.getField(_tagMusicAndTalk) case final mtField?
        when mtField.varints.isNotEmpty) {
      isMusicAndTalk = mtField.varints.last.toInt() != 0;
    }

    bool isAudiobookChapter = false;
    if (unknown.getField(_tagIsAudiobookChapter) case final abField?
        when abField.varints.isNotEmpty) {
      isAudiobookChapter = abField.varints.last.toInt() != 0;
    }

    final contentRatings = <EpisodeContentRating>[];
    if (unknown.getField(_tagContentRatings) case final crField?) {
      for (final rawRating in crField.lengthDelimited) {
        final parsed = meta_pb.ContentRating.fromBuffer(rawRating);
        contentRatings.add(
          EpisodeContentRating(country: parsed.country, tags: parsed.tag),
        );
      }
    }

    return EpisodeV4(
      uri: uri,
      id: id,
      name: ep.name,
      show: show,
      coverImage: coverImage,
      isExplicit: ep.explicit,
      type: episodeType,
      isMusicAndTalk: isMusicAndTalk,
      isAudiobookChapter: isAudiobookChapter,
      description: ep.description,
      duration: ep.duration,
      publishTime: publishTime,
      contentRatings: contentRatings,
      externalUrl: externalUrl,
      language: ep.language,
    );
  }
}
