library;

import 'package:equatable/equatable.dart';

/// 1:1 replica of Spotify `p199p.kp70` & `p199p.jp70` (InteractionId).
class InteractionId extends Equatable {
  static const InteractionIdCompanion companion = InteractionIdCompanion();

  final String value;

  const InteractionId(this.value);

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

/// 1:1 replica of Spotify `p199p.jp70` Companion.
class InteractionIdCompanion {
  const InteractionIdCompanion();

  InteractionId create(String value) => InteractionId(value);
}
