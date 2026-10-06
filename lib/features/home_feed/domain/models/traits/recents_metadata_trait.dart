import 'trait.dart';

class RecentsMetadataTrait extends Trait {
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

  @override
  Map<String, dynamic> toJson() => {
    'songsCount': songsCount,
    'recentType': recentType,
    'contentCategory': contentCategory,
    'groupName': groupName,
    'timestamp': timestamp,
    'entityUris': entityUris,
  };

  factory RecentsMetadataTrait.fromJson(Map<String, dynamic> json) => RecentsMetadataTrait(
    songsCount: json['songsCount'] ?? 0,
    recentType: json['recentType'] ?? 'played',
    contentCategory: json['contentCategory'] ?? '',
    groupName: json['groupName'] ?? '',
    timestamp: json['timestamp'] ?? 0,
    entityUris: (json['entityUris'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
  );
}
