/// Behavior executed when the Secure Vault transitions to locked state while audio is playing.
///
/// Maps directly to ILockPlaybackStrategy implementations in the presentation/domain boundary.
enum LockPlaybackBehaviorEnum {
  /// Immediately halt playback and evict private tracks from RAM queue.
  stopImmediately(
    id: 'STOP_IMMEDIATELY',
    displayName: 'Stop Immediately',
    description: 'Stop audio playback instantly when the vault locks and clear the queue.',
  ),

  /// Allow the currently playing private track to complete, then stop.
  /// Subsequent private tracks in the queue are blocked from starting.
  finishCurrentTrack(
    id: 'FINISH_CURRENT_TRACK',
    displayName: 'Finish Current Track',
    description: 'Let the currently playing song finish, then pause and clear private queue.',
  ),

  /// Continue playback masked in the background while vault UI locks.
  continueMaskedInBackground(
    id: 'CONTINUE_MASKED_IN_BACKGROUND',
    displayName: 'Continue Masked in Background',
    description: 'Keep playing audio in background with metadata masked while locking the vault UI.',
  );

  /// Canonical serialization identifier.
  final String id;

  /// User-facing display title.
  final String displayName;

  /// Policy description for settings screens.
  final String description;

  const LockPlaybackBehaviorEnum({
    required this.id,
    required this.displayName,
    required this.description,
  });

  /// Evaluates whether audio must stop immediately upon vault lock.
  bool get shouldStopImmediately => this == LockPlaybackBehaviorEnum.stopImmediately;

  /// Evaluates whether the current track should be permitted to finish.
  bool get allowsTrackCompletion => this == LockPlaybackBehaviorEnum.finishCurrentTrack;

  /// Evaluates whether playback continues masked in background.
  bool get allowsBackgroundPlayback => this == LockPlaybackBehaviorEnum.continueMaskedInBackground;

  /// Serializes the policy to its unique identifier string.
  String toJson() => id;

  /// Deserializes a string identifier into [LockPlaybackBehaviorEnum].
  ///
  /// Throws [FormatException] if [id] does not match any variant.
  static LockPlaybackBehaviorEnum fromId(String id) {
    for (final behavior in LockPlaybackBehaviorEnum.values) {
      if (behavior.id == id || behavior.name == id) {
        return behavior;
      }
    }
    throw FormatException(
      'Invalid LockPlaybackBehaviorEnum identifier: "$id". '
      'Valid options are: ${LockPlaybackBehaviorEnum.values.map((v) => v.id).join(', ')}.',
    );
  }

  /// Alias for [fromId] supporting JSON decoding pipelines.
  static LockPlaybackBehaviorEnum fromJson(String json) => fromId(json);
}
