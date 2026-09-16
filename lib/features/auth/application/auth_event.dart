import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check stored session on app launch.
final class AuthSessionRestored extends AuthEvent {
  const AuthSessionRestored();
}

/// User initiated login (tapped "Connect with Spotify").
final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested();
}

/// WebView captured tokens after successful Spotify login.
final class AuthTokensCaptured extends AuthEvent {
  final String spDcCookie;
  final String accessToken;

  const AuthTokensCaptured({
    required this.spDcCookie,
    required this.accessToken,
  });

  @override
  List<Object?> get props => [spDcCookie, accessToken];
}

/// User initiated logout.
final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
