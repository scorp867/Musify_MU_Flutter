import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/home_feed/application/home_feed_bloc.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/facet_chip_row.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/home_feed_shimmer.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/quick_grid_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/content_carousel_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/recents_carousel_section.dart';

/// The authenticated home feed — renders sections from Casita data.
class HomeFeedView extends StatelessWidget {
  const HomeFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeFeedBloc, HomeFeedState>(
      builder: (context, state) {
        return switch (state) {
          HomeFeedLoading() => const HomeFeedShimmer(),
          HomeFeedLoaded(:final data, :final isRefreshing) =>
            _FeedContent(data: data, isRefreshing: isRefreshing),
          HomeFeedError(:final message, :final staleData) =>
            staleData != null
                ? _FeedContent(data: staleData, isRefreshing: false)
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

  const _FeedContent({required this.data, required this.isRefreshing});

  @override
  Widget build(BuildContext context) {
    // Total items: refreshing bar (conditional) + facet row + sections + bottom padding.
    final sectionCount = data.sections.length;

    return RefreshIndicator(
      color: const Color(0xFF1DB954),
      backgroundColor: const Color(0xFF282828),
      onRefresh: () async {
        context
            .read<HomeFeedBloc>()
            .add(const HomeFeedRefreshRequested());
        await context.read<HomeFeedBloc>().stream.firstWhere(
              (s) => s is HomeFeedLoaded && !s.isRefreshing,
            );
      },
      child: ListView.builder(
        // facet row + sections + bottom padding
        itemCount: sectionCount + 2,
        itemBuilder: (context, index) {
          // 0: Facet chip row
          if (index == 0) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRefreshing)
                  const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                    minHeight: 2,
                  ),
                const FacetChipRow(),
              ],
            );
          }
          // Last: bottom padding
          if (index > sectionCount) {
            return const SizedBox(height: 120);
          }
          // Sections (1-indexed → subtract 1)
          return _buildSection(data.sections[index - 1]);
        },
      ),
    );
  }

  Widget _buildSection(HomeSection section) {
    // Route by section type to dedicated widgets.
    if (section.sectionType == 'shortcuts') {
      return QuickGridSection(title: section.title, items: section.items);
    }
    if (section.sectionType == 'recents') {
      return RecentsCarouselSection(
          title: section.title, items: section.items);
    }
    // Default: standard content carousel (albums, playlists, artists).
    return ContentCarouselSection(
        title: section.title, items: section.items);
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
