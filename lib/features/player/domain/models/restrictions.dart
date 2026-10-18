// 1:1 replica of com.spotify.player.model.Restrictions

class RestrictionReasons {
  final Set<String> reasons;

  const RestrictionReasons({this.reasons = const <String>{}});

  static RestrictionReasonsBuilder builder() => RestrictionReasonsBuilder();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RestrictionReasons &&
          other.reasons.length == reasons.length &&
          other.reasons.containsAll(reasons));

  @override
  int get hashCode => Object.hashAll(reasons);

  @override
  String toString() => 'RestrictionReasons{reasons=$reasons}';
}

class RestrictionReasonsBuilder {
  Set<String> _reasons;

  RestrictionReasonsBuilder([Set<String>? reasons])
      : _reasons = reasons != null ? Set<String>.from(reasons) : <String>{};

  RestrictionReasonsBuilder reasons(Set<String> val) {
    _reasons = Set<String>.from(val);
    return this;
  }

  RestrictionReasons build() =>
      RestrictionReasons(reasons: Set<String>.unmodifiable(_reasons));
}

class ModeRestrictions {
  final Map<String, RestrictionReasons> values;

  const ModeRestrictions({this.values = const <String, RestrictionReasons>{}});

  static ModeRestrictionsBuilder builder() => ModeRestrictionsBuilder();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModeRestrictions && _mapEquals(other.values, values));

  @override
  int get hashCode => Object.hashAll(values.entries.map((e) => Object.hash(e.key, e.value)));

  @override
  String toString() => 'ModeRestrictions{values=$values}';

  static bool _mapEquals(Map<String, RestrictionReasons> a, Map<String, RestrictionReasons> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (b[key] != a[key]) return false;
    }
    return true;
  }
}

class ModeRestrictionsBuilder {
  Map<String, RestrictionReasons> _values;

  ModeRestrictionsBuilder([Map<String, RestrictionReasons>? values])
      : _values = values != null
            ? Map<String, RestrictionReasons>.from(values)
            : <String, RestrictionReasons>{};

  ModeRestrictionsBuilder values(Map<String, RestrictionReasons> val) {
    _values = Map<String, RestrictionReasons>.from(val);
    return this;
  }

  ModeRestrictions build() =>
      ModeRestrictions(values: Map<String, RestrictionReasons>.unmodifiable(_values));
}

class Restrictions {
  static final Restrictions empty = builder().build();

  final Set<String> disallowPausingReasons;
  final Set<String> disallowResumingReasons;
  final Set<String> disallowSeekingReasons;
  final Set<String> disallowPeekingPrevReasons;
  final Set<String> disallowPeekingNextReasons;
  final Set<String> disallowSkippingPrevReasons;
  final Set<String> disallowSkippingNextReasons;
  final Set<String> disallowSwipeNextReasons;
  final Set<String> disallowSwipePrevReasons;
  final Set<String> disallowTogglingRepeatContextReasons;
  final Set<String> disallowTogglingRepeatTrackReasons;
  final Set<String> disallowTogglingShuffleReasons;
  final Set<String> disallowSetQueueReasons;
  final Set<String> disallowAddToQueueReasons;
  final Set<String> disallowAddToQueueTrackReasons;
  final Set<String> disallowInterruptingPlaybackReasons;
  final Set<String> disallowTransferringPlaybackReasons;
  final Set<String> disallowRemoteControlReasons;
  final Set<String> disallowInsertingIntoNextTracksReasons;
  final Set<String> disallowInsertingIntoContextTracksReasons;
  final Set<String> disallowReorderingInNextTracksReasons;
  final Set<String> disallowReorderingInContextTracksReasons;
  final Set<String> disallowRemovingFromNextTracksReasons;
  final Set<String> disallowRemovingFromContextTracksReasons;
  final Set<String> disallowUpdatingContextReasons;
  final Set<String> disallowSettingPlaybackSpeedReasons;
  final Map<String, ModeRestrictions> disallowSettingModes;
  final Map<String, RestrictionReasons> disallowSignals;
  final Set<String> disallowPlayAsNextInQueueReasons;
  final Set<String> disallowSleepTimerClearReasons;
  final Set<String> disallowSleepTimerDurationReasons;
  final Set<String> disallowSleepTimerEndOfTrackReasons;
  final Set<String> disallowTapToPlayTrackInNextTracksReasons;
  final Set<String> disallowReorderingTrackInNextTracksReasons;
  final Set<String> disallowReorderingEpisodeInNextTracksReasons;
  final Set<String> disallowReorderingEnqueuedTrackInNextTracksReasons;
  final Set<String> disallowReorderingEnqueuedEpisodeInNextTracksReasons;
  final Set<String> disallowViewingQueueReasons;
  final Set<String> disallowViewingOrderedTracksInNextTracksReasons;

