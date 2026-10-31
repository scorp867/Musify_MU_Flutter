library;

import 'package:equatable/equatable.dart';

/// 1:1 replica of Spotify `p199p.sz60` (ImpressionId).
class ImpressionId extends Equatable {
  final String value;

  const ImpressionId(this.value);

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
