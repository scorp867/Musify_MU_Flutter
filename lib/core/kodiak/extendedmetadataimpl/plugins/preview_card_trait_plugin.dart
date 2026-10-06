import 'dart:typed_data';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/protocol/generated/spotify/traits/preview_card_trait.pb.dart'
    as pct;
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';
import 'plugin_utils.dart';

/// Plugin for ExtensionKind 118 (PREVIEW_CARD_TRAIT).
class PreviewCardTraitPlugin implements ExtendedMetadataPlugin<PreviewCardTrait> {
  const PreviewCardTraitPlugin();

  @override
  Type get traitType => PreviewCardTrait;

  @override
  int get extensionKindValue => 118;

  @override
  ExtensionKind? get extensionKind => ExtensionKind.PREVIEW_CARD_TRAIT;

  @override
  PreviewCardTrait parse(Uint8List payload) {
    final trait = pct.PreviewCardTrait.fromBuffer(payload);
    return PreviewCardTrait(
      title: trait.title,
      contentTypeName: trait.contentTypeName,
      description: trait.description,
      imageUrl: cleanImageUrl(trait.entityImageUrl),
      backgroundColor: trait.backgroundColorHex,
      waveformColor: trait.waveformColorHex,
      trackCount: trait.numberOfItems,
      entityUri: trait.entityUri,
      navigateUri: trait.navigateUri,
      tags: trait.descriptorTags.map((t) => t.name).toList(),
      previewLabel: trait.hasLabels() ? trait.labels.previewLabel : '',
      playingLabel: trait.hasLabels() ? trait.labels.playingLabel : '',
      creatorName: trait.hasContentParent() ? trait.contentParent.name : '',
      creatorUri: trait.hasContentParent() ? trait.contentParent.uri : '',
      creatorImageUrl: trait.hasContentParent()
          ? trait.contentParent.imageUrl
          : '',
    );
  }
}
