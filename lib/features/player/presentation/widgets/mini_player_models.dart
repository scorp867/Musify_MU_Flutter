// Typed configuration models for Spotify's 1:1 `now_playing_bar` MiniPlayer
// (`res/layout/now_playing_bar.xml`, `res/xml/now_playing_bar_scene.xml`,
// `p/hjn0.java`, `p/zin0.java`, `p/ain0.java`, `p/thn0.java`, `p/ajn0.java`,
// `p/f9m0.java`, `p/vb4.java`).

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';

/// MotionLayout size state matching `res/xml/now_playing_bar_scene.xml` and
/// `p/zin0.java` (`b()`).
enum MiniPlayerSizeMode {
  /// Automatically uses `56dp` (`default_size`) or `68dp` (`scaled_font_height`)
  /// when `MediaQuery.textScalerOf(context).scale(1.0) >= 1.5`, and supports
  /// Spotify's interactive long-press + vertical drag resize (`56/68dp <-> 96dp`)
  /// when playing local video (`MiniPlayerVideoSlot`).
  automatic,

  /// Fixed `56dp` standard floating bar (`default_size`).
  defaultSize,

  /// Fixed `68dp` accessibility scaled-font bar (`scaled_font_height`).
  scaledFont,

  /// Fixed expanded `96dp` bar (`large_size`).
  largeSize,
}

/// Sealed left-side media slot in `now_playing_bar.xml` (`content_container`).
@immutable
sealed class MiniPlayerMediaSlot {
  const MiniPlayerMediaSlot();
}

/// Standard `40x40dp` square album artwork (`cover_image`, `ufl`).
@immutable
final class MiniPlayerArtworkSlot extends MiniPlayerMediaSlot {
  const MiniPlayerArtworkSlot();
}

/// `16:9` embedded video surface (`video_surface`, `vfl`) with `#000000`
/// background (`now_playing_bar_video_bg.xml`), `4dp -> 8dp` corner radius, and
/// interactive long-press + vertical drag resize eligibility (`f9m0.java:120`).
@immutable
final class MiniPlayerVideoSlot extends MiniPlayerMediaSlot {
  const MiniPlayerVideoSlot({
    required this.videoBuilder,
  });

  final WidgetBuilder videoBuilder;
}

/// Custom companion slot (`companion_content`, `tfl`).
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

/// Visual presentation & gesture modifiers matching `hjn0.java`, `vb4.java`,
/// `xs01.java`, and `now_playing_bar_outline.xml`.
@immutable
final class MiniPlayerVisualConfig extends Equatable {
  const MiniPlayerVisualConfig({
    this.sizeMode = MiniPlayerSizeMode.automatic,
    this.bottomSheetMode = false,
    this.showOutlineHalo = false,
    this.outlineHaloColor = ConnectEncoreTheme.tintedBase,
    this.showAddToButton = true,
    this.enableMarquee = true,
    this.enableResizeGesture = true,
    this.initialIsLarge = false,
    this.removeDefaultVideoPadding = false,
    this.removeLargeVideoPadding = false,
  });

  final MiniPlayerSizeMode sizeMode;

  /// When `true` (`hjn0` bottom-sheet mode `z`), removes horizontal outer
  /// margins and disables interactive resize (`hjn0.java:286`).
  final bool bottomSheetMode;

  /// Forces Spotify's `now_playing_bar_outline.xml` (`4dp` stroke,
  /// `10dp -> 18dp` radius, `-4dp` outset, `?attr/backgroundTintedBase` `#1AFFFFFF`)
  /// visible even when not actively resizing. During an active long-press resize
  /// gesture, the halo is shown automatically (`hjn0.g(true)`).
  final bool showOutlineHalo;

  final Color outlineHaloColor;
  final bool showAddToButton;
  final bool enableMarquee;

  /// Matches Spotify's `enable_resize_gesture` (`vb4.c()`, `xs01.a`).
  /// Enables long-press + haptic + vertical drag resize when playing local video.
  final bool enableResizeGesture;

  /// Initial persisted large-size preference for video playback
  /// (`qin0Var.d` / `larger_npb_video_on_by_default`).
  final bool initialIsLarge;

  /// Matches `default_size_remove_video_padding` (`vb4.b()`).
  final bool removeDefaultVideoPadding;

  /// Matches `large_size_remove_video_padding` (`vb4.e()`).
  final bool removeLargeVideoPadding;

  @override
  List<Object?> get props => [
        sizeMode,
        bottomSheetMode,
        showOutlineHalo,
        outlineHaloColor,
        showAddToButton,
        enableMarquee,
        enableResizeGesture,
        initialIsLarge,
        removeDefaultVideoPadding,
        removeLargeVideoPadding,
      ];
}
