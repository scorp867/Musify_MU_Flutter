import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Result of parsing a Casita `ResolvedHome` protobuf response.
@immutable
final class CasitaResult {
  final HomeViewData homeData;
  final List<String> ondemandUris;
  final Map<String, Map<String, Trait>> traits;
  final Map<CellKey, Trait> eagerCells;
  final Map<(int, String), Uint8List> eagerRawPayloads;

  const CasitaResult({
    required this.homeData,
    required this.ondemandUris,
    this.traits = const {},
    this.eagerCells = const {},
    this.eagerRawPayloads = const {},
  });
}
