library;

import 'package:equatable/equatable.dart';
import 'page_instance_id.dart';

/// 1:1 replica of Spotify `p199p.ace1` (UbiEventMetadata).
class UbiEventMetadata extends Equatable {
  final String uuid;
  final PageInstanceId? pageInstanceId;
  final String? mode;
  final String clientVersion;
  final String navigationReason;
  final String navOrigin;
  final String clientTimezone;
  final String? appInstanceId;
  final int? appVisitIndex;

  const UbiEventMetadata({
    required this.uuid,
    this.pageInstanceId,
    this.mode,
    this.clientVersion = '',
    this.navigationReason = '',
    this.navOrigin = '',
    required this.clientTimezone,
    this.appInstanceId,
    this.appVisitIndex,
  });

  @override
  List<Object?> get props => [
        uuid,
        pageInstanceId,
        mode,
        clientVersion,
        navigationReason,
        navOrigin,
        clientTimezone,
        appInstanceId,
        appVisitIndex,
      ];
}
