import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show StateStreamableSource;

import '../../data/esperanto/context_player_control_client.dart';
import '../../data/esperanto/context_player_options_client.dart';
import '../../data/esperanto/context_player_play_client.dart';
import '../../data/esperanto/context_player_queue_client.dart';
import '../../data/esperanto/context_player_state_client.dart';
import '../../domain/models/player_queue.dart';
import 'mobius/mobius_loop.dart';
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

/// Mutable holder for dynamic queue resolution without using banned late fields.
final class _DynamicQueueRef {
  PlayerQueue Function()? _getter;

  void bind(PlayerQueue Function() getter) {
    _getter = getter;
  }

  PlayerQueue resolve() {
    return switch (_getter) {
      final g? => g(),
      null => PlayerQueue.empty,
    };
  }
}

/// 1:1 Application state controller for Player and Queue matching Spotify's
/// pure Mobius Loop architecture (com.spotify.mobius, p199p/mgx0.java, p199p/lgx0.java).
///
/// Drives unidirectional data flow:
/// EventSources -> Update (jcv0.m54765n) -> (Model, Effects) -> EffectHandler (tbx0/ibx0) -> Clients
class PlayerQueueMobiusController extends ChangeNotifier
    implements
        ValueListenable<PlayerQueueState>,
        StateStreamableSource<PlayerQueueState> {
  final ContextPlayerQueueClient? _queueClient;
  final ContextPlayerControlClient? _controlClient;
  final ContextPlayerOptionsClient? _optionsClient;
  final ContextPlayerStateClient? _stateClient;
  final ContextPlayerPlayClient? _playClient;

  final QueueMobiusEffectHandler _effectHandler;
  final MobiusLoop<PlayerQueueState, PlayerQueueEvent, QueueEffect> _loop;
  final List<StreamSubscription> _subscriptions = [];
  bool _isClosed = false;

  PlayerQueueMobiusController._({
    required ContextPlayerQueueClient? queueClient,
    required ContextPlayerControlClient? controlClient,
    required ContextPlayerOptionsClient? optionsClient,
    required ContextPlayerStateClient? stateClient,
    required ContextPlayerPlayClient? playClient,
    required QueueMobiusEffectHandler effectHandler,
    required MobiusLoop<PlayerQueueState, PlayerQueueEvent, QueueEffect> loop,
  })  : _queueClient = queueClient,
        _controlClient = controlClient,
        _optionsClient = optionsClient,
        _stateClient = stateClient,
        _playClient = playClient,
        _effectHandler = effectHandler,
        _loop = loop;

  factory PlayerQueueMobiusController({
    ContextPlayerQueueClient? queueClient,
    ContextPlayerControlClient? controlClient,
    ContextPlayerOptionsClient? optionsClient,
    ContextPlayerStateClient? stateClient,
    ContextPlayerPlayClient? playClient,
    PlayerQueue initialQueue = PlayerQueue.empty,
  }) {
    final queueRef = _DynamicQueueRef();

    final handler = QueueMobiusEffectHandler(
      queueClient: queueClient,
      controlClient: controlClient,
      optionsClient: optionsClient,
      playClient: playClient,
      getCurrentQueue: queueRef.resolve,
    );

    final loop = MobiusLoop<PlayerQueueState, PlayerQueueEvent, QueueEffect>(
      initialModel: PlayerQueueState(queue: initialQueue),
      update: queueMobiusUpdate,
      effectHandler: handler,
    );

    queueRef.bind(() => loop.currentModel.queue);

    final controller = PlayerQueueMobiusController._(
      queueClient: queueClient,
      controlClient: controlClient,
      optionsClient: optionsClient,
      stateClient: stateClient,
      playClient: playClient,
      effectHandler: handler,
      loop: loop,
    );

    controller._init();
    return controller;
  }

  void _init() {
    _subscriptions.add(_loop.models.listen((model) {
      if (!_isClosed) {
        notifyListeners();
      }
    }));
    _initEventSources();
  }

  /// 1:1 with Spotify lgx0.java lines 291-336:
  /// Connects ContextPlayerQueueClient (pvy) and ContextPlayerStateClient (rvy)
  /// as reactive EventSources feeding wcx0 and xcx0 events into the Mobius loop.
  void _initEventSources() {
    final queueClient = _queueClient;
    if (queueClient != null) {
      _subscriptions.add(
        queueClient.getQueueStream().listen(
          (queue) => add(QueueUpdated(queue)),
          onError: (err) => add(QueueErrorOccurred(err.toString())),
        ),
      );
    }

    final stateClient = _stateClient;
    if (stateClient != null) {
      _subscriptions.add(
        stateClient.getStateStream().listen(
          (playerState) => add(PlayerStateChanged(playerState)),
          onError: (err) => add(QueueErrorOccurred(err.toString())),
        ),
      );
    }
  }

  // Component accessors (1:1 with Spotify Dagger bindings in p.afs0 / p.mgx0)
  ContextPlayerQueueClient? get queueClient => _queueClient;
  ContextPlayerControlClient? get controlClient => _controlClient;
  ContextPlayerOptionsClient? get optionsClient => _optionsClient;
  ContextPlayerStateClient? get stateClient => _stateClient;
  ContextPlayerPlayClient? get playClient => _playClient;
  QueueMobiusEffectHandler get effectHandler => _effectHandler;

  /// Active state model snapshot
  @override
  PlayerQueueState get state => _loop.currentModel;

  /// ValueListenable interface implementation
  @override
  PlayerQueueState get value => state;

  /// Observable model stream
  @override
  Stream<PlayerQueueState> get stream => _loop.models;

  @override
  bool get isClosed => _isClosed;

  /// Dispatches a high-level intent event into the Mobius state loop (1:1 with mgx0.java dispatch).
  void add(PlayerQueueEvent event) {
    if (_isClosed) return;
    _loop.dispatchEvent(event);
  }

  /// Alias for add matching Spotify Mobius controller API.
  void dispatch(PlayerQueueEvent event) => add(event);

  @override
  Future<void> close() async {
    _isClosed = true;
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _loop.dispose();
  }

  @override
  void dispose() {
    unawaited(close());
    super.dispose();
  }
}

/// 1:1 Aliases for seamless migration away from BLoC across the codebase.
typedef PlayerQueueBloc = PlayerQueueMobiusController;
