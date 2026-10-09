import 'package:flutter/material.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
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
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/podcast_preview_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/preview_carousel_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/preview_feed_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/promotion_banner_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/recents_carousel_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/reflection_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/showcase_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/story_bubble_carousel.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/vertical_card_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/video_carousel_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/video_promo_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/full_bleed_banner_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/caught_up_banner_section.dart';

/// Direct equivalent to Spotify Android's `p.s400` / `KodiakElementRegistry`.
/// Maps strongly typed Section FeatureTypes / sectionType discriminators directly to UI Widgets.
class SectionRegistry {
  const SectionRegistry();

  Widget buildSection(HomeSection section) {
    switch (section.sectionType) {
      // ── Shortcuts / Quick Grid (Tag 2: p.arn0 / p.yex0) ────────────
      case 'shortcuts':
        return QuickGridSection(title: section.title, items: section.items);

      // ── Recents Shelf (Tag 10: p.hdr0 / p.ony0) ────────────────────
      case 'recentsShelf':
        return RecentsCarouselSection(title: section.title, items: section.items);

      // ── Podcast & Video Feed Previews (Tag 4: p.kkn0 -> vab0/wab0/xab0) ─
      case 'preview':
        return PodcastPreviewSection(title: section.title, items: section.items);

      // ── Immersive Music Previews (Tag 6: p.hif0 -> iab0/jab0/kab0) ─────
      case 'immersivePreview':
      case 'associatedPreview':
        return PreviewFeedSection(title: section.title, items: section.items);

      // ── Showcase (Tag 17: p.ppx0 -> aox0) ──────────────────────────
      case 'showcase':
        return ShowcaseSection(title: section.title, items: section.items);

      // ── Video Promo (Tag 18: p.vbb0) ───────────────────────────────
      case 'videoPromo':
        return VideoPromoSection(title: section.title, items: section.items);

      // ── Audio Spotlight & Audio Promo (Tag 36 & 33: p.m7b0) ────────
      case 'audioSpotlight':
      case 'audioPromo':
        return AudioSpotlightSection(title: section.title, items: section.items);

      // ── Live Event (Tag 16: p.e270 / p.xoo0) ───────────────────────
      case 'liveEvent':
        return LiveEventSection(title: section.title, items: section.items);

      // ── Interactive Entrypoint (Tag 30: p.jtf0) ────────────────────
      case 'interactiveEntrypoint':
        return InteractivePromptSection(title: section.title, items: section.items);

      // ── Top Story Carousel / Story Bubbles (Tag 31: p.rp31) ────────
      case 'topStoryCarousel':
        return StoryBubbleCarousel(title: section.title, items: section.items);

      // ── Vertical Single Entry (Tag 24: p.ur61) ─────────────────────
      case 'verticalSingleEntry':
        return VerticalCardSection(title: section.title, items: section.items);

      // ── Reflection / Wrapped (Tag 41: p.rxr0) ──────────────────────
      case 'reflection':
        return ReflectionSection(title: section.title, items: section.items);

      // ── Inline Card (Tag 34: p.fn20) ───────────────────────────────
      case 'inlineCard':
        return InlineCardSection(title: section.title, items: section.items);

      // ── Episode List / Content Evaluation (Tag 8: p.dei) ───────────
      case 'contentEvaluationList':
        return EpisodeListSection(title: section.title, items: section.items);

      // ── Video Carousels & Watch Feed (Tag 25 & 11: p.lg81) ─────────
      case 'videoCarousel':
      case 'watchFeed':
        return VideoCarouselSection(title: section.title, items: section.items);

      // ── Preview Carousels (Tag 37 & 39: p.qcb0 / p.arn0) ───────────
      case 'previewCarousel':
      case 'previewPromotionCarousel':
        return PreviewCarouselSection(title: section.title, items: section.items);

      // ── Action Cards (Tag 15: p.d20) ───────────────────────────────
      case 'actionCardCarousel':
        return ActionCardSection(title: section.title, items: section.items);

      // ── Campaign Link Carousel (Tag 23: p.cua) ─────────────────────
      case 'campaignLinkCarousel':
        return CampaignCarouselSection(title: section.title, items: section.items);

      // ── Release Banners (Tag 12, 13, 28: p.zno0 / p.ke21) ──────────
      case 'promotionV1':
      case 'promotionV3':
      case 'bannerWithAnimations':
        return PromotionBannerSection(title: section.title, items: section.items);

      // ── 1-Tap Quick Playback (Tag 35: p.oal0) ──────────────────────
      case 'playLinkPromo':
        return PlayLinkSection(title: section.title, items: section.items);

      // ── Anchors (rendered in sticky header) ────────────────────────
      case 'anchors':
        return const SizedBox.shrink();

      // ── Standard ImageLink Carousel (Tag 3: p.h620 -> a620) ────────
      case 'imageLink':
        return ContentCarouselSection(title: section.title, items: section.items);

      // ── Full Bleed Hero Banner (Tag 26: p.FullBleedBanner) ─────────
      case 'fullBleedBanner':
        return FullBleedBannerSection(section: section);

      // ── Caught Up Celebration Banner (Tag 19: p.zno0 / p.en4) ──────
      case 'banner':
        return CaughtUpBannerSection(section: section);

      // ── Non-visual or unknown: zero fallback to carousel ───────────
      default:
        return const SizedBox.shrink();
    }
  }
}
