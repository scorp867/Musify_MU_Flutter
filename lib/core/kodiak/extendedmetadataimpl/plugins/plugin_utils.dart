import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/visual_types.pb.dart'
    as vt;
import 'package:musify_mu/core/protocol/generated/spotify/metadata.pb.dart'
    as meta_pb;
import 'package:musify_mu/features/home_feed/domain/models/traits/cover_image.dart';

/// Lowercase hexadecimal encoding matching Spotify Android's `xel1.m91041z`.
String bytesToLowerHex(List<int> bytes) {
  if (bytes.isEmpty) return '';
  final sb = StringBuffer();
  for (final b in bytes) {
    sb.write((b & 0xFF).toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}

/// Normalizes Spotify image URLs (for example, `spotify:image:<hex>` to CDN URLs).
String? cleanImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('spotify:image:')) {
    return 'https://i.scdn.co/image/${url.split(':').last}';
  }
  return url;
}

/// 1:1 replica of Spotify Android's `tuk1.m82617p(Metadata$ImageGroup)` -> `CoverImage`.
CoverImage decodeCoverImageGroup(meta_pb.ImageGroup? group) {
  if (group == null || group.image.isEmpty) {
    return const CoverImage();
  }

  String? defaultUrl;
  String? smallUrl;
  String? largeUrl;
  String? xlargeUrl;

  for (final img in group.image) {
    if (!img.hasFileId() || img.fileId.isEmpty) continue;
    final hex = bytesToLowerHex(img.fileId);
    if (hex.isEmpty) continue;
    final url = 'https://i.scdn.co/image/$hex';

    switch (img.size) {
      case meta_pb.Image_Size.DEFAULT:
        defaultUrl ??= url;
      case meta_pb.Image_Size.SMALL:
        smallUrl ??= url;
      case meta_pb.Image_Size.LARGE:
        largeUrl ??= url;
      case meta_pb.Image_Size.XLARGE:
        xlargeUrl ??= url;
    }
  }

  final String resolvedDefault;
  if (defaultUrl case final d? when d.isNotEmpty) {
    resolvedDefault = d;
  } else if (largeUrl case final l? when l.isNotEmpty) {
    resolvedDefault = l;
  } else if (smallUrl case final s? when s.isNotEmpty) {
    resolvedDefault = s;
  } else if (xlargeUrl case final xl? when xl.isNotEmpty) {
    resolvedDefault = xl;
  } else {
    resolvedDefault = '';
  }

  return CoverImage(
    defaultUrl: resolvedDefault,
    smallUrl: smallUrl,
    largeUrl: largeUrl,
    xlargeUrl: xlargeUrl,
  );
}

/// Selects the best high resolution image from protobuf image instances.
String? selectHighResImageUrl(vt.Image image) {
  if (image.instances.isEmpty) return null;
  vt.ImageInstance? selected;
  for (final inst in image.instances) {
    if (inst.size == vt.ImageSize.IMAGE_SIZE_LARGE ||
        inst.size == vt.ImageSize.IMAGE_SIZE_DEFAULT ||
        inst.size == vt.ImageSize.IMAGE_SIZE_XLARGE) {
      selected = inst;
      break;
    }
  }
  final resolved = selected != null ? selected : image.instances.last;
  return cleanImageUrl(resolved.flatFile.cdnUrl);
}
