import 'trait.dart';

/// Show / Podcast access entitlement metadata (ExtensionKind 31).
class ShowAccessTrait extends Trait {
  final bool hasAccess;
  final bool isLocked;
  final String accessType;

  const ShowAccessTrait({
    this.hasAccess = true,
    this.isLocked = false,
    this.accessType = '',
  });

  @override
  Map<String, dynamic> toJson() => {
    'hasAccess': hasAccess,
    'isLocked': isLocked,
    'accessType': accessType,
  };

  factory ShowAccessTrait.fromJson(Map<String, dynamic> json) => ShowAccessTrait(
    hasAccess: json['hasAccess'] ?? true,
    isLocked: json['isLocked'] ?? false,
    accessType: json['accessType'] ?? '',
  );
}
