import '../../../data/queue/queue_add_handler.dart';
import '../../../domain/commands/options/logging_params.dart';
import '../../../domain/commands/options/prepare_play_options.dart';
import '../../../domain/commands/set_sleep_timer_command.dart';
import '../../../domain/commands/signal_command.dart';
import '../../../domain/models/context.dart';
import '../../../domain/models/context_track.dart';
import '../../../domain/models/play_origin.dart';

/// 1:1 sealed side effect hierarchy for Spotify Mobius Queue Loop (p199p/u9x0.java).
/// Every effect is a final subclass of the sealed root effect.
sealed class QueueEffect {
  const QueueEffect();
}

/// 1:1 with u9x0 / AddToQueue
final class AddTracksEffect extends QueueEffect {
  final List<ContextTrack> tracks;
  final QueueInsertMode mode;
  const AddTracksEffect(this.tracks, this.mode);
}

/// 1:1 with w9x0 / SetQueue
final class SetQueueTracksEffect extends QueueEffect {
  final List<ContextTrack> nextTracks;
  final List<ContextTrack>? prevTracks;
  const SetQueueTracksEffect({
    required this.nextTracks,
    this.prevTracks,
  });
}

/// 1:1 with aax0 / PlayContext
final class PlayContextEffect extends QueueEffect {
  final Context context;
  final PreparePlayOptions? options;
  final PlayOrigin playOrigin;

  const PlayContextEffect({
    required this.context,
    this.options,
    this.playOrigin = const PlayOrigin(),
  });
}

/// 1:1 with lax0 / RemoveTracks
final class RemoveTracksEffect extends QueueEffect {
  final List<ContextTrack> tracks;
  const RemoveTracksEffect(this.tracks);
}

/// 1:1 with z9x0 / ReorderTrack
final class ReorderTrackEffect extends QueueEffect {
  final ContextTrack track;
  final int destinationIndex;
  const ReorderTrackEffect(this.track, this.destinationIndex);
}

/// 1:1 with y9x0 / ClearQueue
final class ClearQueueEffect extends QueueEffect {
  const ClearQueueEffect();
}

/// 1:1 with cax0 / SetOptions (Shuffling)
final class ToggleShuffleEffect extends QueueEffect {
  final bool nextShuffle;
  final LoggingParams? loggingParams;
  const ToggleShuffleEffect(this.nextShuffle, {this.loggingParams});
}

/// 1:1 with cax0 / SetOptions (Repeat)
final class ToggleRepeatEffect extends QueueEffect {
  final bool nextRepeatContext;
  final bool nextRepeatTrack;
  final LoggingParams? loggingParams;
  const ToggleRepeatEffect({
    required this.nextRepeatContext,
    required this.nextRepeatTrack,
    this.loggingParams,
  });
}

/// 1:1 with x9x0 / Pause or Resume
final class PlayPauseEffect extends QueueEffect {
  final bool currentlyPlaying;
  final LoggingParams? loggingParams;
  const PlayPauseEffect(this.currentlyPlaying, {this.loggingParams});
}

/// 1:1 with v9x0 / SkipNext
final class SkipNextEffect extends QueueEffect {
  final LoggingParams? loggingParams;
  const SkipNextEffect({this.loggingParams});
}

/// 1:1 with SkipPrev
final class SkipPrevEffect extends QueueEffect {
  final LoggingParams? loggingParams;
  const SkipPrevEffect({this.loggingParams});
}

/// 1:1 with fax0 / PlayTrack
final class PlayTrackEffect extends QueueEffect {
  final ContextTrack track;
  final PlayOrigin playOrigin;
  const PlayTrackEffect(this.track, {this.playOrigin = const PlayOrigin()});
}

/// 1:1 with eax0 / SeekTo
final class SeekToEffect extends QueueEffect {
  final int positionMs;
  final LoggingParams? loggingParams;
  const SeekToEffect(this.positionMs, {this.loggingParams});
}

/// 1:1 with sax0 / Stop
final class StopEffect extends QueueEffect {
  const StopEffect();
}

/// 1:1 with rax0 / Signal
final class SignalEffect extends QueueEffect {
  final SignalCommand command;
  const SignalEffect(this.command);
}

/// 1:1 with pax0 / SetSleepTimer
final class SetSleepTimerEffect extends QueueEffect {
  final SetSleepTimerCommand command;
  const SetSleepTimerEffect(this.command);
}

/// 1:1 with kax0 / PlayAsNextInQueue
final class PlayAsNextInQueueEffect extends QueueEffect {
  final List<ContextTrack> tracks;
  const PlayAsNextInQueueEffect(this.tracks);
}

/// 1:1 with UpdateContext
final class UpdateContextEffect extends QueueEffect {
  final Context context;
  const UpdateContextEffect(this.context);
}

/// 1:1 with UpdateTrack
final class UpdateTrackEffect extends QueueEffect {
  final ContextTrack track;
  const UpdateTrackEffect(this.track);
}