  const Restrictions({
    this.disallowPausingReasons = const <String>{},
    this.disallowResumingReasons = const <String>{},
    this.disallowSeekingReasons = const <String>{},
    this.disallowPeekingPrevReasons = const <String>{},
    this.disallowPeekingNextReasons = const <String>{},
    this.disallowSkippingPrevReasons = const <String>{},
    this.disallowSkippingNextReasons = const <String>{},
    this.disallowSwipeNextReasons = const <String>{},
    this.disallowSwipePrevReasons = const <String>{},
    this.disallowTogglingRepeatContextReasons = const <String>{},
    this.disallowTogglingRepeatTrackReasons = const <String>{},
    this.disallowTogglingShuffleReasons = const <String>{},
    this.disallowSetQueueReasons = const <String>{},
    this.disallowAddToQueueReasons = const <String>{},
    this.disallowAddToQueueTrackReasons = const <String>{},
    this.disallowInterruptingPlaybackReasons = const <String>{},
    this.disallowTransferringPlaybackReasons = const <String>{},
    this.disallowRemoteControlReasons = const <String>{},
    this.disallowInsertingIntoNextTracksReasons = const <String>{},
    this.disallowInsertingIntoContextTracksReasons = const <String>{},
    this.disallowReorderingInNextTracksReasons = const <String>{},
    this.disallowReorderingInContextTracksReasons = const <String>{},
    this.disallowRemovingFromNextTracksReasons = const <String>{},
    this.disallowRemovingFromContextTracksReasons = const <String>{},
    this.disallowUpdatingContextReasons = const <String>{},
    this.disallowSettingPlaybackSpeedReasons = const <String>{},
    this.disallowSettingModes = const <String, ModeRestrictions>{},
    this.disallowSignals = const <String, RestrictionReasons>{},
    this.disallowPlayAsNextInQueueReasons = const <String>{},
    this.disallowSleepTimerClearReasons = const <String>{},
    this.disallowSleepTimerDurationReasons = const <String>{},
    this.disallowSleepTimerEndOfTrackReasons = const <String>{},
    this.disallowTapToPlayTrackInNextTracksReasons = const <String>{},
    this.disallowReorderingTrackInNextTracksReasons = const <String>{},
    this.disallowReorderingEpisodeInNextTracksReasons = const <String>{},
    this.disallowReorderingEnqueuedTrackInNextTracksReasons = const <String>{},
    this.disallowReorderingEnqueuedEpisodeInNextTracksReasons = const <String>{},
    this.disallowViewingQueueReasons = const <String>{},
    this.disallowViewingOrderedTracksInNextTracksReasons = const <String>{},
  });

  static RestrictionsBuilder builder() => RestrictionsBuilder();

