library;

import 'package:flutter/foundation.dart';
import 'package:musify_mu/features/player/application/queue/player_queue_state.dart';
import 'package:musify_mu/features/player/data/queue/context_track_extensions.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/presentation/widgets/queue_controls_layout.dart';

/// Strongly-typed, immutable view model representing the complete visual state of
/// Spotify's Now Playing View (NPV). Matches Spotify Android `com.spotify.nowplaying`
/// Component-Model architecture.
@immutable
class NowPlayingViewModel {
  final String trackUri;
  final String trackId;
  final String title;
  final String artist;
  final String album;
  final String? imageUrl;
  final int? songId;
  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final bool isFavorite;
  final QueueShuffleMode shuffleMode;
  final QueueRepeatMode repeatMode;
  final String artistUri;
  final bool canSeek;
  final bool canSkipNext;
  final bool canSkipPrev;

  const NowPlayingViewModel({
    required this.trackUri,
    required this.trackId,
    required this.title,
    required this.artist,
    required this.album,
    this.imageUrl,
    this.songId,
    required this.duration,
    required this.position,
    required this.isPlaying,
    this.isFavorite = false,
    this.shuffleMode = QueueShuffleMode.none,
    this.repeatMode = QueueRepeatMode.none,
    this.artistUri = '',
    this.canSeek = true,
    this.canSkipNext = true,
    this.canSkipPrev = true,
  });

  /// URI prefixes that must never trigger ScrollSita or lyrics network fetches.
  /// Matches Spotify's wi21.java blocklist + ock1.m68144T episode filter.
  static const List<String> nonMusicUriPrefixes = [
    'spotify:ad:',
    'spotify:interruption:',
    'spotify:delimiter',
    'spotify:local:',
    'spotify:meta:',
    'spotify:episode:',
    'spotify:podcast-chapter:',
    'spotify:clip:',
  ];

  static String extractTrackId(ContextTrack? track, int? songId) {
    if (track != null && track.uri.isNotEmpty) {
      for (final prefix in nonMusicUriPrefixes) {
        if (track.uri.startsWith(prefix)) return '';
      }
      if (track.uri.startsWith('spotify:track:')) {
        return track.uri.substring('spotify:track:'.length);
      }
      return track.uri;
    }
    if (songId != null && songId > 0) {
      return songId.toString();
    }
    return '';
  }

