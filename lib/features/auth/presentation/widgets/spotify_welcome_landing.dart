import 'package:flutter/material.dart';

/// Spotify-green accent for auth-related UI.
const _kSpotifyGreen = Color(0xFF1DB954);

/// Welcome landing shown inside OnlineHomeScreen when user is not logged in.
/// Not a separate screen — inline within the existing home tab.
class SpotifyWelcomeLanding extends StatelessWidget {
  final VoidCallback onConnect;
  final bool isLoading;

  const SpotifyWelcomeLanding({
    super.key,
    required this.onConnect,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // App icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/app_icon.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 32),

              // Headline
              const Text(
                'Stream millions\nof songs',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Connect your Spotify account to unlock\nstreaming, playlists, and more.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Feature bullets
              const _FeatureRow(
                icon: Icons.headphones_rounded,
                text: 'Access your full Spotify library',
              ),
              const SizedBox(height: 16),
              const _FeatureRow(
                icon: Icons.playlist_play_rounded,
                text: 'Playlists, albums & podcasts',
              ),
              const SizedBox(height: 16),
              const _FeatureRow(
                icon: Icons.explore_rounded,
                text: 'Discover new music & recommendations',
              ),

              const Spacer(flex: 2),

              // Connect button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onConnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kSpotifyGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _kSpotifyGreen.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Connect with Spotify',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),

              // Account note
              Text(
                'You need a Spotify account to use online features.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _kSpotifyGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _kSpotifyGreen, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
