import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/esperanto/context_player_control_client.dart';
import '../../data/esperanto/context_player_options_client.dart';
import '../../data/esperanto/context_player_queue_client.dart';
import '../../data/esperanto/context_player_state_client.dart';
import '../../data/queue/queue_add_handler.dart';
import '../../data/queue/queue_clear_handler.dart';
import '../../data/queue/queue_helpers.dart';
import '../../data/queue/queue_remove_handler.dart';
import '../../data/queue/queue_reorder_handler.dart';
import '../../domain/commands/pause_command.dart';
import '../../domain/commands/resume_command.dart';
import '../../domain/commands/skip_to_next_track_command.dart';
import '../../domain/commands/skip_to_prev_track_command.dart';
import '../../domain/models/player_queue.dart';
import 'player_queue_event.dart';
import 'player_queue_state.dart';

export 'player_queue_event.dart';
export 'player_queue_state.dart';

class PlayerQueueBloc extends Bloc<PlayerQueueEvent, PlayerQueueState> {
  final ContextPlayerQueueClient? _queueClient;
  final ContextPlayerControlClient? _controlClient;
  final ContextPlayerOptionsClient? _optionsClient;
  final ContextPlayerStateClient? _stateClient;

  StreamSubscription<PlayerQueue>? _queueSubscription;
  StreamSubscription? _stateSubscription;

  PlayerQueueBloc({
    ContextPlayerQueueClient? queueClient,
    ContextPlayerControlClient? controlClient,
    ContextPlayerOptionsClient? optionsClient,
    ContextPlayerStateClient? stateClient,
    PlayerQueue initialQueue = PlayerQueue.empty,
  })  : _queueClient = queueClient,
        _controlClient = controlClient,
        _optionsClient = optionsClient,
        _stateClient = stateClient,
        super(PlayerQueueState(queue: initialQueue)) {
    on<LoadQueue>(_onLoadQueue);
    on<QueueUpdated>(_onQueueUpdated);
    on<PlayerStateChanged>(_onPlayerStateChanged);
    on<QueueErrorOccurred>(_onQueueErrorOccurred);
    on<AddTracksToQueue>(_onAddTracksToQueue);
    on<RemoveTracksFromQueue>(_onRemoveTracksFromQueue);
    on<ReorderQueueTrack>(_onReorderQueueTrack);
    on<ClearQueue>(_onClearQueue);
    on<ToggleShuffle>(_onToggleShuffle);
    on<ToggleRepeat>(_onToggleRepeat);
    on<TogglePlayPause>(_onTogglePlayPause);
    on<SkipToNextTrack>(_onSkipToNextTrack);
    on<SkipToPrevTrack>(_onSkipToPrevTrack);
    on<PlayTrackFromQueue>(_onPlayTrackFromQueue);

    _initStreams();
  }

  void _initStreams() {
    final queueClient = _queueClient;
    if (queueClient != null) {
      _queueSubscription = queueClient.getQueueStream().listen(
        (queue) => add(QueueUpdated(queue)),
        onError: (err) => add(QueueErrorOccurred(err.toString())),
      );
    }

    final stateClient = _stateClient;
    if (stateClient != null) {
      _stateSubscription = stateClient.getStateStream().listen(
        (playerState) => add(PlayerStateChanged(playerState)),
        onError: (err) => add(QueueErrorOccurred(err.toString())),
      );
    }
  }

  Future<void> _onLoadQueue(
    LoadQueue event,
    Emitter<PlayerQueueState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
  }

  void _onQueueUpdated(
    QueueUpdated event,
    Emitter<PlayerQueueState> emit,
  ) {
    emit(state.copyWith(
      queue: event.queue,
      isLoading: false,
    ));
  }

  void _onPlayerStateChanged(
    PlayerStateChanged event,
    Emitter<PlayerQueueState> emit,
  ) {
    emit(state.copyWith(
      playerState: event.playerState,
    ));
  }

  void _onQueueErrorOccurred(
    QueueErrorOccurred event,
    Emitter<PlayerQueueState> emit,
  ) {
    emit(state.copyWith(errorMessage: event.error));
  }

  Future<void> _onAddTracksToQueue(
    AddTracksToQueue event,
    Emitter<PlayerQueueState> emit,
  ) async {
    final updatedQueue = QueueAddHandler.addTracks(
      state.queue,
      event.tracks,
      mode: event.mode,
    );

    // Optimistic UI update
    emit(state.copyWith(queue: updatedQueue));

    final queueClient = _queueClient;
    if (queueClient != null) {
      try {
        final command = QueueHelpers.createSetQueueCommand(updatedQueue);
        await queueClient.setQueue(command);
      } catch (e) {
        emit(state.copyWith(errorMessage: 'Failed to add tracks: $e'));
      }
    }
  }