  factory NowPlayingViewModel.fromPlayerQueueState(
    PlayerQueueState? state, {
    ContextTrack? fallbackTrack,
    String? fallbackTitle,
    String? fallbackArtist,
    String? fallbackAlbum,
    Duration? fallbackDuration,
    String? fallbackImageUrl,
    int? fallbackSongId,
  }) {
    final track = switch (state?.nowPlaying) {
      final t? => t,
      null => switch (state?.currentTrack) {
        final t? => t,
        null => fallbackTrack,
      },
    };

    final title = switch (track?.title) {
      final t? when t.isNotEmpty => t,
      _ => switch (state?.title) {
          final t? when t.isNotEmpty => t,
          _ => switch (fallbackTitle) {
              final t? when t.isNotEmpty => t,
              _ => 'Musify',
            },
        },
    };

    final artist = switch (track?.artist) {
      final a? when a.isNotEmpty => a,
      _ => switch (state?.artist) {
          final a? when a.isNotEmpty => a,
          _ => switch (fallbackArtist) {
              final a? when a.isNotEmpty => a,
              _ => 'Unknown Artist',
            },
        },
    };

    final album = switch (track?.album) {
      final a? when a.isNotEmpty => a,
      _ => switch (state?.album) {
          final a? when a.isNotEmpty => a,
          _ => switch (fallbackAlbum) {
              final a? when a.isNotEmpty => a,
              _ => '',
            },
        },
    };

    final duration = switch (state) {
      final q? when q.durationMs > 0 => q.currentDuration,
      _ => switch (track?.duration) {
          final dur? => dur,
          null => switch (fallbackDuration) {
              final dur? => dur,
              null => Duration.zero,
            },
        },
    };

    final imageUrl = switch (track?.imageUrl) {
      final url? when url.isNotEmpty => url,
      _ => switch (state?.imageUrl) {
          final url? when url.isNotEmpty => url,
          _ => fallbackImageUrl,
        },
    };

    final songId = switch (track?.songId) {
      final id? when id > 0 => id,
      _ => switch (state?.songId) {
          final id? when id > 0 => id,
          _ => fallbackSongId,
        },
    };

    final isPlaying = switch (state?.isPlaying) {
      final playing? => playing,
      null => false,
    };

    final shuffleMode = switch (state?.isShuffling) {
      true => QueueShuffleMode.all,
      false => QueueShuffleMode.none,
      null => QueueShuffleMode.none,
    };

    final repeatMode = switch (state) {
      final q? when q.repeatTrack => QueueRepeatMode.one,
      final q? when q.repeatContext => QueueRepeatMode.all,
      _ => QueueRepeatMode.none,
    };

    final trackUri = switch (track?.uri) {
      final uri? when uri.isNotEmpty => uri,
      _ => '',
    };

    final artistUri = switch (track?.metadata[ContextTrackMetadata.keyArtistUri]) {
      final uri? => uri,
      null => '',
    };

    final trackId = extractTrackId(track, songId);

    final canSkipNext = switch (state?.canSkipNext) {
      final can? => can,
      null => true,
    };
    final canSkipPrev = switch (state?.canSkipPrevious) {
      final can? => can,
      null => true,
    };

    return NowPlayingViewModel(
      trackUri: trackUri,
      trackId: trackId,
      title: title,
      artist: artist,
      album: album,
      imageUrl: imageUrl,
      songId: songId,
      duration: duration,
      position: switch (state?.currentPosition) {
        final pos? => pos,
        null => Duration.zero,
      },
      isPlaying: isPlaying,
      isFavorite: false,
      shuffleMode: shuffleMode,
      repeatMode: repeatMode,
      artistUri: artistUri,
      canSeek: true,
      canSkipNext: canSkipNext,
      canSkipPrev: canSkipPrev,
    );
  }

  NowPlayingViewModel copyWith({
    String? trackUri,
    String? trackId,
    String? title,
    String? artist,
    String? album,
    String? imageUrl,
    int? songId,
    Duration? duration,
    Duration? position,
    bool? isPlaying,
    bool? isFavorite,
    QueueShuffleMode? shuffleMode,
    QueueRepeatMode? repeatMode,
    String? artistUri,
    bool? canSeek,
    bool? canSkipNext,
    bool? canSkipPrev,
  }) {
    return NowPlayingViewModel(
      trackUri: switch (trackUri) {
        final u? => u,
        null => this.trackUri,
      },
      trackId: switch (trackId) {
        final id? => id,
        null => this.trackId,
      },
      title: switch (title) {
        final t? => t,
        null => this.title,
      },
      artist: switch (artist) {
        final a? => a,
        null => this.artist,
      },
      album: switch (album) {
        final al? => al,
        null => this.album,
      },
      imageUrl: switch (imageUrl) {
        final img? => img,
        null => this.imageUrl,
      },
      songId: switch (songId) {
        final s? => s,
        null => this.songId,
      },
      duration: switch (duration) {
        final d? => d,
        null => this.duration,
      },
      position: switch (position) {
        final p? => p,
        null => this.position,
      },
      isPlaying: switch (isPlaying) {
        final p? => p,
        null => this.isPlaying,
      },
      isFavorite: switch (isFavorite) {
        final f? => f,
        null => this.isFavorite,
      },
      shuffleMode: switch (shuffleMode) {
        final s? => s,
        null => this.shuffleMode,
      },
      repeatMode: switch (repeatMode) {
        final r? => r,
        null => this.repeatMode,
      },
      artistUri: switch (artistUri) {
        final a? => a,
        null => this.artistUri,
      },
      canSeek: switch (canSeek) {
        final c? => c,
        null => this.canSeek,
      },
      canSkipNext: switch (canSkipNext) {
        final c? => c,
        null => this.canSkipNext,
      },
      canSkipPrev: switch (canSkipPrev) {
        final c? => c,
        null => this.canSkipPrev,
      },
    );
  }
}
