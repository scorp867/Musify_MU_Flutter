import 'trait.dart';

/// Consumption experience details (ExtensionKind 182).
class ConsumptionExperienceTrait extends Trait {
  final String format;
  final bool isInteractive;

  const ConsumptionExperienceTrait({
    this.format = '',
    this.isInteractive = false,
  });

  @override
  Map<String, dynamic> toJson() => {
    'format': format,
    'isInteractive': isInteractive,
  };

  factory ConsumptionExperienceTrait.fromJson(Map<String, dynamic> json) =>
      ConsumptionExperienceTrait(
        format: json['format'] ?? '',
        isInteractive: json['isInteractive'] ?? false,
      );
}
