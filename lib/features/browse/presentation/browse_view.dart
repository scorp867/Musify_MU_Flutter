import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/ui/widgets/app_header.dart';
import 'package:musify_mu/core/ui/widgets/sticky_header_delegate.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/domain/entities/auth_state.dart';
import 'package:musify_mu/features/browse/application/browse_bloc.dart';
import 'package:musify_mu/features/browse/domain/models/browse_view_data.dart';

/// The browse/search tab view -- renders category grid from Browsita data.
class BrowseView extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onToggleMode;

  const BrowseView({super.key, this.onMenuPressed, this.onToggleMode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrowseBloc, BrowseState>(
      builder: (context, state) {
        return switch (state) {
          BrowseLoading() => const _BrowseShimmer(),
          BrowseLoaded(:final data, :final isRefreshing) =>
            _BrowseContent(
              data: data,
              isRefreshing: isRefreshing,
              onMenuPressed: onMenuPressed,
              onToggleMode: onToggleMode,
            ),
          BrowseError(:final message, :final staleData) => staleData != null
              ? _BrowseContent(
                  data: staleData,
                  isRefreshing: false,
                  onMenuPressed: onMenuPressed,
                  onToggleMode: onToggleMode,
                )
              : _ErrorView(message: message),
        };
      },
    );
  }
}

// ─── Browse content ──────────────────────────────────────────────────

class _BrowseContent extends StatelessWidget {
  final BrowseViewData data;
  final bool isRefreshing;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onToggleMode;

  const _BrowseContent({
    required this.data,
    required this.isRefreshing,
    this.onMenuPressed,
    this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF1DB954),
      backgroundColor: const Color(0xFF282828),
      onRefresh: () async {
        context.read<BrowseBloc>().add(const BrowseRefreshRequested());
        await context.read<BrowseBloc>().stream.firstWhere(
              (s) => (s is BrowseLoaded && !s.isRefreshing) || s is BrowseError,
            );
      },
      child: CustomScrollView(
        slivers: [
          // Header (floating -- reappears on any downward scroll)
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: const Color(0xFF121212),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: 72,
            titleSpacing: 0,
            automaticallyImplyLeading: false,
            title: _BrowseHeader(
              onMenuPressed: onMenuPressed,
              onToggleMode: onToggleMode,
            ),
          ),

          // Search bar (pinned -- stays visible when scrolling)
          SliverPersistentHeader(
            pinned: true,
            delegate: StickyHeaderDelegate(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _SearchBar(),
              ),
            ),
          ),

          // Sections
          for (final section in data.sections)
            if (section.sectionType == 'content_category' &&
                section.items.isNotEmpty)
              ..._buildContentCategory(section),
        ],
      ),
    );
  }

  List<Widget> _buildContentCategory(BrowseSection section) {
    return [
      // Section heading
      if (section.title.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(
              section.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),

      // Category grid (2-column)
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.7,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _BrowseCard(item: section.items[index]),
            childCount: section.items.length,
          ),
        ),
      ),
    ];
  }
}

// ─── Browse card ─────────────────────────────────────────────────────

class _BrowseCard extends StatelessWidget {
  final BrowseItem item;

  const _BrowseCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final bgColor = item.backgroundColor != null
        ? Color(item.backgroundColor!)
        : const Color(0xFF535353);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: bgColor,
        child: Stack(
          children: [
            // Title
            Positioned(
              left: 12,
              top: 12,
              right: 60,
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),

            // Image (bottom-right, rotated like Spotify)
            if (item.imageUrl.isNotEmpty)
              Positioned(
                right: -8,
                bottom: -4,
                child: Transform.rotate(
                  angle: 0.44, // ~25 degrees
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(-2, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(imageUrl:
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
// ─── Browse header ───────────────────────────────────────────────────

class _BrowseHeader extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onToggleMode;

  const _BrowseHeader({this.onMenuPressed, this.onToggleMode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      builder: (context, authState) {
        final user =
            authState is Authenticated ? authState.user : null;

        // Trailing: user avatar (taps to open drawer, same as home)
        Widget avatar;
        if (user?.avatarUrl != null) {
          avatar = CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF1E293B),
            backgroundImage: CachedNetworkImageProvider(user!.avatarUrl!),
          );
        } else if (user?.displayName != null) {
          avatar = CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF1DB954),
            child: Text(
              user!.displayName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          );
        } else {
          avatar = const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFF535353),
            child: Icon(Icons.person, color: Colors.white),
          );
        }

        return AppHeader(
          leading: GestureDetector(
            onTap: onMenuPressed,
            child: avatar,
          ),
          title: 'Search',
          trailing: [
            GestureDetector(
              onTap: onToggleMode,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/app_icon.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Search bar ──────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: const Row(
        children: [
          Icon(Icons.search, color: Color(0xFF121212), size: 24),
          SizedBox(width: 10),
          Text(
            'What do you want to listen to?',
            style: TextStyle(
              color: Color(0xFF757575),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer loading ─────────────────────────────────────────────────

class _BrowseShimmer extends StatefulWidget {
  const _BrowseShimmer();

  @override
  State<_BrowseShimmer> createState() => _BrowseShimmerState();
}

class _BrowseShimmerState extends State<_BrowseShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shimmerColor = ColorTween(
          begin: const Color(0xFF1E1E1E),
          end: const Color(0xFF2A2A2A),
        ).evaluate(_controller)!;

        return CustomScrollView(
          slivers: [
            // Search bar placeholder
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // Grid placeholders
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.7,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Container(
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  childCount: 8,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Error view ──────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.grey.shade400,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade300, fontSize: 15),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                context.read<BrowseBloc>().add(const BrowseLoadRequested());
              },
              child: const Text(
                'Try again',
                style: TextStyle(
                  color: Color(0xFF1DB954),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
