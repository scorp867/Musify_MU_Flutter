import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/visual_types.pb.dart'
    as vt;

/// Normalizes Spotify image URLs (e.g. `spotify:image:<hex>` to CDN URLs).
String? cleanImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('spotify:image:')) {
    return 'https://i.scdn.co/image/${url.split(':').last}';
  }
  return url;
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
  selected ??= image.instances.last;
  return cleanImageUrl(selected.flatFile.cdnUrl);
}
