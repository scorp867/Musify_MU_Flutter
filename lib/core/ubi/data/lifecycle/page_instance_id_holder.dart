library;

import 'dart:async';
import 'package:uuid/uuid.dart';

import '../../domain/models/page_instance_id.dart';
import '../../domain/providers/page_instance_id_provider.dart';

/// 1:1 replica of Spotify `p199p.xlp0` and `p199p.ylp0` (PageInstanceIdHolder & Provider).
class PageInstanceIdHolder implements PageInstanceIdProvider {
  static const String bundleKey = 'ubi.nav-logger.page-instance-id';
  static const Uuid _uuid = Uuid();

  final StreamController<PageInstanceId> _controller =
      StreamController<PageInstanceId>.broadcast();

  PageInstanceId? _currentId;
  PageInstanceId? _restoredId;

  PageInstanceIdHolder([PageInstanceId? initialId]) {
    final id = initialId ?? generateNew();
    _currentId = id;
    _controller.add(id);
  }

  /// 1:1 replica of `p199p.xlp0#m91924a()`.
  static PageInstanceId generateNew() {
    return PageInstanceId(_uuid.v4());
  }

  /// 1:1 replica of `p199p.xlp0#m91925b()` & `p199p.zlp0#get()`.
  @override
  PageInstanceId? get() => _currentId;

  /// Stream of active page instance ID updates.
  Stream<PageInstanceId> get stream => _controller.stream;

  /// 1:1 replica of `p199p.xlp0#m91926e(wlp0)`.
  void update(PageInstanceId newId) {
    if (_currentId != newId) {
      _currentId = newId;
      _controller.add(newId);
    }
  }

  /// 1:1 replica of `p199p.xlp0#mo44049c(Bundle)` (restore from bundle / storage map).
  void restoreFromStorage(Map<String, dynamic>? storage) {
    if (_restoredId != null) return;
    if (storage != null && storage.containsKey(bundleKey)) {
      final rawVal = storage[bundleKey];
      if (rawVal is String && rawVal.isNotEmpty) {
        _restoredId = PageInstanceId(rawVal);
        _currentId = _restoredId;
        _controller.add(_currentId!);
      }
    }
  }

  /// 1:1 replica of `p199p.xlp0#mo44050d(Bundle)` (save to bundle / storage map).
  void saveToStorage(Map<String, dynamic> storage) {
    if (_currentId != null) {
      storage[bundleKey] = _currentId!.value;
    }
  }

  void dispose() {
    _controller.close();
  }
}