  RestrictionsBuilder toBuilder() => RestrictionsBuilder(
        disallowPausingReasons: disallowPausingReasons,
        disallowResumingReasons: disallowResumingReasons,
        disallowSeekingReasons: disallowSeekingReasons,
        disallowPeekingPrevReasons: disallowPeekingPrevReasons,
        disallowPeekingNextReasons: disallowPeekingNextReasons,
        disallowSkippingPrevReasons: disallowSkippingPrevReasons,
        disallowSkippingNextReasons: disallowSkippingNextReasons,
        disallowSwipeNextReasons: disallowSwipeNextReasons,
        disallowSwipePrevReasons: disallowSwipePrevReasons,
        disallowTogglingRepeatContextReasons: disallowTogglingRepeatContextReasons,
        disallowTogglingRepeatTrackReasons: disallowTogglingRepeatTrackReasons,
        disallowTogglingShuffleReasons: disallowTogglingShuffleReasons,
        disallowSetQueueReasons: disallowSetQueueReasons,
        disallowAddToQueueReasons: disallowAddToQueueReasons,
        disallowAddToQueueTrackReasons: disallowAddToQueueTrackReasons,
        disallowInterruptingPlaybackReasons: disallowInterruptingPlaybackReasons,
        disallowTransferringPlaybackReasons: disallowTransferringPlaybackReasons,
        disallowRemoteControlReasons: disallowRemoteControlReasons,
        disallowInsertingIntoNextTracksReasons: disallowInsertingIntoNextTracksReasons,
        disallowInsertingIntoContextTracksReasons: disallowInsertingIntoContextTracksReasons,
        disallowReorderingInNextTracksReasons: disallowReorderingInNextTracksReasons,
        disallowReorderingInContextTracksReasons: disallowReorderingInContextTracksReasons,
        disallowRemovingFromNextTracksReasons: disallowRemovingFromNextTracksReasons,
        disallowRemovingFromContextTracksReasons: disallowRemovingFromContextTracksReasons,
        disallowUpdatingContextReasons: disallowUpdatingContextReasons,
        disallowSettingPlaybackSpeedReasons: disallowSettingPlaybackSpeedReasons,
        disallowSettingModes: disallowSettingModes,
        disallowSignals: disallowSignals,
        disallowPlayAsNextInQueueReasons: disallowPlayAsNextInQueueReasons,
        disallowSleepTimerClearReasons: disallowSleepTimerClearReasons,
        disallowSleepTimerDurationReasons: disallowSleepTimerDurationReasons,
        disallowSleepTimerEndOfTrackReasons: disallowSleepTimerEndOfTrackReasons,
        disallowTapToPlayTrackInNextTracksReasons: disallowTapToPlayTrackInNextTracksReasons,
        disallowReorderingTrackInNextTracksReasons: disallowReorderingTrackInNextTracksReasons,
        disallowReorderingEpisodeInNextTracksReasons: disallowReorderingEpisodeInNextTracksReasons,
        disallowReorderingEnqueuedTrackInNextTracksReasons: disallowReorderingEnqueuedTrackInNextTracksReasons,
        disallowReorderingEnqueuedEpisodeInNextTracksReasons: disallowReorderingEnqueuedEpisodeInNextTracksReasons,
        disallowViewingQueueReasons: disallowViewingQueueReasons,
        disallowViewingOrderedTracksInNextTracksReasons: disallowViewingOrderedTracksInNextTracksReasons,
      );
}

class RestrictionsBuilder {
  Set<String> _disallowPausingReasons = const <String>{};
  Set<String> _disallowResumingReasons = const <String>{};
  Set<String> _disallowSeekingReasons = const <String>{};
  Set<String> _disallowPeekingPrevReasons = const <String>{};
  Set<String> _disallowPeekingNextReasons = const <String>{};
  Set<String> _disallowSkippingPrevReasons = const <String>{};
  Set<String> _disallowSkippingNextReasons = const <String>{};
  Set<String> _disallowSwipeNextReasons = const <String>{};
  Set<String> _disallowSwipePrevReasons = const <String>{};
  Set<String> _disallowTogglingRepeatContextReasons = const <String>{};
  Set<String> _disallowTogglingRepeatTrackReasons = const <String>{};
  Set<String> _disallowTogglingShuffleReasons = const <String>{};
  Set<String> _disallowSetQueueReasons = const <String>{};
  Set<String> _disallowAddToQueueReasons = const <String>{};
  Set<String> _disallowAddToQueueTrackReasons = const <String>{};
  Set<String> _disallowInterruptingPlaybackReasons = const <String>{};
  Set<String> _disallowTransferringPlaybackReasons = const <String>{};
  Set<String> _disallowRemoteControlReasons = const <String>{};
  Set<String> _disallowInsertingIntoNextTracksReasons = const <String>{};
  Set<String> _disallowInsertingIntoContextTracksReasons = const <String>{};
  Set<String> _disallowReorderingInNextTracksReasons = const <String>{};
  Set<String> _disallowReorderingInContextTracksReasons = const <String>{};
  Set<String> _disallowRemovingFromNextTracksReasons = const <String>{};
  Set<String> _disallowRemovingFromContextTracksReasons = const <String>{};
  Set<String> _disallowUpdatingContextReasons = const <String>{};
  Set<String> _disallowSettingPlaybackSpeedReasons = const <String>{};
  Map<String, ModeRestrictions> _disallowSettingModes = const <String, ModeRestrictions>{};
  Map<String, RestrictionReasons> _disallowSignals = const <String, RestrictionReasons>{};
  Set<String> _disallowPlayAsNextInQueueReasons = const <String>{};
  Set<String> _disallowSleepTimerClearReasons = const <String>{};
  Set<String> _disallowSleepTimerDurationReasons = const <String>{};
  Set<String> _disallowSleepTimerEndOfTrackReasons = const <String>{};
  Set<String> _disallowTapToPlayTrackInNextTracksReasons = const <String>{};
  Set<String> _disallowReorderingTrackInNextTracksReasons = const <String>{};
  Set<String> _disallowReorderingEpisodeInNextTracksReasons = const <String>{};
  Set<String> _disallowReorderingEnqueuedTrackInNextTracksReasons = const <String>{};
  Set<String> _disallowReorderingEnqueuedEpisodeInNextTracksReasons = const <String>{};
  Set<String> _disallowViewingQueueReasons = const <String>{};
  Set<String> _disallowViewingOrderedTracksInNextTracksReasons = const <String>{};

