library;

import '../models/impression_logging_result.dart';
import '../models/interaction_logging_result.dart';

/// Specification details for interaction elements.
class UbiInteractionElement {
  final String elementPath;
  final String? uri;
  final int? position;
  final String actionName;

  const UbiInteractionElement({
    required this.elementPath,
    this.uri,
    this.position,
    this.actionName = 'hit',
  });
}

/// Specification details for impression elements.
class UbiImpressionElement {
  final String elementPath;
  final String? uri;
  final int? position;

  const UbiImpressionElement({
    required this.elementPath,
    this.uri,
    this.position,
  });
}

/// 1:1 replica of Spotify `p199p.rde1` (`com.spotify.ubi.logger.UbiLogger`).
abstract interface class UbiLogger {
  /// 1:1 replica of `p199p.rde1#mo42508j(gde1)`.
  InteractionLoggingResult logInteraction(UbiInteractionElement element);

  /// 1:1 replica of `p199p.rde1#mo42507i(uce1)`.
  ImpressionLoggingResult logImpression(UbiImpressionElement element);
}
