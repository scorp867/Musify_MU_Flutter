library;

import 'package:flutter/material.dart';
import '../../../../core/ui/icons/spotify_encore_icons.dart';

/// 1:1 replica of Spotify's search and sort adaptive layout
/// (`search_and_sort_row_adaptive_layout.xml`, `FindInContextView.java`, `SortButtonView.java`).
///
/// Layout hierarchy:
/// ConstraintLayout (search_row_container)
///  ├── FindInContextView (0dp flex width, search_icon, edit_text, clear_text_button)
///  └── SortButtonView (wrap_content, 8dp marginStart, filters_button_background)
///
/// Both elements use:
/// - Background: Color(0x1AFFFFFF) (10% white, dark_base_background_tinted_base)
/// - Corner radius: 4dp (find_in_context_background, filters_button_background)
/// - Typography: TextAppearance.Encore.BodySmallBold (13sp, font weight 700)
class PlaylistSearchSortRow extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onSortTapped;
  final String currentSortName;

  const PlaylistSearchSortRow({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSortTapped,
    this.currentSortName = 'Sort',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // 1. FindInContextView (0dp flex width)
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF), // dark_base_background_tinted_base (#1affffff)
                borderRadius: BorderRadius.circular(4), // find_in_context_background radius 4dp
              ),
              child: Row(
                children: [
                  // Search Icon (encore_action_button_icon_size_small)
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0, right: 8.0),
                    child: SpotifyIcon.search(
                      color: Colors.white,
                      size: 18,
                    ),
                  ),

                  // Edit Text (text_cursor_green, BodySmallBold)
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      cursorColor: const Color(0xFF1DB954), // text_cursor_green
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Find in playlist',
                        hintStyle: TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                      ),
                      onChanged: onSearchChanged,
                    ),
                  ),

                  // ClearButtonView (visible when query is not empty)
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: searchController,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return SizedBox(
                        width: 36,
                        height: 38,
                        child: IconButton(
                          icon: SpotifyIcon.clear(
                            color: const Color(0xFFB3B3B3),
                            size: 16,
                          ),
                          onPressed: () {
                            searchController.clear();
                            onClearSearch();
                          },
                          padding: EdgeInsets.zero,
                          tooltip: 'Clear search',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8), // layout_marginStart="8dp"

          // 2. SortButtonView (wrap_content, filters_button_background)
          InkWell(
            onTap: onSortTapped,
            borderRadius: BorderRadius.circular(4), // filters_button_background radius 4dp
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF), // filters_button_background (#1affffff)
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentSortName.isNotEmpty ? currentSortName : 'Sort',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SpotifyIcon.sort(
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
