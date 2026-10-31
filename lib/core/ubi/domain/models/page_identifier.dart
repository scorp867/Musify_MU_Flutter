library;

import 'package:equatable/equatable.dart';

/// 1:1 replica of Spotify `p199p.jxp0` (PageIdentifier / Entity URI).
class PageIdentifier extends Equatable {
  final String value;

  const PageIdentifier(this.value);

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