  Future<void> _onRemoveTracksFromQueue(
    RemoveTracksFromQueue event,
    Emitter<PlayerQueueState> emit,
  ) async {
    final updatedQueue = QueueRemoveHandler.removeTracks(
      state.queue,
      event.tracks,
    );

    // Optimistic UI update
    emit(state.copyWith(queue: updatedQueue));

    final queueClient = _queueClient;
    if (queueClient != null) {
      try {
        final command = QueueHelpers.createSetQueueCommand(updatedQueue);
        await queueClient.setQueue(command);
      } catch (e) {
        emit(state.copyWith(errorMessage: 'Failed to remove tracks: $e'));
      }
    }
  }

  Future<void> _onReorderQueueTrack(
    ReorderQueueTrack event,
    Emitter<PlayerQueueState> emit,
  ) async {
    final updatedQueue = QueueReorderHandler.reorderTrack(
      playerQueue: state.queue,
      trackToMove: event.track,
      destinationVisibleIndex: event.destinationVisibleIndex,
    );

    // Optimistic UI update
    emit(state.copyWith(queue: updatedQueue));

    final queueClient = _queueClient;
    if (queueClient != null) {
      try {
        final command = QueueHelpers.createSetQueueCommand(updatedQueue);
        await queueClient.setQueue(command);
      } catch (e) {
        emit(state.copyWith(errorMessage: 'Failed to reorder track: $e'));
      }
    }
  }

  Future<void> _onClearQueue(
    ClearQueue event,
    Emitter<PlayerQueueState> emit,
  ) async {
    final updatedQueue = QueueClearHandler.clearUserQueue(state.queue);

    // Optimistic UI update
    emit(state.copyWith(queue: updatedQueue));

    final queueClient = _queueClient;
    if (queueClient != null) {
      try {
        final command = QueueHelpers.createSetQueueCommand(updatedQueue);
        await queueClient.setQueue(command);
      } catch (e) {
        emit(state.copyWith(errorMessage: 'Failed to clear queue: $e'));
      }
    }
  }

  Future<void> _onToggleShuffle(
    ToggleShuffle event,
    Emitter<PlayerQueueState> emit,
  ) async {
    final nextShuffle = !state.isShuffling;
    final optionsClient = _optionsClient;
    if (optionsClient != null) {
      await optionsClient.setShuffle(nextShuffle);
    }
  }

  Future<void> _onToggleRepeat(
    ToggleRepeat event,
    Emitter<PlayerQueueState> emit,
  ) async {
    final current = state.repeatMode;
    final RepeatMode next;
    switch (current) {
      case RepeatMode.none:
        next = RepeatMode.context;
        break;
      case RepeatMode.context:
        next = RepeatMode.track;
        break;
      case RepeatMode.track:
        next = RepeatMode.none;
        break;
    }

    final optionsClient = _optionsClient;
    if (optionsClient != null) {
      await optionsClient.setRepeatMode(next);
    }
  }

  Future<void> _onTogglePlayPause(
    TogglePlayPause event,
    Emitter<PlayerQueueState> emit,
  ) async {
    final controlClient = _controlClient;
    if (controlClient != null) {
      if (state.isPlaying) {
        await controlClient.pause(PauseCommand.create());
      } else {
        await controlClient.resume(ResumeCommand.create());
      }
    }
  }

  Future<void> _onSkipToNextTrack(
    SkipToNextTrack event,
    Emitter<PlayerQueueState> emit,
  ) async {
    final controlClient = _controlClient;
    if (controlClient != null) {
      await controlClient.skipToNext(SkipToNextTrackCommand.create());
    }
  }

  Future<void> _onSkipToPrevTrack(
    SkipToPrevTrack event,
    Emitter<PlayerQueueState> emit,
  ) async {
    final controlClient = _controlClient;
    if (controlClient != null) {
      await controlClient.skipToPrev(SkipToPrevTrackCommand.create());
    }
  }

  Future<void> _onPlayTrackFromQueue(
    PlayTrackFromQueue event,
    Emitter<PlayerQueueState> emit,
  ) async {
    final controlClient = _controlClient;
    if (controlClient != null) {
      final command = SkipToNextTrackCommand.builder()
          .track(event.track)
          .build();
      await controlClient.skipToNext(command);
    }
  }

  @override
  Future<void> close() {
    _queueSubscription?.cancel();
    _stateSubscription?.cancel();
    return super.close();
  }
}
