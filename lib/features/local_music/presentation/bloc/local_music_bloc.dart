import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/local_music/application/local_music_playback_synchronizer.dart';
import 'package:musify_mu/features/local_music/domain/entities/domain_track.dart';
import 'package:musify_mu/features/local_music/domain/repositories/local_music_repository.dart';

import 'local_music_event.dart';
import 'local_music_state.dart';

class LocalMusicBloc extends Bloc<LocalMusicEvent, LocalMusicState> {
  final LocalMusicRepository repository;
  final LocalMusicPlaybackSynchronizer? playbackSynchronizer;

  LocalMusicBloc({required this.repository, this.playbackSynchronizer})
    : super(const LocalMusicInitial()) {
    on<LoadLocalTracks>(_onLoadLocalTracks);
  }

  Future<void> _onLoadLocalTracks(
    LoadLocalTracks event,
    Emitter<LocalMusicState> emit,
  ) async {
    emit(const LocalMusicLoading());
    try {
      await emit.forEach(
        repository.getLocalTracks(),
        onData: (List<DomainTrack> tracks) {
          final synchronizer = playbackSynchronizer;
          if (synchronizer != null) {
            unawaited(synchronizer.synchronize(tracks));
          }
          return LocalMusicLoaded(tracks);
        },
        onError: (error, stackTrace) =>
            LocalMusicError('Failed to load local tracks: $error'),
      );
    } catch (error) {
      emit(LocalMusicError('Failed to load local tracks: $error'));
    }
  }
}
