import '../../../data/queue/queue_add_handler.dart';
import '../../../domain/commands/options/logging_params.dart';
import '../../../domain/commands/options/prepare_play_options.dart';
import '../../../domain/commands/set_sleep_timer_command.dart';
import '../../../domain/commands/signal_command.dart';
import '../../../domain/models/context.dart';
import '../../../domain/models/context_track.dart';
import '../../../domain/models/play_origin.dart';

/// 1:1 replica of Spotify Mobius Queue Side Effects (from Spotify mwp0, dwp0, hwp0).
abstract class QueueEffect {
  const QueueEffect();
}

class AddTracksEffect extends QueueEffect {
  final List<ContextTrack> tracks;
  final QueueInsertMode mode;
  const AddTracksEffect(this.tracks, this.mode);
}

class SetQueueTracksEffect extends QueueEffect {
  final List<ContextTrack> nextTracks;
  final List<ContextTrack>? prevTracks;
  const SetQueueTracksEffect({
    required this.nextTracks,
    this.prevTracks,
  });
}

class PlayContextEffect extends QueueEffect {
  final Context context;
  final PreparePlayOptions? options;
  final PlayOrigin playOrigin;

  const PlayContextEffect({
    required this.context,
    this.options,
    this.playOrigin = const PlayOrigin(),
  });
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
  final LoggingParams? loggingParams;
  const ToggleShuffleEffect(this.nextShuffle, {this.loggingParams});
}

class ToggleRepeatEffect extends QueueEffect {
  final bool nextRepeatContext;
  final bool nextRepeatTrack;
  final LoggingParams? loggingParams;
  const ToggleRepeatEffect({
    required this.nextRepeatContext,
    required this.nextRepeatTrack,
    this.loggingParams,
  });
}

class PlayPauseEffect extends QueueEffect {
  final bool currentlyPlaying;
  final LoggingParams? loggingParams;
  const PlayPauseEffect(this.currentlyPlaying, {this.loggingParams});
}

class SkipNextEffect extends QueueEffect {
  final LoggingParams? loggingParams;
  const SkipNextEffect({this.loggingParams});
}

class SkipPrevEffect extends QueueEffect {
  final LoggingParams? loggingParams;
  const SkipPrevEffect({this.loggingParams});
}

class PlayTrackEffect extends QueueEffect {
  final ContextTrack track;
  const PlayTrackEffect(this.track);
}

class SeekToEffect extends QueueEffect {
  final int positionMs;
  final LoggingParams? loggingParams;
  const SeekToEffect(this.positionMs, {this.loggingParams});
}

class StopEffect extends QueueEffect {
  const StopEffect();
}

class SignalEffect extends QueueEffect {
  final SignalCommand command;
  const SignalEffect(this.command);
}

class SetSleepTimerEffect extends QueueEffect {
  final SetSleepTimerCommand command;
  const SetSleepTimerEffect(this.command);
}

class PlayAsNextInQueueEffect extends QueueEffect {
  final List<ContextTrack> tracks;
  const PlayAsNextInQueueEffect(this.tracks);
}

class UpdateContextEffect extends QueueEffect {
  final Context context;
  const UpdateContextEffect(this.context);
}

class UpdateTrackEffect extends QueueEffect {
  final ContextTrack track;
  const UpdateTrackEffect(this.track);
}
