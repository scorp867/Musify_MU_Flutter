// 1:1 Spotify Encore dark theme tokens for Connect & MiniPlayer (`now_playing_bar`).
//
// Verified against Spotify 9.1.92.3058 (`versionCode=147346334`) bytecode and live
// Pixel_4_XL emulator capture (`emulator_now.png`):
// - Gray & surface scale: `p199p/ogw.java`, `p199p/diw.java` (`f50714e`), `p199p/zfw.java` (`f297876t`)
// - Alpha overlays: `p199p/lgw.java`
// - Brand accent (`spotify_green_157` / `textBrightAccent`): `p199p/tcw.java` (`#FF1ED760`)
// - Typography scale: `p199p/oww.java` (`f178576a`), `p199p/m0x.java`, `p199p/eel1.java` (`m41044k`)
// - MiniPlayer resize tokens: `p/zin0.java`, `p/hjn0.java`, `p/ain0.java`, `p/f9m0.java`,
//   `res/xml/now_playing_bar_scene.xml`, `res/drawable/now_playing_bar_outline.xml`

import 'package:flutter/material.dart';

/// Canonical Spotify Connect bright accent green (`spotify_green_157`).
const Color kSpotifyConnectGreen = Color(0xFF1ED760);

/// Light green tint token paired with [kSpotifyConnectGreen].
const Color kSpotifyConnectGreenTint = Color(0xFF96F0B6);

/// Centralized Spotify Encore dark color, typography, spacing, and shape tokens
/// used across the MiniPlayer, Connect state icons, and Device Picker Sheet.
@immutable
abstract final class ConnectEncoreTheme {
  // ===========================================================================
  // Surfaces & Backgrounds (ogw.java, diw.f50714e, live Pixel_4_XL capture)
  // ===========================================================================

  /// Device Picker bottom sheet surface (`#1F1F1F`).
  static const Color sheetBackground = Color(0xFF1F1F1F);

  /// Elevated dark surface for Active Device Card & bottom footer cards (`#2A2A2A`).
  static const Color elevatedSurface = Color(0xFF2A2A2A);

  /// Default base background of floating `now_playing_bar` (`#282828`).
  static const Color miniPlayerDefaultBackground = Color(0xFF282828);

  /// Deep dark canvas fallback (`#121212`).
  static const Color canvasBackground = Color(0xFF121212);

  /// Modal backdrop scrim (`70%` black).
  static const Color scrimBarrier = Color(0xB3000000);

  /// Bottom sheet top drag handle pill (`#535353`).
  static const Color dragHandle = Color(0xFF535353);

  /// Video surface backing color (`#000000`, `now_playing_bar_video_bg.xml`).
  static const Color videoSurfaceBackground = Color(0xFF000000);

  // ===========================================================================
  // Tints, Overlays & Dividers (lgw.java, colors.xml)
  // ===========================================================================

  /// `backgroundTintedBase` / `dark_base_background_tinted_base` (`#1AFFFFFF`).
  /// Used for volume slider inactive track, sheet dividers, highlight circles,
  /// quality pill background, MiniPlayer progress bar background, and
  /// `now_playing_bar_outline.xml` resize halo stroke.
  static const Color tintedBase = Color(0x1AFFFFFF);

  /// `opacity_white_15` (`15%` white) for subtle pressed/hover states.
  static const Color tintedPress = Color(0x26FFFFFF);

  /// `opacity_white_30` (`30%` white).
  static const Color white30 = Color(0x4DFFFFFF);

  /// `opacity_white_50` (`50%` white).
  static const Color white50 = Color(0x80FFFFFF);

  /// `opacity_white_70` (`70%` white) for `TextAppearance.NowPlayingBar.SingleLineSubtitle`.
  static const Color miniPlayerSubtitle = Color(0xB3FFFFFF);

  // ===========================================================================
  // Foreground / Text / Accents (ogw.java, tcw.java)
  // ===========================================================================

