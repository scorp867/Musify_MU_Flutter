// 1:1 replica of com.spotify.player.model.Restrictions

import 'dart:collection';

class RestrictionReasons {
  final Set<String> reasons;

  const RestrictionReasons({this.reasons = const <String>{}});

  static RestrictionReasonsBuilder builder() => RestrictionReasonsBuilder();

  RestrictionReasonsBuilder toBuilder() => RestrictionReasonsBuilder(reasons);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RestrictionReasons &&
          other.reasons.length == reasons.length &&
          other.reasons.containsAll(reasons));

  @override
  int get hashCode => Object.hashAll(reasons) ^ 1000003;

  @override
  String toString() => 'RestrictionReasons{reasons=$reasons}';
}

class RestrictionReasonsBuilder {
  Set<String> _reasons;

  RestrictionReasonsBuilder([Set<String>? reasons])
      : _reasons = reasons != null ? Set<String>.from(reasons) : <String>{};

  RestrictionReasonsBuilder reasons(Set<String> set) {
    _reasons = Set<String>.from(set);
    return this;
  }

  RestrictionReasons build() =>
      RestrictionReasons(reasons: UnmodifiableSetView<String>(_reasons));
}

class ModeRestrictions {
  final Map<String, RestrictionReasons> values;

  const ModeRestrictions({this.values = const <String, RestrictionReasons>{}});

  static ModeRestrictionsBuilder builder() => ModeRestrictionsBuilder();

