import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final bool isOnlineMode;
  final VoidCallback onMenuPressed;
  final VoidCallback onToggleMode;
  final GlobalKey iconKey;
  final bool iconVisible;

  /// Spotify user's display name (null = offline / not logged in).
  final String? spotifyDisplayName;

  /// Spotify user's avatar URL (null = show default icon).
  final String? spotifyAvatarUrl;

  const HomeHeader({
    super.key,
    required this.isOnlineMode,
    required this.onMenuPressed,
    required this.onToggleMode,
    required this.iconKey,
    this.iconVisible = true,
    this.spotifyDisplayName,
    this.spotifyAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = isOnlineMode && spotifyDisplayName != null
        ? spotifyDisplayName!
        : 'Musify';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onToggleMode,
                child: Opacity(
                  opacity: iconVisible ? 1.0 : 0.0,
                  child: Container(
                    key: iconKey,
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Transform.flip(
                      flipX: !isOnlineMode,
                      child: Image.asset(
                        'assets/images/app_icon.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onMenuPressed,
            child: _buildAvatar(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (isOnlineMode && spotifyAvatarUrl != null) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFF1E293B),
        backgroundImage: NetworkImage(spotifyAvatarUrl!),
      );
    }

    // Default avatar — initials or generic icon.
    if (isOnlineMode && spotifyDisplayName != null) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFF1DB954),
        child: Text(
          spotifyDisplayName![0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );
    }

    return const CircleAvatar(
      radius: 20,
      backgroundColor: Color(0xFF3B82F6),
      child: Icon(Icons.person, color: Colors.white),
    );
  }
}
