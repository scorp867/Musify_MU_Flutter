import 'package:equatable/equatable.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';

abstract class QueueEvent extends Equatable {
  const QueueEvent();

  @override
  List<Object?> get props => [];
}

class QueueStarted extends QueueEvent {
  const QueueStarted();
}

class QueueTrackTapped extends QueueEvent {
  final ContextTrack track;
  final int absoluteIndex;

  const QueueTrackTapped({required this.track, required this.absoluteIndex});

  @override
  List<Object?> get props => [track.uid, absoluteIndex];
}

class QueueReordered extends QueueEvent {
  final int oldIndex;
  final int newIndex;

  const QueueReordered(this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class QueueTrackRemoved extends QueueEvent {
  final String uid;

  const QueueTrackRemoved(this.uid);

  @override
  List<Object?> get props => [uid];
}

class QueueTrackAdded extends QueueEvent {
  final ContextTrack track;

  const QueueTrackAdded(this.track);

  @override
  List<Object?> get props => [track.uid];
}

class QueueCleared extends QueueEvent {
  const QueueCleared();
}

class QueueShuffleToggled extends QueueEvent {
  const QueueShuffleToggled();
}

class QueueRepeatToggled extends QueueEvent {
  const QueueRepeatToggled();
}

class QueuePlayPauseToggled extends QueueEvent {
  const QueuePlayPauseToggled();
}

class QueueNextPageRequested extends QueueEvent {
  const QueueNextPageRequested();
}
