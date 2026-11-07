import 'package:flutter/foundation.dart';

import 'image_size.dart';
import 'trait.dart';

/// 1:1 replica of Spotify Android's `p199p/ljm.java` (`CoverImage`, ExtensionKind 79).
@immutable
final class CoverImage extends Trait {
  final String defaultUrl;
  final String? smallUrl;
  final String? largeUrl;
  final String? xlargeUrl;

  const CoverImage({
    this.defaultUrl = '',
    this.smallUrl,
    this.largeUrl,
    this.xlargeUrl,
  });

  /// 1:1 replica of `ljm.m60582a(hjm)` resolving the URL for a requested [ImageSize].
  String urlForSize(ImageSize size) {
    if (size == ImageSize.xlarge) {
      if (xlargeUrl case final xlarge? when xlarge.isNotEmpty) {
        return xlarge;
      }
    }
    if (size == ImageSize.large || size == ImageSize.xlarge) {
      if (largeUrl case final large? when large.isNotEmpty) {
        return large;
      }
    }
    if (size == ImageSize.small) {
      if (smallUrl case final small? when small.isNotEmpty) {
        return small;
      }
    }
    return defaultUrl;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoverImage &&
        other.defaultUrl == defaultUrl &&
        other.smallUrl == smallUrl &&
        other.largeUrl == largeUrl &&
        other.xlargeUrl == xlargeUrl;
  }

  @override
  int get hashCode => Object.hash(defaultUrl, smallUrl, largeUrl, xlargeUrl);
}
