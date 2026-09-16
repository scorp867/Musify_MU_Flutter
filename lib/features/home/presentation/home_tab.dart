import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/domain/entities/auth_state.dart';
import 'package:musify_mu/features/home/presentation/online_home_screen.dart';
import 'package:musify_mu/features/home/presentation/widgets/home_header.dart';
import 'package:musify_mu/features/local_music/presentation/screens/local_music_screen.dart';

class HomeTab extends StatelessWidget {
  final bool isOnlineMode;
  final VoidCallback onMenuPressed;
  final VoidCallback onToggleMode;
  final GlobalKey iconKey;
  final bool iconVisible;
  final PlaybackController? playbackController;

  const HomeTab({
    super.key,
    required this.isOnlineMode,
    required this.onMenuPressed,
    required this.onToggleMode,
    required this.iconKey,
    this.iconVisible = true,
    this.playbackController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Read auth state to pass profile data to the header.
            BlocBuilder<AuthBloc, AuthState>(
              buildWhen: (prev, curr) =>
                  prev.runtimeType != curr.runtimeType,
              builder: (context, authState) {
                final user = authState is Authenticated
                    ? authState.user
                    : null;

                return HomeHeader(
                  isOnlineMode: isOnlineMode,
                  onMenuPressed: onMenuPressed,
                  onToggleMode: onToggleMode,
                  iconKey: iconKey,
                  iconVisible: iconVisible,
                  spotifyDisplayName: user?.displayName,
                  spotifyAvatarUrl: user?.avatarUrl,
                );
              },
            ),
            Expanded(
              child: isOnlineMode
                  ? const OnlineHomeScreen()
                  : LocalMusicScreen(playbackController: playbackController),
            ),
          ],
        ),
      ),
    );
  }
}
