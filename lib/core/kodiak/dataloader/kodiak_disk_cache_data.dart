import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Decoded binary disk cache snapshot for Kodiak DataPool.
@immutable
final class KodiakDiskCacheData {
  final Map<String, Map<String, Trait>> traits;
  final Map<(int, String), Uint8List> rawPayloads;
  final Map<String, Set<int>> resolvedKinds;

  const KodiakDiskCacheData({
    required this.traits,
    required this.rawPayloads,
    required this.resolvedKinds,
  });
}
