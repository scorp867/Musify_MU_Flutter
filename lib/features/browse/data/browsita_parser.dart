import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:musify_mu/core/protocol/generated/spotify/browsita/resolved.pb.dart'
    as browsita;
import 'package:musify_mu/features/browse/domain/models/browse_view_data.dart';

/// Parses the Browsita protobuf response into UI-ready BrowseViewData.
///
/// Browsita is the Browse tab's equivalent of Casita (home feed).
/// Response structure:
///   ResolvedBrowse
///     └── structure.sections[]
///           ├── section_info.section_id
///           └── feature_type (oneof):
///                 ├── content_category (main: heading + items[])
///                 ├── showcase, watch_feed, promotions, etc.
class BrowsitaParser {
  final Uint8List data;

  BrowsitaParser(this.data);

  BrowseViewData parse() {
    try {
      final resolved = browsita.ResolvedBrowse.fromBuffer(data);
      final sections = <BrowseSection>[];

      for (final section in resolved.structure.sections) {
        final parsed = _parseSection(section);
        if (parsed != null) {
          sections.add(parsed);
        }
      }

      dev.log(
        'BrowsitaParser: ${sections.length} sections parsed',
        name: 'Browse',
      );
      return BrowseViewData(sections: sections);
    } catch (e, stack) {
      dev.log('BrowsitaParser error: $e\n$stack', name: 'Browse');
      return const BrowseViewData();
    }
  }

  BrowseSection? _parseSection(browsita.Section section) {
    final sectionId = section.sectionInfo.sectionId;
    final featureType = section.whichFeatureType();

    switch (featureType) {
      case browsita.Section_FeatureType.contentCategory:
        return _parseContentCategory(sectionId, section.contentCategory);

      case browsita.Section_FeatureType.showcase:
        return BrowseSection(
          sectionId: sectionId,
          sectionType: 'showcase',
          title: '',
        );

      case browsita.Section_FeatureType.watchFeed:
        return BrowseSection(
          sectionId: sectionId,
          sectionType: 'watch_feed',
          title: '',
          items: section.watchFeed.items.map((item) {
            return BrowseItem(
              uri: item.uri,
              title: item.metadata.title,
            );
          }).toList(),
        );

      case browsita.Section_FeatureType.previewPromotionCarousel:
        return BrowseSection(
          sectionId: sectionId,
          sectionType: 'preview_promotion_carousel',
          title: '',
          items: section.previewPromotionCarousel.items.map((item) {
            return BrowseItem(uri: item.uri);
          }).toList(),
        );

      // Skip ad/promo types
      case browsita.Section_FeatureType.promotionV1:
      case browsita.Section_FeatureType.promotionV3:
      case browsita.Section_FeatureType.brandAds:
      case browsita.Section_FeatureType.audioPromo:
      case browsita.Section_FeatureType.playLinkPromo:
      case browsita.Section_FeatureType.videoPromo:
      case browsita.Section_FeatureType.audioSpotlight:
        return null;

      case browsita.Section_FeatureType.notSet:
        return null;
    }
  }

  BrowseSection _parseContentCategory(
    String sectionId,
    browsita.ContentCategory category,
  ) {
    // Extract heading text
    String title = '';
    String? iconName;
    String? navigateUri;

    if (category.heading.hasTextHeading()) {
      title = category.heading.textHeading.text;
      iconName = category.heading.textHeading.encoreIconName.isNotEmpty
          ? category.heading.textHeading.encoreIconName
          : null;
      if (category.heading.textHeading.hasNavigationAction()) {
        navigateUri = category.heading.textHeading.navigationAction.uri;
      }
    } else if (category.heading.hasSponsoredHeading()) {
      title = category.heading.sponsoredHeading.text;
    }

    // Parse items
    final items = category.items.map((item) {
      return BrowseItem(
        uri: item.uri,
        targetUri: item.targetUri,
      );
    }).toList();

    return BrowseSection(
      sectionId: sectionId,
      sectionType: 'content_category',
      title: title,
      iconName: iconName,
      items: items,
      navigateUri: navigateUri,
    );
  }
}
