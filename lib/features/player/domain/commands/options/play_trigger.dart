// 1:1 replica of com.spotify.player.model.command.options.PlayTrigger

enum PlayTrigger {
  immediately,
  advancedPastTrack,
  advancedPastContext;

  static PlayTrigger fromString(String value) {
    switch (value.toUpperCase()) {
      case 'IMMEDIATELY':
        return PlayTrigger.immediately;
      case 'ADVANCED_PAST_TRACK':
        return PlayTrigger.advancedPastTrack;
      case 'ADVANCED_PAST_CONTEXT':
        return PlayTrigger.advancedPastContext;
      default:
        throw FormatException('Unknown PlayTrigger: $value');
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
