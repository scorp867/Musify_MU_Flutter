import 'package:flutter/material.dart';

import 'player_sheet_header.dart';
import 'player_theme.dart';

/// Track options modal sheet.
///
/// Citations:
/// - Decompiled Java: `com/spotify/music/nowplaying/` (Track options modal sheet)
/// - Decompiled Java: `p199p/es81.java` (Modal sheet navigation endpoints)
class PlayerOptionsSheet extends StatelessWidget {
  const PlayerOptionsSheet({
    super.key,
    required this.onShowDetails,
    required this.onShowQueue,
  });

  final VoidCallback onShowDetails;
  final VoidCallback onShowQueue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: PlayerSheetHeader(title: 'Track options'),
          ),
          ListTile(
            leading: const Icon(
              Icons.info_outline_rounded,
              color: PlayerColors.accent,
            ),
            title: const Text(
              'Track details',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              onShowDetails();
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.queue_music_rounded,
              color: PlayerColors.accent,
            ),
            title: const Text(
              'Open queue',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              onShowQueue();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
