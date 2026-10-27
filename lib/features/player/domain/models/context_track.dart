// 1:1 replica of com.spotify.player.model.ContextTrack

class ContextTrack {
  static const String trackThumbStateDown = 'down';
  static const String trackThumbStateUp = 'up';
  static const List<String> delimiters = <String>[
    'spotify:meta:delimiter',
    'spotify:delimiter',
  ];

  final String uri;
  final String uid;
  final Map<String, String> metadata;
  final String provider;

  const ContextTrack({
    required this.uri,
    this.uid = '',
    this.metadata = const <String, String>{},
    this.provider = '',
  });

  static ContextTrackBuilder builder([String uri = '']) =>
      ContextTrackBuilder(uri: uri);

  static ContextTrack create(String uri) => builder(uri).build();

  bool isDelimiter() => delimiters.contains(uri);

  ContextTrackBuilder toBuilder() => ContextTrackBuilder(
        uri: uri,
        uid: uid,
        metadata: metadata,
        provider: provider,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContextTrack &&
          other.uri == uri &&
          other.uid == uid &&
          other.provider == provider &&
          _mapEquals(other.metadata, metadata));

  @override
  int get hashCode => Object.hash(
        uri,
        uid,
        provider,
        Object.hashAll(metadata.entries.map((e) => Object.hash(e.key, e.value))),
      );

  @override
  String toString() =>
      'ContextTrack{uri=$uri, uid=$uid, provider=$provider, metadata=$metadata}';

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (b[key] != a[key]) return false;
    }
    return true;
  }
}

class ContextTrackBuilder {
  String _uri;
  String _uid;
  Map<String, String> _metadata;
  String _provider;

  ContextTrackBuilder({
    String uri = '',
    String uid = '',
    Map<String, String> metadata = const <String, String>{},
    String provider = '',
  })  : _uri = uri,
        _uid = uid,
        _metadata = Map<String, String>.from(metadata),
        _provider = provider;

  ContextTrackBuilder uri(String val) {
    _uri = val;
    return this;
  }

  ContextTrackBuilder uid(String val) {
    _uid = val;
    return this;
  }

  ContextTrackBuilder metadata(Map<String, String> val) {
    _metadata = Map<String, String>.from(val);
    return this;
  }

  ContextTrackBuilder provider(String val) {
    _provider = val;
    return this;
  }

  ContextTrack build() => ContextTrack(
        uri: _uri,
        uid: _uid,
        metadata: Map<String, String>.unmodifiable(_metadata),
        provider: _provider,
      );
}

abstract class ContextTrackMediaType {
  static const String audio = 'audio';
  static const String mixed = 'mixed';
  static const String video = 'video';
}

abstract class ContextTrackAction {
  static const String pause = 'pause';
  static const String resume = 'resume';
  static const String stop = 'stop';
}

abstract class ContextTrackPlayer {
  static const String audio = 'audio';
  static const String video = 'video';
}

