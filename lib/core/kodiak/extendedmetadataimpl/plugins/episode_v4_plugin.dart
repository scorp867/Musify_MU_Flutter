import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/protocol/generated/spotify/metadata.pb.dart'
    as meta_pb;
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Plugin for ExtensionKind 12 (EPISODE_V4).
/// Provides complete podcast episode metadata matching Spotify Android's EpisodeV4 extension.
class EpisodeV4Plugin implements ExtendedMetadataPlugin<EpisodeMetaTrait> {
  const EpisodeV4Plugin();

  @override
  Type get traitType => EpisodeMetaTrait;

  @override
  int get extensionKindValue => 12;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.EPISODE_V4;

  @override
  EpisodeMetaTrait parse(Uint8List payload) {
    final ep = meta_pb.Episode.fromBuffer(payload);
    final title = ep.name;
    final showName =
        (ep.hasShow() && ep.show.hasName()) ? ep.show.name : '';
    final duration = ep.hasDuration() ? ep.duration : 0;

    final imageUrls = <String, String>{};
    String? largeImageHex;

    if (ep.hasCoverImage()) {
      for (final image in ep.coverImage.image) {
        if (!image.hasFileId() || image.fileId.isEmpty) continue;
        final hex = image.fileId
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
        final url = 'https://i.scdn.co/image/$hex';

        switch (image.size) {
          case meta_pb.Image_Size.SMALL:
            imageUrls['small'] = url;
            break;
          case meta_pb.Image_Size.LARGE:
            imageUrls['large'] = url;
            largeImageHex = hex;
            break;
          case meta_pb.Image_Size.XLARGE:
            imageUrls['large'] = url;
            largeImageHex = hex;
            break;
          default:
            imageUrls.putIfAbsent('medium', () => url);
        }
      }
    }

    return EpisodeMetaTrait(
      uri: ep.hasGid()
          ? 'spotify:episode:${ep.gid.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}'
          : '',
      title: title,
      subtitle: showName,
      albumName: '',
      imageUrls: imageUrls,
      largeImageHex: largeImageHex,
      durationMs: duration,
    );
  }
}
