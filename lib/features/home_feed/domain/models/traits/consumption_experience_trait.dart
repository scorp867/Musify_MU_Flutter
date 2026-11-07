import 'package:flutter/foundation.dart';

import 'trait.dart';

/// Consumption experience details (ExtensionKind 182).
@immutable
final class ConsumptionExperienceTrait extends Trait {
  final String format;
  final bool isInteractive;

  const ConsumptionExperienceTrait({
    this.format = '',
    this.isInteractive = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConsumptionExperienceTrait &&
        other.format == format &&
        other.isInteractive == isInteractive;
  }

  @override
  int get hashCode => Object.hash(format, isInteractive);
}