  RestrictionsBuilder({
    Set<String>? disallowPausingReasons,
    Set<String>? disallowResumingReasons,
    Set<String>? disallowSeekingReasons,
    Set<String>? disallowPeekingPrevReasons,
    Set<String>? disallowPeekingNextReasons,
    Set<String>? disallowSkippingPrevReasons,
    Set<String>? disallowSkippingNextReasons,
    Set<String>? disallowSwipeNextReasons,
    Set<String>? disallowSwipePrevReasons,
    Set<String>? disallowTogglingRepeatContextReasons,
    Set<String>? disallowTogglingRepeatTrackReasons,
    Set<String>? disallowTogglingShuffleReasons,
    Set<String>? disallowSetQueueReasons,
    Set<String>? disallowAddToQueueReasons,
    Set<String>? disallowAddToQueueTrackReasons,
    Set<String>? disallowInterruptingPlaybackReasons,
    Set<String>? disallowTransferringPlaybackReasons,
    Set<String>? disallowRemoteControlReasons,
    Set<String>? disallowInsertingIntoNextTracksReasons,
    Set<String>? disallowInsertingIntoContextTracksReasons,
    Set<String>? disallowReorderingInNextTracksReasons,
    Set<String>? disallowReorderingInContextTracksReasons,
    Set<String>? disallowRemovingFromNextTracksReasons,
    Set<String>? disallowRemovingFromContextTracksReasons,
    Set<String>? disallowUpdatingContextReasons,
    Set<String>? disallowSettingPlaybackSpeedReasons,
    Map<String, ModeRestrictions>? disallowSettingModes,
    Map<String, RestrictionReasons>? disallowSignals,
    Set<String>? disallowPlayAsNextInQueueReasons,
    Set<String>? disallowSleepTimerClearReasons,
    Set<String>? disallowSleepTimerDurationReasons,
    Set<String>? disallowSleepTimerEndOfTrackReasons,
    Set<String>? disallowTapToPlayTrackInNextTracksReasons,
    Set<String>? disallowReorderingTrackInNextTracksReasons,
    Set<String>? disallowReorderingEpisodeInNextTracksReasons,
    Set<String>? disallowReorderingEnqueuedTrackInNextTracksReasons,
    Set<String>? disallowReorderingEnqueuedEpisodeInNextTracksReasons,
    Set<String>? disallowViewingQueueReasons,
    Set<String>? disallowViewingOrderedTracksInNextTracksReasons,
  }) {
    if (disallowPausingReasons != null) _disallowPausingReasons = Set.from(disallowPausingReasons);
    if (disallowResumingReasons != null) _disallowResumingReasons = Set.from(disallowResumingReasons);
    if (disallowSeekingReasons != null) _disallowSeekingReasons = Set.from(disallowSeekingReasons);
    if (disallowPeekingPrevReasons != null) _disallowPeekingPrevReasons = Set.from(disallowPeekingPrevReasons);
    if (disallowPeekingNextReasons != null) _disallowPeekingNextReasons = Set.from(disallowPeekingNextReasons);
    if (disallowSkippingPrevReasons != null) _disallowSkippingPrevReasons = Set.from(disallowSkippingPrevReasons);
    if (disallowSkippingNextReasons != null) _disallowSkippingNextReasons = Set.from(disallowSkippingNextReasons);
    if (disallowSwipeNextReasons != null) _disallowSwipeNextReasons = Set.from(disallowSwipeNextReasons);
    if (disallowSwipePrevReasons != null) _disallowSwipePrevReasons = Set.from(disallowSwipePrevReasons);
    if (disallowTogglingRepeatContextReasons != null) _disallowTogglingRepeatContextReasons = Set.from(disallowTogglingRepeatContextReasons);
    if (disallowTogglingRepeatTrackReasons != null) _disallowTogglingRepeatTrackReasons = Set.from(disallowTogglingRepeatTrackReasons);
    if (disallowTogglingShuffleReasons != null) _disallowTogglingShuffleReasons = Set.from(disallowTogglingShuffleReasons);
    if (disallowSetQueueReasons != null) _disallowSetQueueReasons = Set.from(disallowSetQueueReasons);
    if (disallowAddToQueueReasons != null) _disallowAddToQueueReasons = Set.from(disallowAddToQueueReasons);
    if (disallowAddToQueueTrackReasons != null) _disallowAddToQueueTrackReasons = Set.from(disallowAddToQueueTrackReasons);
    if (disallowInterruptingPlaybackReasons != null) _disallowInterruptingPlaybackReasons = Set.from(disallowInterruptingPlaybackReasons);
    if (disallowTransferringPlaybackReasons != null) _disallowTransferringPlaybackReasons = Set.from(disallowTransferringPlaybackReasons);
    if (disallowRemoteControlReasons != null) _disallowRemoteControlReasons = Set.from(disallowRemoteControlReasons);
    if (disallowInsertingIntoNextTracksReasons != null) _disallowInsertingIntoNextTracksReasons = Set.from(disallowInsertingIntoNextTracksReasons);
    if (disallowInsertingIntoContextTracksReasons != null) _disallowInsertingIntoContextTracksReasons = Set.from(disallowInsertingIntoContextTracksReasons);
    if (disallowReorderingInNextTracksReasons != null) _disallowReorderingInNextTracksReasons = Set.from(disallowReorderingInNextTracksReasons);
    if (disallowReorderingInContextTracksReasons != null) _disallowReorderingInContextTracksReasons = Set.from(disallowReorderingInContextTracksReasons);
    if (disallowRemovingFromNextTracksReasons != null) _disallowRemovingFromNextTracksReasons = Set.from(disallowRemovingFromNextTracksReasons);
    if (disallowRemovingFromContextTracksReasons != null) _disallowRemovingFromContextTracksReasons = Set.from(disallowRemovingFromContextTracksReasons);
    if (disallowUpdatingContextReasons != null) _disallowUpdatingContextReasons = Set.from(disallowUpdatingContextReasons);
    if (disallowSettingPlaybackSpeedReasons != null) _disallowSettingPlaybackSpeedReasons = Set.from(disallowSettingPlaybackSpeedReasons);
    if (disallowSettingModes != null) _disallowSettingModes = Map.from(disallowSettingModes);
    if (disallowSignals != null) _disallowSignals = Map.from(disallowSignals);
    if (disallowPlayAsNextInQueueReasons != null) _disallowPlayAsNextInQueueReasons = Set.from(disallowPlayAsNextInQueueReasons);
    if (disallowSleepTimerClearReasons != null) _disallowSleepTimerClearReasons = Set.from(disallowSleepTimerClearReasons);
    if (disallowSleepTimerDurationReasons != null) _disallowSleepTimerDurationReasons = Set.from(disallowSleepTimerDurationReasons);
    if (disallowSleepTimerEndOfTrackReasons != null) _disallowSleepTimerEndOfTrackReasons = Set.from(disallowSleepTimerEndOfTrackReasons);
    if (disallowTapToPlayTrackInNextTracksReasons != null) _disallowTapToPlayTrackInNextTracksReasons = Set.from(disallowTapToPlayTrackInNextTracksReasons);
    if (disallowReorderingTrackInNextTracksReasons != null) _disallowReorderingTrackInNextTracksReasons = Set.from(disallowReorderingTrackInNextTracksReasons);
    if (disallowReorderingEpisodeInNextTracksReasons != null) _disallowReorderingEpisodeInNextTracksReasons = Set.from(disallowReorderingEpisodeInNextTracksReasons);
    if (disallowReorderingEnqueuedTrackInNextTracksReasons != null) _disallowReorderingEnqueuedTrackInNextTracksReasons = Set.from(disallowReorderingEnqueuedTrackInNextTracksReasons);
    if (disallowReorderingEnqueuedEpisodeInNextTracksReasons != null) _disallowReorderingEnqueuedEpisodeInNextTracksReasons = Set.from(disallowReorderingEnqueuedEpisodeInNextTracksReasons);
    if (disallowViewingQueueReasons != null) _disallowViewingQueueReasons = Set.from(disallowViewingQueueReasons);
    if (disallowViewingOrderedTracksInNextTracksReasons != null) _disallowViewingOrderedTracksInNextTracksReasons = Set.from(disallowViewingOrderedTracksInNextTracksReasons);
  }

