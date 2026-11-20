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
import 'package:musify_mu/features/connect/presentation/screens/device_picker_sheet.dart';
import 'package:musify_mu/features/connect/presentation/widgets/active_device_banner.dart';
import 'package:musify_mu/features/connect/presentation/widgets/device_list_tile.dart';

import '../../application/queue/player_queue_bloc.dart';
import '../../data/logging/player_logging_params_factory.dart';
import '../../data/queue/context_track_extensions.dart';
import '../../domain/commands/options/logging_params.dart';
import '../../domain/models/context_track.dart';
import '../screens/player_screen.dart';
import 'player_artwork.dart';

/// Sleek 1:1 Spotify MiniPlayer matching:
/// - `com.spotify.nowplayingmini.nowplayingmini.NowPlayingMiniMode`
/// - `com.spotify.nowplayingmini.uicomponents.seekbar.FadingSeekBarView`
/// - `com.spotify.nowplayingmini.uicomponents.trackinfo.TrackInfoView`
/// - `p199p.edi0` (NowPlayingMini default view binder, line 207: `connect_entry_point_stub`)
/// - `p199p/bdi0.java` (line 146: `connect_entry_point_stub`)
/// - `p199p/hjn0.java` + `p199p/nfc0.java` (lines 93-109: `connect_destination_button` / `connect_label`)
///
/// Driven directly by pure Mobius Loop Controller `PlayerQueueMobiusController`
/// via [ValueListenableBuilder<PlayerQueueState>].
class MiniPlayer extends StatefulWidget {
  final String title;
  final String artist;
  final String? imageUrl;
  final bool isPlaying;
  final double progress;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onTap;
  final ColorExtractionService? colorService;
  final PlayerQueueMobiusController? queueBloc;
  final ContextTrack? currentTrack;
  final ConnectMobiusController? connectController;
  final ConnectOutputStatusPolicy? outputStatusPolicy;
  final UbiLogger? ubiLogger;
  final PlayerLoggingParamsFactory? loggingParamsFactory;
  final PageInstanceIdHolder? pageInstanceIdHolder;

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
    this.colorService,
    this.queueBloc,
    this.currentTrack,
    this.connectController,
    this.outputStatusPolicy,
    this.ubiLogger,
    this.loggingParamsFactory,
    this.pageInstanceIdHolder,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  static void _noop() {}

