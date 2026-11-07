import 'package:flutter/foundation.dart';

/// Resolved browse item trait summary from `IdentityTrait` + `VisualIdentityTrait`.
@immutable
final class BrowseCardData {
  final String name;
  final String type;
  final String? imageUrl;
  final int? bgColorArgb;

  const BrowseCardData({
    this.name = '',
    this.type = '',
    this.imageUrl,
    this.bgColorArgb,
  });
}
