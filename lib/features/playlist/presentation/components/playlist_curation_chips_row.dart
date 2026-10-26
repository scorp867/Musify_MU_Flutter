library;

import 'package:flutter/material.dart';
import '../../../../core/ui/icons/spotify_encore_icons.dart';

/// 1:1 replica of Spotify's Curation Actions chip row
/// (`uwt.java`, `f9v0.java`, `ul51.java`, `cwp_header_action1`..`5`).
///
/// Rendered conditionally based on playlist type and permission level:
/// - If `isEditorial`: Returns `SizedBox.shrink()` (zero curation row in official editorial playlists).
/// - If `canEdit` (Owner / Editor): Displays `+ Add`, `☰ Edit`, `✎ Name & details`, and `⇅ Sort`.
/// - If `canEdit` is false (Followed): Displays only `⇅ Sort`.
///
/// Design guardrails: Never uses pill-shaped buttons; uses Encore 8dp rounded rectangle geometry.
class PlaylistCurationChipsRow extends StatelessWidget {
  final bool isEditorial;
  final bool canEdit;
  final VoidCallback onAddTapped;
  final VoidCallback onEditTapped;
  final VoidCallback onDetailsTapped;
  final VoidCallback onSortTapped;
  final String currentSortName;

  const PlaylistCurationChipsRow({
    super.key,
    this.isEditorial = false,
    required this.canEdit,
    required this.onAddTapped,
    required this.onEditTapped,
    required this.onDetailsTapped,
    required this.onSortTapped,
    this.currentSortName = 'Sort',
  });

  @override
  Widget build(BuildContext context) {
    if (isEditorial) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. Add to playlist chip (Owner / Editor only, cwp_header_action1)
          if (canEdit) ...[
            _buildChip(
              icon: SpotifyIcon.plus(
                color: Colors.white,
                size: 16,
              ),
              label: 'Add',
              onTap: onAddTapped,
            ),
            const SizedBox(width: 8),

            // 2. Edit playlist chip (Owner only, cwp_header_action2)
            _buildChip(
              icon: SpotifyIcon.listView(
                color: Colors.white,
                size: 16,
              ),
              label: 'Edit',
              onTap: onEditTapped,
            ),
            const SizedBox(width: 8),

            // 3. Name & details chip (Owner only, cwp_header_action3)
            _buildChip(
              icon: SpotifyIcon.edit(
                color: Colors.white,
                size: 16,
              ),
              label: 'Name & details',
              onTap: onDetailsTapped,
            ),
            const SizedBox(width: 8),
          ],

          // 4. Sort playlist chip (Available for user-owned and followed playlists, cwp_header_action4)
          _buildChip(
            icon: SpotifyIcon.sort(
              color: Colors.white,
              size: 16,
            ),
            label: currentSortName.isNotEmpty ? currentSortName : 'Sort',
            onTap: onSortTapped,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0x1AFFFFFF), // dark_base_background_tinted_base (10% white)
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: const Color(0x33FFFFFF),
        highlightColor: const Color(0x1FFFFFFF),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0x1AFFFFFF),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
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
