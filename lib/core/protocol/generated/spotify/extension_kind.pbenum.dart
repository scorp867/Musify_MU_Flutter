// This is a generated file - do not edit.
//
// Generated from spotify/extension_kind.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ExtensionKind extends $pb.ProtobufEnum {
  static const ExtensionKind UNKNOWN_EXTENSION =
      ExtensionKind._(0, _omitEnumNames ? '' : 'UNKNOWN_EXTENSION');
  static const ExtensionKind CANVAZ =
      ExtensionKind._(1, _omitEnumNames ? '' : 'CANVAZ');
  static const ExtensionKind STORYLINES =
      ExtensionKind._(2, _omitEnumNames ? '' : 'STORYLINES');
  static const ExtensionKind PODCAST_TOPICS =
      ExtensionKind._(3, _omitEnumNames ? '' : 'PODCAST_TOPICS');
  static const ExtensionKind PODCAST_SEGMENTS =
      ExtensionKind._(4, _omitEnumNames ? '' : 'PODCAST_SEGMENTS');
  static const ExtensionKind AUDIO_FILES =
      ExtensionKind._(5, _omitEnumNames ? '' : 'AUDIO_FILES');
  static const ExtensionKind TRACK_DESCRIPTOR =
      ExtensionKind._(6, _omitEnumNames ? '' : 'TRACK_DESCRIPTOR');
  static const ExtensionKind PODCAST_COUNTER =
      ExtensionKind._(7, _omitEnumNames ? '' : 'PODCAST_COUNTER');
  static const ExtensionKind ARTIST_V4 =
      ExtensionKind._(8, _omitEnumNames ? '' : 'ARTIST_V4');
  static const ExtensionKind ALBUM_V4 =
      ExtensionKind._(9, _omitEnumNames ? '' : 'ALBUM_V4');
  static const ExtensionKind TRACK_V4 =
      ExtensionKind._(10, _omitEnumNames ? '' : 'TRACK_V4');
  static const ExtensionKind SHOW_V4 =
      ExtensionKind._(11, _omitEnumNames ? '' : 'SHOW_V4');
  static const ExtensionKind EPISODE_V4 =
      ExtensionKind._(12, _omitEnumNames ? '' : 'EPISODE_V4');
  static const ExtensionKind PODCAST_HTML_DESCRIPTION =
      ExtensionKind._(13, _omitEnumNames ? '' : 'PODCAST_HTML_DESCRIPTION');
  static const ExtensionKind PODCAST_QUOTES =
      ExtensionKind._(14, _omitEnumNames ? '' : 'PODCAST_QUOTES');
  static const ExtensionKind USER_PROFILE =
      ExtensionKind._(15, _omitEnumNames ? '' : 'USER_PROFILE');
  static const ExtensionKind CANVAS_V1 =
      ExtensionKind._(16, _omitEnumNames ? '' : 'CANVAS_V1');
  static const ExtensionKind SHOW_V4_BASE =
      ExtensionKind._(17, _omitEnumNames ? '' : 'SHOW_V4_BASE');
  static const ExtensionKind SHOW_V4_EPISODES_ASSOC =
      ExtensionKind._(18, _omitEnumNames ? '' : 'SHOW_V4_EPISODES_ASSOC');
  static const ExtensionKind TRACK_DESCRIPTOR_SIGNATURES =
      ExtensionKind._(19, _omitEnumNames ? '' : 'TRACK_DESCRIPTOR_SIGNATURES');
  static const ExtensionKind PODCAST_AD_SEGMENTS =
      ExtensionKind._(20, _omitEnumNames ? '' : 'PODCAST_AD_SEGMENTS');
  static const ExtensionKind EPISODE_TRANSCRIPTS =
      ExtensionKind._(21, _omitEnumNames ? '' : 'EPISODE_TRANSCRIPTS');
  static const ExtensionKind PODCAST_SUBSCRIPTIONS =
      ExtensionKind._(22, _omitEnumNames ? '' : 'PODCAST_SUBSCRIPTIONS');
  static const ExtensionKind EXTRACTED_COLOR =
      ExtensionKind._(23, _omitEnumNames ? '' : 'EXTRACTED_COLOR');
  static const ExtensionKind PODCAST_VIRALITY =
      ExtensionKind._(24, _omitEnumNames ? '' : 'PODCAST_VIRALITY');
  static const ExtensionKind IMAGE_SPARKLES_HACK =
      ExtensionKind._(25, _omitEnumNames ? '' : 'IMAGE_SPARKLES_HACK');
  static const ExtensionKind PODCAST_POPULARITY_HACK =
      ExtensionKind._(26, _omitEnumNames ? '' : 'PODCAST_POPULARITY_HACK');
  static const ExtensionKind AUTOMIX_MODE =
      ExtensionKind._(27, _omitEnumNames ? '' : 'AUTOMIX_MODE');
  static const ExtensionKind CUEPOINTS =
      ExtensionKind._(28, _omitEnumNames ? '' : 'CUEPOINTS');
  static const ExtensionKind PODCAST_POLL =
      ExtensionKind._(29, _omitEnumNames ? '' : 'PODCAST_POLL');
  static const ExtensionKind EPISODE_ACCESS =
      ExtensionKind._(30, _omitEnumNames ? '' : 'EPISODE_ACCESS');
  static const ExtensionKind SHOW_ACCESS =
      ExtensionKind._(31, _omitEnumNames ? '' : 'SHOW_ACCESS');
  static const ExtensionKind PODCAST_QNA =
      ExtensionKind._(32, _omitEnumNames ? '' : 'PODCAST_QNA');
  static const ExtensionKind CLIPS =
      ExtensionKind._(33, _omitEnumNames ? '' : 'CLIPS');
  static const ExtensionKind SHOW_V5 =
      ExtensionKind._(34, _omitEnumNames ? '' : 'SHOW_V5');
  static const ExtensionKind EPISODE_V5 =
      ExtensionKind._(35, _omitEnumNames ? '' : 'EPISODE_V5');
  static const ExtensionKind PODCAST_CTA_CARDS =
      ExtensionKind._(36, _omitEnumNames ? '' : 'PODCAST_CTA_CARDS');
  static const ExtensionKind PODCAST_RATING =
      ExtensionKind._(37, _omitEnumNames ? '' : 'PODCAST_RATING');
  static const ExtensionKind DISPLAY_SEGMENTS =
      ExtensionKind._(38, _omitEnumNames ? '' : 'DISPLAY_SEGMENTS');
  static const ExtensionKind GREENROOM =
      ExtensionKind._(39, _omitEnumNames ? '' : 'GREENROOM');
  static const ExtensionKind USER_CREATED =
      ExtensionKind._(40, _omitEnumNames ? '' : 'USER_CREATED');
  static const ExtensionKind SHOW_DESCRIPTION =
      ExtensionKind._(41, _omitEnumNames ? '' : 'SHOW_DESCRIPTION');
  static const ExtensionKind SHOW_HTML_DESCRIPTION =
      ExtensionKind._(42, _omitEnumNames ? '' : 'SHOW_HTML_DESCRIPTION');
  static const ExtensionKind SHOW_PLAYABILITY =
      ExtensionKind._(43, _omitEnumNames ? '' : 'SHOW_PLAYABILITY');
  static const ExtensionKind EPISODE_DESCRIPTION =
      ExtensionKind._(44, _omitEnumNames ? '' : 'EPISODE_DESCRIPTION');
  static const ExtensionKind EPISODE_HTML_DESCRIPTION =
      ExtensionKind._(45, _omitEnumNames ? '' : 'EPISODE_HTML_DESCRIPTION');
  static const ExtensionKind EPISODE_PLAYABILITY =
      ExtensionKind._(46, _omitEnumNames ? '' : 'EPISODE_PLAYABILITY');
  static const ExtensionKind SHOW_EPISODES_ASSOC =
      ExtensionKind._(47, _omitEnumNames ? '' : 'SHOW_EPISODES_ASSOC');
  static const ExtensionKind CLIENT_CONFIG =
      ExtensionKind._(48, _omitEnumNames ? '' : 'CLIENT_CONFIG');
  static const ExtensionKind PLAYLISTABILITY =
      ExtensionKind._(49, _omitEnumNames ? '' : 'PLAYLISTABILITY');
  static const ExtensionKind AUDIOBOOK_V5 =
      ExtensionKind._(50, _omitEnumNames ? '' : 'AUDIOBOOK_V5');
  static const ExtensionKind CHAPTER_V5 =
      ExtensionKind._(51, _omitEnumNames ? '' : 'CHAPTER_V5');
  static const ExtensionKind AUDIOBOOK_SPECIFICS =
      ExtensionKind._(52, _omitEnumNames ? '' : 'AUDIOBOOK_SPECIFICS');
  static const ExtensionKind EPISODE_RANKING =
      ExtensionKind._(53, _omitEnumNames ? '' : 'EPISODE_RANKING');
  static const ExtensionKind HTML_DESCRIPTION =
      ExtensionKind._(54, _omitEnumNames ? '' : 'HTML_DESCRIPTION');
  static const ExtensionKind CREATOR_CHANNEL =
      ExtensionKind._(55, _omitEnumNames ? '' : 'CREATOR_CHANNEL');
  static const ExtensionKind AUDIOBOOK_PROVIDERS =
      ExtensionKind._(56, _omitEnumNames ? '' : 'AUDIOBOOK_PROVIDERS');
  static const ExtensionKind PLAY_TRAIT =
      ExtensionKind._(57, _omitEnumNames ? '' : 'PLAY_TRAIT');
  static const ExtensionKind CONTENT_WARNING =
      ExtensionKind._(58, _omitEnumNames ? '' : 'CONTENT_WARNING');
  static const ExtensionKind IMAGE_CUE =
      ExtensionKind._(59, _omitEnumNames ? '' : 'IMAGE_CUE');
  static const ExtensionKind STREAM_COUNT =
      ExtensionKind._(60, _omitEnumNames ? '' : 'STREAM_COUNT');
  static const ExtensionKind AUDIO_ATTRIBUTES =
      ExtensionKind._(61, _omitEnumNames ? '' : 'AUDIO_ATTRIBUTES');
  static const ExtensionKind NAVIGABLE_TRAIT =
      ExtensionKind._(62, _omitEnumNames ? '' : 'NAVIGABLE_TRAIT');
  static const ExtensionKind NEXT_BEST_EPISODE =
      ExtensionKind._(63, _omitEnumNames ? '' : 'NEXT_BEST_EPISODE');
  static const ExtensionKind AUDIOBOOK_PRICE =
      ExtensionKind._(64, _omitEnumNames ? '' : 'AUDIOBOOK_PRICE');
  static const ExtensionKind EXPRESSIVE_PLAYLISTS =
      ExtensionKind._(65, _omitEnumNames ? '' : 'EXPRESSIVE_PLAYLISTS');
  static const ExtensionKind DYNAMIC_SHOW_EPISODE =
      ExtensionKind._(66, _omitEnumNames ? '' : 'DYNAMIC_SHOW_EPISODE');
  static const ExtensionKind LIVE =
      ExtensionKind._(67, _omitEnumNames ? '' : 'LIVE');
  static const ExtensionKind SKIP_PLAYED =
      ExtensionKind._(68, _omitEnumNames ? '' : 'SKIP_PLAYED');
  static const ExtensionKind AD_BREAK_FREE_PODCASTS =
      ExtensionKind._(69, _omitEnumNames ? '' : 'AD_BREAK_FREE_PODCASTS');
  static const ExtensionKind ASSOCIATIONS =
      ExtensionKind._(70, _omitEnumNames ? '' : 'ASSOCIATIONS');
  static const ExtensionKind PLAYLIST_EVALUATION =
      ExtensionKind._(71, _omitEnumNames ? '' : 'PLAYLIST_EVALUATION');
  static const ExtensionKind CACHE_INVALIDATIONS =
      ExtensionKind._(72, _omitEnumNames ? '' : 'CACHE_INVALIDATIONS');
  static const ExtensionKind LIVESTREAM_ENTITY =
      ExtensionKind._(73, _omitEnumNames ? '' : 'LIVESTREAM_ENTITY');
  static const ExtensionKind SINGLE_TAP_REACTIONS =
      ExtensionKind._(74, _omitEnumNames ? '' : 'SINGLE_TAP_REACTIONS');
  static const ExtensionKind USER_COMMENTS =
      ExtensionKind._(75, _omitEnumNames ? '' : 'USER_COMMENTS');
  static const ExtensionKind CLIENT_RESTRICTIONS =
      ExtensionKind._(76, _omitEnumNames ? '' : 'CLIENT_RESTRICTIONS');
  static const ExtensionKind PODCAST_GUEST =
      ExtensionKind._(77, _omitEnumNames ? '' : 'PODCAST_GUEST');
  static const ExtensionKind PLAYABILITY =
      ExtensionKind._(78, _omitEnumNames ? '' : 'PLAYABILITY');
  static const ExtensionKind COVER_IMAGE =
      ExtensionKind._(79, _omitEnumNames ? '' : 'COVER_IMAGE');
  static const ExtensionKind SHARE_TRAIT =
      ExtensionKind._(80, _omitEnumNames ? '' : 'SHARE_TRAIT');
  static const ExtensionKind INSTANCE_SHARING =
      ExtensionKind._(81, _omitEnumNames ? '' : 'INSTANCE_SHARING');
  static const ExtensionKind ARTIST_TOUR =
      ExtensionKind._(82, _omitEnumNames ? '' : 'ARTIST_TOUR');
  static const ExtensionKind AUDIOBOOK_GENRE =
      ExtensionKind._(83, _omitEnumNames ? '' : 'AUDIOBOOK_GENRE');
  static const ExtensionKind CONCEPT =
      ExtensionKind._(84, _omitEnumNames ? '' : 'CONCEPT');
  static const ExtensionKind ORIGINAL_VIDEO =
      ExtensionKind._(85, _omitEnumNames ? '' : 'ORIGINAL_VIDEO');
  static const ExtensionKind SMART_SHUFFLE =
      ExtensionKind._(86, _omitEnumNames ? '' : 'SMART_SHUFFLE');
  static const ExtensionKind LIVE_EVENTS =
      ExtensionKind._(87, _omitEnumNames ? '' : 'LIVE_EVENTS');
  static const ExtensionKind AUDIOBOOK_RELATIONS =
      ExtensionKind._(88, _omitEnumNames ? '' : 'AUDIOBOOK_RELATIONS');
  static const ExtensionKind HOME_POC_BASECARD =
      ExtensionKind._(89, _omitEnumNames ? '' : 'HOME_POC_BASECARD');
  static const ExtensionKind AUDIOBOOK_SUPPLEMENTS =
      ExtensionKind._(90, _omitEnumNames ? '' : 'AUDIOBOOK_SUPPLEMENTS');
  static const ExtensionKind PAID_PODCAST_BANNER =
      ExtensionKind._(91, _omitEnumNames ? '' : 'PAID_PODCAST_BANNER');
  static const ExtensionKind FEWER_ADS =
      ExtensionKind._(92, _omitEnumNames ? '' : 'FEWER_ADS');
  static const ExtensionKind WATCH_FEED_SHOW_EXPLORER =
      ExtensionKind._(93, _omitEnumNames ? '' : 'WATCH_FEED_SHOW_EXPLORER');
  static const ExtensionKind TRACK_EXTRA_DESCRIPTORS =
      ExtensionKind._(94, _omitEnumNames ? '' : 'TRACK_EXTRA_DESCRIPTORS');
  static const ExtensionKind TRACK_EXTRA_AUDIO_ATTRIBUTES =
      ExtensionKind._(95, _omitEnumNames ? '' : 'TRACK_EXTRA_AUDIO_ATTRIBUTES');
  static const ExtensionKind TRACK_EXTENDED_CREDITS =
      ExtensionKind._(96, _omitEnumNames ? '' : 'TRACK_EXTENDED_CREDITS');
  static const ExtensionKind SIMPLE_TRAIT =
      ExtensionKind._(97, _omitEnumNames ? '' : 'SIMPLE_TRAIT');
  static const ExtensionKind AUDIO_ASSOCIATIONS =
      ExtensionKind._(98, _omitEnumNames ? '' : 'AUDIO_ASSOCIATIONS');
  static const ExtensionKind VIDEO_ASSOCIATIONS =
      ExtensionKind._(99, _omitEnumNames ? '' : 'VIDEO_ASSOCIATIONS');
  static const ExtensionKind PLAYLIST_TUNER =
      ExtensionKind._(100, _omitEnumNames ? '' : 'PLAYLIST_TUNER');
  static const ExtensionKind ARTIST_VIDEOS_ENTRYPOINT =
      ExtensionKind._(101, _omitEnumNames ? '' : 'ARTIST_VIDEOS_ENTRYPOINT');
  static const ExtensionKind ALBUM_PRERELEASE =
      ExtensionKind._(102, _omitEnumNames ? '' : 'ALBUM_PRERELEASE');
  static const ExtensionKind CONTENT_ALTERNATIVES =
      ExtensionKind._(103, _omitEnumNames ? '' : 'CONTENT_ALTERNATIVES');
  static const ExtensionKind SNAPSHOT_SHARING =
      ExtensionKind._(105, _omitEnumNames ? '' : 'SNAPSHOT_SHARING');
  static const ExtensionKind DISPLAY_SEGMENTS_COUNT =
      ExtensionKind._(106, _omitEnumNames ? '' : 'DISPLAY_SEGMENTS_COUNT');
  static const ExtensionKind PODCAST_FEATURED_EPISODE =
      ExtensionKind._(107, _omitEnumNames ? '' : 'PODCAST_FEATURED_EPISODE');
  static const ExtensionKind PODCAST_SPONSORED_CONTENT =
      ExtensionKind._(108, _omitEnumNames ? '' : 'PODCAST_SPONSORED_CONTENT');
  static const ExtensionKind PODCAST_EPISODE_TOPICS_LLM =
      ExtensionKind._(109, _omitEnumNames ? '' : 'PODCAST_EPISODE_TOPICS_LLM');
  static const ExtensionKind PODCAST_EPISODE_TOPICS_KG =
      ExtensionKind._(110, _omitEnumNames ? '' : 'PODCAST_EPISODE_TOPICS_KG');
  static const ExtensionKind EPISODE_RANKING_POPULARITY =
      ExtensionKind._(111, _omitEnumNames ? '' : 'EPISODE_RANKING_POPULARITY');
  static const ExtensionKind MERCH =
      ExtensionKind._(112, _omitEnumNames ? '' : 'MERCH');
  static const ExtensionKind COMPANION_CONTENT =
      ExtensionKind._(113, _omitEnumNames ? '' : 'COMPANION_CONTENT');
  static const ExtensionKind WATCH_FEED_ENTITY_EXPLORER =
      ExtensionKind._(114, _omitEnumNames ? '' : 'WATCH_FEED_ENTITY_EXPLORER');
  static const ExtensionKind ANCHOR_CARD_TRAIT =
      ExtensionKind._(115, _omitEnumNames ? '' : 'ANCHOR_CARD_TRAIT');
  static const ExtensionKind AUDIO_PREVIEW_PLAYBACK_TRAIT = ExtensionKind._(
      116, _omitEnumNames ? '' : 'AUDIO_PREVIEW_PLAYBACK_TRAIT');
  static const ExtensionKind VIDEO_PREVIEW_STILL_TRAIT =
      ExtensionKind._(117, _omitEnumNames ? '' : 'VIDEO_PREVIEW_STILL_TRAIT');
  static const ExtensionKind PREVIEW_CARD_TRAIT =
      ExtensionKind._(118, _omitEnumNames ? '' : 'PREVIEW_CARD_TRAIT');
  static const ExtensionKind SHORTCUTS_CARD_TRAIT =
      ExtensionKind._(119, _omitEnumNames ? '' : 'SHORTCUTS_CARD_TRAIT');
  static const ExtensionKind VIDEO_PREVIEW_PLAYBACK_TRAIT = ExtensionKind._(
      120, _omitEnumNames ? '' : 'VIDEO_PREVIEW_PLAYBACK_TRAIT');
  static const ExtensionKind COURSE_SPECIFICS =
      ExtensionKind._(121, _omitEnumNames ? '' : 'COURSE_SPECIFICS');
  static const ExtensionKind CONCERT =
      ExtensionKind._(122, _omitEnumNames ? '' : 'CONCERT');
  static const ExtensionKind CONCERT_LOCATION =
      ExtensionKind._(123, _omitEnumNames ? '' : 'CONCERT_LOCATION');
  static const ExtensionKind CONCERT_MARKETING =
      ExtensionKind._(124, _omitEnumNames ? '' : 'CONCERT_MARKETING');
  static const ExtensionKind CONCERT_PERFORMERS =
      ExtensionKind._(125, _omitEnumNames ? '' : 'CONCERT_PERFORMERS');
  static const ExtensionKind TRACK_PAIR_TRANSITION =
      ExtensionKind._(126, _omitEnumNames ? '' : 'TRACK_PAIR_TRANSITION');
  static const ExtensionKind CONTENT_TYPE_TRAIT =
      ExtensionKind._(127, _omitEnumNames ? '' : 'CONTENT_TYPE_TRAIT');
  static const ExtensionKind NAME_TRAIT =
      ExtensionKind._(128, _omitEnumNames ? '' : 'NAME_TRAIT');
  static const ExtensionKind ARTWORK_TRAIT =
      ExtensionKind._(129, _omitEnumNames ? '' : 'ARTWORK_TRAIT');
  static const ExtensionKind RELEASE_DATE_TRAIT =
      ExtensionKind._(130, _omitEnumNames ? '' : 'RELEASE_DATE_TRAIT');
  static const ExtensionKind CREDITS_TRAIT =
      ExtensionKind._(131, _omitEnumNames ? '' : 'CREDITS_TRAIT');
  static const ExtensionKind RELEASE_URI_TRAIT =
      ExtensionKind._(132, _omitEnumNames ? '' : 'RELEASE_URI_TRAIT');
  static const ExtensionKind ENTITY_CAPPING =
      ExtensionKind._(133, _omitEnumNames ? '' : 'ENTITY_CAPPING');
  static const ExtensionKind LESSON_SPECIFICS =
      ExtensionKind._(134, _omitEnumNames ? '' : 'LESSON_SPECIFICS');
  static const ExtensionKind CONCERT_OFFERS =
      ExtensionKind._(135, _omitEnumNames ? '' : 'CONCERT_OFFERS');
  static const ExtensionKind TRANSITION_MAPS =
      ExtensionKind._(136, _omitEnumNames ? '' : 'TRANSITION_MAPS');
  static const ExtensionKind ARTIST_HAS_CONCERTS =
      ExtensionKind._(137, _omitEnumNames ? '' : 'ARTIST_HAS_CONCERTS');
  static const ExtensionKind PRERELEASE =
      ExtensionKind._(138, _omitEnumNames ? '' : 'PRERELEASE');
  static const ExtensionKind PLAYLIST_ATTRIBUTES_V2 =
      ExtensionKind._(139, _omitEnumNames ? '' : 'PLAYLIST_ATTRIBUTES_V2');
  static const ExtensionKind LIST_ATTRIBUTES_V2 =
      ExtensionKind._(140, _omitEnumNames ? '' : 'LIST_ATTRIBUTES_V2');
  static const ExtensionKind LIST_METADATA =
      ExtensionKind._(141, _omitEnumNames ? '' : 'LIST_METADATA');
  static const ExtensionKind LIST_TUNER_AUDIO_ANALYSIS =
      ExtensionKind._(142, _omitEnumNames ? '' : 'LIST_TUNER_AUDIO_ANALYSIS');
  static const ExtensionKind LIST_TUNER_CUEPOINTS =
      ExtensionKind._(143, _omitEnumNames ? '' : 'LIST_TUNER_CUEPOINTS');
  static const ExtensionKind CONTENT_RATING_TRAIT =
      ExtensionKind._(144, _omitEnumNames ? '' : 'CONTENT_RATING_TRAIT');
  static const ExtensionKind COPYRIGHT_TRAIT =
      ExtensionKind._(145, _omitEnumNames ? '' : 'COPYRIGHT_TRAIT');
  static const ExtensionKind SUPPORTED_BADGES =
      ExtensionKind._(146, _omitEnumNames ? '' : 'SUPPORTED_BADGES');
  static const ExtensionKind BADGES =
      ExtensionKind._(147, _omitEnumNames ? '' : 'BADGES');
  static const ExtensionKind PREVIEW_TRAIT =
      ExtensionKind._(148, _omitEnumNames ? '' : 'PREVIEW_TRAIT');
  static const ExtensionKind ROOTLISTABILITY_TRAIT =
      ExtensionKind._(149, _omitEnumNames ? '' : 'ROOTLISTABILITY_TRAIT');
  static const ExtensionKind LOCAL_CONCERTS =
      ExtensionKind._(150, _omitEnumNames ? '' : 'LOCAL_CONCERTS');
  static const ExtensionKind RECOMMENDED_PLAYLISTS =
      ExtensionKind._(151, _omitEnumNames ? '' : 'RECOMMENDED_PLAYLISTS');
  static const ExtensionKind POPULAR_RELEASES =
      ExtensionKind._(152, _omitEnumNames ? '' : 'POPULAR_RELEASES');
  static const ExtensionKind RELATED_RELEASES =
      ExtensionKind._(153, _omitEnumNames ? '' : 'RELATED_RELEASES');
  static const ExtensionKind SHARE_RESTRICTIONS =
      ExtensionKind._(154, _omitEnumNames ? '' : 'SHARE_RESTRICTIONS');
  static const ExtensionKind CONCERT_OFFER =
      ExtensionKind._(155, _omitEnumNames ? '' : 'CONCERT_OFFER');
  static const ExtensionKind CONCERT_OFFER_PROVIDER =
      ExtensionKind._(156, _omitEnumNames ? '' : 'CONCERT_OFFER_PROVIDER');
  static const ExtensionKind ENTITY_BOOKMARKS =
      ExtensionKind._(157, _omitEnumNames ? '' : 'ENTITY_BOOKMARKS');
  static const ExtensionKind PRIVACY_TRAIT =
      ExtensionKind._(158, _omitEnumNames ? '' : 'PRIVACY_TRAIT');
  static const ExtensionKind DUPLICATE_ITEMS_TRAIT =
      ExtensionKind._(159, _omitEnumNames ? '' : 'DUPLICATE_ITEMS_TRAIT');
  static const ExtensionKind REORDERING_TRAIT =
      ExtensionKind._(160, _omitEnumNames ? '' : 'REORDERING_TRAIT');
  static const ExtensionKind PODCAST_RESUMPTION_SEGMENTS =
      ExtensionKind._(161, _omitEnumNames ? '' : 'PODCAST_RESUMPTION_SEGMENTS');
  static const ExtensionKind ARTIST_EXPRESSION_VIDEO =
      ExtensionKind._(162, _omitEnumNames ? '' : 'ARTIST_EXPRESSION_VIDEO');
  static const ExtensionKind PRERELEASE_VIDEO =
      ExtensionKind._(163, _omitEnumNames ? '' : 'PRERELEASE_VIDEO');
  static const ExtensionKind GATED_ENTITY_RELATIONS =
      ExtensionKind._(164, _omitEnumNames ? '' : 'GATED_ENTITY_RELATIONS');
  static const ExtensionKind RELATED_CREATORS_SECTION =
      ExtensionKind._(165, _omitEnumNames ? '' : 'RELATED_CREATORS_SECTION');
  static const ExtensionKind CREATORS_APPEARS_ON_SECTION =
      ExtensionKind._(166, _omitEnumNames ? '' : 'CREATORS_APPEARS_ON_SECTION');
  static const ExtensionKind PROMO_V1_TRAIT =
      ExtensionKind._(167, _omitEnumNames ? '' : 'PROMO_V1_TRAIT');
  static const ExtensionKind SPEECHLESS_SHARE_CARD =
      ExtensionKind._(168, _omitEnumNames ? '' : 'SPEECHLESS_SHARE_CARD');
  static const ExtensionKind TOP_PLAYABLES_SECTION =
      ExtensionKind._(169, _omitEnumNames ? '' : 'TOP_PLAYABLES_SECTION');
  static const ExtensionKind AUTO_LENS =
      ExtensionKind._(170, _omitEnumNames ? '' : 'AUTO_LENS');
  static const ExtensionKind PROMO_V3_TRAIT =
      ExtensionKind._(171, _omitEnumNames ? '' : 'PROMO_V3_TRAIT');
  static const ExtensionKind TRACK_CONTENT_FILTER =
      ExtensionKind._(172, _omitEnumNames ? '' : 'TRACK_CONTENT_FILTER');
  static const ExtensionKind HIGHLIGHTABILITY =
      ExtensionKind._(173, _omitEnumNames ? '' : 'HIGHLIGHTABILITY');
  static const ExtensionKind LINK_CARD_WITH_IMAGE_TRAIT =
      ExtensionKind._(174, _omitEnumNames ? '' : 'LINK_CARD_WITH_IMAGE_TRAIT');
  static const ExtensionKind TRACK_CLOUD_SECTION =
      ExtensionKind._(175, _omitEnumNames ? '' : 'TRACK_CLOUD_SECTION');
  static const ExtensionKind EPISODE_TOPICS =
      ExtensionKind._(176, _omitEnumNames ? '' : 'EPISODE_TOPICS');
  static const ExtensionKind VIDEO_THUMBNAIL =
      ExtensionKind._(177, _omitEnumNames ? '' : 'VIDEO_THUMBNAIL');
  static const ExtensionKind IDENTITY_TRAIT =
      ExtensionKind._(178, _omitEnumNames ? '' : 'IDENTITY_TRAIT');
  static const ExtensionKind VISUAL_IDENTITY_TRAIT =
      ExtensionKind._(179, _omitEnumNames ? '' : 'VISUAL_IDENTITY_TRAIT');
  static const ExtensionKind CONTENT_TYPE_V2_TRAIT =
      ExtensionKind._(180, _omitEnumNames ? '' : 'CONTENT_TYPE_V2_TRAIT');
  static const ExtensionKind PREVIEW_PLAYBACK_TRAIT =
      ExtensionKind._(181, _omitEnumNames ? '' : 'PREVIEW_PLAYBACK_TRAIT');
  static const ExtensionKind CONSUMPTION_EXPERIENCE_TRAIT = ExtensionKind._(
      182, _omitEnumNames ? '' : 'CONSUMPTION_EXPERIENCE_TRAIT');
  static const ExtensionKind PUBLISHING_METADATA_TRAIT =
      ExtensionKind._(183, _omitEnumNames ? '' : 'PUBLISHING_METADATA_TRAIT');
  static const ExtensionKind DETAILED_EVALUATION_TRAIT =
      ExtensionKind._(184, _omitEnumNames ? '' : 'DETAILED_EVALUATION_TRAIT');
  static const ExtensionKind ON_PLATFORM_REPUTATION_TRAIT = ExtensionKind._(
      185, _omitEnumNames ? '' : 'ON_PLATFORM_REPUTATION_TRAIT');
  static const ExtensionKind CREDITS_V2_TRAIT =
      ExtensionKind._(186, _omitEnumNames ? '' : 'CREDITS_V2_TRAIT');
  static const ExtensionKind HIGHLIGHT_PLAYABILITY_TRAIT =
      ExtensionKind._(187, _omitEnumNames ? '' : 'HIGHLIGHT_PLAYABILITY_TRAIT');
  static const ExtensionKind SHOW_EPISODE_LIST =
      ExtensionKind._(188, _omitEnumNames ? '' : 'SHOW_EPISODE_LIST');
  static const ExtensionKind AVAILABLE_RELEASES =
      ExtensionKind._(189, _omitEnumNames ? '' : 'AVAILABLE_RELEASES');
  static const ExtensionKind PLAYLIST_DESCRIPTORS =
      ExtensionKind._(190, _omitEnumNames ? '' : 'PLAYLIST_DESCRIPTORS');
  static const ExtensionKind LINK_CARD_WITH_ANIMATIONS_TRAIT = ExtensionKind._(
      191, _omitEnumNames ? '' : 'LINK_CARD_WITH_ANIMATIONS_TRAIT');
  static const ExtensionKind RECAP =
      ExtensionKind._(192, _omitEnumNames ? '' : 'RECAP');
  static const ExtensionKind AUDIOBOOK_COMPANION_CONTENT =
      ExtensionKind._(193, _omitEnumNames ? '' : 'AUDIOBOOK_COMPANION_CONTENT');
  static const ExtensionKind THREE_OH_THREE_PLAY_TRAIT =
      ExtensionKind._(194, _omitEnumNames ? '' : 'THREE_OH_THREE_PLAY_TRAIT');
  static const ExtensionKind ARTIST_WRAPPED_2024_VIDEO =
      ExtensionKind._(195, _omitEnumNames ? '' : 'ARTIST_WRAPPED_2024_VIDEO');
  static const ExtensionKind PLAYBACK_TRAIT =
      ExtensionKind._(212, _omitEnumNames ? '' : 'PLAYBACK_TRAIT');

  static const $core.List<ExtensionKind> values = <ExtensionKind>[
    UNKNOWN_EXTENSION,
    CANVAZ,
    STORYLINES,
    PODCAST_TOPICS,
    PODCAST_SEGMENTS,
    AUDIO_FILES,
    TRACK_DESCRIPTOR,
    PODCAST_COUNTER,
    ARTIST_V4,
    ALBUM_V4,
    TRACK_V4,
    SHOW_V4,
    EPISODE_V4,
    PODCAST_HTML_DESCRIPTION,
    PODCAST_QUOTES,
    USER_PROFILE,
    CANVAS_V1,
    SHOW_V4_BASE,
    SHOW_V4_EPISODES_ASSOC,
    TRACK_DESCRIPTOR_SIGNATURES,
    PODCAST_AD_SEGMENTS,
    EPISODE_TRANSCRIPTS,
    PODCAST_SUBSCRIPTIONS,
    EXTRACTED_COLOR,
    PODCAST_VIRALITY,
    IMAGE_SPARKLES_HACK,
    PODCAST_POPULARITY_HACK,
    AUTOMIX_MODE,
    CUEPOINTS,
    PODCAST_POLL,
    EPISODE_ACCESS,
    SHOW_ACCESS,
    PODCAST_QNA,
    CLIPS,
    SHOW_V5,
    EPISODE_V5,
    PODCAST_CTA_CARDS,
    PODCAST_RATING,
    DISPLAY_SEGMENTS,
    GREENROOM,
    USER_CREATED,
    SHOW_DESCRIPTION,
    SHOW_HTML_DESCRIPTION,
    SHOW_PLAYABILITY,
    EPISODE_DESCRIPTION,
    EPISODE_HTML_DESCRIPTION,
    EPISODE_PLAYABILITY,
    SHOW_EPISODES_ASSOC,
    CLIENT_CONFIG,
    PLAYLISTABILITY,
    AUDIOBOOK_V5,
    CHAPTER_V5,
    AUDIOBOOK_SPECIFICS,
    EPISODE_RANKING,
    HTML_DESCRIPTION,
    CREATOR_CHANNEL,
    AUDIOBOOK_PROVIDERS,
    PLAY_TRAIT,
    CONTENT_WARNING,
    IMAGE_CUE,
    STREAM_COUNT,
    AUDIO_ATTRIBUTES,
    NAVIGABLE_TRAIT,
    NEXT_BEST_EPISODE,
    AUDIOBOOK_PRICE,
    EXPRESSIVE_PLAYLISTS,
    DYNAMIC_SHOW_EPISODE,
    LIVE,
    SKIP_PLAYED,
    AD_BREAK_FREE_PODCASTS,
    ASSOCIATIONS,
    PLAYLIST_EVALUATION,
    CACHE_INVALIDATIONS,
    LIVESTREAM_ENTITY,
    SINGLE_TAP_REACTIONS,
    USER_COMMENTS,
    CLIENT_RESTRICTIONS,
    PODCAST_GUEST,
    PLAYABILITY,
    COVER_IMAGE,
    SHARE_TRAIT,
    INSTANCE_SHARING,
    ARTIST_TOUR,
    AUDIOBOOK_GENRE,
    CONCEPT,
    ORIGINAL_VIDEO,
    SMART_SHUFFLE,
    LIVE_EVENTS,
    AUDIOBOOK_RELATIONS,
    HOME_POC_BASECARD,
    AUDIOBOOK_SUPPLEMENTS,
    PAID_PODCAST_BANNER,
    FEWER_ADS,
    WATCH_FEED_SHOW_EXPLORER,
    TRACK_EXTRA_DESCRIPTORS,
    TRACK_EXTRA_AUDIO_ATTRIBUTES,
    TRACK_EXTENDED_CREDITS,
    SIMPLE_TRAIT,
    AUDIO_ASSOCIATIONS,
    VIDEO_ASSOCIATIONS,
    PLAYLIST_TUNER,
    ARTIST_VIDEOS_ENTRYPOINT,
    ALBUM_PRERELEASE,
    CONTENT_ALTERNATIVES,
    SNAPSHOT_SHARING,
    DISPLAY_SEGMENTS_COUNT,
    PODCAST_FEATURED_EPISODE,
    PODCAST_SPONSORED_CONTENT,
    PODCAST_EPISODE_TOPICS_LLM,
    PODCAST_EPISODE_TOPICS_KG,
    EPISODE_RANKING_POPULARITY,
    MERCH,
    COMPANION_CONTENT,
    WATCH_FEED_ENTITY_EXPLORER,
    ANCHOR_CARD_TRAIT,
    AUDIO_PREVIEW_PLAYBACK_TRAIT,
    VIDEO_PREVIEW_STILL_TRAIT,
    PREVIEW_CARD_TRAIT,
    SHORTCUTS_CARD_TRAIT,
    VIDEO_PREVIEW_PLAYBACK_TRAIT,
    COURSE_SPECIFICS,
    CONCERT,
    CONCERT_LOCATION,
    CONCERT_MARKETING,
    CONCERT_PERFORMERS,
    TRACK_PAIR_TRANSITION,
    CONTENT_TYPE_TRAIT,
    NAME_TRAIT,
    ARTWORK_TRAIT,
    RELEASE_DATE_TRAIT,
    CREDITS_TRAIT,
    RELEASE_URI_TRAIT,
    ENTITY_CAPPING,
    LESSON_SPECIFICS,
    CONCERT_OFFERS,
    TRANSITION_MAPS,
    ARTIST_HAS_CONCERTS,
    PRERELEASE,
    PLAYLIST_ATTRIBUTES_V2,
    LIST_ATTRIBUTES_V2,
    LIST_METADATA,
    LIST_TUNER_AUDIO_ANALYSIS,
    LIST_TUNER_CUEPOINTS,
    CONTENT_RATING_TRAIT,
    COPYRIGHT_TRAIT,
    SUPPORTED_BADGES,
    BADGES,
    PREVIEW_TRAIT,
    ROOTLISTABILITY_TRAIT,
    LOCAL_CONCERTS,
    RECOMMENDED_PLAYLISTS,
    POPULAR_RELEASES,
    RELATED_RELEASES,
    SHARE_RESTRICTIONS,
    CONCERT_OFFER,
    CONCERT_OFFER_PROVIDER,
    ENTITY_BOOKMARKS,
    PRIVACY_TRAIT,
    DUPLICATE_ITEMS_TRAIT,
    REORDERING_TRAIT,
    PODCAST_RESUMPTION_SEGMENTS,
    ARTIST_EXPRESSION_VIDEO,
    PRERELEASE_VIDEO,
    GATED_ENTITY_RELATIONS,
    RELATED_CREATORS_SECTION,
    CREATORS_APPEARS_ON_SECTION,
    PROMO_V1_TRAIT,
    SPEECHLESS_SHARE_CARD,
    TOP_PLAYABLES_SECTION,
    AUTO_LENS,
    PROMO_V3_TRAIT,
    TRACK_CONTENT_FILTER,
    HIGHLIGHTABILITY,
    LINK_CARD_WITH_IMAGE_TRAIT,
    TRACK_CLOUD_SECTION,
    EPISODE_TOPICS,
    VIDEO_THUMBNAIL,
    IDENTITY_TRAIT,
    VISUAL_IDENTITY_TRAIT,
    CONTENT_TYPE_V2_TRAIT,
    PREVIEW_PLAYBACK_TRAIT,
    CONSUMPTION_EXPERIENCE_TRAIT,
    PUBLISHING_METADATA_TRAIT,
    DETAILED_EVALUATION_TRAIT,
    ON_PLATFORM_REPUTATION_TRAIT,
    CREDITS_V2_TRAIT,
    HIGHLIGHT_PLAYABILITY_TRAIT,
    SHOW_EPISODE_LIST,
    AVAILABLE_RELEASES,
    PLAYLIST_DESCRIPTORS,
    LINK_CARD_WITH_ANIMATIONS_TRAIT,
    RECAP,
    AUDIOBOOK_COMPANION_CONTENT,
    THREE_OH_THREE_PLAY_TRAIT,
    ARTIST_WRAPPED_2024_VIDEO,
    PLAYBACK_TRAIT,
  ];

  static final $core.List<ExtensionKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 212);
  static ExtensionKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ExtensionKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
