import 'package:flutter/foundation.dart';

import 'trait.dart';

@immutable
final class RecentsMetadataTrait extends Trait {
  final int songsCount;
  final String recentType;
  final String contentCategory;
  final String groupName;
  final int timestamp;
  final List<String> entityUris;

  const RecentsMetadataTrait({
    this.songsCount = 0,
    this.recentType = 'played',
    this.contentCategory = '',
    this.groupName = '',
    this.timestamp = 0,
    this.entityUris = const [],
  });
}
