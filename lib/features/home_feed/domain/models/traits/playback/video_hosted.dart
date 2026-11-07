import 'package:flutter/foundation.dart';

/// 1:1 replica of Spotify Android's `p199p/v2h1.java` (`VideoHosted`).
@immutable
final class VideoHosted {
  final String manifestId;

  const VideoHosted({required this.manifestId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoHosted && other.manifestId == manifestId;
  }

  @override
  int get hashCode => manifestId.hashCode;
}
