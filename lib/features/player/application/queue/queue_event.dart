import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';

/// Sealed Dart 3 event hierarchy for all QueueBloc actions.
sealed class QueueEvent extends Equatable {
  const QueueEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched when queue lifecycle begins, initiating subscriptions to audio streams.
final class QueueStarted extends QueueEvent {
  const QueueStarted();
}

/// Dispatched when a track in the upcoming queue or history is tapped for immediate playback.
final class QueueTrackTapped extends QueueEvent {
  final ContextTrack track;
  final int absoluteIndex;

  const QueueTrackTapped({required this.track, required this.absoluteIndex});

  @override
  List<Object?> get props => [track.uid, absoluteIndex];
}

/// Dispatched when tracks are reordered via drag-and-drop.
final class QueueReordered extends QueueEvent {
  final int oldIndex;
  final int newIndex;

  const QueueReordered(this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

/// Dispatched to remove a specific track by its session-unique UID.
final class QueueTrackRemoved extends QueueEvent {
  final String uid;

  const QueueTrackRemoved(this.uid);

  @override
  List<Object?> get props => [uid];
}

/// Dispatched when a track is explicitly queued by user action (e.g. swipe to queue).
final class QueueTrackAdded extends QueueEvent {
  final ContextTrack track;

  const QueueTrackAdded(this.track);

  @override
  List<Object?> get props => [track.uid];
}

/// Dispatched to clear all user-queued tracks while preserving upcoming context tracks.
final class QueueCleared extends QueueEvent {
  const QueueCleared();
}

/// Dispatched to toggle shuffle mode.
final class QueueShuffleToggled extends QueueEvent {
  const QueueShuffleToggled();
}

/// Dispatched to toggle repeat / loop mode through off -> all -> one -> off.
final class QueueRepeatToggled extends QueueEvent {
  const QueueRepeatToggled();
}

/// Dispatched to toggle play/pause transport state.
final class QueuePlayPauseToggled extends QueueEvent {
  const QueuePlayPauseToggled();
}

/// Dispatched to request the next paginated chunk of context tracks.
final class QueueNextPageRequested extends QueueEvent {
  const QueueNextPageRequested();
}

/// Internal event dispatched when the audio engine's playlist or sequence updates.
final class QueueDataChanged extends QueueEvent {
  final SequenceState? sequenceState;
  final List<MediaItem>? fallbackQueue;
  final MediaItem? fallbackCurrentItem;

  const QueueDataChanged({
    this.sequenceState,
    this.fallbackQueue,
    this.fallbackCurrentItem,
  });

  @override
  List<Object?> get props => [
        sequenceState?.currentIndex,
        sequenceState?.effectiveSequence.length,
        fallbackQueue,
        fallbackCurrentItem?.id,
      ];
}

/// Internal event dispatched when playback transport status (playing, shuffle, repeat) changes.
final class PlaybackStatusChanged extends QueueEvent {
  final bool isPlaying;
  final AudioServiceShuffleMode shuffleMode;
  final AudioServiceRepeatMode repeatMode;

  const PlaybackStatusChanged({
    required this.isPlaying,
    required this.shuffleMode,
    required this.repeatMode,
  });

  @override
  List<Object?> get props => [isPlaying, shuffleMode, repeatMode];
}
