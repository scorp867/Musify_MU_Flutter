library;

import '../models/page_instance_id.dart';

/// 1:1 replica of Spotify `p199p.zlp0` (PageInstanceIdProvider).
abstract interface class PageInstanceIdProvider {
  /// Resolves the current active [PageInstanceId] or null if detached.
  PageInstanceId? get();
}
