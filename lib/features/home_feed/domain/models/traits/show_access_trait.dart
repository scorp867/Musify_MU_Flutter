import 'package:flutter/foundation.dart';

import 'trait.dart';

/// Show / Podcast access entitlement metadata (ExtensionKind 31).
@immutable
final class ShowAccessTrait extends Trait {
  final bool hasAccess;
  final bool isLocked;
  final String accessType;

  const ShowAccessTrait({
    this.hasAccess = true,
    this.isLocked = false,
    this.accessType = '',
  });
}
