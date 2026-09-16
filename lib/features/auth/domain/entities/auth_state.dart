import 'package:equatable/equatable.dart';
import 'spotify_user.dart';

/// Sealed auth state — exhaustive matching at compile time.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// No user session. Show the welcome landing.
final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Auth flow is in progress (logging in, refreshing token, etc.).
final class Authenticating extends AuthState {
  const Authenticating();
}

/// User is logged in with a valid session.
final class Authenticated extends AuthState {
  final SpotifyUser user;

  const Authenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Auth failed — show error with option to retry.
final class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
