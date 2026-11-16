// 1:1 replica of p199p/r370.java (lines 7–64), p199p/bsq.java (line 152),
// p199p/n8d.java (lines 706–740), and
// com/spotify/connect/esperanto/proto/ConnectMessages$StateResponse.java (StateResponse.Incarnation).

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Known incarnation transport/login protocols (`n8d.java:706,740`, `bsq.java:152`).
enum IncarnationLoginType {
  connect,
  cast,
  castJs;

  static IncarnationLoginType fromWireName(String raw) {
    final normalized = raw.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw FormatException(
        'IncarnationLoginType wire name must not be empty',
        raw,
      );
    }

    switch (normalized) {
      case 'CONNECT':
        return IncarnationLoginType.connect;
      case 'CAST':
        return IncarnationLoginType.cast;
      case 'CAST_JS':
        return IncarnationLoginType.castJs;
      default:
        throw FormatException(
          'Unknown IncarnationLoginType wire name: $raw',
          raw,
        );
    }
  }

  static IncarnationLoginType? tryFromWireName(String raw) {
    final normalized = raw.trim().toUpperCase();
    switch (normalized) {
      case 'CONNECT':
        return IncarnationLoginType.connect;
      case 'CAST':
        return IncarnationLoginType.cast;
      case 'CAST_JS':
        return IncarnationLoginType.castJs;
      default:
        return null;
    }
  }

  String get wireName {
    switch (this) {
      case IncarnationLoginType.connect:
        return 'CONNECT';
      case IncarnationLoginType.cast:
        return 'CAST';
      case IncarnationLoginType.castJs:
        return 'CAST_JS';
    }
  }
}

/// Known reasons why an incarnation is marked preferred (`StateResponse.Incarnation` tag 4).
enum IncarnationPreferredReason {
  defaultReason,
  userSelected,
  streamExpansion,
  androidTv,
  tapDevice;

  static IncarnationPreferredReason fromWireName(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw FormatException(
        'IncarnationPreferredReason wire name must not be empty',
        raw,
      );
    }

    switch (normalized) {
      case 'default':
      case 'protocol_choice_reason_default':
        return IncarnationPreferredReason.defaultReason;
      case 'user_selected':
      case 'protocol_choice_reason_user_selected':
        return IncarnationPreferredReason.userSelected;
      case 'stream_expansion':
      case 'protocol_choice_reason_stream_expansion':
        return IncarnationPreferredReason.streamExpansion;
      case 'android_tv':
      case 'protocol_choice_reason_android_tv':
        return IncarnationPreferredReason.androidTv;
      case 'tap_device':
      case 'protocol_choice_reason_tap_device':
        return IncarnationPreferredReason.tapDevice;
      default:
        throw FormatException(
          'Unknown IncarnationPreferredReason wire name: $raw',
          raw,
        );
    }
  }

  static IncarnationPreferredReason? tryFromWireName(String raw) {
    final normalized = raw.trim().toLowerCase();
    switch (normalized) {
      case 'default':
      case 'protocol_choice_reason_default':
        return IncarnationPreferredReason.defaultReason;
      case 'user_selected':
      case 'protocol_choice_reason_user_selected':
        return IncarnationPreferredReason.userSelected;
      case 'stream_expansion':
      case 'protocol_choice_reason_stream_expansion':
        return IncarnationPreferredReason.streamExpansion;
      case 'android_tv':
      case 'protocol_choice_reason_android_tv':
        return IncarnationPreferredReason.androidTv;
      case 'tap_device':
      case 'protocol_choice_reason_tap_device':
        return IncarnationPreferredReason.tapDevice;
      default:
        return null;
    }
  }

  String get wireName {
    switch (this) {
      case IncarnationPreferredReason.defaultReason:
        return 'default';
      case IncarnationPreferredReason.userSelected:
        return 'user_selected';
      case IncarnationPreferredReason.streamExpansion:
        return 'stream_expansion';
      case IncarnationPreferredReason.androidTv:
        return 'android_tv';
      case IncarnationPreferredReason.tapDevice:
        return 'tap_device';
    }
  }
}

/// Device protocol incarnation matching `p199p/r370.java` with exact 5 non-null
/// fields (`loginType`, `identifier`, `preferred`, `preferredReason`,
/// `connectStateIdentifier`).
@immutable
final class Incarnation extends Equatable {
  /// Transport login type string (`r370.f202899a`, e.g. `"CONNECT"`, `"CAST"`, `"CAST_JS"`).
  final String loginType;

  /// Protocol-specific device identifier (`r370.f202900b`).
  final String identifier;

  /// Whether this incarnation is currently preferred (`r370.f202901c`).
  final bool preferred;

  /// Reason this incarnation was preferred (`r370.f202902d`, e.g. `"default"`).
  final String preferredReason;

  /// Connect-state identifier associated with this incarnation (`r370.f202903e`).
  final String connectStateIdentifier;

  const Incarnation({
    required this.loginType,
    required this.identifier,
    required this.preferred,
    required this.preferredReason,
    required this.connectStateIdentifier,
  });

  /// Typed [IncarnationLoginType] parsed from [loginType], or `null` if unknown.
  IncarnationLoginType? get parsedLoginType =>
      IncarnationLoginType.tryFromWireName(loginType);

  /// Typed [IncarnationPreferredReason] parsed from [preferredReason], or `null` if unknown.
  IncarnationPreferredReason? get parsedPreferredReason =>
      IncarnationPreferredReason.tryFromWireName(preferredReason);

  Incarnation copyWith({
    String? loginType,
    String? identifier,
    bool? preferred,
    String? preferredReason,
    String? connectStateIdentifier,
  }) {
    return Incarnation(
      loginType: switch (loginType) {
        final value? => value,
        null => this.loginType,
      },
      identifier: switch (identifier) {
        final value? => value,
        null => this.identifier,
      },
      preferred: switch (preferred) {
        final value? => value,
        null => this.preferred,
      },
      preferredReason: switch (preferredReason) {
        final value? => value,
        null => this.preferredReason,
      },
      connectStateIdentifier: switch (connectStateIdentifier) {
        final value? => value,
        null => this.connectStateIdentifier,
      },
    );
  }

  @override
  List<Object?> get props => [
        loginType,
        identifier,
        preferred,
        preferredReason,
        connectStateIdentifier,
      ];
}
