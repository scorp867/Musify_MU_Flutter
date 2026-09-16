import 'package:equatable/equatable.dart';

abstract class QueueEvent extends Equatable {
  const QueueEvent();

  @override
  List<Object?> get props => [];
}

class QueueStarted extends QueueEvent {
  const QueueStarted();
}

class QueueTrackTapped extends QueueEvent {
  final int absoluteIndex;

  const QueueTrackTapped(this.absoluteIndex);

  @override
  List<Object?> get props => [absoluteIndex];
}

class QueueReordered extends QueueEvent {
  final int oldIndex;
  final int newIndex;

  const QueueReordered(this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [oldIndex, newIndex];
}
