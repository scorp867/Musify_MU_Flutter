import 'package:equatable/equatable.dart';

/// Represents a minimal authenticated Spotify user profile.
class SpotifyUser extends Equatable {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? email;
  final String? country;
  final String? product; // "premium", "free", etc.

  const SpotifyUser({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.email,
    this.country,
    this.product,
  });

  bool get isPremium => product == 'premium';

  @override
  List<Object?> get props => [id, displayName, avatarUrl, email, country, product];
}