  ModeRestrictionsBuilder toBuilder() => ModeRestrictionsBuilder(values);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModeRestrictions && _mapEquals(other.values, values));

  @override
  int get hashCode =>
      Object.hashAll(values.entries.map((e) => Object.hash(e.key, e.value))) ^
      1000003;

  @override
  String toString() => 'ModeRestrictions{values=$values}';

  static bool _mapEquals(
    Map<String, RestrictionReasons> a,
    Map<String, RestrictionReasons> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
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

  ModeRestrictionsBuilder values(Map<String, RestrictionReasons> map) {
    _values = Map<String, RestrictionReasons>.from(map);
    return this;
  }

  ModeRestrictions build() =>
      ModeRestrictions(values: UnmodifiableMapView<String, RestrictionReasons>(_values));
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Restrictions &&
          _setEquals(disallowPausingReasons, other.disallowPausingReasons) &&
          _setEquals(disallowResumingReasons, other.disallowResumingReasons) &&
          _setEquals(disallowSeekingReasons, other.disallowSeekingReasons) &&
          _setEquals(disallowPeekingPrevReasons, other.disallowPeekingPrevReasons) &&
          _setEquals(disallowPeekingNextReasons, other.disallowPeekingNextReasons) &&
          _setEquals(disallowSkippingPrevReasons, other.disallowSkippingPrevReasons) &&
          _setEquals(disallowSkippingNextReasons, other.disallowSkippingNextReasons) &&
          _setEquals(disallowTogglingRepeatContextReasons, other.disallowTogglingRepeatContextReasons) &&
          _setEquals(disallowTogglingRepeatTrackReasons, other.disallowTogglingRepeatTrackReasons) &&
          _setEquals(disallowTogglingShuffleReasons, other.disallowTogglingShuffleReasons) &&
          _setEquals(disallowSetQueueReasons, other.disallowSetQueueReasons) &&
          _setEquals(disallowAddToQueueReasons, other.disallowAddToQueueReasons) &&
          _setEquals(disallowInterruptingPlaybackReasons, other.disallowInterruptingPlaybackReasons) &&
          _setEquals(disallowTransferringPlaybackReasons, other.disallowTransferringPlaybackReasons) &&
          _setEquals(disallowRemoteControlReasons, other.disallowRemoteControlReasons) &&
          _setEquals(disallowInsertingIntoNextTracksReasons, other.disallowInsertingIntoNextTracksReasons) &&
          _setEquals(disallowInsertingIntoContextTracksReasons, other.disallowInsertingIntoContextTracksReasons) &&
          _setEquals(disallowReorderingInNextTracksReasons, other.disallowReorderingInNextTracksReasons) &&
          _setEquals(disallowReorderingInContextTracksReasons, other.disallowReorderingInContextTracksReasons) &&
          _setEquals(disallowRemovingFromNextTracksReasons, other.disallowRemovingFromNextTracksReasons) &&
          _setEquals(disallowRemovingFromContextTracksReasons, other.disallowRemovingFromContextTracksReasons) &&
          _setEquals(disallowUpdatingContextReasons, other.disallowUpdatingContextReasons) &&
          _setEquals(disallowSettingPlaybackSpeedReasons, other.disallowSettingPlaybackSpeedReasons) &&
          _modeMapEquals(disallowSettingModes, other.disallowSettingModes) &&
          _reasonsMapEquals(disallowSignals, other.disallowSignals) &&
          _setEquals(disallowPlayAsNextInQueueReasons, other.disallowPlayAsNextInQueueReasons) &&
          _setEquals(disallowSleepTimerClearReasons, other.disallowSleepTimerClearReasons) &&
          _setEquals(disallowSleepTimerDurationReasons, other.disallowSleepTimerDurationReasons) &&
          _setEquals(disallowSleepTimerEndOfTrackReasons, other.disallowSleepTimerEndOfTrackReasons) &&
          _setEquals(disallowAddToQueueTrackReasons, other.disallowAddToQueueTrackReasons) &&
          _setEquals(disallowTapToPlayTrackInNextTracksReasons, other.disallowTapToPlayTrackInNextTracksReasons) &&
          _setEquals(disallowReorderingTrackInNextTracksReasons, other.disallowReorderingTrackInNextTracksReasons) &&
          _setEquals(disallowReorderingEpisodeInNextTracksReasons, other.disallowReorderingEpisodeInNextTracksReasons) &&
          _setEquals(disallowReorderingEnqueuedTrackInNextTracksReasons, other.disallowReorderingEnqueuedTrackInNextTracksReasons) &&
          _setEquals(disallowReorderingEnqueuedEpisodeInNextTracksReasons, other.disallowReorderingEnqueuedEpisodeInNextTracksReasons) &&
          _setEquals(disallowViewingQueueReasons, other.disallowViewingQueueReasons) &&
          _setEquals(disallowViewingOrderedTracksInNextTracksReasons, other.disallowViewingOrderedTracksInNextTracksReasons) &&
          _setEquals(disallowSwipeNextReasons, other.disallowSwipeNextReasons) &&
          _setEquals(disallowSwipePrevReasons, other.disallowSwipePrevReasons));

  @override
  int get hashCode {
    var result = disallowPausingReasons.hashCode ^ 1000003;
    result = (result * 1000003) ^ disallowResumingReasons.hashCode;
    result = (result * 1000003) ^ disallowSeekingReasons.hashCode;
    result = (result * 1000003) ^ disallowPeekingPrevReasons.hashCode;
    result = (result * 1000003) ^ disallowPeekingNextReasons.hashCode;
    result = (result * 1000003) ^ disallowSkippingPrevReasons.hashCode;
    result = (result * 1000003) ^ disallowSkippingNextReasons.hashCode;
    result = (result * 1000003) ^ disallowTogglingRepeatContextReasons.hashCode;
    result = (result * 1000003) ^ disallowTogglingRepeatTrackReasons.hashCode;
    result = (result * 1000003) ^ disallowTogglingShuffleReasons.hashCode;
    result = (result * 1000003) ^ disallowSetQueueReasons.hashCode;
    result = (result * 1000003) ^ disallowAddToQueueReasons.hashCode;
    result = (result * 1000003) ^ disallowInterruptingPlaybackReasons.hashCode;
    result = (result * 1000003) ^ disallowTransferringPlaybackReasons.hashCode;
    result = (result * 1000003) ^ disallowRemoteControlReasons.hashCode;
    result = (result * 1000003) ^ disallowInsertingIntoNextTracksReasons.hashCode;
    result = (result * 1000003) ^ disallowInsertingIntoContextTracksReasons.hashCode;
    result = (result * 1000003) ^ disallowReorderingInNextTracksReasons.hashCode;
    result = (result * 1000003) ^ disallowReorderingInContextTracksReasons.hashCode;
    result = (result * 1000003) ^ disallowRemovingFromNextTracksReasons.hashCode;
    result = (result * 1000003) ^ disallowRemovingFromContextTracksReasons.hashCode;
    result = (result * 1000003) ^ disallowUpdatingContextReasons.hashCode;
    result = (result * 1000003) ^ disallowSettingPlaybackSpeedReasons.hashCode;
    result = (result * 1000003) ^ disallowSettingModes.hashCode;
    result = (result * 1000003) ^ disallowSignals.hashCode;
    result = (result * 1000003) ^ disallowPlayAsNextInQueueReasons.hashCode;
    result = (result * 1000003) ^ disallowSleepTimerClearReasons.hashCode;
    result = (result * 1000003) ^ disallowSleepTimerDurationReasons.hashCode;
    result = (result * 1000003) ^ disallowSleepTimerEndOfTrackReasons.hashCode;
    result = (result * 1000003) ^ disallowAddToQueueTrackReasons.hashCode;
    result = (result * 1000003) ^ disallowTapToPlayTrackInNextTracksReasons.hashCode;
    result = (result * 1000003) ^ disallowReorderingTrackInNextTracksReasons.hashCode;
    result = (result * 1000003) ^ disallowReorderingEpisodeInNextTracksReasons.hashCode;
    result = (result * 1000003) ^ disallowReorderingEnqueuedTrackInNextTracksReasons.hashCode;
    result = (result * 1000003) ^ disallowReorderingEnqueuedEpisodeInNextTracksReasons.hashCode;
    result = (result * 1000003) ^ disallowViewingQueueReasons.hashCode;
    result = (result * 1000003) ^ disallowViewingOrderedTracksInNextTracksReasons.hashCode;
    result = (result * 1000003) ^ disallowSwipeNextReasons.hashCode;
    result = (result * 1000003) ^ disallowSwipePrevReasons.hashCode;
    return result;
  }

  @override
  String toString() =>
      'Restrictions{disallowPausingReasons=$disallowPausingReasons, '
      'disallowResumingReasons=$disallowResumingReasons, '
      'disallowSeekingReasons=$disallowSeekingReasons, '
      'disallowPeekingPrevReasons=$disallowPeekingPrevReasons, '
      'disallowPeekingNextReasons=$disallowPeekingNextReasons, '
      'disallowSkippingPrevReasons=$disallowSkippingPrevReasons, '
      'disallowSkippingNextReasons=$disallowSkippingNextReasons, '
      'disallowTogglingRepeatContextReasons=$disallowTogglingRepeatContextReasons, '
      'disallowTogglingRepeatTrackReasons=$disallowTogglingRepeatTrackReasons, '
      'disallowTogglingShuffleReasons=$disallowTogglingShuffleReasons, '
      'disallowSetQueueReasons=$disallowSetQueueReasons, '
      'disallowAddToQueueReasons=$disallowAddToQueueReasons, '
      'disallowInterruptingPlaybackReasons=$disallowInterruptingPlaybackReasons, '
      'disallowTransferringPlaybackReasons=$disallowTransferringPlaybackReasons, '
      'disallowRemoteControlReasons=$disallowRemoteControlReasons, '
      'disallowInsertingIntoNextTracksReasons=$disallowInsertingIntoNextTracksReasons, '
      'disallowInsertingIntoContextTracksReasons=$disallowInsertingIntoContextTracksReasons, '
      'disallowReorderingInNextTracksReasons=$disallowReorderingInNextTracksReasons, '
      'disallowReorderingInContextTracksReasons=$disallowReorderingInContextTracksReasons, '
      'disallowRemovingFromNextTracksReasons=$disallowRemovingFromNextTracksReasons, '
      'disallowRemovingFromContextTracksReasons=$disallowRemovingFromContextTracksReasons, '
      'disallowUpdatingContextReasons=$disallowUpdatingContextReasons, '
      'disallowSettingPlaybackSpeedReasons=$disallowSettingPlaybackSpeedReasons, '
      'disallowSettingModes=$disallowSettingModes, '
      'disallowSignals=$disallowSignals, '
      'disallowPlayAsNextInQueueReasons=$disallowPlayAsNextInQueueReasons, '
      'disallowSleepTimerClearReasons=$disallowSleepTimerClearReasons, '
      'disallowSleepTimerDurationReasons=$disallowSleepTimerDurationReasons, '
      'disallowSleepTimerEndOfTrackReasons=$disallowSleepTimerEndOfTrackReasons, '
      'disallowAddToQueueTrackReasons=$disallowAddToQueueTrackReasons, '
      'disallowTapToPlayTrackInNextTracksReasons=$disallowTapToPlayTrackInNextTracksReasons, '
      'disallowReorderingTrackInNextTracksReasons=$disallowReorderingTrackInNextTracksReasons, '
      'disallowReorderingEpisodeInNextTracksReasons=$disallowReorderingEpisodeInNextTracksReasons, '
      'disallowReorderingEnqueuedTrackInNextTracksReasons=$disallowReorderingEnqueuedTrackInNextTracksReasons, '
      'disallowReorderingEnqueuedEpisodeInNextTracksReasons=$disallowReorderingEnqueuedEpisodeInNextTracksReasons, '
      'disallowViewingQueueReasons=$disallowViewingQueueReasons, '
      'disallowViewingOrderedTracksInNextTracksReasons=$disallowViewingOrderedTracksInNextTracksReasons, '
      'disallowSwipeNextReasons=$disallowSwipeNextReasons, '
      'disallowSwipePrevReasons=$disallowSwipePrevReasons}';

  static bool _setEquals(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  static bool _modeMapEquals(
    Map<String, ModeRestrictions> a,
    Map<String, ModeRestrictions> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static bool _reasonsMapEquals(
    Map<String, RestrictionReasons> a,
    Map<String, RestrictionReasons> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
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
    if (disallowPausingReasons != null) {
      _disallowPausingReasons = Set<String>.from(disallowPausingReasons);
    }
    if (disallowResumingReasons != null) {
      _disallowResumingReasons = Set<String>.from(disallowResumingReasons);
    }
    if (disallowSeekingReasons != null) {
      _disallowSeekingReasons = Set<String>.from(disallowSeekingReasons);
    }
    if (disallowPeekingPrevReasons != null) {
      _disallowPeekingPrevReasons = Set<String>.from(disallowPeekingPrevReasons);
    }
    if (disallowPeekingNextReasons != null) {
      _disallowPeekingNextReasons = Set<String>.from(disallowPeekingNextReasons);
    }
    if (disallowSkippingPrevReasons != null) {
      _disallowSkippingPrevReasons = Set<String>.from(disallowSkippingPrevReasons);
    }
    if (disallowSkippingNextReasons != null) {
      _disallowSkippingNextReasons = Set<String>.from(disallowSkippingNextReasons);
    }
    if (disallowSwipeNextReasons != null) {
      _disallowSwipeNextReasons = Set<String>.from(disallowSwipeNextReasons);
    }
    if (disallowSwipePrevReasons != null) {
      _disallowSwipePrevReasons = Set<String>.from(disallowSwipePrevReasons);
    }
    if (disallowTogglingRepeatContextReasons != null) {
      _disallowTogglingRepeatContextReasons =
          Set<String>.from(disallowTogglingRepeatContextReasons);
    }
    if (disallowTogglingRepeatTrackReasons != null) {
      _disallowTogglingRepeatTrackReasons =
          Set<String>.from(disallowTogglingRepeatTrackReasons);
    }
    if (disallowTogglingShuffleReasons != null) {
      _disallowTogglingShuffleReasons =
          Set<String>.from(disallowTogglingShuffleReasons);
    }
    if (disallowSetQueueReasons != null) {
      _disallowSetQueueReasons = Set<String>.from(disallowSetQueueReasons);
    }
    if (disallowAddToQueueReasons != null) {
      _disallowAddToQueueReasons = Set<String>.from(disallowAddToQueueReasons);
    }
    if (disallowAddToQueueTrackReasons != null) {
      _disallowAddToQueueTrackReasons =
          Set<String>.from(disallowAddToQueueTrackReasons);
    }
    if (disallowInterruptingPlaybackReasons != null) {
      _disallowInterruptingPlaybackReasons =
          Set<String>.from(disallowInterruptingPlaybackReasons);
    }
    if (disallowTransferringPlaybackReasons != null) {
      _disallowTransferringPlaybackReasons =
          Set<String>.from(disallowTransferringPlaybackReasons);
    }
    if (disallowRemoteControlReasons != null) {
      _disallowRemoteControlReasons =
          Set<String>.from(disallowRemoteControlReasons);
    }
    if (disallowInsertingIntoNextTracksReasons != null) {
      _disallowInsertingIntoNextTracksReasons =
          Set<String>.from(disallowInsertingIntoNextTracksReasons);
    }
    if (disallowInsertingIntoContextTracksReasons != null) {
      _disallowInsertingIntoContextTracksReasons =
          Set<String>.from(disallowInsertingIntoContextTracksReasons);
    }
    if (disallowReorderingInNextTracksReasons != null) {
      _disallowReorderingInNextTracksReasons =
          Set<String>.from(disallowReorderingInNextTracksReasons);
    }
    if (disallowReorderingInContextTracksReasons != null) {
      _disallowReorderingInContextTracksReasons =
          Set<String>.from(disallowReorderingInContextTracksReasons);
    }
    if (disallowRemovingFromNextTracksReasons != null) {
      _disallowRemovingFromNextTracksReasons =
          Set<String>.from(disallowRemovingFromNextTracksReasons);
    }
    if (disallowRemovingFromContextTracksReasons != null) {
      _disallowRemovingFromContextTracksReasons =
          Set<String>.from(disallowRemovingFromContextTracksReasons);
    }
    if (disallowUpdatingContextReasons != null) {
      _disallowUpdatingContextReasons =
          Set<String>.from(disallowUpdatingContextReasons);
    }
    if (disallowSettingPlaybackSpeedReasons != null) {
      _disallowSettingPlaybackSpeedReasons =
          Set<String>.from(disallowSettingPlaybackSpeedReasons);
    }
    if (disallowSettingModes != null) {
      _disallowSettingModes =
          Map<String, ModeRestrictions>.from(disallowSettingModes);
    }
    if (disallowSignals != null) {
      _disallowSignals =
          Map<String, RestrictionReasons>.from(disallowSignals);
    }
    if (disallowPlayAsNextInQueueReasons != null) {
      _disallowPlayAsNextInQueueReasons =
          Set<String>.from(disallowPlayAsNextInQueueReasons);
    }
    if (disallowSleepTimerClearReasons != null) {
      _disallowSleepTimerClearReasons =
          Set<String>.from(disallowSleepTimerClearReasons);
    }
    if (disallowSleepTimerDurationReasons != null) {
      _disallowSleepTimerDurationReasons =
          Set<String>.from(disallowSleepTimerDurationReasons);
    }
    if (disallowSleepTimerEndOfTrackReasons != null) {
      _disallowSleepTimerEndOfTrackReasons =
          Set<String>.from(disallowSleepTimerEndOfTrackReasons);
    }
    if (disallowTapToPlayTrackInNextTracksReasons != null) {
      _disallowTapToPlayTrackInNextTracksReasons =
          Set<String>.from(disallowTapToPlayTrackInNextTracksReasons);
    }
    if (disallowReorderingTrackInNextTracksReasons != null) {
      _disallowReorderingTrackInNextTracksReasons =
          Set<String>.from(disallowReorderingTrackInNextTracksReasons);
    }
    if (disallowReorderingEpisodeInNextTracksReasons != null) {
      _disallowReorderingEpisodeInNextTracksReasons =
          Set<String>.from(disallowReorderingEpisodeInNextTracksReasons);
    }
    if (disallowReorderingEnqueuedTrackInNextTracksReasons != null) {
      _disallowReorderingEnqueuedTrackInNextTracksReasons =
          Set<String>.from(disallowReorderingEnqueuedTrackInNextTracksReasons);
    }
    if (disallowReorderingEnqueuedEpisodeInNextTracksReasons != null) {
      _disallowReorderingEnqueuedEpisodeInNextTracksReasons =
          Set<String>.from(disallowReorderingEnqueuedEpisodeInNextTracksReasons);
    }
    if (disallowViewingQueueReasons != null) {
      _disallowViewingQueueReasons =
          Set<String>.from(disallowViewingQueueReasons);
    }
    if (disallowViewingOrderedTracksInNextTracksReasons != null) {
      _disallowViewingOrderedTracksInNextTracksReasons =
          Set<String>.from(disallowViewingOrderedTracksInNextTracksReasons);
    }
  }

  RestrictionsBuilder disallowPausingReasons(Set<String> set) {
    _disallowPausingReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowResumingReasons(Set<String> set) {
    _disallowResumingReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowSeekingReasons(Set<String> set) {
    _disallowSeekingReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowPeekingPrevReasons(Set<String> set) {
    _disallowPeekingPrevReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowPeekingNextReasons(Set<String> set) {
    _disallowPeekingNextReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowSkippingPrevReasons(Set<String> set) {
    _disallowSkippingPrevReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowSkippingNextReasons(Set<String> set) {
    _disallowSkippingNextReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowSwipeNextReasons(Set<String> set) {
    _disallowSwipeNextReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowSwipePrevReasons(Set<String> set) {
    _disallowSwipePrevReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowTogglingRepeatContextReasons(Set<String> set) {
    _disallowTogglingRepeatContextReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowTogglingRepeatTrackReasons(Set<String> set) {
    _disallowTogglingRepeatTrackReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowTogglingShuffleReasons(Set<String> set) {
    _disallowTogglingShuffleReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowSetQueueReasons(Set<String> set) {
    _disallowSetQueueReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowAddToQueueReasons(Set<String> set) {
    _disallowAddToQueueReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowAddToQueueTrackReasons(Set<String> set) {
    _disallowAddToQueueTrackReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowInterruptingPlaybackReasons(Set<String> set) {
    _disallowInterruptingPlaybackReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowTransferringPlaybackReasons(Set<String> set) {
    _disallowTransferringPlaybackReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowRemoteControlReasons(Set<String> set) {
    _disallowRemoteControlReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowInsertingIntoNextTracksReasons(Set<String> set) {
    _disallowInsertingIntoNextTracksReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowInsertingIntoContextTracksReasons(Set<String> set) {
    _disallowInsertingIntoContextTracksReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowReorderingInNextTracksReasons(Set<String> set) {
    _disallowReorderingInNextTracksReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowReorderingInContextTracksReasons(Set<String> set) {
    _disallowReorderingInContextTracksReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowRemovingFromNextTracksReasons(Set<String> set) {
    _disallowRemovingFromNextTracksReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowRemovingFromContextTracksReasons(Set<String> set) {
    _disallowRemovingFromContextTracksReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowUpdatingContextReasons(Set<String> set) {
    _disallowUpdatingContextReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowSettingPlaybackSpeedReasons(Set<String> set) {
    _disallowSettingPlaybackSpeedReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowSettingModes(Map<String, ModeRestrictions> map) {
    _disallowSettingModes = Map<String, ModeRestrictions>.from(map);
    return this;
  }

  RestrictionsBuilder disallowSignals(Map<String, RestrictionReasons> map) {
    _disallowSignals = Map<String, RestrictionReasons>.from(map);
    return this;
  }

  RestrictionsBuilder disallowPlayAsNextInQueueReasons(Set<String> set) {
    _disallowPlayAsNextInQueueReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowSleepTimerClearReasons(Set<String> set) {
    _disallowSleepTimerClearReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowSleepTimerDurationReasons(Set<String> set) {
    _disallowSleepTimerDurationReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowSleepTimerEndOfTrackReasons(Set<String> set) {
    _disallowSleepTimerEndOfTrackReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowTapToPlayTrackInNextTracksReasons(Set<String> set) {
    _disallowTapToPlayTrackInNextTracksReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowReorderingTrackInNextTracksReasons(Set<String> set) {
    _disallowReorderingTrackInNextTracksReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowReorderingEpisodeInNextTracksReasons(Set<String> set) {
    _disallowReorderingEpisodeInNextTracksReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowReorderingEnqueuedTrackInNextTracksReasons(Set<String> set) {
    _disallowReorderingEnqueuedTrackInNextTracksReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowReorderingEnqueuedEpisodeInNextTracksReasons(Set<String> set) {
    _disallowReorderingEnqueuedEpisodeInNextTracksReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowViewingQueueReasons(Set<String> set) {
    _disallowViewingQueueReasons = Set<String>.from(set);
    return this;
  }

  RestrictionsBuilder disallowViewingOrderedTracksInNextTracksReasons(Set<String> set) {
    _disallowViewingOrderedTracksInNextTracksReasons = Set<String>.from(set);
    return this;
  }

  Restrictions build() => Restrictions(
        disallowPausingReasons:
            UnmodifiableSetView<String>(_disallowPausingReasons),
        disallowResumingReasons:
            UnmodifiableSetView<String>(_disallowResumingReasons),
        disallowSeekingReasons:
            UnmodifiableSetView<String>(_disallowSeekingReasons),
        disallowPeekingPrevReasons:
            UnmodifiableSetView<String>(_disallowPeekingPrevReasons),
        disallowPeekingNextReasons:
            UnmodifiableSetView<String>(_disallowPeekingNextReasons),
        disallowSkippingPrevReasons:
            UnmodifiableSetView<String>(_disallowSkippingPrevReasons),
        disallowSkippingNextReasons:
            UnmodifiableSetView<String>(_disallowSkippingNextReasons),
        disallowSwipeNextReasons:
            UnmodifiableSetView<String>(_disallowSwipeNextReasons),
        disallowSwipePrevReasons:
            UnmodifiableSetView<String>(_disallowSwipePrevReasons),
        disallowTogglingRepeatContextReasons:
            UnmodifiableSetView<String>(_disallowTogglingRepeatContextReasons),
        disallowTogglingRepeatTrackReasons:
            UnmodifiableSetView<String>(_disallowTogglingRepeatTrackReasons),
        disallowTogglingShuffleReasons:
            UnmodifiableSetView<String>(_disallowTogglingShuffleReasons),
        disallowSetQueueReasons:
            UnmodifiableSetView<String>(_disallowSetQueueReasons),
        disallowAddToQueueReasons:
            UnmodifiableSetView<String>(_disallowAddToQueueReasons),
        disallowAddToQueueTrackReasons:
            UnmodifiableSetView<String>(_disallowAddToQueueTrackReasons),
        disallowInterruptingPlaybackReasons:
            UnmodifiableSetView<String>(_disallowInterruptingPlaybackReasons),
        disallowTransferringPlaybackReasons:
            UnmodifiableSetView<String>(_disallowTransferringPlaybackReasons),
        disallowRemoteControlReasons:
            UnmodifiableSetView<String>(_disallowRemoteControlReasons),
        disallowInsertingIntoNextTracksReasons:
            UnmodifiableSetView<String>(_disallowInsertingIntoNextTracksReasons),
        disallowInsertingIntoContextTracksReasons:
            UnmodifiableSetView<String>(_disallowInsertingIntoContextTracksReasons),
        disallowReorderingInNextTracksReasons:
            UnmodifiableSetView<String>(_disallowReorderingInNextTracksReasons),
        disallowReorderingInContextTracksReasons:
            UnmodifiableSetView<String>(_disallowReorderingInContextTracksReasons),
        disallowRemovingFromNextTracksReasons:
            UnmodifiableSetView<String>(_disallowRemovingFromNextTracksReasons),
        disallowRemovingFromContextTracksReasons:
            UnmodifiableSetView<String>(_disallowRemovingFromContextTracksReasons),
        disallowUpdatingContextReasons:
            UnmodifiableSetView<String>(_disallowUpdatingContextReasons),
        disallowSettingPlaybackSpeedReasons:
            UnmodifiableSetView<String>(_disallowSettingPlaybackSpeedReasons),
        disallowSettingModes:
            UnmodifiableMapView<String, ModeRestrictions>(_disallowSettingModes),
        disallowSignals:
            UnmodifiableMapView<String, RestrictionReasons>(_disallowSignals),
        disallowPlayAsNextInQueueReasons:
            UnmodifiableSetView<String>(_disallowPlayAsNextInQueueReasons),
        disallowSleepTimerClearReasons:
            UnmodifiableSetView<String>(_disallowSleepTimerClearReasons),
        disallowSleepTimerDurationReasons:
            UnmodifiableSetView<String>(_disallowSleepTimerDurationReasons),
        disallowSleepTimerEndOfTrackReasons:
            UnmodifiableSetView<String>(_disallowSleepTimerEndOfTrackReasons),
        disallowTapToPlayTrackInNextTracksReasons:
            UnmodifiableSetView<String>(_disallowTapToPlayTrackInNextTracksReasons),
        disallowReorderingTrackInNextTracksReasons:
            UnmodifiableSetView<String>(_disallowReorderingTrackInNextTracksReasons),
        disallowReorderingEpisodeInNextTracksReasons:
            UnmodifiableSetView<String>(_disallowReorderingEpisodeInNextTracksReasons),
        disallowReorderingEnqueuedTrackInNextTracksReasons:
            UnmodifiableSetView<String>(
                _disallowReorderingEnqueuedTrackInNextTracksReasons),
        disallowReorderingEnqueuedEpisodeInNextTracksReasons:
            UnmodifiableSetView<String>(
                _disallowReorderingEnqueuedEpisodeInNextTracksReasons),
        disallowViewingQueueReasons:
            UnmodifiableSetView<String>(_disallowViewingQueueReasons),
        disallowViewingOrderedTracksInNextTracksReasons:
            UnmodifiableSetView<String>(
                _disallowViewingOrderedTracksInNextTracksReasons),
      );
}
