/// Represents the result of querying a cell from a Kodiak DataSource.
/// Direct 1:1 equivalent to Spotify Android's `DataSourceResult` (`p.a7n` / `p.y6n`).
sealed class DataSourceResult<T> {
  const DataSourceResult();

  bool get isAvailable => this is Available<T>;
  T? get valueOrNull => switch (this) {
        Available<T>(value: final v) => v,
        _ => null,
      };
}

/// The cell is available and loaded with data.
class Available<T> extends DataSourceResult<T> {
  final T value;
  const Available(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Available<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Available($value)';
}

/// The cell is currently not available in cache or remote service returned no trait.
class NotAvailable<T> extends DataSourceResult<T> {
  const NotAvailable();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NotAvailable<T>;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'NotAvailable';
}

/// The cell query encountered an error.
class Failed<T> extends DataSourceResult<T> {
  final Object error;
  const Failed(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failed<T> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failed($error)';
}
