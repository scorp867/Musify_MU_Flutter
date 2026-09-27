import 'dart:isolate';
import 'dart:typed_data';

/// Runs a protobuf parse function in a background isolate.
///
/// Use this for any protobuf payload > ~10KB to keep the UI thread free.
/// The [parser] function must be a top-level or static function
/// (isolate requirement).
///
/// Usage:
/// ```dart
/// final result = await parseInBackground(
///   bytes,
///   (data) => MyProto.fromBuffer(data),
/// );
/// ```
Future<T> parseInBackground<T>(
  Uint8List data,
  T Function(Uint8List) parser,
) {
  return Isolate.run(() => parser(data));
}
