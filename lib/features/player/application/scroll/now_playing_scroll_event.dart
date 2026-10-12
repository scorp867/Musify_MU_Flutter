import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';

/// Events for [NowPlayingScrollBloc].
sealed class NowPlayingScrollEvent extends Equatable {
  const NowPlayingScrollEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when the active now playing media item changes.
final class FetchNowPlayingScroll extends NowPlayingScrollEvent {
  final MediaItem item;

  const FetchNowPlayingScroll(this.item);

  @override
  List<Object?> get props => [item.id];
}
