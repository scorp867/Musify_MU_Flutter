// 1:1 replica of com.spotify.player.model.ErrorType

enum ErrorType {
  success,
  playTokenLost,
  playbackStuck,
  playbackStartSlow,
  playbackStartTimeout,
  playbackStuckTimeout,
  playbackClientVersionIsSunsetted,
  playbackError,
  licenseChange,
  playbackReportingError,
  trackUnavailableOffline,
  contextPageMalformedData,
  contextPageMiscError,
  contextPageNotFound,
  playRestricted,
  stopRestricted,
  updateRestricted,
  pauseRestricted,
  resumeRestricted,
  skipToPrevRestricted,
  skipToNextRestricted,
  skipToNonExistentTrack,
  skipToNonExistentTrackAutoStopped,
  toggleRepeatContextRestricted,
  toggleRepeatTrackRestricted,
  toggleShuffleRestricted,
  setOptionsRestricted,
  setQueueRestricted,
  addToQueueRestricted,
  interruptPlaybackRestricted,
  seekToRestricted,
  oneTrackUnplayable,
  oneTrackUnplayableAutoStopped,
  allTracksUnplayableAutoStopped,
  queueRevisionMismatch,
  videoPlaybackError,
  videoGeorestricted,
  videoUnsupportedPlatformVersion,
  videoUnsupportedClientVersion,
  videoUnsupportedKeyVersion,
  videoCountryRestricted,
  videoUnavailable,
  videoCatalogueRestricted,
  videoManifestDeleted,
  pickAndShuffleCapped,
  pickAndShuffleConnectRestricted,
  contextLoadingFailed,
  audiobookNotPlayable,
  signalNotAvailable,
  setSleepTimerRestricted,
  timeout,
  invalid,
  unknown;

  static ErrorType fromString(String? value) {
    if (value == null) return ErrorType.unknown;
    for (final type in ErrorType.values) {
      if (type.toJson().toLowerCase() == value.toLowerCase()) {
        return type;
      }
    }
    return ErrorType.unknown;
  }