  /// Primary foreground / `textBase` (`#FFFFFF`).
  static const Color textBase = Color(0xFFFFFFFF);

  /// Secondary foreground / `textSubdued` (`#B3B3B3`).
  static const Color textSubdued = Color(0xFFB3B3B3);

  /// Disabled foreground (`#B3B3B3` at `50%` alpha, `na7.java` `t7k`).
  static const Color iconDisabled = Color(0x80B3B3B3);

  /// `textBrightAccent` / `essentialBrightAccent` (`#1ED760`).
  static const Color brightAccent = kSpotifyConnectGreen;

  /// Soft bright accent tint (`#96F0B6`).
  static const Color brightAccentTint = kSpotifyConnectGreenTint;

  /// Negative/error surface and foreground accents.
  static const Color negativeSurface = Color(0xFF3A1A1A);
  static const Color negativeBorder = Color(0xA6EF4444);
  static const Color negativeAccent = Color(0xFFFCA5A5);

  // ===========================================================================
  // Encore Typography Scale (oww.f178576a -> m0x in eel1.m41044k)
  // ===========================================================================

  /// `f145232d`: `24sp Bold` — Active device card title (`"This phone"`).
  static const TextStyle title24Bold = TextStyle(
    color: textBase,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.4,
  );

  /// `f145233e`: `20sp Bold` — Device Picker sheet header (`"Connect"`).
  static const TextStyle header20Bold = TextStyle(
    color: textBase,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.2,
  );

