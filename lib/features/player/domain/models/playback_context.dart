import 'package:equatable/equatable.dart';
import 'context_page.dart';
import 'context_track.dart';

/// 1:1 with Spotify's com.spotify.player.model.Context
class PlaybackContext extends Equatable {
  final String uri;
  final String url;
  final Map<String, String> metadata;
  final List<ContextPage> pages;
  final Map<String, dynamic> restrictions;

  const PlaybackContext({
    required this.uri,
    this.url = '',
    this.metadata = const {},
    this.pages = const [],
    this.restrictions = const {},
  });

  /// 1:1 with Context.fromTrackUris(uri, trackUris)
  factory PlaybackContext.fromTracks(String uri, List<ContextTrack> tracks) {
    return PlaybackContext(
      uri: uri,
      pages: [
        ContextPage(
          tracks: tracks,
        ),
      ],
    );
  }

  PlaybackContext copyWith({
    String? uri,
    String? url,
    Map<String, String>? metadata,
    List<ContextPage>? pages,
    Map<String, dynamic>? restrictions,
  }) {
    return PlaybackContext(
      uri: uri ?? this.uri,
      url: url ?? this.url,
      metadata: metadata ?? this.metadata,
      pages: pages ?? this.pages,
      restrictions: restrictions ?? this.restrictions,
    );
  }

  @override
  List<Object?> get props => [uri, url, metadata, pages, restrictions];
}
