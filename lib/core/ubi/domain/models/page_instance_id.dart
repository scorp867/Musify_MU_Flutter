library;

import 'package:equatable/equatable.dart';

/// 1:1 replica of Spotify `p199p.wlp0` & `p199p.vlp0` (PageInstanceId).
class PageInstanceId extends Equatable {
  static const PageInstanceIdCompanion companion = PageInstanceIdCompanion();

  final String value;

  const PageInstanceId(this.value);

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

/// 1:1 replica of Spotify `p199p.vlp0` Companion.
class PageInstanceIdCompanion {
  const PageInstanceIdCompanion();

  PageInstanceId create(String value) => PageInstanceId(value);
}
