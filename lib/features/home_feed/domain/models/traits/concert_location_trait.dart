import 'trait.dart';

/// Concert location metadata (ExtensionKind 123).
class ConcertLocationTrait extends Trait {
  final String venue;
  final String city;

  const ConcertLocationTrait({this.venue = '', this.city = ''});

  @override
  Map<String, dynamic> toJson() => {'venue': venue, 'city': city};

  factory ConcertLocationTrait.fromJson(Map<String, dynamic> json) =>
      ConcertLocationTrait(
        venue: json['venue'] ?? '',
        city: json['city'] ?? '',
      );
}
