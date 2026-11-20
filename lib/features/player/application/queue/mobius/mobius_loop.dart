import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;

import 'mobius_types.dart';

/// 1:1 implementation of Spotify's MobiusLoop controller (com.spotify.mobius.MobiusLoop).
/// Drives functional unidirectional state flow: Events -> Update -> (Model, Effects) -> EffectHandler -> Events.
class MobiusLoop<M, E, F> {
  M _currentModel;
  final Update<M, E, F> _update;
  final MobiusEffectHandler<F, E> _effectHandler;
  final void Function(Object error, StackTrace stackTrace)? _onError;

  final StreamController<M> _modelController = StreamController<M>.broadcast();
  final List<StreamSubscription<E>> _subscriptions = <StreamSubscription<E>>[];
  bool _isDisposed = false;

  MobiusLoop({
    required M initialModel,
    required Update<M, E, F> update,
    required MobiusEffectHandler<F, E> effectHandler,
    List<Stream<E>> eventSources = const [],
    void Function(Object error, StackTrace stackTrace)? onError,
  })  : _currentModel = initialModel,
        _update = update,
        _effectHandler = effectHandler,
        _onError = onError {
    for (final source in eventSources) {
      _subscriptions.add(
        source.listen(
          dispatchEvent,
          onError: (Object error, StackTrace stackTrace) {
            _reportError('eventSource', error, stackTrace);
          },
        ),
      );
    }
  }

  /// Current snapshot of the Mobius state model.
  M get currentModel => _currentModel;

  /// Observable stream of state changes with replay(1) semantics (1:1 with Spotify RxJava replay(1)).
  Stream<M> get models => Stream<M>.multi(
        (controller) {
          if (_modelController.isClosed) {
            controller.close();
            return;
          }
          controller.add(_currentModel);
          final sub = _modelController.stream.listen(
            controller.add,
            onError: controller.addError,
            onDone: controller.close,
          );
          controller.onCancel = sub.cancel;
        },
        isBroadcast: true,
      );

  /// Dispatches an event into the Mobius state loop.
  void dispatchEvent(E event) {
    if (_isDisposed) return;

    final next = _update(_currentModel, event);

    if (next.model case final nextModel? when nextModel != _currentModel) {
      _currentModel = nextModel;
      if (!_modelController.isClosed) {
        _modelController.add(_currentModel);
      }
    }

    if (next.hasEffects) {
      for (final effect in next.effects) {
        unawaited(_executeEffect(effect));
      }
    }
  }

  Future<void> _executeEffect(F effect) async {
    try {
      final resultingEvent = await _effectHandler.handleEffect(effect);
      if (resultingEvent != null && !_isDisposed) {
        dispatchEvent(resultingEvent);
      }
    } on Object catch (error, stackTrace) {
      _reportError('effect(${effect.runtimeType})', error, stackTrace);
    }
  }

  void _reportError(String source, Object error, StackTrace stackTrace) {
    debugPrint('[MobiusLoop] Unhandled error in $source: $error\n$stackTrace');
    if (_onError case final handler?) {
      handler(error, stackTrace);
    }
  }

  void dispose() {
    _isDisposed = true;
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
    unawaited(_modelController.close());
  }
}
