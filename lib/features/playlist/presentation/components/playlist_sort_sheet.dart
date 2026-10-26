library;

import 'package:flutter/material.dart';
import '../../domain/models/sort_order.dart';

/// 1:1 replica of Spotify's Sort Order bottom sheet modal
/// (`add_to_playlist_sort_bottom_sheet.xml` & `sort_row_add_to_playlist.xml`).
class PlaylistSortSheet extends StatelessWidget {
  final ProvidedSortOrder currentOrder;
  final ValueChanged<ProvidedSortOrder> onOrderSelected;

  const PlaylistSortSheet({
    super.key,
    required this.currentOrder,
    required this.onOrderSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required ProvidedSortOrder currentOrder,
    required ValueChanged<ProvidedSortOrder> onOrderSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => PlaylistSortSheet(
        currentOrder: currentOrder,
        onOrderSelected: (order) {
          Navigator.pop(ctx);
          onOrderSelected(order);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF535353),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Text(
                'Sort by',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const Divider(color: Color(0xFF383838), height: 1),

            // Sort Options List
            ...ProvidedSortOrder.values.map((order) {
              final isSelected = order == currentOrder;
              return InkWell(
                onTap: () => onOrderSelected(order),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.displayName,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF1DB954) : Colors.white,
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check,
                          color: Color(0xFF1DB954),
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
