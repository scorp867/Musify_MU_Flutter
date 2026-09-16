import 'package:equatable/equatable.dart';
import 'package:musify_mu/features/local_music/domain/entities/domain_track.dart';

abstract class LocalMusicState extends Equatable {
  const LocalMusicState();

  @override
  List<Object?> get props => [];
}

class LocalMusicInitial extends LocalMusicState {
  const LocalMusicInitial();
}

class LocalMusicLoading extends LocalMusicState {
  const LocalMusicLoading();
}

class LocalMusicLoaded extends LocalMusicState {
  final List<DomainTrack> tracks;

  const LocalMusicLoaded(this.tracks);

  @override
  List<Object?> get props => [tracks];
}

class LocalMusicError extends LocalMusicState {
  final String message;

  const LocalMusicError(this.message);

  @override
  List<Object?> get props => [message];
}
