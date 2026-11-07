import 'dart:collection';
import 'package:flutter/foundation.dart';

import 'credit_contributor.dart';
import 'trait.dart';

/// ExtensionKind 186 (`CREDITS_V2_TRAIT`).
/// Equivalent to Spotify Android's `adn` / `bmk`.
@immutable
final class CreditsTrait extends Trait {
  final UnmodifiableListView<CreditContributor> contributors;
  final UnmodifiableListView<String> sourceNames;

  CreditsTrait({
    List<CreditContributor> contributors = const [],
    List<String> sourceNames = const [],
  }) : contributors = UnmodifiableListView<CreditContributor>(
         List<CreditContributor>.of(contributors),
       ),
       sourceNames = UnmodifiableListView<String>(List<String>.of(sourceNames));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreditsTrait &&
        listEquals(other.contributors, contributors) &&
        listEquals(other.sourceNames, sourceNames);
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(contributors), Object.hashAll(sourceNames));
}
