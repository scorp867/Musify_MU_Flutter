import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';

/// Presentation-layer helpers for `VisualIdentityTrait`.
extension VisualIdentityTraitPresentation on VisualIdentityTrait {
  VisualColorSet? get preferredCardPalette {
    if (higherContrast case final higher?) return higher;
    if (highContrast case final high?) return high;
    return minContrast;
  }
}

/// Presentation-layer helpers for `PreviewPlaybackTrait`.
extension PreviewPlaybackTraitPresentation on PreviewPlaybackTrait {
  bool get hasAudio => audioUrl.isNotEmpty;
  bool get hasVideo => videoUrl.isNotEmpty;
}

/// Context-specific presentation getters for `SpotifyEntity` widgets.
/// Extracted from the domain model so `SpotifyEntity` remains strictly pure.
extension SpotifyEntityPresentation on SpotifyEntity {
  String get shortcutTitle {
    if (getTrait<ShortcutsCardTrait>() case final sct?
        when sct.title.isNotEmpty) {
      return sct.title;
    }
    if (getTrait<SimpleCardTrait>() case final simple?
        when simple.title.isNotEmpty) {
      return simple.title;
    }
    if (getTrait<IdentityTrait>() case final identity?
        when identity.title.isNotEmpty) {
      return identity.title;
    }
    if (getTrait<TrackV4>() case final track? when track.name.isNotEmpty) {
      return track.name;
    }
    if (getTrait<EpisodeV4>() case final ep? when ep.name.isNotEmpty) {
      return ep.name;
    }
    return '';
  }

  String? get shortcutImageUrl {
    if (getTrait<ShortcutsCardTrait>()?.imageUrl case final url?
        when url.isNotEmpty) {
      return url;
    }
    if (getTrait<SimpleCardTrait>()?.imageUrl case final url?
        when url.isNotEmpty) {
      return url;
    }
    if (getTrait<TrackV4>()?.albumCover.urlForSize(ImageSize.normal)
        case final url? when url.isNotEmpty) {
      return url;
    }
    return null;
  }

  String get cardTitle {
    if (getTrait<SimpleCardTrait>() case final simple?
        when simple.title.isNotEmpty) {
      return simple.title;
    }
    if (getTrait<IdentityTrait>() case final identity?
        when identity.title.isNotEmpty) {
      return identity.title;
    }
    if (getTrait<PreviewCardTrait>() case final preview?
        when preview.title.isNotEmpty) {
      return preview.title;
    }
    if (getTrait<ShortcutsCardTrait>() case final sct?
        when sct.title.isNotEmpty) {
      return sct.title;
    }
    if (getTrait<TrackV4>() case final track? when track.name.isNotEmpty) {
      return track.name;
    }
    if (getTrait<EpisodeV4>() case final ep? when ep.name.isNotEmpty) {
      return ep.name;
    }
    return '';
  }

  String get cardSubtitle {
    if (getTrait<SimpleCardTrait>() case final simple?
        when simple.subtitle.isNotEmpty) {
      return simple.subtitle;
    }
    if (getTrait<PreviewCardTrait>() case final preview?) {
      if (preview.creatorName.isNotEmpty) return preview.creatorName;
      if (preview.description.isNotEmpty) return preview.description;
    }
    if (getTrait<TrackV4>() case final track? when track.artists.isNotEmpty) {
      final names = track.artists
          .map((artist) => artist.name)
          .where((name) => name.isNotEmpty)
          .join(', ');
      if (names.isNotEmpty) return names;
    }
    if (getTrait<EpisodeV4>() case final ep?) {
      if (ep.show?.name case final showName? when showName.isNotEmpty) {
        return showName;
      }
      if (ep.description.isNotEmpty) return ep.description;
    }
    if (getTrait<VideoCardTrait>() case final video?
        when video.subtitle.isNotEmpty) {
      return video.subtitle;
    }
    if (getTrait<IdentityTrait>() case final identity?) {
      if (identity.description.isNotEmpty) return identity.description;
      if (identity.contributors.isNotEmpty) {
        return identity.contributors.join(', ');
      }
    }
    return '';
  }

  String? get cardImageUrl {
    if (getTrait<VisualIdentityTrait>()?.squareCoverUrl case final url?
        when url.isNotEmpty) {
      return url;
    }
    if (getTrait<SimpleCardTrait>()?.imageUrl case final url?
        when url.isNotEmpty) {
      return url;
    }
    if (getTrait<PreviewCardTrait>()?.imageUrl case final url?
        when url.isNotEmpty) {
      return url;
    }
    if (getTrait<ShortcutsCardTrait>()?.imageUrl case final url?
        when url.isNotEmpty) {
      return url;
    }
    if (getTrait<TrackV4>()?.albumCover.urlForSize(ImageSize.normal)
        case final url? when url.isNotEmpty) {
      return url;
    }
    if (getTrait<EpisodeV4>()?.coverImage.urlForSize(ImageSize.normal)
        case final url? when url.isNotEmpty) {
      return url;
    }
    return null;
  }

