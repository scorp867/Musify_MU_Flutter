import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/ui/widgets/sticky_header_delegate.dart';
import 'package:musify_mu/features/home/presentation/widgets/home_header.dart';
import 'package:musify_mu/features/home_feed/application/home_feed_bloc.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:musify_mu/features/home_feed/presentation/section_registry.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/home_feed_shimmer.dart';

/// The authenticated home feed -- renders sections from Casita data.
///
/// When [headerTitleRow] is provided, it's included as a scrollable
/// sliver at the top (scrolls away), with filter chips pinned below.
class HomeFeedView extends StatelessWidget {
  final Widget? headerTitleRow;

  const HomeFeedView({super.key, this.headerTitleRow});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeFeedBloc, HomeFeedState>(
      builder: (context, state) {
        return switch (state) {
          HomeFeedLoading() => const HomeFeedShimmer(),
          HomeFeedLoaded(:final data, :final isRefreshing) =>
            _FeedContent(
              data: data,
              isRefreshing: isRefreshing,
              headerTitleRow: headerTitleRow,
            ),
          HomeFeedError(:final message, :final staleData) =>
            staleData != null
                ? _FeedContent(
                    data: staleData,
                    isRefreshing: false,
                    headerTitleRow: headerTitleRow,
                  )
                : _ErrorView(message: message),
        };
      },
    );
  }
}

// ─── Feed content ────────────────────────────────────────────────────

class _FeedContent extends StatelessWidget {
  final HomeViewData data;
  final bool isRefreshing;
  final Widget? headerTitleRow;

  const _FeedContent({
    required this.data,
    required this.isRefreshing,
    this.headerTitleRow,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF1DB954),
      backgroundColor: const Color(0xFF282828),
      onRefresh: () async {
        context
            .read<HomeFeedBloc>()
            .add(const HomeFeedRefreshRequested());
        await context.read<HomeFeedBloc>().stream.firstWhere(
              (s) => (s is HomeFeedLoaded && !s.isRefreshing) || s is HomeFeedError,
            );
      },
      child: CustomScrollView(
        slivers: [
          // Title row (floating -- reappears on any downward scroll)
          if (headerTitleRow != null)
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
              title: headerTitleRow,
            ),

          // Filter chips (pinned -- stays visible when scrolling)
          // Only show when anchors/chips exist; collapses pill section otherwise (Rule B)
          if (headerTitleRow != null && data.chips.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: StickyHeaderDelegate(
                height: 40,
                child: HomeFilterChips(chips: data.chips),
              ),
            ),

          // Feed sections
          SliverList.builder(
            itemCount: data.sections.length + 1,
            itemBuilder: (context, index) {
              if (index >= data.sections.length) {
                return const SizedBox(height: 120);
              }
              return _buildSection(data.sections[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection(HomeSection section) {
    return const SectionRegistry().buildSection(section);
  }

}

// ─── Error fallback ──────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                color: Colors.grey.shade600, size: 48),
            const SizedBox(height: 16),
            Text(
              'Couldn\'t load your feed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => context
                  .read<HomeFeedBloc>()
                  .add(const HomeFeedLoadRequested()),
              child: const Text(
                'Retry',
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
