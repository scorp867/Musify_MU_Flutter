import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/protocol/generated/spotify/metadata.pb.dart'
    as meta_pb;
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Plugin for ExtensionKind 10 (TRACK_V4).
/// Provides complete track metadata matching Spotify Android's TrackV4 extension.
class TrackV4Plugin implements ExtendedMetadataPlugin<TrackMetaTrait> {
  const TrackV4Plugin();

  @override
  Type get traitType => TrackMetaTrait;

  @override
  int get extensionKindValue => 10;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.TRACK_V4;

  @override
  TrackMetaTrait parse(Uint8List payload) {
    final track = meta_pb.Track.fromBuffer(payload);
    final title = track.name;
    final artists = track.artist.map((a) => a.name).where((n) => n.isNotEmpty);
    final subtitle = artists.join(', ');
    final albumName = track.hasAlbum() ? track.album.name : '';
    final duration = track.hasDuration() ? track.duration : 0;

    final imageUrls = <String, String>{};
    String? largeImageHex;

    if (track.hasAlbum() && track.album.hasCoverGroup()) {
      for (final image in track.album.coverGroup.image) {
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
            imageUrls['medium'] = url;
            largeImageHex ??= hex;
            break;
          case meta_pb.Image_Size.XLARGE:
            imageUrls['large'] = url;
            largeImageHex = hex;
            break;
          default:
            imageUrls.putIfAbsent('medium', () => url);
            largeImageHex ??= hex;
        }
      }
    }

    return TrackMetaTrait(
      uri: track.hasGid()
          ? 'spotify:track:${track.gid.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}'
          : '',
      title: title,
      subtitle: subtitle,
      albumName: albumName,
      imageUrls: imageUrls,
      largeImageHex: largeImageHex,
      durationMs: duration,
    );
  }
}
