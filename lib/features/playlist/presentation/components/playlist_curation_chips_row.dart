library;

import 'package:flutter/material.dart';

/// 1:1 replica of Spotify's Curation Actions chip row
/// (`uwt.java`, `f9v0.java`, `ul51.java`, `curation_actions_*`).
///
/// Rendered conditionally based on the user's permission level:
/// - If `canEdit` (Owner / Editor): Displays `+ Add`, `☰ Edit`, `✎ Name & details`, and `⇅ Sort`.
/// - If `canEdit` is false (Viewer): Displays only `⇅ Sort`.
class PlaylistCurationChipsRow extends StatelessWidget {
  final bool canEdit;
  final VoidCallback onAddTapped;
  final VoidCallback onEditTapped;
  final VoidCallback onDetailsTapped;
  final VoidCallback onSortTapped;
  final String currentSortName;

  const PlaylistCurationChipsRow({
    super.key,
    required this.canEdit,
    required this.onAddTapped,
    required this.onEditTapped,
    required this.onDetailsTapped,
    required this.onSortTapped,
    this.currentSortName = 'Sort',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. Add to playlist chip (Owner only)
          if (canEdit) ...[
            _buildChip(
              icon: Icons.add,
              label: 'Add',
              onTap: onAddTapped,
            ),
            const SizedBox(width: 8),

            // 2. Edit playlist chip (Owner only)
            _buildChip(
              icon: Icons.format_list_bulleted,
              label: 'Edit',
              onTap: onEditTapped,
            ),
            const SizedBox(width: 8),

            // 3. Name & details chip (Owner only)
            _buildChip(
              icon: Icons.edit_outlined,
              label: 'Name & details',
              onTap: onDetailsTapped,
            ),
            const SizedBox(width: 8),
          ],

          // 4. Sort playlist chip (Available for all permission levels)
          _buildChip(
            icon: Icons.swap_vert,
            label: currentSortName.isNotEmpty ? currentSortName : 'Sort',
            onTap: onSortTapped,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0x1AFFFFFF), // dark_base_background_tinted_base (10% white)
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: const Color(0x33FFFFFF),
        highlightColor: const Color(0x1FFFFFFF),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
