import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/esperanto/context_player_control_client.dart';
import '../../data/esperanto/context_player_options_client.dart';
import '../../data/esperanto/context_player_play_client.dart';
import '../../data/esperanto/context_player_queue_client.dart';
import '../../data/esperanto/context_player_state_client.dart';
import '../../domain/models/player_queue.dart';
import 'mobius/mobius_types.dart';
import 'mobius/queue_effect_handler.dart';
import 'mobius/queue_effects.dart';
import 'mobius/queue_mobius_update.dart';
import 'player_queue_event.dart';
import 'player_queue_state.dart';

export 'mobius/mobius_loop.dart';
export 'mobius/mobius_types.dart';
export 'mobius/queue_effect_handler.dart';
export 'mobius/queue_effects.dart';
export 'mobius/queue_mobius_update.dart';
export 'player_queue_event.dart';
export 'player_queue_state.dart';

/// Application state controller for Player and Queue.
/// Backed 1:1 by Spotify's functional Mobius Loop architecture (com.spotify.mobius)
/// with pure algebraic reducer (queueMobiusUpdate) and effect handlers (p.mwp0, p.dwp0, p.hwp0).
class PlayerQueueBloc extends Bloc<PlayerQueueEvent, PlayerQueueState> {
  final ContextPlayerQueueClient? _queueClient;
  final ContextPlayerControlClient? _controlClient;
  final ContextPlayerOptionsClient? _optionsClient;
  final ContextPlayerStateClient? _stateClient;
  final ContextPlayerPlayClient? _playClient;

  late final QueueMobiusEffectHandler _effectHandler;
  StreamSubscription<PlayerQueue>? _queueSubscription;
  StreamSubscription? _stateSubscription;

  PlayerQueueBloc({
    ContextPlayerQueueClient? queueClient,
    ContextPlayerControlClient? controlClient,
    ContextPlayerOptionsClient? optionsClient,
    ContextPlayerStateClient? stateClient,
    ContextPlayerPlayClient? playClient,
    PlayerQueue initialQueue = PlayerQueue.empty,
  })  : _queueClient = queueClient,
        _controlClient = controlClient,
        _optionsClient = optionsClient,
        _stateClient = stateClient,
        _playClient = playClient,
        super(PlayerQueueState(queue: initialQueue)) {
    _effectHandler = QueueMobiusEffectHandler(
      queueClient: _queueClient,
      controlClient: _controlClient,
      optionsClient: _optionsClient,
      playClient: _playClient,
      getCurrentQueue: () => state.queue,
    );

    on<LoadQueue>(_onDispatch);
    on<QueueUpdated>(_onDispatch);
    on<PlayerStateChanged>(_onDispatch);
    on<QueueErrorOccurred>(_onDispatch);
    on<AddTracksToQueue>(_onDispatch);
    on<RemoveTracksFromQueue>(_onDispatch);
    on<ReorderQueueTrack>(_onDispatch);
    on<ClearQueue>(_onDispatch);
    on<ToggleShuffle>(_onDispatch);
    on<ToggleRepeat>(_onDispatch);
    on<TogglePlayPause>(_onDispatch);
    on<SkipToNextTrack>(_onDispatch);
    on<SkipToPrevTrack>(_onDispatch);
    on<PlayTrackFromQueue>(_onDispatch);

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

  /// Dispatches any event through the 1:1 Spotify Mobius Update function
  /// and executes resulting side effects via QueueMobiusEffectHandler.
  Future<void> _onDispatch(
    PlayerQueueEvent event,
    Emitter<PlayerQueueState> emit,
  ) async {
    final Next<PlayerQueueState, QueueEffect> next = queueMobiusUpdate(state, event);

    if (next.hasModel && next.model != state) {
      emit(next.model!);
    }

    if (next.hasEffects) {
      for (final effect in next.effects) {
        final resultingEvent = await _effectHandler.handleEffect(effect);
        if (resultingEvent != null) {
          add(resultingEvent);
        }
      }
    }
  }

  @override
  Future<void> close() {
    _queueSubscription?.cancel();
    _stateSubscription?.cancel();
    return super.close();
  }
}
