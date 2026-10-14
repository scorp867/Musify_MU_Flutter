import 'package:equatable/equatable.dart';
import 'context_track.dart';

/// 1:1 with Spotify's com.spotify.player.model.ContextPage
class ContextPage extends Equatable {
  final String pageUrl;
  final String nextPageUrl;
  final List<ContextTrack>? tracks;
  final Map<String, String> metadata;
  final bool isLoading;

  const ContextPage({
    this.pageUrl = '',
    this.nextPageUrl = '',
    this.tracks,
    this.metadata = const {},
    this.isLoading = false,
  });

  static const ContextPage empty = ContextPage();

  ContextPage copyWith({
    String? pageUrl,
    String? nextPageUrl,
    List<ContextTrack>? tracks,
    Map<String, String>? metadata,
    bool? isLoading,
  }) {
    return ContextPage(
      pageUrl: pageUrl ?? this.pageUrl,
      nextPageUrl: nextPageUrl ?? this.nextPageUrl,
      tracks: tracks ?? this.tracks,
      metadata: metadata ?? this.metadata,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        pageUrl,
        nextPageUrl,
        tracks,
        metadata,
        isLoading,
      ];
}
