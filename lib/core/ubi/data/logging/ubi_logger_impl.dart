library;

import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

import '../../domain/logging/ubi_logger.dart';
import '../../domain/models/impression_id.dart';
import '../../domain/models/impression_logging_result.dart';
import '../../domain/models/interaction_id.dart';
import '../../domain/models/interaction_logging_result.dart';
import '../../domain/providers/page_instance_id_provider.dart';
import '../factory/ubi_event_metadata_factory.dart';

/// 1:1 replica of Spotify `p199p.tde1` (`com.spotify.ubi.logger.UbiLoggerImpl`).
class UbiLoggerImpl implements UbiLogger {
  final UbiEventMetadataFactory _metadataFactory;
  final PageInstanceIdProvider _pageInstanceIdProvider;

  const UbiLoggerImpl({
    required UbiEventMetadataFactory metadataFactory,
    required PageInstanceIdProvider pageInstanceIdProvider,
  })  : _metadataFactory = metadataFactory,
        _pageInstanceIdProvider = pageInstanceIdProvider;

  @override
  InteractionLoggingResult logInteraction(UbiInteractionElement element) {
    final meta = _metadataFactory.createMetadata();
    final now = DateTime.now().millisecondsSinceEpoch;
    final interactionId = InteractionId(meta.uuid);
    final pageInstanceId = meta.pageInstanceId ?? _pageInstanceIdProvider.get();

    final result = InteractionLoggingResult(
      interactionId: interactionId,
      pageInstanceId: pageInstanceId,
      authenticated: true,
      eventCreationTimestamp: now,
      eventLoggedTimestamp: now,
      leafSpecificationId: element.elementPath,
      interactionType: element.actionName,
      interactionTypeVersion: 1,
    );

    final logMsg =
        'Logged interaction: interaction_id=${interactionId.value}, page_instance_id=${pageInstanceId?.value}, path=${element.elementPath}, action=${element.actionName}';
    dev.log(logMsg, name: 'UBI');
    if (kDebugMode) {
      debugPrint('[UBI] $logMsg');
    }

    return result;
  }

  @override
  ImpressionLoggingResult logImpression(UbiImpressionElement element) {
    final meta = _metadataFactory.createMetadata();
    final impressionId = ImpressionId(meta.uuid);
    final pageInstanceId = meta.pageInstanceId ?? _pageInstanceIdProvider.get();

    final result = ImpressionLoggingResult(
      impressionId: impressionId,
      pageInstanceId: pageInstanceId,
    );

    final logMsg =
        'Logged impression: impression_id=${impressionId.value}, page_instance_id=${pageInstanceId?.value}, path=${element.elementPath}';
    dev.log(logMsg, name: 'UBI');
    if (kDebugMode) {
      debugPrint('[UBI] $logMsg');
    }

    return result;
  }
}
