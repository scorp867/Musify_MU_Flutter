library;

import '../../../../core/ubi/domain/models/interaction_logging_result.dart';
import '../../../../core/ubi/domain/providers/page_instance_id_provider.dart';
import '../../../player/domain/commands/options/logging_params.dart';

/// 1:1 replica of Spotify `p199p.r93#m75361d` (PlaylistPlayCoordinator).
class PlaylistPlayCoordinator {
  final PageInstanceIdProvider _pageInstanceIdProvider;

  const PlaylistPlayCoordinator(this._pageInstanceIdProvider);

  /// 1:1 replica of Spotify `p199p.r93#m75361d(oq70)`.
  LoggingParams buildLoggingParams(InteractionLoggingResult? interactionResult) {
    final builder = LoggingParams.builder();
    final interactionIdStr =
        interactionResult?.interactionId.value ?? 'unknown';

    final interactionIdBuilder = builder.interactionId(interactionIdStr);
    final commandInitiatedTime = interactionIdBuilder
        .commandInitiatedTime(DateTime.now().millisecondsSinceEpoch);

    final pageInstanceId = _pageInstanceIdProvider.get();
    final pageInstanceIdStr = pageInstanceId?.value ?? 'unknown';

    return commandInitiatedTime.pageInstanceId(pageInstanceIdStr).build();
  }
}
