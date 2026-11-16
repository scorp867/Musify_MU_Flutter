import 'package:flutter/material.dart';
import 'package:musify_mu/core/ui/formatters/duration_formatter.dart';

import 'player_sheet_detail_row.dart';
import 'player_sheet_header.dart';

/// Track metadata details sheet.
///
/// Citations:
/// - Decompiled Java: `com/spotify/music/nowplaying/` (Track details metadata sheet)
/// - Decompiled Java: `p199p/ac0.java` (Track metadata display)
class PlayerTrackDetailsSheet extends StatelessWidget {
  const PlayerTrackDetailsSheet({
    super.key,
    this.title = 'Starboy',
    this.artist = 'The Weeknd, Daft Punk',
    this.album = 'Starboy',
    this.duration = const Duration(minutes: 3, seconds: 50),
  });

  final String title;
  final String artist;
  final String album;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PlayerSheetHeader(title: 'Track details'),
            const SizedBox(height: 18),
            PlayerSheetDetailRow(label: 'Title', value: title),
            PlayerSheetDetailRow(
              label: 'Artist',
              value: artist.isNotEmpty ? artist : 'Unknown Artist',
            ),
            PlayerSheetDetailRow(
              label: 'Album',
              value: album.isNotEmpty ? album : 'Unknown Album',
            ),
            if (duration case final trackDuration?)
              PlayerSheetDetailRow(
                label: 'Duration',
                value: DurationFormatter.duration(trackDuration),
              ),
          ],
        ),
      ),
    );
  }
}