  /// `f145236h`: `16sp Bold` — Section header / context menu title.
  static const TextStyle section16Bold = TextStyle(
    color: textBase,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  /// `f145235g`: `16sp Regular` — Device list row display name.
  static const TextStyle deviceRow16Regular = TextStyle(
    color: textBase,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.25,
  );

  /// `f145238j`: `13sp Regular` — Active card peripheral subtitle, now playing
  /// green marquee row, empty state text, and MiniPlayer subtitle.
  static const TextStyle bodySmall13Regular = TextStyle(
    color: textSubdued,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.25,
  );

  /// `f145239k`: `13sp Bold` — MiniPlayer track title, `"On other networks"`
  /// header, and volume slider floating drag percentage.
  static const TextStyle bodySmall13Bold = TextStyle(
    color: textBase,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  /// `f145241m`: `11sp Regular` — MiniPlayer `connect_label`, device row
  /// subtitles, `"•"` separator, promo indicator, and footer button labels.
  static const TextStyle caption11Regular = TextStyle(
    color: textSubdued,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.2,
  );

  /// `f145242n`: `11sp Bold` — Streaming quality pill badge (`"Normal"`, `"Very high"`, `"Lossless"`).
  static const TextStyle caption11Bold = TextStyle(
    color: textBase,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  // ===========================================================================
  // Layout Constants (now_playing_bar.xml, now_playing_bar_scene.xml, zin0, lxs)
  // ===========================================================================

  /// Default floating MiniPlayer bar height (`floating_now_playing_bar_height`).
  static const double miniPlayerDefaultHeight = 56.0;

  /// Scaled-font MiniPlayer height when `fontScale >= 1.5` (`floating_now_playing_bar_scaled_font_height`).
  static const double miniPlayerScaledFontHeight = 68.0;

  /// Large MotionLayout MiniPlayer height (`now_playing_bar_large_height`).
  static const double miniPlayerLargeHeight = 96.0;

  /// Font scale threshold triggering [miniPlayerScaledFontHeight] (`zin0.b`).
  static const double miniPlayerScaledFontThreshold = 1.5;

  /// Max font scale permitting 2-line metadata in resized video bar (`f9m0.java:131`).
  static const double miniPlayerLargeMetadataMaxFontScale = 1.8;

  /// Floating MiniPlayer corner radius in `default_size` (`encore_corner_radius_larger_2`).
  static const double miniPlayerDefaultRadius = 8.0;

  /// Floating MiniPlayer corner radius in `large_size` (`encore_corner_radius_larger_3`, `zin0.java:44`).
  static const double miniPlayerLargeRadius = 16.0;

  /// MiniPlayer artwork / video corner radius in `default_size` (`encore_corner_radius_base`).
  static const double miniPlayerArtworkDefaultRadius = 4.0;

  /// MiniPlayer video corner radius in `large_size` (`encore_corner_radius_larger_2`, `zin0.java:46`).
  static const double miniPlayerArtworkLargeRadius = 8.0;

  /// MiniPlayer outline halo stroke width (`encore_border_width_thick` / `floating_now_playing_bar_outline_width`).
  static const double miniPlayerOutlineStrokeWidth = 4.0;

  /// MiniPlayer outline halo corner radius in `default_size` (`(4dp / 2) + 8dp = 10dp`).
  static const double miniPlayerOutlineRadius = 10.0;

  /// MiniPlayer outline halo corner radius in `large_size` (`(4dp / 2) + 16dp = 18dp`, `zin0.java:89`).
  static const double miniPlayerOutlineLargeRadius = 18.0;

  /// MiniPlayer default content padding (`floating_now_playing_bar_content_padding`).
  static const double miniPlayerContentPadding = 8.0;

  /// MiniPlayer large content padding for progress bar inset (`floating_now_playing_bar_large_content_padding`).
  static const double miniPlayerLargeContentPadding = 16.0;

  /// MiniPlayer carousel horizontal margin (`now_playing_bar_carousel_margin`).
  static const double miniPlayerCarouselMargin = 12.0;

  /// MiniPlayer action slot size (`now_playing_bar_actions_button_size`).
  static const double miniPlayerActionButtonSize = 40.0;

  /// MiniPlayer action spacing & bottom/end margin in `large_size` (`now_playing_bar_large_button_spacing`).
  static const double miniPlayerLargeButtonSpacing = 4.0;

  /// MiniPlayer `device_name_label` bottom margin aligned to `play_pause_button` in `large_size`
  /// (`now_playing_bar_large_connect_label_bottom_margin`).
  static const double miniPlayerLargeConnectLabelBottomMargin = 12.0;

  /// MiniPlayer progress bar height (`now_playing_bar.xml`).
  static const double miniPlayerProgressHeight = 2.0;

  /// Resize progress threshold that toggles 1-line/2-line metadata (`ain0.java:100`, `x55.java:41`).
  static const double miniPlayerResizeMetadataThreshold = 0.75;

  /// Resize progress threshold deciding final snap target on release (`ain0.java:116`).
  static const double miniPlayerResizeSnapThreshold = 0.5;

  /// MiniPlayer MotionLayout transition duration (`now_playing_bar_scene.xml`, `hjn0.h`).
  static const Duration miniPlayerMotionDuration = Duration(milliseconds: 100);

  /// MiniPlayer outline halo alpha fade duration (`hjn0.g`).
  static const Duration miniPlayerOutlineFadeDuration =
      Duration(milliseconds: 150);

  /// MiniPlayer background artwork color crossfade duration (`dkg.java`).
  static const Duration miniPlayerColorTransitionDuration =
      Duration(milliseconds: 300);

  /// Device Picker sheet initial height fraction (`lxs.java`).
  static const double devicePickerInitialHeightFraction = 0.70;

  /// Viewport height threshold below which Device Picker expands fully (`lxs.java`).
  static const double devicePickerCompactViewportThreshold = 600.0;

  /// Device Picker top sheet corner radius (`16dp`).
  static const double devicePickerSheetCornerRadius = 16.0;

  /// Active Device Card corner radius (`16dp`, `frl1.java`).
  static const double activeCardCornerRadius = 16.0;

  /// Footer action card corner radius (`4dp`, `ksi.java:2536`).
  static const double footerCardCornerRadius = 4.0;

  /// Device list row minimum height (`56dp`, `btl1.java`).
  static const double deviceRowMinHeight = 56.0;
}
