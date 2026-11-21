import 'package:equatable/equatable.dart';

/// Events for [NowPlayingScrollController].
sealed class NowPlayingScrollEvent extends Equatable {
  const NowPlayingScrollEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when an eligible Spotify track becomes active in Now Playing.
final class FetchNowPlayingScroll extends NowPlayingScrollEvent {
  final String? trackId;
  final String? artistUri;

  const FetchNowPlayingScroll([this.trackId, this.artistUri]);

  @override
  List<Object?> get props => [trackId, artistUri];
}

/// Triggered when playback transitions to a local file, Private Vault track,
/// or non-music item so any in-flight Spotify scroll request is invalidated
/// and stale Spotify cards are cleared immediately.
final class ClearNowPlayingScroll extends NowPlayingScrollEvent {
  const ClearNowPlayingScroll();
}
