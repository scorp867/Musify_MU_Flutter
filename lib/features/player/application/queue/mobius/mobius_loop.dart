import 'dart:async';

import 'mobius_types.dart';

/// 1:1 implementation of Spotify's MobiusLoop controller (com.spotify.mobius.MobiusLoop).
/// Drives functional unidirectional state flow: Events -> Update -> (Model, Effects) -> EffectHandler -> Events.
class MobiusLoop<M, E, F> {
  M _currentModel;
  final Update<M, E, F> _update;
  final MobiusEffectHandler<F, E> _effectHandler;

  final StreamController<M> _modelController = StreamController<M>.broadcast();
  final List<StreamSubscription> _subscriptions = [];
  bool _isDisposed = false;

  MobiusLoop({
    required M initialModel,
    required Update<M, E, F> update,
    required MobiusEffectHandler<F, E> effectHandler,
    List<Stream<E>> eventSources = const [],
  })  : _currentModel = initialModel,
        _update = update,
        _effectHandler = effectHandler {
    for (final source in eventSources) {
      _subscriptions.add(source.listen(
        dispatchEvent,
        onError: (err, stack) {
          // Log or handle stream errors safely
        },
      ));
    }
  }

  /// Current snapshot of the Mobius state model.
  M get currentModel => _currentModel;

  /// Observable stream of state changes.
  Stream<M> get models => _modelController.stream;

  /// Dispatches an event into the Mobius state loop.
  void dispatchEvent(E event) {
    if (_isDisposed) return;

    final next = _update(_currentModel, event);

    if (next.hasModel && next.model != _currentModel) {
      _currentModel = next.model as M;
      if (!_modelController.isClosed) {
        _modelController.add(_currentModel);
      }
    }

    if (next.hasEffects) {
      for (final effect in next.effects) {
        _executeEffect(effect);
      }
    }
  }

  Future<void> _executeEffect(F effect) async {
    try {
      final resultingEvent = await _effectHandler.handleEffect(effect);
      if (resultingEvent != null && !_isDisposed) {
        dispatchEvent(resultingEvent);
      }
    } catch (_) {
      // Handled within effect handler
    }
  }

  void dispose() {
    _isDisposed = true;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _modelController.close();
  }
}
