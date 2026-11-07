import 'package:flutter/foundation.dart';

import 'trait.dart';

/// ExtensionKind 119 (SHORTCUTS_CARD_TRAIT).
@immutable
final class ShortcutsCardTrait extends Trait {
  final String title;
  final String? imageUrl;

  const ShortcutsCardTrait({required this.title, this.imageUrl});
}
