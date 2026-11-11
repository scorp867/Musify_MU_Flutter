import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Authentication method utilized to unlock the vault session.
enum AuthMethodEnum {
  /// Custom 6-digit PIN authentication.
  pin(id: 'PIN', displayName: 'PIN'),

  /// Android KeyStore Class 3 hardware-backed biometric authentication.
  biometric(id: 'BIOMETRIC', displayName: 'Biometric');

  /// Canonical serialization identifier.
  final String id;

  /// Human-readable display label.
  final String displayName;

  const AuthMethodEnum({
    required this.id,
    required this.displayName,
  });

  /// Serializes the enum variant to its canonical identifier string.
  String toJson() => id;

  /// Deserializes a string identifier into an [AuthMethodEnum] instance.
  ///
  /// Throws [FormatException] if [id] does not match any valid enum variant.
  static AuthMethodEnum fromId(String id) {
    for (final method in AuthMethodEnum.values) {
      if (method.id == id || method.name == id) {
        return method;
      }
    }
    throw FormatException(
      'Invalid AuthMethodEnum identifier: "$id". '
      'Valid options are: ${AuthMethodEnum.values.map((v) => v.id).join(', ')}.',
    );
  }

  /// Alias for [fromId] supporting JSON decoding pipelines.
  static AuthMethodEnum fromJson(String json) => fromId(json);
}

/// Deeply immutable value object representing an active authenticated vault session context.
///
/// Strictly enforces the Zero Loose Booleans mandate: contains zero `bool isAuthenticated` flags.
/// The presence of a valid [AuthSession] within an active state variant is the single source
/// of truth for authentication.
@immutable
class AuthSession extends Equatable {
  /// Ephemeral cryptographic session token authorizing in-memory operations.
  final String sessionToken;

  /// Monotonic or epoch timestamp in milliseconds when authentication succeeded.
  final int sessionStartedEpochMs;

  /// Monotonic or epoch timestamp in milliseconds of the latest user interaction.
  final int lastActiveEpochMs;

  /// Authentication mechanism used to establish this session.
  final AuthMethodEnum authMethod;

  /// Constructs a verified [AuthSession] instance.
  ///
  /// Throws [FormatException] if [sessionToken] is empty, [sessionStartedEpochMs] is non-positive,
  /// or [lastActiveEpochMs] is earlier than [sessionStartedEpochMs].
  AuthSession({
    required this.sessionToken,
    required this.sessionStartedEpochMs,
    required this.lastActiveEpochMs,
    required this.authMethod,
  }) {
    if (sessionToken.trim().isEmpty) {
      throw const FormatException('AuthSession sessionToken must not be empty.');
    }
    if (sessionStartedEpochMs <= 0) {
      throw FormatException(
        'AuthSession sessionStartedEpochMs must be positive: $sessionStartedEpochMs',
      );
    }
    if (lastActiveEpochMs < sessionStartedEpochMs) {
      throw FormatException(
        'AuthSession lastActiveEpochMs ($lastActiveEpochMs) cannot be earlier than sessionStartedEpochMs ($sessionStartedEpochMs)',
      );
    }
  }

  /// Creates a copy of this session with updated properties.
  AuthSession copyWith({
    String? sessionToken,
    int? sessionStartedEpochMs,
    int? lastActiveEpochMs,
    AuthMethodEnum? authMethod,
  }) {
    return AuthSession(
      sessionToken: sessionToken ?? this.sessionToken,
      sessionStartedEpochMs: sessionStartedEpochMs ?? this.sessionStartedEpochMs,
      lastActiveEpochMs: lastActiveEpochMs ?? this.lastActiveEpochMs,
      authMethod: authMethod ?? this.authMethod,
    );
  }

  @override
  List<Object?> get props => [
        sessionToken,
        sessionStartedEpochMs,
        lastActiveEpochMs,
        authMethod,
      ];
}