  String get previewTitle {
    if (getTrait<PreviewCardTrait>() case final preview?
        when preview.title.isNotEmpty) {
      return preview.title;
    }
    if (getTrait<SimpleCardTrait>() case final simple?
        when simple.title.isNotEmpty) {
      return simple.title;
    }
    if (getTrait<IdentityTrait>() case final identity?
        when identity.title.isNotEmpty) {
      return identity.title;
    }
    return '';
  }

  String? get previewImageUrl {
    if (getTrait<VisualIdentityTrait>() case final vit?) {
      if (vit.wideFullBleedUrl case final url? when url.isNotEmpty) return url;
      if (vit.sixteenByNineCoverUrl case final url? when url.isNotEmpty) {
        return url;
      }
      if (vit.squareCoverUrl case final url? when url.isNotEmpty) return url;
    }
    if (getTrait<PreviewCardTrait>()?.imageUrl case final url?
        when url.isNotEmpty) {
      return url;
    }
    if (getTrait<SimpleCardTrait>()?.imageUrl case final url?
        when url.isNotEmpty) {
      return url;
    }
    return null;
  }

  String? get videoThumbnailUrl {
    if (getTrait<VideoCardTrait>()?.videoThumbnailUrl case final url?
        when url.isNotEmpty) {
      return url;
    }
    if (getTrait<VisualIdentityTrait>()?.sixteenByNineCoverUrl case final url?
        when url.isNotEmpty) {
      return url;
    }
    if (getTrait<PreviewPlaybackTrait>() case final pt?
        when pt.videoImageUrl.isNotEmpty) {
      return pt.videoImageUrl;
    }
    if (getTrait<AudioPreviewPlaybackTrait>() case final at?
        when at.videoPlaceholderImageUrl.isNotEmpty) {
      return at.videoPlaceholderImageUrl;
    }
    if (hasVideo) {
      if (previewImageUrl case final url?) return url;
      return cardImageUrl;
    }
    return null;
  }

  String? get showArtworkUrl {
    if (getTrait<PreviewCardTrait>()?.creatorImageUrl case final url?
        when url.isNotEmpty) {
      return url;
    }
    if (getTrait<VideoCardTrait>()?.showArtworkUrl case final url?
        when url.isNotEmpty) {
      return url;
    }
    if (getTrait<VisualIdentityTrait>()?.squareCoverUrl case final url?
        when url.isNotEmpty) {
      return url;
    }
    return cardImageUrl;
  }

  String get durationString {
    if (getTrait<VideoCardTrait>() case final vt?
        when vt.durationString.isNotEmpty) {
      return vt.durationString;
    }
    if (getTrait<EpisodeV4>() case final ep? when ep.duration > 0) {
      final totalSec = ep.duration ~/ 1000;
      final minutes = totalSec ~/ 60;
      final seconds = totalSec % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '';
  }

  bool get hasVideo {
    if (getTrait<VisualIdentityTrait>() case final vit?) {
      if (vit.hasVideo) return true;
      if (vit.sixteenByNineCoverUrl case final url? when url.isNotEmpty) {
        return true;
      }
    }
    if (getTrait<VideoCardTrait>()?.videoThumbnailUrl case final url?
        when url.isNotEmpty) {
      return true;
    }
    if (getTrait<PreviewPlaybackTrait>() case final pt?
        when pt.videoUrl.isNotEmpty) {
      return true;
    }
    if (getTrait<AudioPreviewPlaybackTrait>() case final at?
        when at.videoFileId.isNotEmpty ||
            at.videoPlaceholderImageUrl.isNotEmpty) {
      return true;
    }
    if (getTrait<PreviewCardTrait>() case final pct?) {
      if (pct.contentTypeName.toLowerCase().contains('video')) return true;
      if (pct.previewLabel.toLowerCase().contains('video')) return true;
      if (pct.tags.any((tag) => tag.toLowerCase().contains('video'))) {
        return true;
      }
    }
    return false;
  }

  String? get backgroundColorHex {
    if (getTrait<PreviewCardTrait>()?.backgroundColor case final hex?
        when hex.isNotEmpty) {
      return hex;
    }
    if (getTrait<VisualIdentityTrait>()?.backgroundColorHex case final hex?
        when hex.isNotEmpty) {
      return hex;
    }
    return null;
  }
}
