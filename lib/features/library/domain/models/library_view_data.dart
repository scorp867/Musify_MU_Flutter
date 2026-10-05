import 'package:equatable/equatable.dart';

export 'library_item.dart';

import 'package:musify_mu/features/library/domain/models/library_item.dart';

/// Aggregated library data ready for the UI.
class LibraryViewData extends Equatable {
  final List<LibraryItem> items;
  final Set<String> pinnedUris;

  const LibraryViewData({
    required this.items,
    this.pinnedUris = const {},
  });

  @override
  List<Object?> get props => [items, pinnedUris];

  /// Items filtered by type.
  List<LibraryItem> filterByType(String type) {
    return items.where((item) => item.type == type).toList();
  }

  /// Items sorted by recency (added_at descending), with pinned items first.
  List<LibraryItem> sortedByRecents() {
    final sorted = List<LibraryItem>.from(items);
    sorted.sort((a, b) {
      // Pinned items first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      // Then by added_at descending
      final aTime = a.addedAt ?? DateTime(1970);
      final bTime = b.addedAt ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });
    return sorted;
  }
}
