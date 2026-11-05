library;

import 'package:flutter/widgets.dart';
import '../../features/player/domain/models/context_track.dart';
import '../ubi/data/lifecycle/page_instance_id_holder.dart';
import '../ubi/domain/models/interaction_logging_result.dart';

/// 1:1 replica of Spotify Android `p199p.vgm0` (Navigator interface).
abstract interface class SpotifyNavigator {
  /// 1:1 replica of `p199p.vgm0#mo27228a(String uri, oq70 interactionLoggingResult, Bundle bundle)`.
  /// Navigates to a target URI while binding the originating UBI interaction logging result.
  bool navigateToUri(
    BuildContext context,
    String uri, {
    InteractionLoggingResult? interactionLoggingResult,
    Map<String, dynamic>? extras,
  });

  /// 1:1 replica of `p199p.vgm0#mo27230c()`.
  /// Closes the current screen or overlay and pops back in the navigation stack.
  bool goBack(BuildContext context);

  /// 1:1 replica of `p199p.vgm0#mo27234h(String uri)`.
  /// Convenient single-argument overload for URI navigation.
  bool openUri(BuildContext context, String uri);

  /// Directly plays an entity URI (track, episode, or playlist) without navigating away.
  Future<bool> playUri(BuildContext context, String uri, {ContextTrack? track});

  /// Access to the underlying PageInstanceIdHolder managed by navigation lifecycle.
  PageInstanceIdHolder get pageInstanceIdHolder;
}
