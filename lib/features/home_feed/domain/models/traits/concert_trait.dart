import 'trait.dart';

/// Live Concert / Tour event trait (ExtensionKind 122).
class ConcertTrait extends Trait {
  final String title;
  final String artistName;
  final int eventDateTimestamp;

  const ConcertTrait({
    required this.title,
    this.artistName = '',
    this.eventDateTimestamp = 0,
  });

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'artistName': artistName,
    'eventDateTimestamp': eventDateTimestamp,
  };

  factory ConcertTrait.fromJson(Map<String, dynamic> json) => ConcertTrait(
    title: json['title'] ?? '',
    artistName: json['artistName'] ?? '',
    eventDateTimestamp: json['eventDateTimestamp'] ?? 0,
  );
}
