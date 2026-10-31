library;

import '../../../../core/ubi/domain/models/interaction_logging_result.dart';
import '../../../../core/ubi/domain/providers/page_instance_id_provider.dart';
import '../../domain/commands/options/logging_params.dart';

/// 1:1 replica of Spotify `p199p.zpl` (PlayerLoggingParamsFactory).
class PlayerLoggingParamsFactory {
  final PageInstanceIdProvider _pageInstanceIdProvider;

  const PlayerLoggingParamsFactory(this._pageInstanceIdProvider);

  /// 1:1 replica of `p199p.zpl#m98121a(String)`.
  LoggingParams createFromInteractionId(String interactionId) {
    final pageInstanceId = _pageInstanceIdProvider.get();
    final pageInstanceIdStr = pageInstanceId?.value ?? '';

    return LoggingParams.builder()
        .interactionId(interactionId)
        .commandInitiatedTime(DateTime.now().millisecondsSinceEpoch)
        .pageInstanceId(pageInstanceIdStr)
        .build();
  }

  /// 1:1 replica of `p199p.zpl#m98122b(oq70)`.
  LoggingParams createFromInteractionResult(InteractionLoggingResult result) {
    final interactionIdStr = result.interactionId.value;
    final pageInstanceIdStr =
        result.pageInstanceId?.value ?? _pageInstanceIdProvider.get()?.value ?? '';

    return LoggingParams.builder()
        .interactionId(interactionIdStr)
        .commandInitiatedTime(DateTime.now().millisecondsSinceEpoch)
        .pageInstanceId(pageInstanceIdStr)
        .build();
  }
}
