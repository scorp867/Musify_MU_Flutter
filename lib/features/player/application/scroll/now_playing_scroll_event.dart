import 'package:equatable/equatable.dart';

/// Events for [NowPlayingScrollBloc].
sealed class NowPlayingScrollEvent extends Equatable {
  const NowPlayingScrollEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when the active now playing track changes.
final class FetchNowPlayingScroll extends NowPlayingScrollEvent {
  final String? trackId;

  const FetchNowPlayingScroll([this.trackId]);

  @override
  List<Object?> get props => [trackId];
}
