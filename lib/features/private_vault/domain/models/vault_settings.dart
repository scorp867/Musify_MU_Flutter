import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:musify_mu/features/private_vault/domain/models/vault_theme.dart';

export 'package:musify_mu/features/private_vault/domain/models/vault_theme.dart';

/// Exhaustive cool-off timeout options for the private vault session.
enum CoolOffDuration {
  immediate(0, 'Immediately upon exit'),
  oneMinute(60, '1 minute'),
  fiveMinutes(300, '5 minutes'),
  fifteenMinutes(900, '15 minutes');

  final int inSeconds;
  final String label;

  const CoolOffDuration(this.inSeconds, this.label);

  Duration get duration => Duration(seconds: inSeconds);
}

/// Immutable domain model encapsulating all user-configurable security and appearance settings.
@immutable
final class VaultSettings extends Equatable {
  final CoolOffDuration coolOffDuration;
  final bool maskMediaSession;
  final bool preventScreenshots;
  final VaultTheme theme;
  final bool showDrawerGestureTrail;

  const VaultSettings({
    required this.coolOffDuration,
    required this.maskMediaSession,
    required this.preventScreenshots,
    required this.theme,
    required this.showDrawerGestureTrail,
  });

  /// Factory providing default security and appearance settings.
  static const VaultSettings defaultSettings = VaultSettings(
    coolOffDuration: CoolOffDuration.fiveMinutes,
    maskMediaSession: true,
    preventScreenshots: true,
    theme: VaultTheme.deepMoss,
    showDrawerGestureTrail: false,
  );

  VaultSettings copyWith({
    CoolOffDuration? coolOffDuration,
    bool? maskMediaSession,
    bool? preventScreenshots,
    VaultTheme? theme,
    bool? showDrawerGestureTrail,
  }) {
    return VaultSettings(
      coolOffDuration: coolOffDuration ?? this.coolOffDuration,
      maskMediaSession: maskMediaSession ?? this.maskMediaSession,
      preventScreenshots: preventScreenshots ?? this.preventScreenshots,
      theme: theme ?? this.theme,
      showDrawerGestureTrail: showDrawerGestureTrail ?? this.showDrawerGestureTrail,
    );
  }

  factory VaultSettings.fromJson(Map<String, dynamic> json) {
    final coolOffRaw = json['coolOffDuration'];
    if (coolOffRaw is! String) {
      throw const FormatException('Missing or invalid coolOffDuration in VaultSettings');
    }

    final CoolOffDuration duration = switch (coolOffRaw) {
      'immediate' => CoolOffDuration.immediate,
      'oneMinute' => CoolOffDuration.oneMinute,
      'fiveMinutes' => CoolOffDuration.fiveMinutes,
      'fifteenMinutes' => CoolOffDuration.fifteenMinutes,
      _ => throw FormatException('Unknown coolOffDuration value: $coolOffRaw'),
    };

    final maskMediaRaw = json['maskMediaSession'];
    if (maskMediaRaw is! bool) {
      throw const FormatException('Missing or invalid maskMediaSession in VaultSettings');
    }

    final preventScreenshotsRaw = json['preventScreenshots'];
    if (preventScreenshotsRaw is! bool) {
      throw const FormatException('Missing or invalid preventScreenshots in VaultSettings');
    }

    final themeRaw = json['theme'];
    final VaultTheme parsedTheme;
    if (themeRaw is String) {
      parsedTheme = VaultTheme.fromJson(themeRaw);
    } else {
      parsedTheme = VaultTheme.deepMoss;
    }

    final trailRaw = json['showDrawerGestureTrail'];
    final bool parsedTrail;
    if (trailRaw is bool) {
      parsedTrail = trailRaw;
    } else {
      parsedTrail = false;
    }

    return VaultSettings(
      coolOffDuration: duration,
      maskMediaSession: maskMediaRaw,
      preventScreenshots: preventScreenshotsRaw,
      theme: parsedTheme,
      showDrawerGestureTrail: parsedTrail,
    );
  }

  Map<String, dynamic> toJson() {
    final String durationString = switch (coolOffDuration) {
      CoolOffDuration.immediate => 'immediate',
      CoolOffDuration.oneMinute => 'oneMinute',
      CoolOffDuration.fiveMinutes => 'fiveMinutes',
      CoolOffDuration.fifteenMinutes => 'fifteenMinutes',
    };

    return <String, dynamic>{
      'coolOffDuration': durationString,
      'maskMediaSession': maskMediaSession,
      'preventScreenshots': preventScreenshots,
      'theme': theme.toJson(),
      'showDrawerGestureTrail': showDrawerGestureTrail,
    };
  }

  @override
  List<Object?> get props => [
        coolOffDuration,
        maskMediaSession,
        preventScreenshots,
        theme,
        showDrawerGestureTrail,
      ];
}
