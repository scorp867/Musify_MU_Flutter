import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_artwork.dart';

void main() {
  testWidgets('compact placeholder matches the mini-player artwork slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: PlayerArtworkImage(
            item: MediaItem(id: 'online-track', title: 'Track'),
            artworkWidth: 40,
            artworkHeight: 40,
            placeholderIconSize: 20,
          ),
        ),
      ),
    );

    final artworkSize = tester.getSize(find.byType(PlayerArtworkPlaceholder));

    expect(artworkSize, const Size(40, 40));
    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
  });
}
