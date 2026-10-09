import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/audio/playback_controller.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/domain/entities/auth_state.dart';
import 'package:musify_mu/features/home/presentation/online_home_screen.dart';
import 'package:musify_mu/features/home/presentation/widgets/home_header.dart';
import 'package:musify_mu/features/home_feed/application/home_feed_bloc.dart';
import 'package:musify_mu/features/local_music/presentation/screens/local_music_screen.dart';

class HomeTab extends StatelessWidget {
  final bool isOnlineMode;
  final bool isActive;
  final VoidCallback onMenuPressed;
  final VoidCallback onToggleMode;
  final GlobalKey iconKey;
  final bool iconVisible;
  final PlaybackController? playbackController;
  final HomeFeedBloc Function() createHomeFeedBloc;

  const HomeTab({
    super.key,
    required this.isOnlineMode,
    this.isActive = true,
    required this.onMenuPressed,
    required this.onToggleMode,
    required this.iconKey,
    required this.createHomeFeedBloc,
    this.iconVisible = true,
    this.playbackController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (prev, curr) =>
              prev.runtimeType != curr.runtimeType,
          builder: (context, authState) {
            final user = authState is Authenticated
                ? authState.user
                : null;

            // Build the title row widget (shared across states)
            final titleRow = HomeHeaderTitleRow(
              isOnlineMode: isOnlineMode,
              onMenuPressed: onMenuPressed,
              onToggleMode: onToggleMode,
              iconKey: iconKey,
              iconVisible: iconVisible,
              spotifyDisplayName: user?.displayName,
              spotifyAvatarUrl: user?.avatarUrl,
            );

            if (isOnlineMode) {
              // Pass header widgets into OnlineHomeScreen so the feed
              // can include them as slivers (title scrolls, chips pin).
              return OnlineHomeScreen(
                headerTitleRow: titleRow,
                createHomeFeedBloc: createHomeFeedBloc,
                isActive: isActive,
              );
            }

            // Offline: header stays fixed above the local music screen.
            return Column(
              children: [
                titleRow,
                Expanded(
                  child: LocalMusicScreen(
                    playbackController: playbackController,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
