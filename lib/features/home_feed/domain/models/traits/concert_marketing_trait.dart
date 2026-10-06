import 'trait.dart';

/// Concert marketing details (ExtensionKind 124).
class ConcertMarketingTrait extends Trait {
  final String ticketingPartner;
  final String ticketingUrl;

  const ConcertMarketingTrait({
    this.ticketingPartner = '',
    this.ticketingUrl = '',
  });

  @override
  Map<String, dynamic> toJson() => {
    'ticketingPartner': ticketingPartner,
    'ticketingUrl': ticketingUrl,
  };

  factory ConcertMarketingTrait.fromJson(Map<String, dynamic> json) =>
      ConcertMarketingTrait(
        ticketingPartner: json['ticketingPartner'] ?? '',
        ticketingUrl: json['ticketingUrl'] ?? '',
      );
}
