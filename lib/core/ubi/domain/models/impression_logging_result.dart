library;

import 'package:equatable/equatable.dart';
import 'impression_id.dart';
import 'page_instance_id.dart';

/// 1:1 replica of Spotify `p199p.uz60` (`com.spotify.ubi.logger.ImpressionLoggingResult`).
class ImpressionLoggingResult extends Equatable {
  final ImpressionId impressionId;
  final PageInstanceId? pageInstanceId;

  const ImpressionLoggingResult({
    required this.impressionId,
    this.pageInstanceId,
  });

  @override
  List<Object?> get props => [impressionId, pageInstanceId];
}