  String toJson() {
    switch (this) {
      case ErrorType.success:
        return 'SUCCESS';
      case ErrorType.playTokenLost:
        return 'PLAY_TOKEN_LOST';
      case ErrorType.playbackStuck:
        return 'PLAYBACK_STUCK';
      case ErrorType.playbackStartSlow:
        return 'PLAYBACK_START_SLOW';
      case ErrorType.playbackStartTimeout:
        return 'PLAYBACK_START_TIMEOUT';
      case ErrorType.playbackStuckTimeout:
        return 'PLAYBACK_STUCK_TIMEOUT';
      case ErrorType.playbackClientVersionIsSunsetted:
        return 'PLAYBACK_CLIENT_VERSION_IS_SUNSETTED';
      case ErrorType.playbackError:
        return 'PLAYBACK_ERROR';
      case ErrorType.licenseChange:
        return 'LICENSE_CHANGE';
      case ErrorType.playbackReportingError:
        return 'PLAYBACK_REPORTING_ERROR';
      case ErrorType.trackUnavailableOffline:
        return 'TRACK_UNAVAILABLE_OFFLINE';
      case ErrorType.contextPageMalformedData:
        return 'CONTEXT_PAGE_MALFORMED_DATA';
      case ErrorType.contextPageMiscError:
        return 'CONTEXT_PAGE_MISC_ERROR';
      case ErrorType.contextPageNotFound:
        return 'CONTEXT_PAGE_NOT_FOUND';
      case ErrorType.playRestricted:
        return 'PLAY_RESTRICTED';
      case ErrorType.stopRestricted:
        return 'STOP_RESTRICTED';
      case ErrorType.updateRestricted:
        return 'UPDATE_RESTRICTED';
      case ErrorType.pauseRestricted:
        return 'PAUSE_RESTRICTED';
      case ErrorType.resumeRestricted:
        return 'RESUME_RESTRICTED';
      case ErrorType.skipToPrevRestricted:
        return 'SKIP_TO_PREV_RESTRICTED';
      case ErrorType.skipToNextRestricted:
        return 'SKIP_TO_NEXT_RESTRICTED';
      case ErrorType.skipToNonExistentTrack:
        return 'SKIP_TO_NON_EXISTENT_TRACK';
      case ErrorType.skipToNonExistentTrackAutoStopped:
        return 'SKIP_TO_NON_EXISTENT_TRACK_AUTO_STOPPED';
      case ErrorType.toggleRepeatContextRestricted:
        return 'TOGGLE_REPEAT_CONTEXT_RESTRICTED';
      case ErrorType.toggleRepeatTrackRestricted:
        return 'TOGGLE_REPEAT_TRACK_RESTRICTED';
      case ErrorType.toggleShuffleRestricted:
        return 'TOGGLE_SHUFFLE_RESTRICTED';
      case ErrorType.setOptionsRestricted:
        return 'SET_OPTIONS_RESTRICTED';
      case ErrorType.setQueueRestricted:
        return 'SET_QUEUE_RESTRICTED';
      case ErrorType.addToQueueRestricted:
        return 'ADD_TO_QUEUE_RESTRICTED';
      case ErrorType.interruptPlaybackRestricted:
        return 'INTERRUPT_PLAYBACK_RESTRICTED';
      case ErrorType.seekToRestricted:
        return 'SEEK_TO_RESTRICTED';
      case ErrorType.oneTrackUnplayable:
        return 'ONE_TRACK_UNPLAYABLE';
      case ErrorType.oneTrackUnplayableAutoStopped:
        return 'ONE_TRACK_UNPLAYABLE_AUTO_STOPPED';
      case ErrorType.allTracksUnplayableAutoStopped:
        return 'ALL_TRACKS_UNPLAYABLE_AUTO_STOPPED';
      case ErrorType.queueRevisionMismatch:
        return 'QUEUE_REVISION_MISMATCH';
      case ErrorType.videoPlaybackError:
        return 'VIDEO_PLAYBACK_ERROR';
      case ErrorType.videoGeorestricted:
        return 'VIDEO_GEORESTRICTED';
      case ErrorType.videoUnsupportedPlatformVersion:
        return 'VIDEO_UNSUPPORTED_PLATFORM_VERSION';
      case ErrorType.videoUnsupportedClientVersion:
        return 'VIDEO_UNSUPPORTED_CLIENT_VERSION';
      case ErrorType.videoUnsupportedKeyVersion:
        return 'VIDEO_UNSUPPORTED_KEY_VERSION';
      case ErrorType.videoCountryRestricted:
        return 'VIDEO_COUNTRY_RESTRICTED';
      case ErrorType.videoUnavailable:
        return 'VIDEO_UNAVAILABLE';
      case ErrorType.videoCatalogueRestricted:
        return 'VIDEO_CATALOGUE_RESTRICTED';
      case ErrorType.videoManifestDeleted:
        return 'VIDEO_MANIFEST_DELETED';
      case ErrorType.pickAndShuffleCapped:
        return 'PICK_AND_SHUFFLE_CAPPED';
      case ErrorType.pickAndShuffleConnectRestricted:
        return 'PICK_AND_SHUFFLE_CONNECT_RESTRICTED';
      case ErrorType.contextLoadingFailed:
        return 'CONTEXT_LOADING_FAILED';
      case ErrorType.audiobookNotPlayable:
        return 'AUDIOBOOK_NOT_PLAYABLE';
      case ErrorType.signalNotAvailable:
        return 'SIGNAL_NOT_AVAILABLE';
      case ErrorType.setSleepTimerRestricted:
        return 'SET_SLEEP_TIMER_RESTRICTED';
      case ErrorType.timeout:
        return 'TIMEOUT';
      case ErrorType.invalid:
        return 'INVALID';
      case ErrorType.unknown:
        return 'UNKNOWN';
    }
  }
}
