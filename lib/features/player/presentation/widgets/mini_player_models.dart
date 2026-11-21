// Typed configuration models for Spotify's 1:1 `now_playing_bar` MiniPlayer
// (`res/layout/now_playing_bar.xml`, `res/xml/now_playing_bar_scene.xml`,
// `p199p/hjn0.java`, `p199p/zin0.java`, `p199p/ajn0.java`).

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';

/// MotionLayout size state matching `res/xml/now_playing_bar_scene.xml` and
/// `p199p/zin0.java` (`m97542b`).
enum MiniPlayerSizeMode {
  /// Automatically uses `56dp` (`default_size`) or `68dp` (`scaled_font_height`)
  /// when `MediaQuery.textScalerOf(context).scale(1.0) >= 1.5`.
  automatic,

  /// Explicit `56dp` standard floating bar (`default_size`).
  defaultSize,

  /// Explicit `68dp` accessibility scaled-font bar (`scaled_font_height`).
  scaledFont,

  /// Expanded `96dp` bar (`large_size`, e.g., video/promo preview transition).
  largeSize,
}

/// Sealed left-side media slot in `now_playing_bar.xml` (`content_container`).
@immutable
sealed class MiniPlayerMediaSlot {
  const MiniPlayerMediaSlot();
}

/// Standard `40x40dp` square album artwork (`cover_image`).
@immutable
final class MiniPlayerArtworkSlot extends MiniPlayerMediaSlot {
  const MiniPlayerArtworkSlot();
}

/// `16:9` embedded video surface (`video_surface` with `#000000` background and
/// animated `4dp -> 8dp` corner radius).
@immutable
final class MiniPlayerVideoSlot extends MiniPlayerMediaSlot {
  const MiniPlayerVideoSlot({
    required this.videoBuilder,
  });

  final WidgetBuilder videoBuilder;
}

/// Custom companion slot (`companion_content`).
@immutable
final class MiniPlayerCompanionSlot extends MiniPlayerMediaSlot {
  const MiniPlayerCompanionSlot({
    required this.companionBuilder,
  });

  final WidgetBuilder companionBuilder;
}

/// Conditional subtitle & track metadata badges from
/// `res/layout/now_playing_bar_track_info_view.xml` & `device_name_label.xml`.
@immutable
final class MiniPlayerTrackBadges extends Equatable {
  const MiniPlayerTrackBadges({
    this.isQueued = false,
    this.isEnhanced = false,
    this.playbackSpeedLabel,
    this.listenAlongLabel,
  });

  /// `QueuedBadgeView` (`12dp` `encore_icon_queue_badge_16`).
  final bool isQueued;

  /// `EnhancedBadgeView` (`12dp` `encore_icon_enhance_badge_16`).
  final bool isEnhanced;

  /// Optional `SpeedBadgeIconView` text (e.g. `"1.5x"`).
  final String? playbackSpeedLabel;

  /// Optional Jam / Listen-Along badge (`connect_listen_along_badge`).
  final String? listenAlongLabel;

  bool get hasAny {
    if (isQueued || isEnhanced) {
      return true;
    }
    if (playbackSpeedLabel case final speed? when speed.trim().isNotEmpty) {
      return true;
    }
    if (listenAlongLabel case final listen? when listen.trim().isNotEmpty) {
      return true;
    }
    return false;
  }

  @override
  List<Object?> get props => [
        isQueued,
        isEnhanced,
        playbackSpeedLabel,
        listenAlongLabel,
      ];
}

/// Conditional skippable ad slot (`skippable_ad_view_stub` in `now_playing_bar.xml`).
@immutable
final class MiniPlayerAdConfig {
  const MiniPlayerAdConfig({
    required this.canSkip,
    required this.onSkip,
    this.countdownSeconds,
  });

  final bool canSkip;
  final VoidCallback onSkip;
  final int? countdownSeconds;
}

/// Conditional promotional disclosure row (`promo_indicator_row` in `device_name_label.xml`).
@immutable
final class MiniPlayerPromoConfig extends Equatable {
  const MiniPlayerPromoConfig({
    this.label = 'Includes promotional content',
  });

  final String label;

  @override
  List<Object?> get props => [label];
}

/// Visual presentation modifiers matching `hjn0.java` and `now_playing_bar_outline.xml`.
@immutable
final class MiniPlayerVisualConfig extends Equatable {
  const MiniPlayerVisualConfig({
    this.sizeMode = MiniPlayerSizeMode.automatic,
    this.bottomSheetMode = false,
    this.showOutlineHalo = false,
    this.outlineHaloColor = ConnectEncoreTheme.brightAccent,
    this.showAddToButton = true,
    this.enableMarquee = true,
  });

  final MiniPlayerSizeMode sizeMode;

  /// When `true` (`hjn0` bottom-sheet mode `z`), removes horizontal outer margins.
  final bool bottomSheetMode;

  /// Renders Spotify's `now_playing_bar_outline.xml` (`4dp` stroke, `10dp` radius,
  /// `-4dp` outset) smoothly animated (`alpha 0 -> 1`).
  final bool showOutlineHalo;

  final Color outlineHaloColor;
  final bool showAddToButton;
  final bool enableMarquee;

  @override
  List<Object?> get props => [
        sizeMode,
        bottomSheetMode,
        showOutlineHalo,
        outlineHaloColor,
        showAddToButton,
        enableMarquee,
      ];
}
