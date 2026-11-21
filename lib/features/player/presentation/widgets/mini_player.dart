// 1:1 replica of Spotify 9.1.92.3058 MiniPlayer (`now_playing_bar`)
//
// Verified against:
// - `res/layout/now_playing_bar.xml`
// - `res/layout/now_playing_bar_track_info_view.xml`
// - `res/layout/device_name_label.xml`
// - `res/xml/now_playing_bar_scene.xml`
// - `res/drawable/now_playing_bar_outline.xml`
// - `res/drawable/cat_progress.xml`
// - `p199p/hjn0.java`, `p199p/zin0.java`, `p199p/ajn0.java`, `p199p/ba7.java`

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/core/ubi/data/lifecycle/page_instance_id_holder.dart';
import 'package:musify_mu/core/ubi/domain/logging/ubi_logger.dart';
import 'package:musify_mu/core/ubi/domain/models/page_instance_id.dart';
import 'package:musify_mu/features/connect/application/mobius/connect_mobius_controller.dart';
import 'package:musify_mu/features/connect/domain/services/connect_output_status_policy.dart';
import 'package:musify_mu/features/connect/presentation/icons/connect_encore_icons.dart';
import 'package:musify_mu/features/connect/presentation/screens/device_picker_sheet.dart';
import 'package:musify_mu/features/connect/presentation/theme/connect_encore_theme.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_device_label.dart';
import 'package:musify_mu/features/connect/presentation/widgets/connect_state_icon.dart';
import 'package:musify_mu/features/connect/presentation/widgets/spotify_marquee_text.dart';
import 'package:musify_mu/features/player/application/queue/player_queue_bloc.dart';
import 'package:musify_mu/features/player/data/logging/player_logging_params_factory.dart';
import 'package:musify_mu/features/player/data/queue/context_track_extensions.dart';
import 'package:musify_mu/features/player/domain/commands/options/logging_params.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/playback_quality.dart';
import 'package:musify_mu/features/player/presentation/screens/player_screen.dart';
import 'package:musify_mu/features/player/presentation/widgets/mini_player_models.dart';
import 'package:musify_mu/features/player/presentation/widgets/player_artwork.dart';

export 'package:musify_mu/features/player/presentation/widgets/mini_player_models.dart';

/// Byte-exact 1:1 Spotify `now_playing_bar` MiniPlayer.
///
/// Key structural invariants matched directly to Spotify 9.1.92.3058:
/// - Floating bar height: `56dp` (`default_size`), `68dp` (`scaled_font_height`
///   when `fontScale >= 1.5`), or `96dp` (`large_size`) with `100ms` MotionLayout
///   geometry animation.
/// - Corner radius: `8dp` (`default_size`) <-> `12dp` (`large_size`); outer
///   horizontal margin `8dp` (`16dp` on `>= 600dp` wide screens, `0dp` in
///   bottom-sheet mode); optional `4dp` / `10dp`-radius outline halo.
/// - Base color `#FF282828` animating smoothly (`300ms`) to extracted artwork
///   dark surface color.
/// - Left media container: `40x40dp` artwork (`4dp` radius, `8dp` margin) OR
///   `16:9` video surface (`4dp -> 8dp` radius) OR companion slot.
/// - Center track info carousel (`12dp` H margin):
///   - Local built-in playback (2-line mode): Line 1 = `Title` (`13sp Bold #FFFFFF`),
///     Line 2 = optional queued/enhanced/speed/listen-along badges + `Artist`
///     (`13sp Regular #B3FFFFFF`) or promo disclosure.
///   - Active Connect / external peripheral / transferring (1-line mode):
///     Line 1 = `"Title • Artist"` (`Title` bold `#FFFFFF`, inline badges,
///     `Artist` `#B3FFFFFF`), Line 2 = `ConnectDeviceLabel` (`11sp Regular`
///     `#1ED760` + `12dp` badge icon, or `#FFFFFF` `"Connecting..."`).
/// - Right `40x40dp` action buttons (`8dp` padding -> `24dp` Encore vector icon;
///   `play_pause_button` has `8dp` trailing margin):
///   1. `connect_destination_button` ([ConnectStateIcon])
///   2. Conditional `skippable_ad_view_stub`
///   3. `add_to_button` (Encore `plusAlt24` / `#1ED760` `checkAltFill24`)
///   4. `play_pause_button` (Encore `play24` / `pause24`)
/// - Bottom `2dp` progress bar inset `8dp` start/end (`16dp` in `large_size`),
///   `1dp` corner radius, `#1AFFFFFF` track, `#FFFFFFFF` fill (`cat_progress.xml`).
class MiniPlayer extends StatefulWidget {
  const MiniPlayer({
    super.key,
    this.title = '',
    this.artist = '',
    this.imageUrl,
    this.isPlaying = false,
    this.progress = 0.0,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onTap,
    this.isSaved,
    this.onToggleSave,
    this.colorService,
    this.queueBloc,
    this.currentTrack,
    this.connectController,
    this.outputStatusPolicy,
    this.playbackQuality,
    this.ubiLogger,
    this.loggingParamsFactory,
    this.pageInstanceIdHolder,
    this.mediaSlot = const MiniPlayerArtworkSlot(),
    this.badges = const MiniPlayerTrackBadges(),
    this.adConfig,
    this.promoConfig,
    this.visualConfig = const MiniPlayerVisualConfig(),
  });

