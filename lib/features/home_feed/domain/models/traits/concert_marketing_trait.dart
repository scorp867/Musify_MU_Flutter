import 'package:flutter/foundation.dart';

import 'trait.dart';

/// Concert marketing details (ExtensionKind 124).
@immutable
final class ConcertMarketingTrait extends Trait {
  final String ticketingPartner;
  final String ticketingUrl;

  const ConcertMarketingTrait({
    this.ticketingPartner = '',
    this.ticketingUrl = '',
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConcertMarketingTrait &&
        other.ticketingPartner == ticketingPartner &&
        other.ticketingUrl == ticketingUrl;
  }

  @override
  int get hashCode => Object.hash(ticketingPartner, ticketingUrl);
}
