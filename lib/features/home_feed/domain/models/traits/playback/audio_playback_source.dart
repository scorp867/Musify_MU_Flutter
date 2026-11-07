import 'package:flutter/foundation.dart';

part 'audio_hosted.dart';
part 'audio_pass_through.dart';

/// 1:1 replica of Spotify Android's `p199p/ep7.java` (`AudioPlaybackSource`).
///
/// Subtypes `AudioHosted` (`ap7.java`) and `AudioPassThrough` (`bp7.java`) live in
/// part files so the sealed hierarchy stays exhaustive within one library.
@immutable
sealed class AudioPlaybackSource {
  const AudioPlaybackSource();
}
