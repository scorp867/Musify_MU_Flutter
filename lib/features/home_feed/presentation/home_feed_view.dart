import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/ui/widgets/sticky_header_delegate.dart';
import 'package:musify_mu/features/home/presentation/widgets/home_header.dart';
import 'package:musify_mu/features/home_feed/application/home_feed_bloc.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/home_feed_shimmer.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/quick_grid_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/action_card_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/audio_spotlight_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/campaign_carousel_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/content_carousel_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/episode_list_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/inline_card_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/interactive_prompt_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/live_event_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/play_link_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/preview_carousel_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/preview_feed_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/promotion_banner_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/recents_carousel_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/reflection_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/story_bubble_carousel.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/vertical_card_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/video_carousel_section.dart';

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
          if (headerTitleRow != null)
            SliverPersistentHeader(
              pinned: true,
              delegate: StickyHeaderDelegate(
                height: 40,
                child: const HomeFilterChips(),
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
    switch (section.sectionType) {

      // ── Grid ───────────────────────────────────────────────────────
      case 'shortcuts':
        return QuickGridSection(title: section.title, items: section.items);

      // ── Recents ────────────────────────────────────────────────────
      case 'recentsShelf':
        return RecentsCarouselSection(
            title: section.title, items: section.items);

      // ── Full-bleed hero preview / Playlist previews ───────────────
      case 'preview':
      case 'immersivePreview':
      case 'associatedPreview':
        if (section.items.any((item) => item.getTrait<VideoCardTrait>() != null)) {
          return VideoCarouselSection(
              title: section.title, items: section.items);
        }
        if (section.items.any((item) => item.getTrait<PreviewCardTrait>() != null)) {
          return PreviewFeedSection(
              title: section.title, items: section.items);
        }
        return ContentCarouselSection(
            title: section.title, items: section.items);

      // ── Showcase (featured banner / "Picked for you") ──────────────
      case 'showcase':
        return PromotionBannerSection(
            title: section.title, items: section.items);

      // ── Audio spotlight / promo ────────────────────────────────────
      case 'audioSpotlight':
      case 'audioPromo':
        return AudioSpotlightSection(
            title: section.title, items: section.items);

      // ── Live events ────────────────────────────────────────────────
      case 'liveEvent':
        return LiveEventSection(title: section.title, items: section.items);

      // ── Interactive search / AI prompt ─────────────────────────────
      case 'interactiveEntrypoint':
        return InteractivePromptSection(
            title: section.title, items: section.items);

      // ── Story bubbles ──────────────────────────────────────────────
      case 'topStoryCarousel':
        return StoryBubbleCarousel(
            title: section.title, items: section.items);

      // ── Single large vertical card ─────────────────────────────────
      case 'verticalSingleEntry':
        return VerticalCardSection(
            title: section.title, items: section.items);

      // ── Reflection (Wrapped-style) ─────────────────────────────────
      case 'reflection':
        return ReflectionSection(title: section.title, items: section.items);

      // ── Inline card ────────────────────────────────────────────────
      case 'inlineCard':
        return InlineCardSection(title: section.title, items: section.items);


      // ── Episode list ───────────────────────────────────────────────
      case 'contentEvaluationList':
        return EpisodeListSection(title: section.title, items: section.items);

      // ── Video carousels ────────────────────────────────────────────
      case 'videoCarousel':
      case 'watchFeed':
        return VideoCarouselSection(
            title: section.title, items: section.items);

      // ── Preview carousels ──────────────────────────────────────────
      case 'previewCarousel':
      case 'previewPromotionCarousel':
        return PreviewCarouselSection(
            title: section.title, items: section.items);

      // ── Action cards (interactive prompts) ─────────────────────────
      case 'actionCardCarousel':
        return ActionCardSection(
            title: section.title, items: section.items);

      // ── Campaign carousels (RADAR, EQUAL, etc.) ────────────────────
      case 'campaignLinkCarousel':
        return CampaignCarouselSection(
            title: section.title, items: section.items);

      // ── Release & promo banners ────────────────────────────────────
      case 'promotionV1':
      case 'promotionV3':
      case 'bannerWithAnimations':
        return PromotionBannerSection(
            title: section.title, items: section.items);

      // ── 1-tap quick playback ───────────────────────────────────────
      case 'playLinkPromo':
        return PlayLinkSection(
            title: section.title, items: section.items);

      // ── Video promo ────────────────────────────────────────────────
      case 'videoPromo':
        return VideoCarouselSection(
            title: section.title, items: section.items);

      // ── Text-only / non-visual (skip) ──────────────────────────────
      case 'narrative':
      case 'callToAction':
        return const SizedBox.shrink();

      // ── Standard horizontal carousels (default) ────────────────────
      case 'imageLink':
      default:
        return ContentCarouselSection(
            title: section.title, items: section.items);
    }
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
