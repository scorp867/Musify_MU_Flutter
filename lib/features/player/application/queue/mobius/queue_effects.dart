import '../../../data/queue/queue_add_handler.dart';
import '../../../domain/models/context_track.dart';

/// 1:1 replica of Spotify Mobius Queue Side Effects (from Spotify mwp0, dwp0, hwp0).
abstract class QueueEffect {
  const QueueEffect();
}

class AddTracksEffect extends QueueEffect {
  final List<ContextTrack> tracks;
  final QueueInsertMode mode;
  const AddTracksEffect(this.tracks, this.mode);
}

class RemoveTracksEffect extends QueueEffect {
  final List<ContextTrack> tracks;
  const RemoveTracksEffect(this.tracks);
}

class ReorderTrackEffect extends QueueEffect {
  final ContextTrack track;
  final int destinationIndex;
  const ReorderTrackEffect(this.track, this.destinationIndex);
}

class ClearQueueEffect extends QueueEffect {
  const ClearQueueEffect();
}

class ToggleShuffleEffect extends QueueEffect {
  final bool nextShuffle;
  const ToggleShuffleEffect(this.nextShuffle);
}

class ToggleRepeatEffect extends QueueEffect {
  final bool nextRepeatContext;
  final bool nextRepeatTrack;
  const ToggleRepeatEffect({
    required this.nextRepeatContext,
    required this.nextRepeatTrack,
  });
}

class PlayPauseEffect extends QueueEffect {
  final bool currentlyPlaying;
  const PlayPauseEffect(this.currentlyPlaying);
}

class SkipNextEffect extends QueueEffect {
  const SkipNextEffect();
}

class SkipPrevEffect extends QueueEffect {
  const SkipPrevEffect();
}

class PlayTrackEffect extends QueueEffect {
  final ContextTrack track;
  const PlayTrackEffect(this.track);
}
