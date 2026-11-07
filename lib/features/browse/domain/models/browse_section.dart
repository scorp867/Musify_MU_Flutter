import 'dart:collection';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'browse_item.dart';

/// A section in the Spotify Browsita page.
@immutable
final class BrowseSection extends Equatable {
  final String sectionId;
  final String sectionType;
  final String title;
  final String? iconName;
  final UnmodifiableListView<BrowseItem> items;
  final String? navigateUri;

  BrowseSection({
    this.sectionId = '',
    this.sectionType = '',
    this.title = '',
    this.iconName,
    List<BrowseItem> items = const [],
    this.navigateUri,
  }) : items = UnmodifiableListView<BrowseItem>(List<BrowseItem>.of(items));

  @override
  List<Object?> get props => [
    sectionId,
    sectionType,
    title,
    iconName,
    items,
    navigateUri,
  ];
}
