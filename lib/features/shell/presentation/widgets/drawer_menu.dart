import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/application/auth_event.dart';
import 'package:musify_mu/features/auth/domain/entities/auth_state.dart';
import 'package:musify_mu/features/player/presentation/screens/debug_now_playing_screen.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
          builder: (context, authState) {
            final user =
                authState is Authenticated ? authState.user : null;
            final displayName = user?.displayName ?? 'Musify';
            final handle = user != null ? '@${user.id}' : 'Offline Mode';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(user?.avatarUrl, displayName),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  handle,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 48),
                _DrawerMenuItem(
                    icon: Icons.person, title: 'Profile'),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DebugNowPlayingScreen(),
                      ),
                    );
                  },
                  child: const _DrawerMenuItem(
                      icon: Icons.bug_report, title: 'Debug: NowPlaying'),
                ),
                _DrawerMenuItem(
                    icon: Icons.history,
                    title: 'Listening History'),
                _DrawerMenuItem(
                    icon: Icons.headset, title: 'Equalizer'),
                const Spacer(),
                if (user != null)
                  GestureDetector(
                    onTap: () => context
                        .read<AuthBloc>()
                        .add(const AuthLogoutRequested()),
                    child: const _DrawerMenuItem(
                      icon: Icons.logout,
                      title: 'Log Out',
                      color: Color(0xFFF97316),
                    ),
                  )
                else
                  const _DrawerMenuItem(
                    icon: Icons.login,
                    title: 'Connect Spotify',
                    color: Color(0xFF1DB954),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String displayName) {
    if (avatarUrl != null) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: const Color(0xFF1E293B),
        backgroundImage: CachedNetworkImageProvider(
          avatarUrl,
          maxWidth: 160,
          maxHeight: 160,
        ),
      );
    }

    return CircleAvatar(
      radius: 40,
      backgroundColor: const Color(0xFF3B82F6),
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