  RestrictionsBuilder disallowPausingReasons(Set<String> val) { _disallowPausingReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowResumingReasons(Set<String> val) { _disallowResumingReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowSeekingReasons(Set<String> val) { _disallowSeekingReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowPeekingPrevReasons(Set<String> val) { _disallowPeekingPrevReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowPeekingNextReasons(Set<String> val) { _disallowPeekingNextReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowSkippingPrevReasons(Set<String> val) { _disallowSkippingPrevReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowSkippingNextReasons(Set<String> val) { _disallowSkippingNextReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowSwipeNextReasons(Set<String> val) { _disallowSwipeNextReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowSwipePrevReasons(Set<String> val) { _disallowSwipePrevReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowTogglingRepeatContextReasons(Set<String> val) { _disallowTogglingRepeatContextReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowTogglingRepeatTrackReasons(Set<String> val) { _disallowTogglingRepeatTrackReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowTogglingShuffleReasons(Set<String> val) { _disallowTogglingShuffleReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowSetQueueReasons(Set<String> val) { _disallowSetQueueReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowAddToQueueReasons(Set<String> val) { _disallowAddToQueueReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowAddToQueueTrackReasons(Set<String> val) { _disallowAddToQueueTrackReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowInterruptingPlaybackReasons(Set<String> val) { _disallowInterruptingPlaybackReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowTransferringPlaybackReasons(Set<String> val) { _disallowTransferringPlaybackReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowRemoteControlReasons(Set<String> val) { _disallowRemoteControlReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowInsertingIntoNextTracksReasons(Set<String> val) { _disallowInsertingIntoNextTracksReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowInsertingIntoContextTracksReasons(Set<String> val) { _disallowInsertingIntoContextTracksReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowReorderingInNextTracksReasons(Set<String> val) { _disallowReorderingInNextTracksReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowReorderingInContextTracksReasons(Set<String> val) { _disallowReorderingInContextTracksReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowRemovingFromNextTracksReasons(Set<String> val) { _disallowRemovingFromNextTracksReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowRemovingFromContextTracksReasons(Set<String> val) { _disallowRemovingFromContextTracksReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowUpdatingContextReasons(Set<String> val) { _disallowUpdatingContextReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowSettingPlaybackSpeedReasons(Set<String> val) { _disallowSettingPlaybackSpeedReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowSettingModes(Map<String, ModeRestrictions> val) { _disallowSettingModes = Map.from(val); return this; }
  RestrictionsBuilder disallowSignals(Map<String, RestrictionReasons> val) { _disallowSignals = Map.from(val); return this; }
  RestrictionsBuilder disallowPlayAsNextInQueueReasons(Set<String> val) { _disallowPlayAsNextInQueueReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowSleepTimerClearReasons(Set<String> val) { _disallowSleepTimerClearReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowSleepTimerDurationReasons(Set<String> val) { _disallowSleepTimerDurationReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowSleepTimerEndOfTrackReasons(Set<String> val) { _disallowSleepTimerEndOfTrackReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowTapToPlayTrackInNextTracksReasons(Set<String> val) { _disallowTapToPlayTrackInNextTracksReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowReorderingTrackInNextTracksReasons(Set<String> val) { _disallowReorderingTrackInNextTracksReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowReorderingEpisodeInNextTracksReasons(Set<String> val) { _disallowReorderingEpisodeInNextTracksReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowReorderingEnqueuedTrackInNextTracksReasons(Set<String> val) { _disallowReorderingEnqueuedTrackInNextTracksReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowReorderingEnqueuedEpisodeInNextTracksReasons(Set<String> val) { _disallowReorderingEnqueuedEpisodeInNextTracksReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowViewingQueueReasons(Set<String> val) { _disallowViewingQueueReasons = Set.from(val); return this; }
  RestrictionsBuilder disallowViewingOrderedTracksInNextTracksReasons(Set<String> val) { _disallowViewingOrderedTracksInNextTracksReasons = Set.from(val); return this; }

  Restrictions build() => Restrictions(
        disallowPausingReasons: Set.unmodifiable(_disallowPausingReasons),
        disallowResumingReasons: Set.unmodifiable(_disallowResumingReasons),
        disallowSeekingReasons: Set.unmodifiable(_disallowSeekingReasons),
        disallowPeekingPrevReasons: Set.unmodifiable(_disallowPeekingPrevReasons),
        disallowPeekingNextReasons: Set.unmodifiable(_disallowPeekingNextReasons),
        disallowSkippingPrevReasons: Set.unmodifiable(_disallowSkippingPrevReasons),
        disallowSkippingNextReasons: Set.unmodifiable(_disallowSkippingNextReasons),
        disallowSwipeNextReasons: Set.unmodifiable(_disallowSwipeNextReasons),
        disallowSwipePrevReasons: Set.unmodifiable(_disallowSwipePrevReasons),
        disallowTogglingRepeatContextReasons: Set.unmodifiable(_disallowTogglingRepeatContextReasons),
        disallowTogglingRepeatTrackReasons: Set.unmodifiable(_disallowTogglingRepeatTrackReasons),
        disallowTogglingShuffleReasons: Set.unmodifiable(_disallowTogglingShuffleReasons),
        disallowSetQueueReasons: Set.unmodifiable(_disallowSetQueueReasons),
        disallowAddToQueueReasons: Set.unmodifiable(_disallowAddToQueueReasons),
        disallowAddToQueueTrackReasons: Set.unmodifiable(_disallowAddToQueueTrackReasons),
        disallowInterruptingPlaybackReasons: Set.unmodifiable(_disallowInterruptingPlaybackReasons),
        disallowTransferringPlaybackReasons: Set.unmodifiable(_disallowTransferringPlaybackReasons),
        disallowRemoteControlReasons: Set.unmodifiable(_disallowRemoteControlReasons),
        disallowInsertingIntoNextTracksReasons: Set.unmodifiable(_disallowInsertingIntoNextTracksReasons),
        disallowInsertingIntoContextTracksReasons: Set.unmodifiable(_disallowInsertingIntoContextTracksReasons),
        disallowReorderingInNextTracksReasons: Set.unmodifiable(_disallowReorderingInNextTracksReasons),
        disallowReorderingInContextTracksReasons: Set.unmodifiable(_disallowReorderingInContextTracksReasons),
        disallowRemovingFromNextTracksReasons: Set.unmodifiable(_disallowRemovingFromNextTracksReasons),
        disallowRemovingFromContextTracksReasons: Set.unmodifiable(_disallowRemovingFromContextTracksReasons),
        disallowUpdatingContextReasons: Set.unmodifiable(_disallowUpdatingContextReasons),
        disallowSettingPlaybackSpeedReasons: Set.unmodifiable(_disallowSettingPlaybackSpeedReasons),
        disallowSettingModes: Map.unmodifiable(_disallowSettingModes),
        disallowSignals: Map.unmodifiable(_disallowSignals),
        disallowPlayAsNextInQueueReasons: Set.unmodifiable(_disallowPlayAsNextInQueueReasons),
        disallowSleepTimerClearReasons: Set.unmodifiable(_disallowSleepTimerClearReasons),
        disallowSleepTimerDurationReasons: Set.unmodifiable(_disallowSleepTimerDurationReasons),
        disallowSleepTimerEndOfTrackReasons: Set.unmodifiable(_disallowSleepTimerEndOfTrackReasons),
        disallowTapToPlayTrackInNextTracksReasons: Set.unmodifiable(_disallowTapToPlayTrackInNextTracksReasons),
        disallowReorderingTrackInNextTracksReasons: Set.unmodifiable(_disallowReorderingTrackInNextTracksReasons),
        disallowReorderingEpisodeInNextTracksReasons: Set.unmodifiable(_disallowReorderingEpisodeInNextTracksReasons),
        disallowReorderingEnqueuedTrackInNextTracksReasons: Set.unmodifiable(_disallowReorderingEnqueuedTrackInNextTracksReasons),
        disallowReorderingEnqueuedEpisodeInNextTracksReasons: Set.unmodifiable(_disallowReorderingEnqueuedEpisodeInNextTracksReasons),
        disallowViewingQueueReasons: Set.unmodifiable(_disallowViewingQueueReasons),
        disallowViewingOrderedTracksInNextTracksReasons: Set.unmodifiable(_disallowViewingOrderedTracksInNextTracksReasons),
      );
}
