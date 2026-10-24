library;

/// Core functional types for Spotify's Mobius state management pattern (com.spotify.mobius).

/// Represents the output of a Mobius `Update` function: a potentially new model
/// and an optional set of side effects to dispatch.
class Next<M, F> {
  final M? model;
  final Set<F> effects;

  const Next._(this.model, this.effects);

  bool get hasModel => model != null;
  bool get hasEffects => effects.isNotEmpty;

  /// Transition to a new model, optionally dispatching side effects.
  static Next<M, F> next<M, F>(M model, [Set<F> effects = const {}]) {
    return Next._(model, Set.unmodifiable(effects));
  }

  /// Keep the current model and dispatch side effects.
  static Next<M, F> dispatch<M, F>(Set<F> effects) {
    return Next._(null, Set.unmodifiable(effects));
  }

  /// No state change and no side effects.
  static Next<M, F> noChange<M, F>() {
    return Next._(null, const {});
  }
}

/// Pure state transition function: `(Model, Event) -> Next<Model, Effect>`.
typedef Update<M, E, F> = Next<M, F> Function(M model, E event);

/// Effect handler interface mapping emitted side effects to resulting events.
abstract class MobiusEffectHandler<F, E> {
  Future<E?> handleEffect(F effect);
}
