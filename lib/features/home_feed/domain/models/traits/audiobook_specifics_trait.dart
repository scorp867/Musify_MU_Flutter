import 'trait.dart';

/// Audiobook specific details (ExtensionKind 52).
/// Equivalent to Spotify Android's `eu6` (AudiobookSpecificsTrait).
class AudiobookSpecificsTrait extends Trait {
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

  @override
  Map<String, dynamic> toJson() => {
    'narrator': narrator,
    'author': author,
    'durationSeconds': durationSeconds,
    'isUnabridged': isUnabridged,
  };

  factory AudiobookSpecificsTrait.fromJson(Map<String, dynamic> json) =>
      AudiobookSpecificsTrait(
        narrator: json['narrator'] ?? '',
        author: json['author'] ?? '',
        durationSeconds: json['durationSeconds'] ?? 0,
        isUnabridged: json['isUnabridged'] ?? true,
      );
}
