import 'package:flutter/foundation.dart';

import 'trait.dart';

/// Audiobook specific details (ExtensionKind 52).
/// Equivalent to Spotify Android's `eu6` (`AudiobookSpecificsTrait`).
@immutable
final class AudiobookSpecificsTrait extends Trait {
  final String narrator;
  final String author;
  final int durationSeconds;
  final bool isUnabridged;

  const AudiobookSpecificsTrait({
    this.narrator = '',
    this.author = '',
    this.durationSeconds = 0,
    this.isUnabridged = true,
  });
}