  Color _currentColor = const Color(0xFF242424);
  bool _isFavorite = false;
  bool _isPlaying = false;
  String? _lastExtractedKey;
  PageInstanceId _pageInstanceId = PageInstanceIdHolder.generateNew();
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);
  Ticker? _progressTicker;

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
        const UbiImpressionElement(
          elementPath: 'mini_player',
        ),
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

    final ticker = createTicker((elapsed) {
      if (mounted) {
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
    _progressTicker?.dispose();
    _progressTicker = null;
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
    if (oldWidget.isPlaying != widget.isPlaying) {
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
    final key = switch (imageUrl) {
      final url? when url.isNotEmpty => url,
      _ => '',
    };
    if (key.isEmpty) {
      if (_lastExtractedKey != null ||
          _currentColor != const Color(0xFF242424)) {
        _lastExtractedKey = null;
        if (allowSetState && mounted) {
          setState(() {
            _currentColor = const Color(0xFF242424);
          });
        } else {
          _currentColor = const Color(0xFF242424);
        }
      }
      return;
    }
    if (key == _lastExtractedKey) return;
    _lastExtractedKey = key;

    final service = _resolveColorService();
    if (service == null) return;

    final cached = service.getCached(key);
    if (cached != null) {
      final targetColor =
          cached.isNeutral ? const Color(0xFF242424) : cached.surface;
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
                  ? const Color(0xFF242424)
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
    if (!progress.isFinite || progress < 0.0) return 0.0;
    if (progress > 1.0) return 1.0;
    return progress;
  }

  @override
  Widget build(BuildContext context) {
    final bloc = widget.queueBloc;
    if (bloc != null) {
      return ValueListenableBuilder<PlayerQueueState>(
        valueListenable: bloc,
        builder: (context, state, child) {
          return _buildMiniPlayerContent(context, state: state);
        },
      );
    }
    return _buildMiniPlayerContent(context);
  }

  Widget _buildMiniPlayerContent(
    BuildContext context, {
    PlayerQueueState? state,
  }) {
    final isMasked = _isMaskedTrack(state);
    final displayTitle = switch (state?.title) {
      final t? when t.isNotEmpty => t,
      _ => widget.title,
    };
    final displayArtist = switch (state?.artist) {
      final a? when a.isNotEmpty => a,
      _ => widget.artist,
    };
    final displayThumbnailUrl = isMasked
        ? null
        : switch (state?.thumbnailImageUrl) {
            final url? when url.isNotEmpty => url,
            _ => switch (state?.imageUrl) {
              final url? when url.isNotEmpty => url,
              _ => widget.imageUrl,
            },
          };
    final highResImageUrl = isMasked
        ? null
        : switch (state?.imageUrl) {
            final url? when url.isNotEmpty => url,
            _ => widget.imageUrl,
          };
    final isPlaying = switch (state?.isPlaying) {
      final playing? => playing,
      null => _isPlaying,
    };
    final effectiveConnectController = _resolveConnectController();
    final policy = _resolveOutputStatusPolicy();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GestureDetector(
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
        onHorizontalDragEnd: (details) {
          final velocity = switch (details.primaryVelocity) {
            final v? => v,
            null => 0.0,
          };
          if (velocity < -250) {
            final lp = _logMiniPlayerInteraction('swipe_skip_next', 'swipe');
            if (widget.onNext case final onNextAction?) {
              onNextAction();
            } else if (widget.queueBloc case final bloc?) {
              bloc.add(SkipToNextTrackEvent(loggingParams: lp));
            }
          } else if (velocity > 250) {
            final lp = _logMiniPlayerInteraction('swipe_skip_prev', 'swipe');
            if (widget.onPrevious case final onPrevAction?) {
              onPrevAction();
            } else if (widget.queueBloc case final bloc?) {
              bloc.add(SkipToPrevTrackEvent(loggingParams: lp));
            }
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _currentColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: switch (effectiveConnectController) {
            final controller? => ValueListenableBuilder<ConnectState>(
                valueListenable: controller,
                builder: (context, connectState, _) {
                  return _buildMiniPlayerCardBody(
                    context: context,
                    displayTitle: displayTitle,
                    displayArtist: displayArtist,
                    displayThumbnailUrl: displayThumbnailUrl,
                    isPlaying: isPlaying,
                    connectController: controller,
                    connectState: connectState,
                    policy: policy,
                  );
                },
              ),
            null => _buildMiniPlayerCardBody(
                context: context,
                displayTitle: displayTitle,
                displayArtist: displayArtist,
                displayThumbnailUrl: displayThumbnailUrl,
                isPlaying: isPlaying,
                connectController: null,
                connectState: null,
                policy: policy,
              ),
          },
        ),
      ),
    );
  }

  Widget _buildMiniPlayerCardBody({
    required BuildContext context,
    required String displayTitle,
    required String displayArtist,
    required String? displayThumbnailUrl,
    required bool isPlaying,
    required ConnectMobiusController? connectController,
    required ConnectState? connectState,
    required ConnectOutputStatusPolicy policy,
  }) {
    final bool isConnectActive =
        connectState != null && policy.isConnectOutputActive(connectState);
    final bool showBanner =
        connectState != null && policy.shouldShowBanner(connectState);

    final VoidCallback handleConnectTap = switch (connectController) {
      final controller? => () {
          _logMiniPlayerInteraction('connect_destination_button', 'hit');
          DevicePickerSheet.show(
            context,
            controller: controller,
          );
        },
      null => _noop,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: PlayerArtworkImage(
                  imageUrl: displayThumbnailUrl,
                  artworkWidth: 40,
                  artworkHeight: 40,
                  placeholderIconSize: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isConnectActive) ...[
                          const Icon(
                            Icons.graphic_eq_rounded,
                            key: ValueKey<String>(
                              'mini_player_active_output_indicator',
                            ),
                            size: 12,
                            color: kSpotifyConnectGreen,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            displayArtist,
                            style: TextStyle(
                              color: isConnectActive
                                  ? kSpotifyConnectGreen
                                  : Colors.white.withValues(alpha: 0.70),
                              fontWeight: isConnectActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontSize: 11,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                key: const ValueKey<String>('mini_player_connect_button'),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                tooltip: 'Devices',
                icon: Icon(
                  Icons.devices_rounded,
                  color: isConnectActive
                      ? kSpotifyConnectGreen
                      : Colors.white.withValues(alpha: 0.75),
                  size: 20,
                ),
                onPressed: handleConnectTap,
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                icon: Icon(
                  _isFavorite
                      ? Icons.check_circle_rounded
                      : Icons.favorite_border_rounded,
                  color: _isFavorite
                      ? kSpotifyConnectGreen
                      : Colors.white.withValues(alpha: 0.75),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isFavorite = !_isFavorite;
                  });
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  final lp = _logMiniPlayerInteraction(
                    'play_pause_button',
                    'hit',
                  );
                  if (widget.onPlayPause case final onPlayPauseAction?) {
                    onPlayPauseAction();
                  } else if (widget.queueBloc case final bloc?) {
                    bloc.add(TogglePlayPauseEvent(loggingParams: lp));
                  }
                },
              ),
            ],
          ),
        ),
        if (showBanner && connectController != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: ActiveDeviceBanner(
              activeDevice: connectState.activeDevice,
              activeSelfPeripheral: connectState.activeSelfPeripheral,
              selfDevice: connectState.selfDevice,
              devices: connectState.devices,
              transferState: connectState.transferState,
              outputStatusPolicy: policy,
              compact: true,
              showWhenLocalBuiltIn: false,
              onTap: () => DevicePickerSheet.show(
                context,
                controller: connectController,
              ),
            ),
          ),
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          child: RepaintBoundary(
            child: ValueListenableBuilder<double>(
              valueListenable: _progressNotifier,
              builder: (context, currentProgress, _) {
                return LinearProgressIndicator(
                  value: currentProgress,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                  minHeight: 2,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
