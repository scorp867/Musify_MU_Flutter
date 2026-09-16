import 'package:equatable/equatable.dart';

abstract class LocalMusicEvent extends Equatable {
  const LocalMusicEvent();

  @override
  List<Object> get props => [];
}

class LoadLocalTracks extends LocalMusicEvent {
  const LoadLocalTracks();
}