  final String title;
  final String artist;
  final String? imageUrl;
  final bool isPlaying;
  final double progress;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onTap;
  final bool? isSaved;
  final VoidCallback? onToggleSave;
  final ColorExtractionService? colorService;
  final PlayerQueueMobiusController? queueBloc;
  final ContextTrack? currentTrack;
  final ConnectMobiusController? connectController;
  final ConnectOutputStatusPolicy? outputStatusPolicy;
  final PlaybackQuality? playbackQuality;
  final UbiLogger? ubiLogger;
  final PlayerLoggingParamsFactory? loggingParamsFactory;
  final PageInstanceIdHolder? pageInstanceIdHolder;
  final MiniPlayerMediaSlot mediaSlot;
  final MiniPlayerTrackBadges badges;
  final MiniPlayerAdConfig? adConfig;
  final MiniPlayerPromoConfig? promoConfig;
  final MiniPlayerVisualConfig visualConfig;

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  static void _noop() {}

  Color _currentColor = ConnectEncoreTheme.miniPlayerDefaultBackground;
  bool _localSaved = false;
  bool _isPlaying = false;
  String? _lastExtractedKey;
  PageInstanceId _pageInstanceId = PageInstanceIdHolder.generateNew();
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);
  Ticker? _progressTicker;

  // Carousel drag offset in logical pixels for tactile horizontal track swipe.
  double _dragOffsetDx = 0.0;
  int _carouselDirection = 0;

  UbiLogger? _resolveUbiLogger() {
    if (widget.ubiLogger case final explicit?) {
      return explicit;
    }
    return context.read<UbiLogger?>();
  }

  PlayerLoggingParamsFactory? _resolveLoggingParamsFactory() {
    if (widget.loggingParamsFactory case final explicit?) {
      return explicit;
    }
    return context.read<PlayerLoggingParamsFactory?>();
  }

  PageInstanceIdHolder? _resolvePageInstanceIdHolder() {
    if (widget.pageInstanceIdHolder case final explicit?) {
      return explicit;
    }
    return context.read<PageInstanceIdHolder?>();
  }

  ColorExtractionService? _resolveColorService() {
    if (widget.colorService case final explicit?) {
      return explicit;
    }
    return context.read<ColorExtractionService?>();
  }

  ConnectMobiusController? _resolveConnectController() {
    if (widget.connectController case final explicit?) {
      return explicit;
    }
    return context.read<ConnectMobiusController?>();
  }

  ConnectOutputStatusPolicy _resolveOutputStatusPolicy() {
    if (widget.outputStatusPolicy case final explicit?) {
      return explicit;
    }
    if (context.read<ConnectOutputStatusPolicy?>() case final provided?) {
      return provided;
    }
    return ConnectOutputStatusPolicy.instance;
  }

  LoggingParams? _logMiniPlayerInteraction(
    String elementPath, [
    String actionName = 'hit',
  ]) {
    if (_resolveUbiLogger() case final ubiLogger?) {
      final result = ubiLogger.logInteraction(
        UbiInteractionElement(
          elementPath: elementPath,
          actionName: actionName,
        ),
      );
      if (_resolveLoggingParamsFactory() case final factory?) {
        return factory.createFromInteractionResult(result);
      }
    }
    return null;
  }

  PageInstanceId get pageInstanceId => _pageInstanceId;

  @override
  void initState() {
    super.initState();
    _pageInstanceId = PageInstanceIdHolder.generateNew();
    if (_resolvePageInstanceIdHolder() case final holder?) {
      holder.update(_pageInstanceId);
    }

    if (_resolveUbiLogger() case final ubiLogger?) {
      ubiLogger.logImpression(
        const UbiImpressionElement(elementPath: 'mini_player'),
      );
    }

    _isPlaying = switch (widget.queueBloc?.state.isPlaying) {
      final playing? => playing,
      null => widget.isPlaying,
    };

    final initialImageUrl = _resolveImageUrl(widget.queueBloc?.state);
    _extractColor(imageUrl: initialImageUrl, allowSetState: false);

    final initialProgress = _boundProgress(
      switch (widget.queueBloc?.state.playbackProgress) {
        final p? => p,
        null => widget.progress,
      },
    );
    _progressNotifier.value = initialProgress;

    final ticker = createTicker((_) {
      if (!mounted) {
        return;
      }
      final bloc = widget.queueBloc;
      if (bloc != null) {
        final state = bloc.state;
        if (state.isPlaying) {
          final currentProgress = _boundProgress(state.playbackProgress);
          if ((currentProgress - _progressNotifier.value).abs() >= 0.0005) {
            _progressNotifier.value = currentProgress;
          }
        }
      }
    });
    _progressTicker = ticker;

    if (_isPlaying) {
      ticker.start();
    }

    widget.queueBloc?.addListener(_onQueueStateChanged);
  }

  @override
  void dispose() {
    if (_progressTicker case final ticker?) {
      ticker.dispose();
      _progressTicker = null;
    }
    _progressNotifier.dispose();
    widget.queueBloc?.removeListener(_onQueueStateChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queueBloc != widget.queueBloc) {
      oldWidget.queueBloc?.removeListener(_onQueueStateChanged);
      widget.queueBloc?.addListener(_onQueueStateChanged);
    }
    if (oldWidget.isPlaying != widget.isPlaying && widget.queueBloc == null) {
      _isPlaying = widget.isPlaying;
      _syncProgressTicker();
    }
    if (oldWidget.progress != widget.progress && widget.queueBloc == null) {
      _progressNotifier.value = _boundProgress(widget.progress);
    }
    if (oldWidget.queueBloc != widget.queueBloc ||
        oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.currentTrack != widget.currentTrack) {
      final updatedImageUrl = _resolveImageUrl(widget.queueBloc?.state);
      _extractColor(imageUrl: updatedImageUrl, allowSetState: false);
    }
  }

  void _syncProgressTicker() {
    final ticker = _progressTicker;
    if (ticker == null) {
      return;
    }
    if (_isPlaying) {
      if (!ticker.isActive) {
        ticker.start();
      }
    } else {
      if (ticker.isActive) {
        ticker.stop();
      }
    }
  }

  void _onQueueStateChanged() {
    if (widget.queueBloc case final bloc?) {
      final state = bloc.state;
      if (state.isPlaying != _isPlaying) {
        setState(() {
          _isPlaying = state.isPlaying;
        });
        _syncProgressTicker();
      }
      _progressNotifier.value = _boundProgress(state.playbackProgress);
      final resolvedImageUrl = _resolveImageUrl(state);
      _extractColor(imageUrl: resolvedImageUrl, allowSetState: true);
    }
  }

  bool _isMaskedTrack(PlayerQueueState? state) {
    final activeTrack = switch (state?.nowPlaying) {
      final t? => t,
      null => widget.currentTrack,
    };
    return activeTrack?.metadata['musify_vault_masked'] == 'true';
  }

  String? _resolveImageUrl(PlayerQueueState? state) {
    if (_isMaskedTrack(state)) {
      return null;
    }
    if (state != null) {
      if (state.thumbnailImageUrl case final url? when url.isNotEmpty) {
        return url;
      }
      if (state.imageUrl case final url? when url.isNotEmpty) {
        return url;
      }
    }
    if (widget.currentTrack case final track?) {
      if (track.thumbnailImageUrl case final url? when url.isNotEmpty) {
        return url;
      }
      if (track.imageUrl case final url? when url.isNotEmpty) {
        return url;
      }
    }
    return widget.imageUrl;
  }

  void _extractColor({String? imageUrl, required bool allowSetState}) {
    final String key = switch (imageUrl) {
      final url? when url.isNotEmpty => url,
      _ => '',
    };
    if (key.isEmpty) {
      if (_lastExtractedKey != null ||
          _currentColor != ConnectEncoreTheme.miniPlayerDefaultBackground) {
        _lastExtractedKey = null;
        if (allowSetState && mounted) {
          setState(() {
            _currentColor = ConnectEncoreTheme.miniPlayerDefaultBackground;
          });
        } else {
          _currentColor = ConnectEncoreTheme.miniPlayerDefaultBackground;
        }
      }
      return;
    }
    if (key == _lastExtractedKey) {
      return;
    }
    _lastExtractedKey = key;

    final service = _resolveColorService();
    if (service == null) {
      return;
    }

    final cached = service.getCached(key);
    if (cached != null) {
      final targetColor = cached.isNeutral
          ? ConnectEncoreTheme.miniPlayerDefaultBackground
          : cached.surface;
      if (_currentColor != targetColor) {
        if (allowSetState && mounted) {
          setState(() {
            _currentColor = targetColor;
          });
        } else {
          _currentColor = targetColor;
        }
      }
      return;
    }

    unawaited(
      service
          .extract(
            imageUrl: imageUrl,
            cacheKey: key,
          )
          .then((scheme) {
            if (mounted && _lastExtractedKey == key) {
              final targetColor = scheme.isNeutral
                  ? ConnectEncoreTheme.miniPlayerDefaultBackground
                  : scheme.surface;
              if (_currentColor != targetColor) {
                setState(() {
                  _currentColor = targetColor;
                });
              }
            }
          }),
    );
  }

  static double _boundProgress(double progress) {
    if (!progress.isFinite || progress < 0.0) {
      return 0.0;
    }
    if (progress > 1.0) {
      return 1.0;
    }
    return progress;
  }

  MiniPlayerTrackBadges _resolveEffectiveBadges(PlayerQueueState? state) {
    final bool isQueuedFromQueue = switch (state?.nowPlaying) {
      final track? => track.isQueued,
      null => false,
    };
    if (!isQueuedFromQueue || widget.badges.isQueued) {
      return widget.badges;
    }
    return MiniPlayerTrackBadges(
      isQueued: true,
      isEnhanced: widget.badges.isEnhanced,
      playbackSpeedLabel: widget.badges.playbackSpeedLabel,
      listenAlongLabel: widget.badges.listenAlongLabel,
    );
  }

  double _resolveTargetHeight(BuildContext context) {
    switch (widget.visualConfig.sizeMode) {
      case MiniPlayerSizeMode.largeSize:
        return ConnectEncoreTheme.miniPlayerLargeHeight;
      case MiniPlayerSizeMode.scaledFont:
        return ConnectEncoreTheme.miniPlayerScaledFontHeight;
      case MiniPlayerSizeMode.defaultSize:
        return ConnectEncoreTheme.miniPlayerDefaultHeight;
      case MiniPlayerSizeMode.automatic:
        final double scale = MediaQuery.textScalerOf(context).scale(1.0);
        return scale >= ConnectEncoreTheme.miniPlayerScaledFontThreshold
            ? ConnectEncoreTheme.miniPlayerScaledFontHeight
            : ConnectEncoreTheme.miniPlayerDefaultHeight;
    }
  }

  void _triggerNextTrack() {
    final lp = _logMiniPlayerInteraction('swipe_skip_next', 'swipe');
    if (widget.onNext case final onNextAction?) {
      onNextAction();
    } else if (widget.queueBloc case final bloc?) {
      bloc.add(SkipToNextTrackEvent(loggingParams: lp));
    }
  }

  void _triggerPreviousTrack() {
    final lp = _logMiniPlayerInteraction('swipe_skip_prev', 'swipe');
    if (widget.onPrevious case final onPrevAction?) {
      onPrevAction();
    } else if (widget.queueBloc case final bloc?) {
      bloc.add(SkipToPrevTrackEvent(loggingParams: lp));
    }
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    final double nextOffset = _dragOffsetDx + details.delta.dx;
    final double boundedOffset = nextOffset > 72.0
        ? 72.0
        : (nextOffset < -72.0 ? -72.0 : nextOffset);
    setState(() {
      _dragOffsetDx = boundedOffset;
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final double velocity = switch (details.primaryVelocity) {
      final v? => v,
      null => 0.0,
    };
    final double offset = _dragOffsetDx;

    if (velocity < -250.0 || offset <= -48.0) {
      setState(() {
        _carouselDirection = 1;
        _dragOffsetDx = 0.0;
      });
      _triggerNextTrack();
    } else if (velocity > 250.0 || offset >= 48.0) {
      setState(() {
        _carouselDirection = -1;
        _dragOffsetDx = 0.0;
      });
      _triggerPreviousTrack();
    } else if (_dragOffsetDx != 0.0) {
      setState(() {
        _dragOffsetDx = 0.0;
      });
    }
  }

  void _handleHorizontalDragCancel() {
    if (_dragOffsetDx != 0.0) {
      setState(() {
        _dragOffsetDx = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = widget.queueBloc;
    if (bloc != null) {
      return ValueListenableBuilder<PlayerQueueState>(
        valueListenable: bloc,
        builder: (context, state, _) {
          return _buildMiniPlayerShell(context, state: state);
        },
      );
    }
    return _buildMiniPlayerShell(context);
  }

  Widget _buildMiniPlayerShell(
    BuildContext context, {
    PlayerQueueState? state,
  }) {
    final bool isMasked = _isMaskedTrack(state);
    final String displayTitle = switch (state?.title) {
      final t? when t.isNotEmpty => t,
      _ => widget.title,
    };
    final String displayArtist = switch (state?.artist) {
      final a? when a.isNotEmpty => a,
      _ => widget.artist,
    };
    final String? displayThumbnailUrl = isMasked
        ? null
        : switch (state?.thumbnailImageUrl) {
            final url? when url.isNotEmpty => url,
            _ => switch (state?.imageUrl) {
              final url? when url.isNotEmpty => url,
              _ => widget.imageUrl,
            },
          };
    final String? highResImageUrl = isMasked
        ? null
        : switch (state?.imageUrl) {
            final url? when url.isNotEmpty => url,
            _ => widget.imageUrl,
          };
    final bool isPlaying = switch (state?.isPlaying) {
      final playing? => playing,
      null => _isPlaying,
    };
    final ConnectMobiusController? effectiveConnectController =
        _resolveConnectController();
    final ConnectOutputStatusPolicy policy = _resolveOutputStatusPolicy();
    final MiniPlayerTrackBadges effectiveBadges = _resolveEffectiveBadges(state);

    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double outerHorizontalMargin = widget.visualConfig.bottomSheetMode
        ? 0.0
        : (screenWidth >= 600.0 ? 16.0 : 8.0);
    final bool isLargeSize =
        widget.visualConfig.sizeMode == MiniPlayerSizeMode.largeSize;
    final double barHeight = _resolveTargetHeight(context);
    final double barRadius = isLargeSize
        ? ConnectEncoreTheme.miniPlayerLargeRadius
        : ConnectEncoreTheme.miniPlayerDefaultRadius;
    final double mediaRadius = isLargeSize
        ? ConnectEncoreTheme.miniPlayerArtworkLargeRadius
        : ConnectEncoreTheme.miniPlayerArtworkDefaultRadius;
    final double progressInset = isLargeSize ? 16.0 : 8.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: outerHorizontalMargin,
        vertical: 4.0,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Optional `now_playing_bar_outline.xml` halo (`4dp` stroke, `10dp`
          // radius, `-4dp` outset, animated alpha `0 -> 1`).
          Positioned(
            left: -ConnectEncoreTheme.miniPlayerOutlineStrokeWidth,
            right: -ConnectEncoreTheme.miniPlayerOutlineStrokeWidth,
            top: -ConnectEncoreTheme.miniPlayerOutlineStrokeWidth,
            bottom: -ConnectEncoreTheme.miniPlayerOutlineStrokeWidth,
            child: IgnorePointer(
              child: AnimatedOpacity(
                key: const ValueKey<String>('mini_player_outline_halo'),
                duration: ConnectEncoreTheme.miniPlayerMotionDuration,
                opacity: widget.visualConfig.showOutlineHalo ? 1.0 : 0.0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      ConnectEncoreTheme.miniPlayerOutlineRadius,
                    ),
                    border: Border.all(
                      color: widget.visualConfig.outlineHaloColor,
                      width: ConnectEncoreTheme.miniPlayerOutlineStrokeWidth,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main MotionLayout bar (`now_playing_bar_layout`)
          GestureDetector(
            key: const ValueKey<String>('now_playing_bar_surface'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _logMiniPlayerInteraction('now_playing_bar', 'ui_navigate');
              if (widget.onTap case final onTapAction?) {
                onTapAction();
              } else {
                PlayerScreen.show(
                  context,
                  queueBloc: widget.queueBloc,
                  connectController: effectiveConnectController,
                  currentTrack: switch (state?.currentTrack) {
                    final track? => track,
                    null => widget.currentTrack,
                  },
                  title: displayTitle,
                  artist: displayArtist,
                  imageUrl: highResImageUrl,
                );
              }
            },
            onHorizontalDragUpdate: _handleHorizontalDragUpdate,
            onHorizontalDragEnd: _handleHorizontalDragEnd,
            onHorizontalDragCancel: _handleHorizontalDragCancel,
            child: AnimatedContainer(
              duration: ConnectEncoreTheme.miniPlayerMotionDuration,
              curve: Curves.easeOut,
              height: barHeight,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(barRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 12.0,
                    offset: const Offset(0.0, 4.0),
                  ),
                ],
              ),
              child: AnimatedContainer(
                duration: ConnectEncoreTheme.miniPlayerColorTransitionDuration,
                curve: Curves.easeOut,
                color: _currentColor,
                child: switch (effectiveConnectController) {
                  final controller? => ValueListenableBuilder<ConnectState>(
                      valueListenable: controller,
                      builder: (context, connectState, _) {
                        return _buildBarInnerLayout(
                          context: context,
                          displayTitle: displayTitle,
                          displayArtist: displayArtist,
                          displayThumbnailUrl: displayThumbnailUrl,
                          isPlaying: isPlaying,
                          isLargeSize: isLargeSize,
                          mediaRadius: mediaRadius,
                          progressInset: progressInset,
                          badges: effectiveBadges,
                          connectController: controller,
                          connectState: connectState,
                          policy: policy,
                        );
                      },
                    ),
                  null => _buildBarInnerLayout(
                      context: context,
                      displayTitle: displayTitle,
                      displayArtist: displayArtist,
                      displayThumbnailUrl: displayThumbnailUrl,
                      isPlaying: isPlaying,
                      isLargeSize: isLargeSize,
                      mediaRadius: mediaRadius,
                      progressInset: progressInset,
                      badges: effectiveBadges,
                      connectController: null,
                      connectState: null,
                      policy: policy,
                    ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarInnerLayout({
    required BuildContext context,
    required String displayTitle,
    required String displayArtist,
    required String? displayThumbnailUrl,
    required bool isPlaying,
    required bool isLargeSize,
    required double mediaRadius,
    required double progressInset,
    required MiniPlayerTrackBadges badges,
    required ConnectMobiusController? connectController,
    required ConnectState? connectState,
    required ConnectOutputStatusPolicy policy,
  }) {
    final ConnectIconState connectIconState = switch (connectState) {
      final state? => resolveConnectIconState(state, policy: policy),
      null => const ConnectIconIdle(),
    };
    final ConnectLabelState connectLabelState = switch (connectState) {
      final state? => resolveConnectLabelState(state, policy: policy),
      null => const ConnectLabelIdle(),
    };
    final bool isSingleLineConnectMode =
        connectLabelState is! ConnectLabelIdle;

    final bool isSaved = switch (widget.isSaved) {
      final explicit? => explicit,
      null => _localSaved,
    };

    final VoidCallback handleConnectTap = switch (connectController) {
      final controller? => () {
          _logMiniPlayerInteraction('connect_destination_button', 'hit');
          DevicePickerSheet.show(
            context,
            controller: controller,
            queueController: widget.queueBloc,
            playbackQuality: widget.playbackQuality,
          );
        },
      null => _noop,
    };

    void handleToggleSave() {
      _logMiniPlayerInteraction('add_to_button', 'hit');
      if (widget.onToggleSave case final callback?) {
        callback();
      } else {
        setState(() {
          _localSaved = !_localSaved;
        });
      }
    }

    void handlePlayPause() {
      final lp = _logMiniPlayerInteraction('play_pause_button', 'hit');
      if (widget.onPlayPause case final onPlayPauseAction?) {
        onPlayPauseAction();
      } else if (widget.queueBloc case final bloc?) {
        bloc.add(TogglePlayPauseEvent(loggingParams: lp));
      }
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left media slot (`content_container`: 40x40dp cover_image,
              // 16:9 video_surface, or companion_content).
              Padding(
                padding: EdgeInsets.only(
                  left: isLargeSize ? 12.0 : 8.0,
                  top: 8.0,
                  bottom: 8.0,
                ),
                child: _buildLeftMediaSlot(
                  context: context,
                  displayThumbnailUrl: displayThumbnailUrl,
                  isLargeSize: isLargeSize,
                  mediaRadius: mediaRadius,
                ),
              ),

              // Center swipeable track carousel (`tracks_carousel_view` +
              // `device_name_label` overlay, 12dp horizontal margin).
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: ClipRect(
                    child: Transform.translate(
                      offset: Offset(_dragOffsetDx * 0.45, 0.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) {
                          final double sign = _carouselDirection >= 0 ? 1.0 : -1.0;
                          final slide = Tween<Offset>(
                            begin: Offset(0.18 * sign, 0.0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          );
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(position: slide, child: child),
                          );
                        },
                        child: _MiniPlayerTrackCarouselItem(
                          key: ValueKey<String>(
                            'track_${displayTitle}_${displayArtist}_$isSingleLineConnectMode',
                          ),
                          title: displayTitle,
                          artist: displayArtist,
                          badges: badges,
                          promoConfig: widget.promoConfig,
                          connectLabelState: connectLabelState,
                          isSingleLineConnectMode: isSingleLineConnectMode,
                          enableMarquee: widget.visualConfig.enableMarquee,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Right action buttons (`40x40dp`, `8dp` padding -> `24dp` Encore icon)
              // 1. Connect Destination Button (`connect_destination_button`)
              _MiniPlayerActionButton(
                key: const ValueKey<String>('mini_player_connect_button'),
                tooltip: 'Devices',
                onPressed: handleConnectTap,
                child: ConnectStateIcon(
                  iconState: connectIconState,
                  size: 24.0,
                  idleColor: ConnectEncoreTheme.textBase,
                ),
              ),

              // 2. Conditional Skippable Ad Button (`skippable_ad_view_stub`)
              if (widget.adConfig case final ad?)
                _MiniPlayerSkippableAdButton(adConfig: ad),

              // 3. Add-To Button (`add_to_button`: hidden during skippable ads)
              if (widget.visualConfig.showAddToButton && widget.adConfig == null)
                _MiniPlayerActionButton(
                  key: const ValueKey<String>('mini_player_add_to_button'),
                  tooltip: isSaved ? 'Saved' : 'Save to Your Library',
                  onPressed: handleToggleSave,
                  child: ConnectEncoreIcon(
                    icon: isSaved
                        ? ConnectEncoreIcons.checkAltFill24
                        : ConnectEncoreIcons.plusAlt24,
                    size: 24.0,
                    color: isSaved
                        ? ConnectEncoreTheme.brightAccent
                        : ConnectEncoreTheme.textBase,
                  ),
                ),

              // 4. Play / Pause Button (`play_pause_button`, 8dp end margin)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _MiniPlayerActionButton(
                  key: const ValueKey<String>('mini_player_play_pause_button'),
                  tooltip: isPlaying ? 'Pause' : 'Play',
                  onPressed: handlePlayPause,
                  child: ConnectEncoreIcon(
                    icon: isPlaying
                        ? ConnectEncoreIcons.pause24
                        : ConnectEncoreIcons.play24,
                    size: 24.0,
                    color: ConnectEncoreTheme.textBase,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom 2dp inset progress bar (`progress_bar`, `cat_progress.xml`)
        Positioned(
          left: progressInset,
          right: progressInset,
          bottom: 0.0,
          child: RepaintBoundary(
            child: ValueListenableBuilder<double>(
              valueListenable: _progressNotifier,
              builder: (context, currentProgress, _) {
                return _MiniPlayerProgressBar(
                  key: const ValueKey<String>('mini_player_progress_bar'),
                  progress: currentProgress,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeftMediaSlot({
    required BuildContext context,
    required String? displayThumbnailUrl,
    required bool isLargeSize,
    required double mediaRadius,
  }) {
    final double artworkDimension = isLargeSize ? 72.0 : 40.0;
    switch (widget.mediaSlot) {
      case MiniPlayerArtworkSlot():
        return AnimatedContainer(
          duration: ConnectEncoreTheme.miniPlayerMotionDuration,
          width: artworkDimension,
          height: artworkDimension,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(mediaRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: PlayerArtworkImage(
            imageUrl: displayThumbnailUrl,
            artworkWidth: artworkDimension,
            artworkHeight: artworkDimension,
            placeholderIconSize: isLargeSize ? 28.0 : 20.0,
          ),
        );
      case MiniPlayerVideoSlot(:final videoBuilder):
        final double videoHeight = isLargeSize ? 72.0 : 40.0;
        final double videoWidth = videoHeight * (16.0 / 9.0);
        return AnimatedContainer(
          key: const ValueKey<String>('mini_player_video_surface'),
          duration: ConnectEncoreTheme.miniPlayerMotionDuration,
          width: videoWidth,
          height: videoHeight,
          decoration: BoxDecoration(
            color: ConnectEncoreTheme.videoSurfaceBackground,
            borderRadius: BorderRadius.circular(mediaRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: videoBuilder(context),
        );
      case MiniPlayerCompanionSlot(:final companionBuilder):
        return AnimatedContainer(
          key: const ValueKey<String>('mini_player_companion_slot'),
          duration: ConnectEncoreTheme.miniPlayerMotionDuration,
          width: artworkDimension,
          height: artworkDimension,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(mediaRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: companionBuilder(context),
        );
    }
  }
}

class _MiniPlayerTrackCarouselItem extends StatelessWidget {
  const _MiniPlayerTrackCarouselItem({
    super.key,
    required this.title,
    required this.artist,
    required this.badges,
    required this.promoConfig,
    required this.connectLabelState,
    required this.isSingleLineConnectMode,
    required this.enableMarquee,
  });

  final String title;
  final String artist;
  final MiniPlayerTrackBadges badges;
  final MiniPlayerPromoConfig? promoConfig;
  final ConnectLabelState connectLabelState;
  final bool isSingleLineConnectMode;
  final bool enableMarquee;

  InlineSpan _buildSingleLineTitleArtistSpan() {
    final List<InlineSpan> children = <InlineSpan>[
      TextSpan(
        text: title,
        style: ConnectEncoreTheme.bodySmall13Bold.copyWith(
          color: ConnectEncoreTheme.textBase,
          height: 1.2,
        ),
      ),
    ];

    final bool hasArtist = artist.trim().isNotEmpty;
    if (hasArtist) {
      children.add(
        TextSpan(
          text: ' \u2022 $artist',
          style: ConnectEncoreTheme.bodySmall13Regular.copyWith(
            color: ConnectEncoreTheme.miniPlayerSubtitle,
            height: 1.2,
          ),
        ),
      );
    }

    return TextSpan(children: children);
  }

  List<Widget> _buildSubtitleBadgeWidgets() {
    return <Widget>[
      if (badges.isQueued) ...[
        const ConnectEncoreIcon(
          key: ValueKey<String>('mini_player_queued_badge'),
          icon: ConnectEncoreIcons.queueBadge16,
          size: 12.0,
          color: ConnectEncoreTheme.miniPlayerSubtitle,
        ),
        const SizedBox(width: 4.0),
      ],
      if (badges.isEnhanced) ...[
        const ConnectEncoreIcon(
          key: ValueKey<String>('mini_player_enhanced_badge'),
          icon: ConnectEncoreIcons.enhanceBadge16,
          size: 12.0,
          color: ConnectEncoreTheme.brightAccent,
        ),
        const SizedBox(width: 4.0),
      ],
      if (badges.playbackSpeedLabel case final speed?
          when speed.trim().isNotEmpty) ...[
        _InlineBadgePill(
          key: const ValueKey<String>('mini_player_speed_badge'),
          label: speed,
          color: ConnectEncoreTheme.miniPlayerSubtitle,
        ),
        const SizedBox(width: 4.0),
      ],
      if (badges.listenAlongLabel case final listenAlong?
          when listenAlong.trim().isNotEmpty) ...[
        _InlineBadgePill(
          key: const ValueKey<String>('mini_player_listen_along_badge'),
          label: listenAlong,
          color: ConnectEncoreTheme.brightAccent,
        ),
        const SizedBox(width: 4.0),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Mode 1 (Active Connect / External Peripheral / Connecting):
    // Exact `ajn0.java` lines 240-299 + `device_name_label.xml` overlay.
    if (isSingleLineConnectMode) {
      return Column(
        key: const ValueKey<String>('mini_player_single_line_connect_mode'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final double maxBadgeWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth * 0.65
                  : double.infinity;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (badges.isQueued || badges.isEnhanced)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxBadgeWidth),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (badges.isQueued) ...[
                              const ConnectEncoreIcon(
                                key: ValueKey<String>(
                                  'mini_player_queued_badge',
                                ),
                                icon: ConnectEncoreIcons.queueBadge16,
                                size: 12.0,
                                color: ConnectEncoreTheme.miniPlayerSubtitle,
                              ),
                              const SizedBox(width: 4.0),
                            ],
                            if (badges.isEnhanced) ...[
                              const ConnectEncoreIcon(
                                key: ValueKey<String>(
                                  'mini_player_enhanced_badge',
                                ),
                                icon: ConnectEncoreIcons.enhanceBadge16,
                                size: 12.0,
                                color: ConnectEncoreTheme.brightAccent,
                              ),
                              const SizedBox(width: 4.0),
                            ],
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: SpotifyMarqueeText(
                      key: const ValueKey<String>(
                        'mini_player_single_line_title_artist',
                      ),
                      text: artist.trim().isNotEmpty
                          ? '$title \u2022 $artist'
                          : title,
                      textSpan: _buildSingleLineTitleArtistSpan(),
                      style: ConnectEncoreTheme.bodySmall13Bold,
                      enableMarquee: enableMarquee,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 2.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: ConnectDeviceLabel(
                  key: const ValueKey<String>('mini_player_connect_label'),
                  labelState: connectLabelState,
                  textStyle: ConnectEncoreTheme.caption11Regular.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  showBadgeIcon: true,
                  enableMarquee: enableMarquee,
                ),
              ),
              if (badges.listenAlongLabel case final listenAlong?
                  when listenAlong.trim().isNotEmpty) ...[
                const SizedBox(width: 6.0),
                _InlineBadgePill(
                  key: const ValueKey<String>('mini_player_listen_along_badge'),
                  label: listenAlong,
                  color: ConnectEncoreTheme.brightAccent,
                ),
              ],
            ],
          ),
        ],
      );
    }

    // Mode 2 (Local built-in playback):
    // Line 1 = Title (13sp Bold #FFFFFF), Line 2 = Badges + Artist (13sp Regular #B3FFFFFF)
    // OR Promo disclosure (`11sp Regular #B3FFFFFF`).
    final List<Widget> badgeWidgets = _buildSubtitleBadgeWidgets();

    return Column(
      key: const ValueKey<String>('mini_player_two_line_local_mode'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SpotifyMarqueeText(
          key: const ValueKey<String>('mini_player_title_text'),
          text: title,
          style: ConnectEncoreTheme.bodySmall13Bold.copyWith(
            color: ConnectEncoreTheme.textBase,
            height: 1.2,
          ),
          enableMarquee: enableMarquee,
        ),
        const SizedBox(height: 1.0),
        if (promoConfig case final promo?)
          SpotifyMarqueeText(
            key: const ValueKey<String>('mini_player_promo_indicator'),
            text: promo.label,
            style: ConnectEncoreTheme.caption11Regular.copyWith(
              color: ConnectEncoreTheme.miniPlayerSubtitle,
              height: 1.2,
            ),
            enableMarquee: enableMarquee,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final double maxBadgeWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth * 0.65
                  : double.infinity;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (badgeWidgets.isNotEmpty)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxBadgeWidth),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: badgeWidgets,
                        ),
                      ),
                    ),
                  Expanded(
                    child: SpotifyMarqueeText(
                      key: const ValueKey<String>('mini_player_artist_text'),
                      text: artist,
                      style: ConnectEncoreTheme.bodySmall13Regular.copyWith(
                        color: ConnectEncoreTheme.miniPlayerSubtitle,
                        height: 1.2,
                      ),
                      enableMarquee: enableMarquee,
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _InlineBadgePill extends StatelessWidget {
  const _InlineBadgePill({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
      decoration: BoxDecoration(
        color: ConnectEncoreTheme.tintedBase,
        borderRadius: BorderRadius.circular(3.0),
      ),
      child: Text(
        label,
        style: ConnectEncoreTheme.caption11Bold.copyWith(
          color: color,
          fontSize: 10.0,
        ),
      ),
    );
  }
}

class _MiniPlayerActionButton extends StatelessWidget {
  const _MiniPlayerActionButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onPressed,
          radius: 20.0,
          child: SizedBox.square(
            dimension: ConnectEncoreTheme.miniPlayerActionButtonSize,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPlayerSkippableAdButton extends StatelessWidget {
  const _MiniPlayerSkippableAdButton({
    required this.adConfig,
  });

  final MiniPlayerAdConfig adConfig;

  @override
  Widget build(BuildContext context) {
    final String label = adConfig.canSkip
        ? 'Skip'
        : switch (adConfig.countdownSeconds) {
            final sec? => '${sec}s',
            null => 'Ad',
          };

    return Padding(
      key: const ValueKey<String>('mini_player_skippable_ad_button'),
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Material(
        color: ConnectEncoreTheme.tintedBase,
        borderRadius: BorderRadius.circular(4.0),
        child: InkWell(
          onTap: adConfig.canSkip ? adConfig.onSkip : null,
          borderRadius: BorderRadius.circular(4.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Text(
              label,
              style: ConnectEncoreTheme.caption11Bold.copyWith(
                color: adConfig.canSkip
                    ? ConnectEncoreTheme.textBase
                    : ConnectEncoreTheme.textSubdued,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Exact `cat_progress.xml` 2dp horizontal progress bar with `1dp` rounded
/// ends, `#1AFFFFFF` background track, and `#FFFFFFFF` active fill.
class _MiniPlayerProgressBar extends StatelessWidget {
  const _MiniPlayerProgressBar({
    super.key,
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ConnectEncoreTheme.miniPlayerProgressHeight,
      child: CustomPaint(
        painter: _MiniPlayerProgressPainter(progress: progress),
      ),
    );
  }
}

final class _MiniPlayerProgressPainter extends CustomPainter {
  const _MiniPlayerProgressPainter({
    required this.progress,
  });

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    const Radius radius = Radius.circular(1.0);
    final RRect track = RRect.fromRectAndRadius(
      Offset.zero & size,
      radius,
    );
    canvas.drawRRect(
      track,
      Paint()
        ..color = ConnectEncoreTheme.tintedBase
        ..style = PaintingStyle.fill,
    );

    final double fillWidth = size.width * progress;
    if (fillWidth > 0.5) {
      canvas.save();
      canvas.clipRRect(track);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.0, 0.0, fillWidth, size.height),
          radius,
        ),
        Paint()
          ..color = ConnectEncoreTheme.textBase
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _MiniPlayerProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
