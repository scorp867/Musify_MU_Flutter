import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/ui/widgets/app_header.dart';
import 'package:musify_mu/features/home_feed/application/home_feed_bloc.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/facet_chip_row.dart';

/// Builds the home header title row (app icon + name + avatar).
/// Used as a scrollable SliverToBoxAdapter in the feed.
class HomeHeaderTitleRow extends StatelessWidget {
  final bool isOnlineMode;
  final VoidCallback onMenuPressed;
  final VoidCallback onToggleMode;
  final GlobalKey iconKey;
  final bool iconVisible;
  final String? spotifyDisplayName;
  final String? spotifyAvatarUrl;

  const HomeHeaderTitleRow({
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

    return AppHeader(
      leading: GestureDetector(
        onTap: onMenuPressed,
        child: _buildAvatar(),
      ),
      title: displayName,
      trailing: [
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
      ],
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

    if (isOnlineMode && spotifyDisplayName != null) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFF1DB954),
        child: Text(
          (spotifyDisplayName != null && spotifyDisplayName!.isNotEmpty)
              ? spotifyDisplayName![0].toUpperCase()
              : '?',
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

/// The filter chips widget -- separate so it can be pinned independently.
class HomeFilterChips extends StatelessWidget {
  final List<HomeChip>? chips;

  const HomeFilterChips({super.key, this.chips});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeFeedBloc, HomeFeedState>(
      buildWhen: (prev, curr) {
        final prevFacet = prev is HomeFeedLoaded ? prev.activeFacet : null;
        final currFacet = curr is HomeFeedLoaded ? curr.activeFacet : null;
        return prevFacet != currFacet;
      },
      builder: (context, state) {
        final activeFacet = state is HomeFeedLoaded
            ? state.activeFacet
            : HomeFacet.all;

        return FacetChipRow(
          selectedFacet: activeFacet,
          chips: chips,
          onSelected: (facet) {
            context.read<HomeFeedBloc>().add(HomeFeedFacetChanged(facet));
          },
        );
      },
    );
  }
}
