import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/core/ubi/data/lifecycle/page_instance_id_holder.dart';
import 'package:musify_mu/core/ubi/domain/logging/ubi_logger.dart';
import 'package:musify_mu/core/ubi/domain/models/page_instance_id.dart';

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
/// - `p199p.edi0` (NowPlayingMini default view binder)
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
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  Color _currentColor = const Color(0xFF242424);
  bool _isFavorite = false;
  late bool _isPlaying;
  String? _lastExtractedKey;
  late final PageInstanceId _pageInstanceId;
  late final ValueNotifier<double> _progressNotifier;
  late final Ticker _progressTicker;

  LoggingParams? _logMiniPlayerInteraction(
    String elementPath, [
    String actionName = 'hit',
  ]) {
    if (getIt.isRegistered<UbiLogger>()) {
      final ubiLogger = getIt<UbiLogger>();
      final result = ubiLogger.logInteraction(
        UbiInteractionElement(
          elementPath: elementPath,
          actionName: actionName,
        ),
      );
      if (getIt.isRegistered<PlayerLoggingParamsFactory>()) {
        final factory = getIt<PlayerLoggingParamsFactory>();
        return factory.createFromInteractionResult(result);
      }
    }
    return null;
  }

  PageInstanceId get pageInstanceId => _pageInstanceId;

  @override
  void initState() {
    super.initState();
    if (getIt.isRegistered<PageInstanceIdHolder>()) {
      final holder = getIt<PageInstanceIdHolder>();
      _pageInstanceId = PageInstanceIdHolder.generateNew();
      holder.update(_pageInstanceId);
    } else {
      _pageInstanceId = PageInstanceIdHolder.generateNew();
    }

    if (getIt.isRegistered<UbiLogger>()) {
      final ubiLogger = getIt<UbiLogger>();
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
    _extractColor(imageUrl: initialImageUrl);

    final initialProgress = _boundProgress(
      switch (widget.queueBloc?.state.playbackProgress) {
        final p? => p,
        null => widget.progress,
      },
    );
    _progressNotifier = ValueNotifier<double>(initialProgress);

    _progressTicker = createTicker((elapsed) {
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

    if (_isPlaying) {
      _progressTicker.start();
    }

    widget.queueBloc?.addListener(_onQueueStateChanged);
  }

  @override
  void dispose() {
    _progressTicker.dispose();
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
      if (_isPlaying) {
        if (!_progressTicker.isActive) _progressTicker.start();
      } else {
        if (_progressTicker.isActive) _progressTicker.stop();
      }
    }
    if (oldWidget.progress != widget.progress && widget.queueBloc == null) {
      _progressNotifier.value = _boundProgress(widget.progress);
    }
    if (oldWidget.imageUrl != widget.imageUrl) {
      _extractColor(imageUrl: widget.imageUrl);
    }
  }

  void _onQueueStateChanged() {
    if (widget.queueBloc case final bloc?) {
      final state = bloc.state;
      if (state.isPlaying != _isPlaying) {
        setState(() {
          _isPlaying = state.isPlaying;
        });
        if (_isPlaying) {
          if (!_progressTicker.isActive) _progressTicker.start();
        } else {
          if (_progressTicker.isActive) _progressTicker.stop();
        }
      }
      _progressNotifier.value = _boundProgress(state.playbackProgress);
      final resolvedImageUrl = _resolveImageUrl(state);
      _extractColor(imageUrl: resolvedImageUrl);
    }
  }

  String? _resolveImageUrl(PlayerQueueState? state) {
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

  void _extractColor({String? imageUrl}) {
    final key = switch (imageUrl) {
      final url? when url.isNotEmpty => url,
      _ => '',
    };
    if (key.isEmpty || key == _lastExtractedKey) return;
    _lastExtractedKey = key;

    final service = switch (widget.colorService) {
      final s? => s,
      null => getIt.isRegistered<ColorExtractionService>()
          ? getIt<ColorExtractionService>()
          : null,
    };
    if (service == null) return;

    final cached = service.getCached(key);
    if (cached != null) {
      final targetColor = cached.isNeutral ? const Color(0xFF242424) : cached.surface;
      if (_currentColor != targetColor) {
        setState(() {
          _currentColor = targetColor;
        });
      }
      return;
    }

    unawaited(
      service.extract(
        imageUrl: imageUrl,
        cacheKey: key,
      ).then((scheme) {
        if (mounted && _lastExtractedKey == key) {
          final targetColor = scheme.isNeutral ? const Color(0xFF242424) : scheme.surface;
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
    if (progress < 0.0) return 0.0;
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
    final displayTitle = switch (state?.title) {
      final t? when t.isNotEmpty => t,
      _ => widget.title,
    };
    final displayArtist = switch (state?.artist) {
      final a? when a.isNotEmpty => a,
      _ => widget.artist,
    };
    final displayThumbnailUrl = switch (state?.thumbnailImageUrl) {
      final url? when url.isNotEmpty => url,
      _ => switch (state?.imageUrl) {
        final url? when url.isNotEmpty => url,
        _ => widget.imageUrl,
      },
    };
    final highResImageUrl = switch (state?.imageUrl) {
      final url? when url.isNotEmpty => url,
      _ => widget.imageUrl,
    };
    final isPlaying = switch (state?.isPlaying) {
      final playing? => playing,
      null => _isPlaying,
    };

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
          child: Column(
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
                          Text(
                            displayArtist,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.70),
                              fontWeight: FontWeight.w400,
                              fontSize: 11,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        _isFavorite
                            ? Icons.check_circle_rounded
                            : Icons.favorite_border_rounded,
                        color: _isFavorite
                            ? const Color(0xFF1DB954)
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
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPlaying = !_isPlaying;
                        });
                        final lp = _logMiniPlayerInteraction('play_pause_button', 'hit');
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
          ),
        ),
      ),
    );
  }
}
