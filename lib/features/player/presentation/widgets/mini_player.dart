// 1:1 replica of Spotify 9.1.92.3058 MiniPlayer (`now_playing_bar`)
//
// Verified against:
// - `res/layout/now_playing_bar.xml`
// - `res/layout/now_playing_bar_track_info_view.xml`
// - `res/layout/device_name_label.xml`
// - `res/xml/now_playing_bar_scene.xml`
// - `res/drawable/now_playing_bar_outline.xml`
// - `res/drawable/now_playing_bar_video_bg.xml`
// - `res/drawable/cat_progress.xml`
// - `p/hjn0.java`, `p/zin0.java`, `p/ain0.java`, `p/thn0.java`, `p/x55.java`,
//   `p/s6n0.java`, `p/f9m0.java`, `p/gjn0.java`, `p/ajn0.java`, `p/c64.java`,
//   `p/ba7.java`, `p/vb4.java`
// - `p199p/rrs0.java:28-31`, `p199p/jhe0.java:63-79`, `p199p/srs0.java:13-16`,
//   `p199p/e9o0.java:133-145`, `p199p/grv.java:803` (live progress bar ticker
//   driven from `PlayerState.position(System.currentTimeMillis())` & `duration`)
// - `liborbit-jni-spotify.so` (`ConnectPlayer::playerState` @ `0xda97a0..0xda97b4`)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
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

/// Callback fired when a long-press video resize gesture completes (`bhn0`).
typedef MiniPlayerResizeCompletedCallback = void Function(
  bool isLarge,
  int startHeightDp,
  int endHeightDp,
);

