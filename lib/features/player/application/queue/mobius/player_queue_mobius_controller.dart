import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show StateStreamableSource;

import '../../../data/esperanto/context_player_control_client.dart';
import '../../../data/esperanto/context_player_options_client.dart';
import '../../../data/esperanto/context_player_play_client.dart';
import '../../../data/esperanto/context_player_queue_client.dart';
import '../../../data/esperanto/context_player_state_client.dart';
import '../../../domain/commands/options/prepare_play_options.dart';
import '../../../domain/commands/play_command.dart';
import '../../../domain/models/context.dart';
import '../../../domain/models/play_origin.dart';
import '../../../domain/models/player_queue.dart';
import 'mobius_loop.dart';
import 'queue_effect.dart';
import 'queue_effect_handler.dart';
import 'queue_event.dart';
import 'queue_mobius_update.dart';
import 'queue_model.dart';

export 'mobius_loop.dart';
export 'mobius_types.dart';
export 'queue_effect.dart';
export 'queue_effect_handler.dart';
export 'queue_event.dart';
export 'queue_mobius_update.dart';
export 'queue_model.dart';

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
/// pure Mobius Loop architecture (`p199p/mgx0.java`, `p199p/lgx0.java`).
///
/// Drives unidirectional data flow:
/// EventSources -> Update (`jcv0.java`) -> (`QueueModel`, `QueueEffect`) -> EffectHandler (`tbx0/sfo0/wos0`) -> Engine
class PlayerQueueMobiusController extends ChangeNotifier
    implements ValueListenable<QueueModel>, StateStreamableSource<QueueModel> {
  final ContextPlayerQueueClient? _queueClient;
  final ContextPlayerControlClient? _controlClient;
  final ContextPlayerOptionsClient? _optionsClient;
  final ContextPlayerStateClient? _stateClient;
  final ContextPlayerPlayClient? _playClient;

  final QueueMobiusEffectHandler _effectHandler;
  final MobiusLoop<QueueModel, QueueEvent, QueueEffect> _loop;
  final List<StreamSubscription> _subscriptions = [];
  bool _isClosed = false;

  PlayerQueueMobiusController._({
    required ContextPlayerQueueClient? queueClient,
    required ContextPlayerControlClient? controlClient,
    required ContextPlayerOptionsClient? optionsClient,
    required ContextPlayerStateClient? stateClient,
    required ContextPlayerPlayClient? playClient,
    required QueueMobiusEffectHandler effectHandler,
    required MobiusLoop<QueueModel, QueueEvent, QueueEffect> loop,
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
    QueueModel initialModel = const QueueModel(isLoading: true),
  }) {
    final queueRef = _DynamicQueueRef();

    final handler = QueueMobiusEffectHandler(
      queueClient: queueClient,
      controlClient: controlClient,
      optionsClient: optionsClient,
      playClient: playClient,
      getCurrentQueue: queueRef.resolve,
    );

    final loop = MobiusLoop<QueueModel, QueueEvent, QueueEffect>(
      update: queueMobiusUpdate,
      effectHandler: handler,
      initialModel: initialModel,
    );

    queueRef.bind(() => loop.currentModel.playerQueue);

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
    _subscriptions.add(
      _loop.models.listen((newModel) {
        notifyListeners();
      }),
    );

    final queueClient = _queueClient;
    if (queueClient != null) {
      _subscriptions.add(
        queueClient.queueStream.listen(
          (queue) => dispatch(QueueUpdatedEvent(queue)),
          onError: (err) => dispatch(QueueErrorEvent(err.toString())),
        ),
      );
    }

    final stateClient = _stateClient;
    if (stateClient != null) {
      _subscriptions.add(
        stateClient.getStateStream().listen(
          (playerState) => dispatch(PlayerStateChangedEvent(playerState)),
          onError: (err) => dispatch(QueueErrorEvent(err.toString())),
        ),
      );
    }
  }

  ContextPlayerQueueClient? get queueClient => _queueClient;
  ContextPlayerControlClient? get controlClient => _controlClient;
  ContextPlayerOptionsClient? get optionsClient => _optionsClient;
  ContextPlayerStateClient? get stateClient => _stateClient;
  ContextPlayerPlayClient? get playClient => _playClient;
  QueueMobiusEffectHandler get effectHandler => _effectHandler;

  QueueModel get model => _loop.currentModel;

  @override
  QueueModel get state => model;

  @override
  QueueModel get value => model;

  @override
  Stream<QueueModel> get stream => _loop.models;

  void dispatch(QueueEvent event) {
    if (!_isClosed) {
      _loop.dispatchEvent(event);
    }
  }

  void add(QueueEvent event) => dispatch(event);

  Future<void> playContext(
    Context context, {
    PreparePlayOptions? options,
    PlayOrigin? playOrigin,
  }) async {
    final pc = _playClient;
    if (pc == null) return;
    final origin = switch (playOrigin) {
      final po? => po,
      null => const PlayOrigin(),
    };
    final builder = PlayCommand.builder(context, origin);
    if (options case final opt?) {
      builder.options(opt);
    }
    final command = builder.build();
    await pc.play(command);
  }

  @override
  bool get isClosed => _isClosed;

  @override
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _loop.dispose();
  }

  @override
  void dispose() {
    close();
    super.dispose();
  }
}
