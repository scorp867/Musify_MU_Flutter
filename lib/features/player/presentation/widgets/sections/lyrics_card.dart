import 'package:flutter/material.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/protocol/generated/spotify/lyrics/color_lyrics.pb.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits/visual_identity_trait.dart';

import 'lyrics_color_parser.dart';

/// Spotify-identical Lyrics preview card (`ScrollCardType.LYRICS`).
///
/// 1:1 replica of official Spotify Android layout (`lyricscard_spotify.jpeg`
/// and decompiled `p/io80.java`, `p/rm2.java`, `p/aw80.java`).
///
/// Palette hierarchy (exact replica of `p/aw80.java`):
/// 1. First-party [VisualIdentityTrait] (`higherContrast` -> `backgroundBase` + `backgroundTintedBase`)
///    extracted from album artwork via Kodiak DataPool.
/// 2. Third-party [ColorLyricsResponse] (`colors.background`) from Musixmatch.
/// 3. Offline constants from Spotify Encore (`p/mzs.java:5-9` -> `#353535` / `#565656`).
class PlayerLyricsSection extends StatelessWidget {
  const PlayerLyricsSection({
    super.key,
    this.onTapHeader,
    this.backgroundColor,
    this.lyricsLines,
    this.activeLineIndex = 0,
    this.colorLyrics,
    this.dataPool,
    this.trackUri,
  });

  final VoidCallback? onTapHeader;
  final Color? backgroundColor;
  final List<String>? lyricsLines;
  final int activeLineIndex;
  final ColorLyricsResponse? colorLyrics;
  final DataPool? dataPool;
  final String? trackUri;

  String? get _normalizedTrackUri {
    if (trackUri == null || trackUri!.isEmpty) return null;
    if (!trackUri!.startsWith('spotify:')) {
      return 'spotify:track:$trackUri';
    }
    return trackUri;
  }

  @override
  Widget build(BuildContext context) {
    final uri = _normalizedTrackUri;

    if (dataPool != null && uri != null) {
      return StreamBuilder<Map<String, dynamic>>(
        stream: dataPool!.watchEntity(uri),
        initialData: dataPool!.getTraits(uri),
        builder: (context, snapshot) {
          final visual = dataPool!.getTrait<VisualIdentityTrait>(uri);
          return _buildCard(visual);
        },
      );
    }

    return _buildCard(null);
  }

  Widget _buildCard(VisualIdentityTrait? visual) {
    // 1. Resolve colors matching Spotify Android `p/rm2.java:121-145`
    final palette = visual?.preferredCardPalette;

    final Color startBg;
    final Color endBg;
    final Color highlightColor;
    final Color inactiveColor;

    if (palette != null) {
      // 1:1 replica of Spotify Encore higherContrast palette
      startBg = palette.backgroundBaseColor;
      endBg = palette.backgroundTintedBaseColor;
      highlightColor = palette.textBaseColor;
      inactiveColor = palette.textSubduedColor;
    } else if (colorLyrics != null && colorLyrics!.hasColors()) {
      // Third-party Musixmatch fallback
      final bg = parseProtoColor(colorLyrics!.colors.background);
      startBg = bg;
      endBg = Color.lerp(bg, Colors.black, 0.15) ?? bg;
      highlightColor = parseProtoColor(
        colorLyrics!.colors.highlightText,
        defaultColor: Colors.white,
      );
      inactiveColor = parseProtoColor(
        colorLyrics!.colors.text,
        defaultColor: Colors.white60,
      );
    } else {
      // Offline fallback: Spotify Encore default constants from `p/mzs.java:5-9`
      startBg = backgroundColor ?? const Color(0xFF353535);
      endBg = const Color(0xFF565656);
      highlightColor = Colors.white;
      inactiveColor = const Color(0xFFCDCDCD);
    }

    final lines = colorLyrics != null && colorLyrics!.hasLyrics()
        ? colorLyrics!.lyrics.lines
            .map((l) => l.words)
            .where((w) => w.isNotEmpty)
            .toList()
        : lyricsLines;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTapHeader,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // Top-to-bottom vertical gradient between backgroundBase and backgroundTintedBase
            // 1:1 replica of Spotify `p/io80.java:120` (s460 LinearGradient from (0,0) to (0,height))
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [startBg, endBg],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: "Lyrics preview"
              const Text(
                'Lyrics preview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 16),
              // Body: 5-line preview or unavailable message
              if (lines != null && lines.isNotEmpty) ...[
                ..._buildLyricsPreview(lines, highlightColor, inactiveColor),
                const SizedBox(height: 16),
                // "Show lyrics" action button
                FilledButton(
                  onPressed: onTapHeader,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Show lyrics',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ] else
                _buildUnavailableMessage(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLyricsPreview(
    List<String> lines,
    Color highlightColor,
    Color inactiveColor,
  ) {
    // Spotify shows 5 lines in the preview card
    final previewLines = lines.take(5).toList();

    return [
      for (int i = 0; i < previewLines.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            previewLines[i],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: i < 2 ? highlightColor : inactiveColor,
              fontSize: 18,
              fontWeight: i < 2 ? FontWeight.w800 : FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
    ];
  }

  Widget _buildUnavailableMessage() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Lyrics aren't available for this track yet.",
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Enjoy the music and check back later for lyrics.',
          style: TextStyle(
            color: Color(0xFFB3B3B3),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
