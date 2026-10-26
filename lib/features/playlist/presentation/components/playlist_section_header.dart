library;

import 'package:flutter/material.dart';
import '../../domain/models/playlist_item.dart';

/// 1:1 replica of Spotify's section header in sectioned playlists (`dg80.java`).
/// Displays section title ("You added", "Includes", "We added") above tracks.
class PlaylistSectionHeader extends StatelessWidget {
  final PlaylistSectionType sectionType;
  final int count;

  const PlaylistSectionHeader({
    super.key,
    required this.sectionType,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (sectionType) {
      PlaylistSectionType.youAdded => 'You added',
      PlaylistSectionType.includes => 'Includes',
      PlaylistSectionType.weAdded => 'We added',
      PlaylistSectionType.standard => '',
    };

    if (title.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($count)',
            style: const TextStyle(
              color: Color(0xFFB3B3B3),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