abstract class ContextTrackMetadata {
  static const String activePlayInterruption = 'sas_active';
  static const String keyActionsAdvancingPastTrack = 'actions.advancing_past_track';
  static const String keyActionsAdvancingToTrack = 'actions.advancing_to_track';
  static const String keyActionsRepeatingTrack = 'actions.repeating_track';
  static const String keyActionsReversingPastTrack = 'actions.reversing_past_track';
  static const String keyActionsReversingToTrack = 'actions.reversing_to_track';
  static const String keyActionsSkippingNextPastTrack = 'actions.skipping_next_past_track';
  static const String keyActionsSkippingPrevPastTrack = 'actions.skipping_prev_past_track';
  static const String keyActiveLicensor = 'mod.active_licensor';
  static const String keyAddedAt = 'added_at';
  static const String keyAddedByName = 'added_by_name';
  static const String keyAddedByUsername = 'added_by_username';
  static const String keyAdvertiser = 'advertiser';
  static const String keyAdId = 'ad_id';
  static const String keyAdType = 'ad_type';
  static const String keyAlbumArtistName = 'album_artist_name';
  static const String keyAlbumDiscCount = 'album_disc_count';
  static const String keyAlbumDiscNumber = 'album_disc_number';
  static const String keyAlbumTitle = 'album_title';
  static const String keyAlbumTrackCount = 'album_track_count';
  static const String keyAlbumTrackNumber = 'album_track_number';
  static const String keyAlbumUri = 'album_uri';
  static const String keyArtistName = 'artist_name';
  static const String keyArtistUri = 'artist_uri';
  static const String keyAssociatedVideoManifestId = 'associated_video_id';
  static const String keyAudioAssociation = 'audio_association';
  static const String keyAudioAssociationImageSmall = 'audio_association_image_small';
  static const String keyAudioFadeInCurves = 'audio.fade_in_curves';
  static const String keyAudioFadeInDuration = 'audio.fade_in_duration';
  static const String keyAudioFadeInStartTime = 'audio.fade_in_start_time';
  static const String keyAudioFadeOutCurves = 'audio.fade_out_curves';
  static const String keyAudioFadeOutDuration = 'audio.fade_out_duration';
  static const String keyAudioFadeOutStartTime = 'audio.fade_out_start_time';
  static const String keyAudioFadeOverlap = 'audio.fade_overlap';
  static const String keyAutoplayIsAutoplay = 'autoplay.is_autoplay';
  static const String keyAvailabilityRestrictions = 'availability_restrictions';
  static const String keyAvailableFileFormats = 'available_file_formats';
  static const String keyClickUrl = 'click_url';
  static const String keyCollectionCanAdd = 'collection.can_add';
  static const String keyCollectionCanBan = 'collection.can_ban';
  static const String keyCollectionInCollection = 'collection.in_collection';
  static const String keyCollectionIsArtistBanned = 'collection.artist.is_banned';
  static const String keyCollectionIsBanned = 'collection.is_banned';
  static const String keyContextUri = 'context_uri';
  static const String keyDislikeFeedbackAvailable = 'dislike-feedback-available';
  static const String keyDislikeFeedbackEnabled = 'dislike-feedback-enabled';
  static const String keyDislikeFeedbackSelected = 'dislike-feedback-selected';
  static const String keyDuration = 'duration';
  static const String keyEntityUri = 'entity_uri';
  static const String keyExternallyInjected = 'mft.externally_injected';
  static const String keyExtractedColor = 'extracted_color';
  static const String keyHasLyrics = 'has_lyrics';
  static const String keyHasTranscripts = 'has_transcripts';
  static const String keyHidden = 'hidden';
  static const String keyImageLargeUrl = 'image_large_url';
  static const String keyImageSmallUrl = 'image_small_url';
  static const String keyImageUrl = 'image_url';
  static const String keyImageXlargeUrl = 'image_xlarge_url';
  static const String keyInteractionId = 'interaction_id';
  static const String keyInterruptionSource = 'mod.interruption_source';
  static const String keyIs19Plus = 'is_19_plus';
  static const String keyIsActivePlayInterruption = 'mod.is_active_play_interruption';
  static const String keyIsAdvertisement = 'is_advertisement';
  static const String keyIsAdSkippable = 'ad.is_skippable';
  static const String keyIsAudiobookChapter = 'is_audiobook_chapter';
  static const String keyIsAudiobookRecap = 'is_audiobook_recap';
  static const String keyIsBackgroundable = 'is_backgroundable';
  static const String keyIsDataSaverTrack = 'is_data_saver_track';
  static const String keyIsExplicit = 'is_explicit';
  static const String keyIsInterruption = 'mod.is_interruption';
  static const String keyIsLocal = 'is_local';
  static const String keyIsNarration = 'is_narration';
  static const String keyIsPodcastAdvertisement = 'is_podcast_advertisement';
  static const String keyIsPodcastAdvertisementInVideo = 'is_podcast_advertisement_in_video';
  static const String keyIsPremiumOnly = 'is_premium_only';
  static const String keyIsQueued = 'is_queued';
  static const String keyIsRepeatInterruption = 'mod.is_repeat_interruption';
  static const String keyIteration = 'iteration';
  static const String keyJumpTrack = 'jump_track';
  static const String keyKeepSkipDirection = 'keep_skip_direction';
  static const String keyLexiconExpirationTime = 'lexicon_expiration_time';
  static const String keyLexiconSetType = 'lexicon_set_type';
  static const String keyLikeFeedbackAvailable = 'like-feedback-available';
  static const String keyLikeFeedbackEnabled = 'like-feedback-enabled';
  static const String keyLikeFeedbackSelected = 'like-feedback-selected';
  static const String keyLoadingFailed = 'loading.failed';
  static const String keyLoadingStatus = 'loading.status';
  static const String keyLocalFilePath = 'local_file_path';
  static const String keyLocalFileSize = 'local_file_size';
  static const String keyMarkedForDownload = 'marked_for_download';
  static const String keyMediaExternalUrl = 'media.external_url';
  static const String keyMediaLive = 'media.live';
  static const String keyMediaManifest = 'media.manifest';
  static const String keyMediaManifestId = 'media.manifest_id';
  static const String keyMediaStartPosition = 'media.start_position';
  static const String keyMediaStopPosition = 'media.stop_position';
  static const String keyMediaType = 'media.type';
  static const String keyMftInjectionReason = 'mft.injection_reason';
  static const String keyMftInjectionSource = 'mft.injection_source';
  static const String keyMftUnplayablePolicy = 'mft.unplayable.policy';
  static const String keyNarrationIntroSsml = 'narration.intro.ssml';
  static const String keyNarrationIntroUri = 'narration.intro.uri';
  static const String keyOnDemandType = 'user_behavior.on_demand_type';
  static const String keyOriginalIndex = 'original_index';
  static const String keyPageInstanceId = 'page_instance_id';
  static const String keyParentEpisodeUri = 'parent_episode.uri';
  static const String keyPipDisallowed = 'pip_disallowed';
  static const String keyPlaybackSpeed = 'playback_speed';
  static const String keyPointerUri = 'pointer.uri';
  static const String keyPopularity = 'popularity';
  static const String keyPreviousAccumulativeMs = 'previous_accumulative_ms';
  static const String keyPromotionType = 'promotion_type';
  static const String keyProvider = 'provider';
  static const String keyRepeatingTrackCount = 'repeating_track.count';
  static const String keyRepeatingTrackMax = 'repeating_track.max';
  static const String keyRepeatingTrackMin = 'repeating_track.min';
  static const String keySaveTrackUri = 'save_track.uri';
  static const String keySegmentIndex = 'segment.index';
  static const String keySegmentName = 'segment_name';
  static const String keySegmentUri = 'segment.uri';
  static const String keyShowCoverImageUri = 'show.cover_image.uri';
  static const String keyShowHtmlDescription = 'show.html_description';
  static const String keyShowPublisher = 'show.publisher';
  static const String keyShuffleAveragePosition = 'shuffle.average_position';
  static const String keySkippableAdDelay = 'ad.skippable_ad_delay';
  static const String keySongId = 'song_id';
  static const String keyStationSubtitle = 'station_subtitle';
  static const String keyStationTitle = 'station_title';
  static const String keyStationUri = 'station_uri';
  static const String keySubtitle = 'subtitle';
  static const String keyThumbnailImageUrl = 'thumbnail_image_url';
  static const String keyTitle = 'title';
  static const String keyTrackPlayer = 'track_player';
  static const String keyTrackRadioThumbState = 'radio.thumb';
  static const String keyVideoAssociation = 'video_association';
  static const String keyVideoRenderingEnabled = 'video_rendering_enabled';
  static const String keyVideoSecondsBeforeTrackStuck = 'video.seconds_before_track_stuck';
  static const String keyVisualizationPlaybackSpeed = 'visualization.playback_speed';
  static const String keyPreviewOggUrl = 'preview_ogg_url';
  static const String keyCdnAacUrl = 'cdn_aac_url';
  static const String keyLicenseServerUrl = 'license_server_url';
  static const String keyDrmAuthHeader = 'drm_auth_header';
  static const String keyHandoffPositionMs = 'handoff_position_ms';
  static const String repeatPlayInterruption = 'sas_repeat';
}

