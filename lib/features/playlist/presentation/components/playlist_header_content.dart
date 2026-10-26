library;

import 'package:flutter/material.dart';
import '../../domain/models/playlist_header_type.dart';
import '../../domain/models/playlist_metadata.dart';
import 'playlist_editorial_header.dart';
import 'playlist_user_header.dart';

/// 1:1 replica of Spotify's Playlist Header Dispatcher & Factory
/// (`h0n.java` lines 120-130, `C2299t3.java` line 803, `pu40.java`).
///
/// Dispatches rendering based on `metadata.headerType`:
/// 1. `editorial` -> `PlaylistEditorialHeader` (`image_header_content.xml`, `b7r.java`):
///    Full-bleed background artwork canvas, TitleLarge typography (32sp), official Spotify verified badge,
///    public saves counter + duration telemetry.
/// 2. `userOwned` / `followed` -> `PlaylistUserHeader` (`expanded_header.xml`, `u0n.java`):
///    Centered square artwork card with scale-down motion, TitleMedium typography (24sp), user avatar,
///    pure duration telemetry.
class PlaylistHeaderContent extends StatelessWidget {
  final PlaylistMetadata metadata;
  final int trackCount;
  final double scrollOffset;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onAddCollaboratorTapped;

  const PlaylistHeaderContent({
    super.key,
    required this.metadata,
    required this.trackCount,
    required this.scrollOffset,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onAddCollaboratorTapped,
  });

  @override
  Widget build(BuildContext context) {
    return switch (metadata.headerType) {
      PlaylistHeaderType.editorial => PlaylistEditorialHeader(
          metadata: metadata,
          trackCount: trackCount,
          scrollOffset: scrollOffset,
          searchController: searchController,
          searchFocusNode: searchFocusNode,
          onSearchChanged: onSearchChanged,
          onClearSearch: onClearSearch,
        ),
      PlaylistHeaderType.userOwned || PlaylistHeaderType.followed => PlaylistUserHeader(
          metadata: metadata,
          trackCount: trackCount,
          scrollOffset: scrollOffset,
          searchController: searchController,
          searchFocusNode: searchFocusNode,
          onSearchChanged: onSearchChanged,
          onClearSearch: onClearSearch,
          onAddCollaboratorTapped: onAddCollaboratorTapped,
        ),
    };
  }
}