/// Byte-exact 1:1 Spotify `now_playing_bar` MiniPlayer.
///
/// Key structural and behavioral invariants matched directly to Spotify 9.1.92.3058:
/// - Floating bar height: `56dp` (`default_size`), `68dp` (`scaled_font_height`
///   when `fontScale >= 1.5`), or `96dp` (`large_size`) with `100ms`
///   `DecelerateInterpolator` MotionLayout geometry animation (`zin0`, `hjn0.h`).
/// - Interactive long-press + vertical drag resize (`ain0`, `x55`, `thn0`, `s6n0`,
///   `c64`, `f9m0`):
///   - Enabled when playing local video (`MiniPlayerVideoSlot`, not remote Connect,
///     not bottom-sheet mode, `enableResizeGesture == true`).
///   - Long press (`kLongPressTimeout`) triggers start haptic (`c64.A`), fades in
///     the `4dp` `#1AFFFFFF` outline halo (`now_playing_bar_outline.xml`, `150ms`),
///     and tracks vertical drag continuously across `[minHeight, 96dp]`.
///   - Interpolates MotionLayout (`now_playing_bar_scene.xml`) geometry smoothly:
///     bar radius `8dp -> 16dp`, outline radius `10dp -> 18dp`, video radius
///     `4dp -> 8dp`, `16:9` video `40dp -> 80dp` tall, progress bar inset
///     `8dp -> 16dp`, `tracks_carousel_view` slides to top full width, and action
///     buttons slide to bottom-right with `4dp` spacing.
///   - Crossing `0.75` toggles 1-line / 2-line metadata mode (`chn0`, `f9m0:131`,
///     guarded by `fontScale <= 1.8`) and relocates active local peripheral
///     `device_name_label` to bottom-left (`12dp` above `play_pause_button` bottom).
///   - Release triggers end haptic (`c64.B`), fades halo out (`150ms`), snaps
///     at `> 0.5` (`100ms` decelerate), and persists the user's preferred size.
/// - Base color `#FF282828` (locked to `#FF282828` during video playback per
///   `f9m0:140`; crossfades `300ms` to extracted artwork dark surface for audio).
/// - Bottom `2dp` progress bar (`cat_progress.xml`), `1dp` radius, `#1AFFFFFF`
///   track, `#FFFFFFFF` fill, inset `8dp -> 16dp`.
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
    this.onResizingChanged,
    this.onResizeCompleted,
    this.onHeightChanged,
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
    this.nowEpochMsProvider = defaultNowEpochMs,
  });

  static int defaultNowEpochMs() => DateTime.now().millisecondsSinceEpoch;

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

  /// Fired when long-press video resize starts (`true`) or ends/cancels (`false`)
  /// (`fjn0.h` / `lm`).
  final ValueChanged<bool>? onResizingChanged;

  /// Fired when a user completes a long-press resize gesture (`bhn0`).
  final MiniPlayerResizeCompletedCallback? onResizeCompleted;

  /// Fired whenever rendered bar height changes during resize (`ejn0` / `zin0.a`).
  final ValueChanged<double>? onHeightChanged;

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
  final int Function() nowEpochMsProvider;

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with TickerProviderStateMixin {
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

  // Exact Spotify `ain0` + `zin0` + `hjn0` + `qin0` resize state machine.
  AnimationController? _resizeController;
  ConnectMobiusController? _attachedConnectController;
  bool _isResizing = false;
  bool _userPrefersLarge = false;
  bool _isAboveMetadataThreshold = false;
  double? _resizeStartGlobalY;
  double? _resizeStartHeight;
  double _lastKnownMinHeight = ConnectEncoreTheme.miniPlayerDefaultHeight;
  double? _lastReportedHeight;

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

  static double _boundUnit(double value) {
    if (!value.isFinite || value <= 0.0) {
      return 0.0;
    }
    if (value >= 1.0) {
      return 1.0;
    }
    return value;
  }

  static double _lerp(double a, double b, double t) {
    return a + ((b - a) * t);
  }

  static double _normalizeResizeProgress(double height, double minHeight) {
    final double span = ConnectEncoreTheme.miniPlayerLargeHeight - minHeight;
    if (span <= 0.0) {
      return 0.0;
    }
    return _boundUnit((height - minHeight) / span);
  }

  double _resolveMinHeight(BuildContext context) {
    switch (widget.visualConfig.sizeMode) {
      case MiniPlayerSizeMode.scaledFont:
        return ConnectEncoreTheme.miniPlayerScaledFontHeight;
      case MiniPlayerSizeMode.defaultSize:
        return ConnectEncoreTheme.miniPlayerDefaultHeight;
      case MiniPlayerSizeMode.automatic:
      case MiniPlayerSizeMode.largeSize:
        final double scale = MediaQuery.textScalerOf(context).scale(1.0);
        return scale >= ConnectEncoreTheme.miniPlayerScaledFontThreshold
            ? ConnectEncoreTheme.miniPlayerScaledFontHeight
            : ConnectEncoreTheme.miniPlayerDefaultHeight;
    }
  }

  /// Exact `f9m0.java:120` + `hjn0.java:286` + `vb4.c()` resize eligibility.
  bool _isResizeEligible(
    ConnectState? connectState,
    ConnectOutputStatusPolicy policy,
  ) {
    if (!widget.visualConfig.enableResizeGesture) {
      return false;
    }
    if (widget.visualConfig.bottomSheetMode) {
      return false;
    }
    if (widget.visualConfig.sizeMode != MiniPlayerSizeMode.automatic) {
      return false;
    }
    if (widget.mediaSlot is! MiniPlayerVideoSlot) {
      return false;
    }
    if (connectState case final state?) {
      if (policy.isRemoteOutputActive(state)) {
        return false;
      }
    }
    return true;
  }

  double _resolveTargetResizeProgress(bool canResize) {
    switch (widget.visualConfig.sizeMode) {
      case MiniPlayerSizeMode.largeSize:
        return 1.0;
      case MiniPlayerSizeMode.defaultSize:
      case MiniPlayerSizeMode.scaledFont:
        return 0.0;
      case MiniPlayerSizeMode.automatic:
        return (canResize && _userPrefersLarge) ? 1.0 : 0.0;
    }
  }

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

    _userPrefersLarge = widget.visualConfig.initialIsLarge;
    final ConnectMobiusController? initialConnect = _resolveConnectController();
    final ConnectOutputStatusPolicy initialPolicy = _resolveOutputStatusPolicy();
    final bool initialCanResize = _isResizeEligible(
      initialConnect?.value,
      initialPolicy,
    );
    final double initialResizeProgress = _resolveTargetResizeProgress(
      initialCanResize,
    );
    _isAboveMetadataThreshold = initialResizeProgress >=
        ConnectEncoreTheme.miniPlayerResizeMetadataThreshold;

    final AnimationController resizeController = AnimationController(
      vsync: this,
      duration: ConnectEncoreTheme.miniPlayerMotionDuration,
      value: initialResizeProgress,
    );
    resizeController.addListener(_onResizeAnimationTick);
    _resizeController = resizeController;

    _isPlaying = switch (widget.queueBloc?.state.isPlaying) {
      final playing? => playing,
      null => widget.isPlaying,
    };

    final initialImageUrl = _resolveImageUrl(widget.queueBloc?.state);
    _extractColor(imageUrl: initialImageUrl, allowSetState: false);

    final initialProgress = _boundUnit(
      switch (widget.queueBloc?.state) {
        final s? => s.progressAt(widget.nowEpochMsProvider()),
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
        if (state.isPlaying && !state.isBuffering) {
          final currentProgress = _boundUnit(
            state.progressAt(widget.nowEpochMsProvider()),
          );
          if ((currentProgress - _progressNotifier.value).abs() >= 0.0005) {
            _progressNotifier.value = currentProgress;
          }
        }
      }
    });
    _progressTicker = ticker;

    _syncProgressTicker();

    widget.queueBloc?.addListener(_onQueueStateChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lastKnownMinHeight = _resolveMinHeight(context);
    _syncConnectControllerListener();
  }

  @override
  void dispose() {
    _attachedConnectController?.removeListener(_onConnectStateChanged);
    _attachedConnectController = null;
    if (_resizeController case final controller?) {
      controller.removeListener(_onResizeAnimationTick);
      controller.dispose();
      _resizeController = null;
    }
    if (_progressTicker case final ticker?) {
      ticker.dispose();
      _progressTicker = null;
    }
    _progressNotifier.dispose();
    widget.queueBloc?.removeListener(_onQueueStateChanged);
    super.dispose();
  }

  void _syncConnectControllerListener() {
    final ConnectMobiusController? nextController = _resolveConnectController();
    if (_attachedConnectController == nextController) {
      return;
    }
    _attachedConnectController?.removeListener(_onConnectStateChanged);
    _attachedConnectController = nextController;
    nextController?.addListener(_onConnectStateChanged);
    _syncResizeStateFromInputs(animate: true);
  }

  void _onConnectStateChanged() {
    if (!mounted) {
      return;
    }
    _syncResizeStateFromInputs(animate: true);
  }

  void _onResizeAnimationTick() {
    final AnimationController? controller = _resizeController;
    if (controller == null) {
      return;
    }
    final double currentHeight = _lerp(
      _lastKnownMinHeight,
      ConnectEncoreTheme.miniPlayerLargeHeight,
      controller.value,
    );
    final double? previous = _lastReportedHeight;
    if (previous == null || (currentHeight - previous).abs() >= 0.5) {
      _lastReportedHeight = currentHeight;
      widget.onHeightChanged?.call(currentHeight);
    }
  }

  void _animateResizeTo(double targetProgress) {
    final AnimationController? controller = _resizeController;
    if (controller == null) {
      return;
    }
    final double boundedTarget = _boundUnit(targetProgress);
    if ((controller.value - boundedTarget).abs() <= 0.0001) {
      controller.value = boundedTarget;
      return;
    }
    unawaited(
      controller.animateTo(
        boundedTarget,
        duration: ConnectEncoreTheme.miniPlayerMotionDuration,
        curve: Curves.decelerate,
      ),
    );
  }

  void _cancelActiveResize({required bool restorePersistedTarget}) {
    if (!_isResizing) {
      return;
    }
    setState(() {
      _isResizing = false;
      _resizeStartGlobalY = null;
      _resizeStartHeight = null;
    });
    widget.onResizingChanged?.call(false);

    if (restorePersistedTarget) {
      final bool canResize = _isResizeEligible(
        _attachedConnectController?.value,
        _resolveOutputStatusPolicy(),
      );
      final double targetProgress = _resolveTargetResizeProgress(canResize);
      final bool nextAboveThreshold = targetProgress >=
          ConnectEncoreTheme.miniPlayerResizeMetadataThreshold;
      if (_isAboveMetadataThreshold != nextAboveThreshold) {
        setState(() {
          _isAboveMetadataThreshold = nextAboveThreshold;
        });
      }
      _animateResizeTo(targetProgress);
    }
  }

  void _syncResizeStateFromInputs({
    required bool animate,
    bool mediaSlotTypeChanged = false,
  }) {
    final bool canResize = _isResizeEligible(
      _attachedConnectController?.value,
      _resolveOutputStatusPolicy(),
    );

    // Exact `gjn0.java:479-482`: switching media content (`ufl`/`vfl`/`tfl`)
    // or losing resize eligibility cancels any active resize gesture.
    if (_isResizing && (!canResize || mediaSlotTypeChanged)) {
      _cancelActiveResize(restorePersistedTarget: false);
    }

    if (_isResizing) {
      return;
    }

    final double targetProgress = _resolveTargetResizeProgress(canResize);
    final bool nextAboveThreshold = targetProgress >=
        ConnectEncoreTheme.miniPlayerResizeMetadataThreshold;
    if (_isAboveMetadataThreshold != nextAboveThreshold) {
      setState(() {
        _isAboveMetadataThreshold = nextAboveThreshold;
      });
    }

    final AnimationController? controller = _resizeController;
    if (controller == null) {
      return;
    }
    if (animate) {
      _animateResizeTo(targetProgress);
    } else {
      controller.value = targetProgress;
    }
  }

  @override
  void didUpdateWidget(covariant MiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queueBloc != widget.queueBloc) {
      oldWidget.queueBloc?.removeListener(_onQueueStateChanged);
      widget.queueBloc?.addListener(_onQueueStateChanged);
      final nextState = widget.queueBloc?.state;
      _isPlaying = switch (nextState?.isPlaying) {
        final playing? => playing,
        null => widget.isPlaying,
      };
      _progressNotifier.value = _boundUnit(
        switch (nextState) {
          final s? => s.progressAt(widget.nowEpochMsProvider()),
          null => widget.progress,
        },
      );
      _syncProgressTicker();
    }
    if (oldWidget.connectController != widget.connectController) {
      _syncConnectControllerListener();
    }
    if (oldWidget.isPlaying != widget.isPlaying && widget.queueBloc == null) {
      _isPlaying = widget.isPlaying;
      _syncProgressTicker();
    }
    if (oldWidget.progress != widget.progress && widget.queueBloc == null) {
      _progressNotifier.value = _boundUnit(widget.progress);
    }
    if (oldWidget.queueBloc != widget.queueBloc ||
        oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.currentTrack != widget.currentTrack) {
      final updatedImageUrl = _resolveImageUrl(widget.queueBloc?.state);
      _extractColor(imageUrl: updatedImageUrl, allowSetState: false);
    }
    if (oldWidget.visualConfig.initialIsLarge !=
        widget.visualConfig.initialIsLarge) {
      _userPrefersLarge = widget.visualConfig.initialIsLarge;
    }
    final bool mediaSlotTypeChanged =
        oldWidget.mediaSlot.runtimeType != widget.mediaSlot.runtimeType;
    if (mediaSlotTypeChanged || oldWidget.visualConfig != widget.visualConfig) {
      _syncResizeStateFromInputs(
        animate: true,
        mediaSlotTypeChanged: mediaSlotTypeChanged,
      );
    }
  }

  bool _shouldTickProgress() {
    if (widget.queueBloc case final bloc?) {
      final state = bloc.state;
      return state.isPlaying && !state.isBuffering;
    }
    return _isPlaying;
  }

  void _syncProgressTicker() {
    final ticker = _progressTicker;
    if (ticker == null) {
      return;
    }
    if (_shouldTickProgress()) {
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
      }
      _syncProgressTicker();
      _progressNotifier.value = _boundUnit(
        state.progressAt(widget.nowEpochMsProvider()),
      );
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

  // ===========================================================================
  // Spotify `ain0` + `x55` + `s6n0` + `c64` Long-Press Video Resize Handlers
  // ===========================================================================

  void _handleResizeLongPressStart(LongPressStartDetails details) {
    final bool canResize = _isResizeEligible(
      _attachedConnectController?.value,
      _resolveOutputStatusPolicy(),
    );
    if (!canResize) {
      return;
    }
    final AnimationController? controller = _resizeController;
    if (controller == null) {
      return;
    }

    final double minHeight = _resolveMinHeight(context);
    _lastKnownMinHeight = minHeight;
    controller.stop();

    final double currentHeight = _lerp(
      minHeight,
      ConnectEncoreTheme.miniPlayerLargeHeight,
      controller.value,
    );
    final bool startedAboveMetadataThreshold =
        _normalizeResizeProgress(currentHeight, minHeight) >=
            ConnectEncoreTheme.miniPlayerResizeMetadataThreshold;

    // Exact `c64.A` (`VibrationEffect.EFFECT_CLICK` / `performHapticFeedback(1)`).
    unawaited(HapticFeedback.mediumImpact());

    setState(() {
      _isResizing = true;
      _resizeStartGlobalY = details.globalPosition.dy;
      _resizeStartHeight = currentHeight;
      _isAboveMetadataThreshold = startedAboveMetadataThreshold;
      _dragOffsetDx = 0.0;
    });

    widget.onResizingChanged?.call(true);
  }

  void _handleResizeLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isResizing) {
      return;
    }
    final double? startGlobalY = _resizeStartGlobalY;
    final double? startHeight = _resizeStartHeight;
    final AnimationController? controller = _resizeController;
    if (startGlobalY == null || startHeight == null || controller == null) {
      return;
    }

    final double minHeight = _resolveMinHeight(context);
    _lastKnownMinHeight = minHeight;

    // Exact `ain0.java:95`: `thn0.a((int) (startHeight + (startRawY - currentRawY)))`
    final double targetHeight =
        startHeight + (startGlobalY - details.globalPosition.dy);
    final double progress = _normalizeResizeProgress(targetHeight, minHeight);

    controller.stop();
    controller.value = progress;

    // Exact `ain0.java:100-109` -> `yhn0` -> `chn0` metadata layout threshold.
    final bool aboveThreshold =
        progress >= ConnectEncoreTheme.miniPlayerResizeMetadataThreshold;
    if (aboveThreshold != _isAboveMetadataThreshold) {
      setState(() {
        _isAboveMetadataThreshold = aboveThreshold;
      });
    }
  }

  void _handleResizeLongPressEnd(LongPressEndDetails details) {
    if (!_isResizing) {
      return;
    }
    final double? startGlobalY = _resizeStartGlobalY;
    final double? startHeight = _resizeStartHeight;
    if (startGlobalY == null || startHeight == null) {
      _cancelActiveResize(restorePersistedTarget: true);
      return;
    }

    final double minHeight = _resolveMinHeight(context);
    _lastKnownMinHeight = minHeight;

    // Exact `ain0.java:116-127` (`vhn0(isLarge, wasLarge)`).
    final double finalHeight =
        startHeight + (startGlobalY - details.globalPosition.dy);
    final double endProgress = _normalizeResizeProgress(finalHeight, minHeight);
    final double startProgress = _normalizeResizeProgress(
      startHeight,
      minHeight,
    );
    final bool snapToLarge =
        endProgress > ConnectEncoreTheme.miniPlayerResizeSnapThreshold;
    final bool startedLarge =
        startProgress > ConnectEncoreTheme.miniPlayerResizeSnapThreshold;

    // Exact `c64.B` (`VibrationEffect.EFFECT_TICK` / `CLOCK_TICK`).
    unawaited(HapticFeedback.selectionClick());

    setState(() {
      _isResizing = false;
      _userPrefersLarge = snapToLarge;
      _isAboveMetadataThreshold = snapToLarge;
      _resizeStartGlobalY = null;
      _resizeStartHeight = null;
    });

    widget.onResizingChanged?.call(false);
    _animateResizeTo(snapToLarge ? 1.0 : 0.0);

    final int startHeightDp = startedLarge
        ? ConnectEncoreTheme.miniPlayerLargeHeight.round()
        : minHeight.round();
    final int endHeightDp = snapToLarge
        ? ConnectEncoreTheme.miniPlayerLargeHeight.round()
        : minHeight.round();
    _logMiniPlayerInteraction('now_playing_bar', 'ui_resize');
    widget.onResizeCompleted?.call(snapToLarge, startHeightDp, endHeightDp);
  }

  void _handleResizeLongPressCancel() {
    if (!_isResizing) {
      return;
    }
    // Exact `uhn0` (`CancelledResizing`, `s6n0.java:116-118`): fade halo out
    // with no release haptic and restore persisted snap position.
    _cancelActiveResize(restorePersistedTarget: true);
  }

  // ===========================================================================
  // Horizontal Track Carousel Swipe Handlers
  // ===========================================================================

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
    if (_isResizing) {
      return;
    }
    final double nextOffset = _dragOffsetDx + details.delta.dx;
    final double boundedOffset = nextOffset > 72.0
        ? 72.0
        : (nextOffset < -72.0 ? -72.0 : nextOffset);
    setState(() {
      _dragOffsetDx = boundedOffset;
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_isResizing) {
      return;
    }
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
    final double fontScale = MediaQuery.textScalerOf(context).scale(1.0);
    final double minHeight = _resolveMinHeight(context);
    final double outerHorizontalMargin = widget.visualConfig.bottomSheetMode
        ? 0.0
        : (screenWidth >= 600.0 ? 16.0 : 8.0);

    // Exact `f9m0.java:140`: video mode uses `#FF282828` regardless of artwork.
    final Color effectiveBarBackground = widget.mediaSlot is MiniPlayerVideoSlot
        ? ConnectEncoreTheme.miniPlayerDefaultBackground
        : _currentColor;

    final AnimationController? resizeController = _resizeController;
    final Listenable resizeListenable = switch (resizeController) {
      final controller? => controller,
      null => kAlwaysDismissedAnimation,
    };

    Widget buildForConnectState(ConnectState? connectState) {
      final bool canResize = _isResizeEligible(connectState, policy);
      final bool showOutlineHalo =
          widget.visualConfig.showOutlineHalo || _isResizing;

      return AnimatedBuilder(
        animation: resizeListenable,
        builder: (context, _) {
          final double resizeProgress = switch (resizeController) {
            final controller? => _boundUnit(controller.value),
            null => 0.0,
          };
          final double barHeight = _lerp(
            minHeight,
            ConnectEncoreTheme.miniPlayerLargeHeight,
            resizeProgress,
          );
          final double barRadius = _lerp(
            ConnectEncoreTheme.miniPlayerDefaultRadius,
            ConnectEncoreTheme.miniPlayerLargeRadius,
            resizeProgress,
          );
          final double outlineRadius =
              (ConnectEncoreTheme.miniPlayerOutlineStrokeWidth / 2.0) +
                  barRadius;
          final double mediaRadius = _lerp(
            ConnectEncoreTheme.miniPlayerArtworkDefaultRadius,
            ConnectEncoreTheme.miniPlayerArtworkLargeRadius,
            resizeProgress,
          );
          final double progressInset = _lerp(
            ConnectEncoreTheme.miniPlayerContentPadding,
            ConnectEncoreTheme.miniPlayerLargeContentPadding,
            resizeProgress,
          );

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: outerHorizontalMargin,
              vertical: 4.0,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Exact `now_playing_bar_outline.xml` (`hjn0.java:271-284`,
                // `zin0.java:89`, `hjn0.g` 150ms fade): `4dp` stroke, `-4dp`
                // outset, radius `(4dp / 2) + barRadius` (`10dp -> 18dp`).
                Positioned(
                  left: -ConnectEncoreTheme.miniPlayerOutlineStrokeWidth,
                  right: -ConnectEncoreTheme.miniPlayerOutlineStrokeWidth,
                  top: -ConnectEncoreTheme.miniPlayerOutlineStrokeWidth,
                  bottom: -ConnectEncoreTheme.miniPlayerOutlineStrokeWidth,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      key: const ValueKey<String>('mini_player_outline_halo'),
                      duration: ConnectEncoreTheme.miniPlayerOutlineFadeDuration,
                      opacity: showOutlineHalo ? 1.0 : 0.0,
                      child: DecoratedBox(
                        key: const ValueKey<String>(
                          'mini_player_outline_halo_box',
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(outlineRadius),
                          border: Border.all(
                            color: widget.visualConfig.outlineHaloColor,
                            width:
                                ConnectEncoreTheme.miniPlayerOutlineStrokeWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Main MotionLayout bar (`now_playing_bar_layout`) wrapped by
                // Spotify's `ain0` long-press vertical resize detector.
                GestureDetector(
                  key: const ValueKey<String>('now_playing_bar_surface'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_isResizing) {
                      return;
                    }
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
                        duration: switch (state) {
                          final q? when q.durationMs > 0 => q.currentDuration,
                          _ => Duration.zero,
                        },
                        imageUrl: highResImageUrl,
                      );
                    }
                  },
                  onLongPressStart:
                      canResize ? _handleResizeLongPressStart : null,
                  onLongPressMoveUpdate:
                      canResize ? _handleResizeLongPressMoveUpdate : null,
                  onLongPressEnd: canResize ? _handleResizeLongPressEnd : null,
                  onLongPressCancel:
                      canResize ? _handleResizeLongPressCancel : null,
                  onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                  onHorizontalDragEnd: _handleHorizontalDragEnd,
                  onHorizontalDragCancel: _handleHorizontalDragCancel,
                  child: SizedBox(
                    height: barHeight,
                    child: DecoratedBox(
                      key: const ValueKey<String>(
                        'now_playing_bar_rounded_box',
                      ),
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(barRadius),
                        child: AnimatedContainer(
                          key: const ValueKey<String>(
                            'now_playing_bar_color_surface',
                          ),
                          duration: ConnectEncoreTheme
                              .miniPlayerColorTransitionDuration,
                          curve: Curves.easeOut,
                          color: effectiveBarBackground,
                          child: _buildBarInnerLayout(
                            context: context,
                            displayTitle: displayTitle,
                            displayArtist: displayArtist,
                            displayThumbnailUrl: displayThumbnailUrl,
                            isPlaying: isPlaying,
                            barHeight: barHeight,
                            resizeProgress: resizeProgress,
                            fontScale: fontScale,
                            canResize: canResize,
                            mediaRadius: mediaRadius,
                            progressInset: progressInset,
                            badges: effectiveBadges,
                            connectController: effectiveConnectController,
                            connectState: connectState,
                            policy: policy,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return switch (effectiveConnectController) {
      final controller? => ValueListenableBuilder<ConnectState>(
          valueListenable: controller,
          builder: (context, connectState, _) =>
              buildForConnectState(connectState),
        ),
      null => buildForConnectState(null),
    };
  }

  Widget _buildBarInnerLayout({
    required BuildContext context,
    required String displayTitle,
    required String displayArtist,
    required String? displayThumbnailUrl,
    required bool isPlaying,
    required double barHeight,
    required double resizeProgress,
    required double fontScale,
    required bool canResize,
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
    final bool hasConnectLabel = connectLabelState is! ConnectLabelIdle;

    // Exact `f9m0.java:131-153` (`d9i0.OneLineMetadata` vs `TwoLineMetadata`):
    // - `fontScale > 1.8` always collapses to 1-line metadata.
    // - When `resizeProgress >= 0.75` (large video mode) and `fontScale <= 1.8`,
    //   `tracks_carousel_view` uses 2-line metadata at the top while any active
    //   local peripheral `device_name_label` migrates to bottom-left.
    final bool isAboveLargeMetadataThreshold = _isResizing
        ? _isAboveMetadataThreshold
        : resizeProgress >=
            ConnectEncoreTheme.miniPlayerResizeMetadataThreshold;
    final bool supportsExpandedTwoLine = canResize ||
        widget.visualConfig.sizeMode == MiniPlayerSizeMode.largeSize;
    final bool useTwoLineMetadata =
        fontScale <= ConnectEncoreTheme.miniPlayerLargeMetadataMaxFontScale &&
            (!hasConnectLabel ||
                (isAboveLargeMetadataThreshold && supportsExpandedTwoLine));
    final bool isSingleLineConnectMode = !useTwoLineMetadata;
    final bool showDetachedBottomConnectLabel =
        hasConnectLabel && useTwoLineMetadata;

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

    final bool showAdButton = widget.adConfig != null;
    final bool showAddToButton =
        widget.visualConfig.showAddToButton && !showAdButton;

    // Exact `zin0.c(f)` video padding interpolation (`8dp` or `0dp` per `vb4.b/e`).
    final bool isVideoSlot = widget.mediaSlot is MiniPlayerVideoSlot;
    final double defaultMediaPad =
        (isVideoSlot && widget.visualConfig.removeDefaultVideoPadding)
            ? 0.0
            : ConnectEncoreTheme.miniPlayerContentPadding;
    final double largeMediaPad =
        (isVideoSlot && widget.visualConfig.removeLargeVideoPadding)
            ? 0.0
            : ConnectEncoreTheme.miniPlayerContentPadding;
    final double mediaMargin = _lerp(
      defaultMediaPad,
      largeMediaPad,
      resizeProgress,
    );

    // Exact `now_playing_bar_scene.xml` action button interpolation.
    final double buttonGap = _lerp(
      0.0,
      ConnectEncoreTheme.miniPlayerLargeButtonSpacing,
      resizeProgress,
    );
    final double trailingMargin = _lerp(
      ConnectEncoreTheme.miniPlayerContentPadding,
      ConnectEncoreTheme.miniPlayerLargeButtonSpacing,
      resizeProgress,
    );
    final double defaultActionsBottom =
        (barHeight - ConnectEncoreTheme.miniPlayerActionButtonSize) / 2.0;
    final double actionsBottom = _lerp(
      defaultActionsBottom > 0.0 ? defaultActionsBottom : 0.0,
      ConnectEncoreTheme.miniPlayerLargeButtonSpacing,
      resizeProgress,
    );

    final List<Widget> actionButtons = <Widget>[
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
      if (widget.adConfig case final ad?)
        _MiniPlayerSkippableAdButton(adConfig: ad),
      if (showAddToButton)
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
      _MiniPlayerActionButton(
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
    ];

    final int fixedIconCount = 2 + (showAddToButton ? 1 : 0);
    final double adSlotWidth = showAdButton ? 52.0 : 0.0;
    final double actionsClusterWidth =
        (fixedIconCount * ConnectEncoreTheme.miniPlayerActionButtonSize) +
            adSlotWidth +
            ((actionButtons.length - 1) * buttonGap);
    final double actionsReservedRight = actionsClusterWidth + trailingMargin;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double barWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final double rawMediaHeight = barHeight - (2.0 * mediaMargin);
        final double mediaHeight = rawMediaHeight > 0.0 ? rawMediaHeight : 0.0;
        final double desiredMediaWidth =
            isVideoSlot ? mediaHeight * (16.0 / 9.0) : mediaHeight;
        final double maxMediaWidth = barWidth * 0.48;
        final double mediaWidth = desiredMediaWidth > maxMediaWidth
            ? maxMediaWidth
            : desiredMediaWidth;
        final double contentRight = mediaMargin + mediaWidth;

        // Exact `now_playing_bar_scene.xml` `tracks_carousel_view` bounds:
        // - `default_size` (`0.0`): left = contentRight + 12, right = actions + 12,
        //   vertically centered inside bar.
        // - `large_size` (`1.0`): left = contentRight + 12, right = 4dp from end
        //   (`End_toEndOf="parent"`), top = 8dp (`vertical_bias = 0`), bottom = 44dp
        //   above bottom-aligned action buttons.
        final double carouselLeft =
            contentRight + ConnectEncoreTheme.miniPlayerCarouselMargin;
        final double rawCarouselRight = _lerp(
          actionsReservedRight + ConnectEncoreTheme.miniPlayerCarouselMargin,
          ConnectEncoreTheme.miniPlayerLargeButtonSpacing,
          resizeProgress,
        );
        final double maxAllowedCarouselRight =
            barWidth - carouselLeft > 0.0 ? barWidth - carouselLeft : 0.0;
        final double carouselRight = rawCarouselRight > maxAllowedCarouselRight
            ? maxAllowedCarouselRight
            : rawCarouselRight;
        final double carouselTop = _lerp(
          0.0,
          ConnectEncoreTheme.miniPlayerContentPadding,
          resizeProgress,
        );
        final double carouselBottom = _lerp(
          ConnectEncoreTheme.miniPlayerProgressHeight,
          ConnectEncoreTheme.miniPlayerActionButtonSize +
              ConnectEncoreTheme.miniPlayerLargeButtonSpacing,
          resizeProgress,
        );
        final Alignment carouselAlignment = Alignment(
          -1.0,
          _lerp(0.0, -1.0, resizeProgress),
        );

        // Exact `now_playing_bar_scene.xml:141-150` `device_name_label`
        // bottom-left placement in `large_size`.
        final double detachedLabelRight = actionsReservedRight + 8.0;
        final double detachedLabelWidth =
            barWidth - carouselLeft - detachedLabelRight;
        final double detachedLabelBottom = actionsBottom +
            ConnectEncoreTheme.miniPlayerLargeConnectLabelBottomMargin;

        return Stack(
          children: [
            // 1. Left media slot (`content_container`: `cover_image`, `16:9`
            //    `video_surface`, or `companion_content`).
            Positioned(
              left: mediaMargin,
              top: mediaMargin,
              width: mediaWidth,
              height: mediaHeight,
              child: _buildLeftMediaSlot(
                context: context,
                displayThumbnailUrl: displayThumbnailUrl,
                mediaWidth: mediaWidth,
                mediaHeight: mediaHeight,
                mediaRadius: mediaRadius,
              ),
            ),

            // 2. Center swipeable track carousel (`tracks_carousel_view`).
            Positioned(
              left: carouselLeft,
              right: carouselRight,
              top: carouselTop,
              bottom: carouselBottom,
              child: Align(
                alignment: carouselAlignment,
                child: ClipRect(
                  child: Transform.translate(
                    offset: Offset(_dragOffsetDx * 0.45, 0.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) {
                        final double sign =
                            _carouselDirection >= 0 ? 1.0 : -1.0;
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
                          child: SlideTransition(
                            position: slide,
                            child: child,
                          ),
                        );
                      },
                      child: _MiniPlayerTrackCarouselItem(
                        key: ValueKey<String>(
                          'track_${displayTitle}_$displayArtist',
                        ),
                        title: displayTitle,
                        artist: displayArtist,
                        badges: badges,
                        promoConfig: widget.promoConfig,
                        connectLabelState: showDetachedBottomConnectLabel
                            ? const ConnectLabelIdle()
                            : connectLabelState,
                        isSingleLineConnectMode: isSingleLineConnectMode,
                        enableMarquee: widget.visualConfig.enableMarquee,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 3. Detached bottom-left `device_name_label` in `large_size`
            //    when playing video on a local peripheral (`now_playing_bar_scene.xml:141`).
            if (showDetachedBottomConnectLabel && detachedLabelWidth > 12.0)
              Positioned(
                left: carouselLeft,
                right: detachedLabelRight,
                bottom: detachedLabelBottom,
                child: ConnectDeviceLabel(
                  key: const ValueKey<String>(
                    'mini_player_large_connect_label',
                  ),
                  labelState: connectLabelState,
                  textStyle: ConnectEncoreTheme.caption11Regular.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  showBadgeIcon: true,
                  enableMarquee: widget.visualConfig.enableMarquee,
                ),
              ),

            // 4. Right action buttons (`connect_destination_button`,
            //    optional `skippable_ad_view_stub`, optional `add_to_button`,
            //    `play_pause_button`).
            Positioned(
              right: trailingMargin,
              bottom: actionsBottom,
              height: ConnectEncoreTheme.miniPlayerActionButtonSize,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (int i = 0; i < actionButtons.length; i++) ...[
                    if (i > 0 && buttonGap > 0.0) SizedBox(width: buttonGap),
                    actionButtons[i],
                  ],
                ],
              ),
            ),

            // 5. Bottom 2dp inset progress bar (`progress_bar`, `cat_progress.xml`).
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
      },
    );
  }

  Widget _buildLeftMediaSlot({
    required BuildContext context,
    required String? displayThumbnailUrl,
    required double mediaWidth,
    required double mediaHeight,
    required double mediaRadius,
  }) {
    switch (widget.mediaSlot) {
      case MiniPlayerArtworkSlot():
        return ClipRRect(
          borderRadius: BorderRadius.circular(mediaRadius),
          child: SizedBox(
            width: mediaWidth,
            height: mediaHeight,
            child: PlayerArtworkImage(
              imageUrl: displayThumbnailUrl,
              artworkWidth: mediaWidth,
              artworkHeight: mediaHeight,
              placeholderIconSize: mediaHeight >= 60.0 ? 28.0 : 20.0,
            ),
          ),
        );
      case MiniPlayerVideoSlot(:final videoBuilder):
        return Container(
          key: const ValueKey<String>('mini_player_video_surface'),
          width: mediaWidth,
          height: mediaHeight,
          decoration: BoxDecoration(
            color: ConnectEncoreTheme.videoSurfaceBackground,
            borderRadius: BorderRadius.circular(mediaRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: videoBuilder(context),
        );
      case MiniPlayerCompanionSlot(:final companionBuilder):
        return ClipRRect(
          key: const ValueKey<String>('mini_player_companion_slot'),
          borderRadius: BorderRadius.circular(mediaRadius),
          child: SizedBox(
            width: mediaWidth,
            height: mediaHeight,
            child: companionBuilder(context),
          ),
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
    // Mode 1 (`d9i0.OneLineMetadata`, `ajn0.java:234-299` + `device_name_label.xml`):
    // Active Connect / External Peripheral / Connecting / fontScale > 1.8.
    if (isSingleLineConnectMode) {
      final bool hasListenAlong = switch (badges.listenAlongLabel) {
        final label? when label.trim().isNotEmpty => true,
        _ => false,
      };
      final bool showInlineConnectRow =
          connectLabelState is! ConnectLabelIdle || hasListenAlong;

      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
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
            if (showInlineConnectRow) ...[
              const SizedBox(height: 2.0),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (connectLabelState is! ConnectLabelIdle)
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
                    if (connectLabelState is! ConnectLabelIdle)
                      const SizedBox(width: 6.0),
                    _InlineBadgePill(
                      key: const ValueKey<String>(
                        'mini_player_listen_along_badge',
                      ),
                      label: listenAlong,
                      color: ConnectEncoreTheme.brightAccent,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      );
    }

    // Mode 2 (`d9i0.TwoLineMetadata`):
    // Line 1 = Title (13sp Bold #FFFFFF), Line 2 = Badges + Artist (13sp Regular #B3FFFFFF)
    // OR Promo disclosure (`11sp Regular #B3FFFFFF`).
    final List<Widget> badgeWidgets = _buildSubtitleBadgeWidgets();

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
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
      ),
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

    return SizedBox(
      width: 52.0,
      height: ConnectEncoreTheme.miniPlayerActionButtonSize,
      child: Center(
        child: Padding(
          key: const ValueKey<String>('mini_player_skippable_ad_button'),
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Material(
            color: ConnectEncoreTheme.tintedBase,
            borderRadius: BorderRadius.circular(4.0),
            child: InkWell(
              onTap: adConfig.canSkip ? adConfig.onSkip : null,
              borderRadius: BorderRadius.circular(4.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 6.0,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ConnectEncoreTheme.caption11Bold.copyWith(
                    color: adConfig.canSkip
                        ? ConnectEncoreTheme.textBase
                        : ConnectEncoreTheme.textSubdued,
                  ),
                ),
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
    return Semantics(
      value: '${(progress * 100).round()}%',
      child: SizedBox(
        height: ConnectEncoreTheme.miniPlayerProgressHeight,
        child: CustomPaint(
          painter: _MiniPlayerProgressPainter(progress: progress),
        ),
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
