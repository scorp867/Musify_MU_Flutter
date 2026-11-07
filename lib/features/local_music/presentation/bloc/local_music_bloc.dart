import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file.dart';
import 'package:musify_mu/features/local_music/domain/repositories/local_music_repository.dart';

import 'local_music_event.dart';
import 'local_music_state.dart';

class LocalMusicBloc extends Bloc<LocalMusicEvent, LocalMusicState> {
  final LocalMusicRepository repository;

  LocalMusicBloc({required this.repository})
      : super(const LocalMusicInitial()) {
    on<LoadLocalTracks>(_onLoadLocalTracks, transformer: restartable());
  }

  Future<void> _onLoadLocalTracks(
    LoadLocalTracks event,
    Emitter<LocalMusicState> emit,
  ) async {
    emit(const LocalMusicLoading());
    try {
      await emit.forEach<List<LocalFile>>(
        repository.getLocalTracks(),
        onData: LocalMusicLoaded.new,
        onError: (error, stackTrace) =>
            LocalMusicError('Failed to load local tracks: $error'),
      );
    } on Object catch (error) {
      emit(LocalMusicError('Failed to load local tracks: $error'));
    }
  }
}
