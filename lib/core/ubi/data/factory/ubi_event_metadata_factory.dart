library;

import 'package:uuid/uuid.dart';
import '../../domain/models/ubi_event_metadata.dart';
import '../../domain/providers/page_instance_id_provider.dart';

/// 1:1 replica of Spotify `p199p.bce1` (UbiEventMetadataFactory).
class UbiEventMetadataFactory {
  static const Uuid _uuid = Uuid();
  final PageInstanceIdProvider _pageInstanceIdProvider;

  const UbiEventMetadataFactory(this._pageInstanceIdProvider);

  /// 1:1 replica of `p199p.bce1#m30135a()`.
  UbiEventMetadata createMetadata() {
    final uuid = _uuid.v4();
    final pageInstanceId = _pageInstanceIdProvider.get();
    final timezone = DateTime.now().timeZoneName;

    return UbiEventMetadata(
      uuid: uuid,
      pageInstanceId: pageInstanceId,
      clientVersion: '1.0.0',
      clientTimezone: timezone,
    );
  }
}
