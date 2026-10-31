library;

import 'package:equatable/equatable.dart';
import 'interaction_id.dart';
import 'page_instance_id.dart';

/// 1:1 replica of Spotify `p199p.oq70` (`com.spotify.ubi.logger.InteractionLoggingResult`).
class InteractionLoggingResult extends Equatable {
  final InteractionId interactionId;
  final PageInstanceId? pageInstanceId;
  final bool authenticated;
  final int eventCreationTimestamp;
  final int eventLoggedTimestamp;
  final int? pagePresentationId;
  final List<String> contextualSources;
  final String? pageId;
  final String? rootSpecificationId;
  final String? leafSpecificationId;
  final String interactionType;
  final int interactionTypeVersion;

  const InteractionLoggingResult({
    required this.interactionId,
    this.pageInstanceId,
    this.authenticated = true,
    this.eventCreationTimestamp = 0,
    this.eventLoggedTimestamp = 0,
    this.pagePresentationId,
    this.contextualSources = const [],
    this.pageId,
    this.rootSpecificationId,
    this.leafSpecificationId,
    this.interactionType = '',
    this.interactionTypeVersion = 1,
  });

  @override
  List<Object?> get props => [
        interactionId,
        pageInstanceId,
        authenticated,
        eventCreationTimestamp,
        eventLoggedTimestamp,
        pagePresentationId,
        contextualSources,
        pageId,
        rootSpecificationId,
        leafSpecificationId,
        interactionType,
        interactionTypeVersion,
      ];
}
