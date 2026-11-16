import 'package:flutter/material.dart';

import 'player_header.dart';

/// Modal bottom sheet grab-handle and title header.
///
/// Citations:
/// - Decompiled Java: `com/spotify/music/nowplaying/` (Modal bottom sheet grab-bar and header)
/// - Decompiled Java: `p199p/ac0.java`
class PlayerSheetHeader extends StatelessWidget {
  const PlayerSheetHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            PlayerCircleButton(
              icon: Icons.close_rounded,
              tooltip: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ],
    );
  }
}
