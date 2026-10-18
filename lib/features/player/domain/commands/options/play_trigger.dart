// 1:1 replica of com.spotify.player.model.command.options.PlayTrigger

enum PlayTrigger {
  immediately,
  advancedPastTrack,
  advancedPastContext;

  static PlayTrigger fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'ADVANCED_PAST_TRACK':
        return PlayTrigger.advancedPastTrack;
      case 'ADVANCED_PAST_CONTEXT':
        return PlayTrigger.advancedPastContext;
      case 'IMMEDIATELY':
      default:
        return PlayTrigger.immediately;
    }
  }

  String toJson() {
    switch (this) {
      case PlayTrigger.immediately:
        return 'IMMEDIATELY';
      case PlayTrigger.advancedPastTrack:
        return 'ADVANCED_PAST_TRACK';
      case PlayTrigger.advancedPastContext:
        return 'ADVANCED_PAST_CONTEXT';
    }
  }
}
