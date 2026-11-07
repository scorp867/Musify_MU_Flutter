import 'dart:collection';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'browse_section.dart';

export 'browse_item.dart';
export 'browse_section.dart';

/// Complete browse tab domain state derived from Browsita + Kodiak traits.
@immutable
final class BrowseViewData extends Equatable {
  final UnmodifiableListView<BrowseSection> sections;

  BrowseViewData({List<BrowseSection> sections = const []})
    : sections = UnmodifiableListView<BrowseSection>(
        List<BrowseSection>.of(sections),
      );

  @override
  List<Object?> get props => [sections];
}
