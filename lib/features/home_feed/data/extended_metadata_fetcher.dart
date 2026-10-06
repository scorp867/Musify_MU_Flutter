import 'dart:developer' as dev;
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/identity_trait.pb.dart'
    as it;
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/visual_identity_trait.pb.dart'
    as vit;
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/visual_types.pb.dart'
    as vt;
import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/protocol/generated/spotify/traits/preview_card_trait.pb.dart'
    as pct;
import 'package:musify_mu/core/protocol/generated/spotify/traits/shortcuts_card_trait.pb.dart'
    as sct;
import 'package:musify_mu/core/protocol/generated/spotify/traits/simple_card_trait.pb.dart'
    as sct2;
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

/// Fetches extended metadata traits for URIs from Spotify's Extended Metadata service.
///
/// Endpoint: POST /extended-metadata/v0/extended-metadata
/// Protocol: BatchedEntityRequest → BatchedExtensionResponse (protobuf)
///
/// Supports multi-trait queries declared by Kodiak DataStatements (e.g. traits
/// 97, 178, 179, 31, 52, 64 for ImageLinkCardDataElement).
class ExtendedMetadataFetcher {
  final SpotifyTransport _client;
  final RuntimeContext _ctx;

  ExtendedMetadataFetcher({
    required SpotifyTransport client,
    required RuntimeContext ctx,
  })  : _client = client,
        _ctx = ctx;

  /// Legacy helper for fetching only SimpleCardTrait.
  Future<Map<String, SimpleCardTrait>> fetchTraits(List<String> uris) async {
    if (uris.isEmpty) return {};

    final queryMap = {
      for (final uri in uris) uri: [97], // SIMPLE_TRAIT
    };

    final result = await fetchEntityTraits(queryMap);
    final simpleMap = <String, SimpleCardTrait>{};
    for (final entry in result.entries) {
      final simple = entry.value['SimpleCardTrait'];
      if (simple is SimpleCardTrait) {
        simpleMap[entry.key] = simple;
      }
    }
    return simpleMap;
  }

  /// Fetches an arbitrary combination of traits per entity URI.
  /// Map of URI -> List of ExtensionKind integer IDs.
  /// Returns Map of URI -> { traitTypeName -> Trait }.
  Future<Map<String, Map<String, Trait>>> fetchEntityTraits(
    Map<String, List<int>> entityQueries,
  ) async {
    if (entityQueries.isEmpty) return {};

    try {
      final payload = _buildRequest(entityQueries);
      final response = await _client.post(
        '/extended-metadata/v0/extended-metadata',
        Uint8List.fromList(payload),
      );
      if (response == null || response.isEmpty) return {};

      return await Isolate.run(() => _parseMultiResponse(response));
    } catch (e, stack) {
      dev.log('ExtendedMetadataFetcher.fetchEntityTraits failed: $e\n$stack');
      return {};
    }
  }

  List<int> _buildRequest(Map<String, List<int>> entityQueries) {
    final taskId = List<int>.generate(16, (_) => Random().nextInt(256));

    final request = BatchedEntityRequest()
      ..header = (BatchedEntityRequestHeader()
        ..country = _ctx.country
        ..catalogue = _ctx.catalogue
        ..taskId = taskId);

    for (final entry in entityQueries.entries) {
      final entityReq = EntityRequest()..entityUri = entry.key;
      for (final kindVal in entry.value) {
        final extKind = ExtensionKind.valueOf(kindVal) ??
            ExtensionKind.UNKNOWN_EXTENSION;
        final query = ExtensionQuery()..extensionKind = extKind;
        entityReq.query.add(query);
      }
      request.entityRequest.add(entityReq);
    }

    return request.writeToBuffer();
  }

  static Map<String, Map<String, Trait>> _parseMultiResponse(Uint8List data) {
    final results = <String, Map<String, Trait>>{};
    final response = BatchedExtensionResponse.fromBuffer(data);

    for (final array in response.extendedMetadata) {
      for (final extData in array.extensionData) {
        final uri = extData.entityUri;
        if (uri.isEmpty || !extData.hasExtensionData()) continue;

        final anyData = extData.extensionData;
        final payload = anyData.value;
        if (payload.isEmpty) continue;

        final typeUrl = anyData.typeUrl;
        final entityTraits = results.putIfAbsent(uri, () => {});

        _decodeTrait(uri, typeUrl, payload, entityTraits);
      }
    }

    dev.log(
      'ExtendedMetadataFetcher: ${results.length} entities resolved in background isolate',
    );
    return results;
  }

  static void _decodeTrait(
    String uri,
    String typeUrl,
    List<int> payload,
    Map<String, Trait> entityTraits,
  ) {
    if (typeUrl.contains('SimpleCardTrait')) {
      _decodeSimpleCardTrait(payload, entityTraits);
    } else if (typeUrl.contains('ShortcutsCardTrait')) {
      _decodeShortcutsCardTrait(payload, entityTraits);
    } else if (typeUrl.contains('PreviewCardTrait')) {
      _decodePreviewCardTrait(payload, entityTraits);
    } else if (typeUrl.contains('VisualIdentityTrait')) {
      _decodeVisualIdentityTrait(payload, entityTraits);
    } else if (typeUrl.contains('IdentityTrait')) {
      _decodeIdentityTrait(payload, entityTraits);
    } else if (typeUrl.contains('ShowAccess') || typeUrl.contains('EpisodeAccess')) {
      _decodeShowAccessTrait(payload, entityTraits);
    } else if (typeUrl.contains('AudiobookPrice')) {
      _decodeAudiobookPriceTrait(payload, entityTraits);
    } else if (typeUrl.contains('AudiobookSpecifics') || typeUrl.contains('Audiobook')) {
      _decodeAudiobookSpecificsTrait(payload, entityTraits);
    } else if (typeUrl.contains('PromotionV1') || typeUrl.contains('PromoV1')) {
      _decodePromoV1Trait(payload, entityTraits);
    } else if (typeUrl.contains('PromotionV3') || typeUrl.contains('PromoV3')) {
      _decodePromoV3Trait(payload, entityTraits);
    } else if (typeUrl.contains('PreviewPlaybackTrait')) {
      _decodePreviewPlaybackTrait(payload, entityTraits);
    }
  }

  static void _decodeSimpleCardTrait(
    List<int> payload,
    Map<String, Trait> entityTraits,
  ) {
    try {
      final trait = sct2.SimpleCardTrait.fromBuffer(payload);
      entityTraits['SimpleCardTrait'] = SimpleCardTrait(
        title: trait.title,
        subtitle: trait.subtitle,
        imageUrl: _cleanImageUrl(trait.imageUri),
        navigationUri: trait.navigationUri,
        accessibility: trait.accessibility,
      );
    } catch (_) {}
  }

  static void _decodeShortcutsCardTrait(
    List<int> payload,
    Map<String, Trait> entityTraits,
  ) {
    try {
      final trait = sct.ShortcutsCardTrait.fromBuffer(payload);
      entityTraits['ShortcutsCardTrait'] = ShortcutsCardTrait(
        title: trait.title,
        imageUrl: _cleanImageUrl(trait.imageUrl),
      );
    } catch (_) {}
  }

  static void _decodePreviewCardTrait(
    List<int> payload,
    Map<String, Trait> entityTraits,
  ) {
    try {
      final trait = pct.PreviewCardTrait.fromBuffer(payload);
      entityTraits['PreviewCardTrait'] = PreviewCardTrait(
        title: trait.title,
        contentTypeName: trait.contentTypeName,
        description: trait.description,
        imageUrl: _cleanImageUrl(trait.entityImageUrl),
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

      if (entityTraits['SimpleCardTrait'] == null) {
        entityTraits['SimpleCardTrait'] = SimpleCardTrait(
          title: trait.title,
          subtitle: trait.description.isNotEmpty
              ? trait.description
              : (trait.hasContentParent() ? trait.contentParent.name : ''),
          imageUrl: _cleanImageUrl(trait.entityImageUrl),
        );
      }
    } catch (_) {}
  }

  static void _decodeIdentityTrait(
    List<int> payload,
    Map<String, Trait> entityTraits,
  ) {
    try {
      final trait = it.IdentityTrait.fromBuffer(payload);
      entityTraits['IdentityTrait'] = IdentityTrait(
        name: trait.name,
        type: trait.type,
        description: trait.description,
      );
    } catch (_) {}
  }

  static void _decodeVisualIdentityTrait(
    List<int> payload,
    Map<String, Trait> entityTraits,
  ) {
    try {
      final trait = vit.VisualIdentityTrait.fromBuffer(payload);
      String? squareUrl;
      String? sixteenNineUrl;

      if (trait.hasSquareCoverImage()) {
        squareUrl = _selectHighResImageUrl(trait.squareCoverImage);
      }
      if (trait.hasSixteenByNineCoverImage()) {
        sixteenNineUrl = _selectHighResImageUrl(trait.sixteenByNineCoverImage);
      }

      String? bgHex;
      String? textHex;
      if (trait.hasCuratedColor() && trait.curatedColor.hasMinContrast()) {
        final minContrast = trait.curatedColor.minContrast;
        if (minContrast.hasBackgroundBase()) {
          final c = minContrast.backgroundBase;
          bgHex =
              '#${c.r.toRadixString(16).padLeft(2, '0')}${c.g.toRadixString(16).padLeft(2, '0')}${c.b.toRadixString(16).padLeft(2, '0')}';
        }
        if (minContrast.hasTextBase()) {
          final c = minContrast.textBase;
          textHex =
              '#${c.r.toRadixString(16).padLeft(2, '0')}${c.g.toRadixString(16).padLeft(2, '0')}${c.b.toRadixString(16).padLeft(2, '0')}';
        }
      }

      entityTraits['VisualIdentityTrait'] = VisualIdentityTrait(
        squareCoverUrl: squareUrl,
        sixteenByNineCoverUrl: sixteenNineUrl,
        hasVideo: trait.hasNineBySixteenCoverVideo(),
        backgroundColorHex: bgHex,
        textColorHex: textHex,
      );
    } catch (_) {}
  }

  static void _decodeShowAccessTrait(
    List<int> payload,
    Map<String, Trait> entityTraits,
  ) {
    entityTraits['ShowAccessTrait'] = const ShowAccessTrait(
      hasAccess: true,
      isLocked: false,
    );
  }

  static void _decodeAudiobookPriceTrait(
    List<int> payload,
    Map<String, Trait> entityTraits,
  ) {
    entityTraits['AudiobookPriceTrait'] = const AudiobookPriceTrait(
      isPurchasable: true,
    );
  }

  static void _decodeAudiobookSpecificsTrait(
    List<int> payload,
    Map<String, Trait> entityTraits,
  ) {
    entityTraits['AudiobookSpecificsTrait'] = const AudiobookSpecificsTrait();
  }

  static void _decodePromoV1Trait(
    List<int> payload,
    Map<String, Trait> entityTraits,
  ) {
    entityTraits['PromoV1Trait'] = const PromoV1Trait(title: '');
  }

  static void _decodePromoV3Trait(
    List<int> payload,
    Map<String, Trait> entityTraits,
  ) {
    entityTraits['PromoV3Trait'] = const PromoV3Trait(title: '');
  }

  static void _decodePreviewPlaybackTrait(
    List<int> payload,
    Map<String, Trait> entityTraits,
  ) {
    entityTraits['PreviewPlaybackTrait'] = const PreviewPlaybackTrait();
  }

  static String? _selectHighResImageUrl(vt.Image image) {
    if (image.instances.isEmpty) return null;

    // Protobuf instances are ordered ascending by size (SMALL -> DEFAULT -> LARGE).
    // Prefer LARGE or DEFAULT; fallback to the last instance (highest resolution).
    vt.ImageInstance? selected;
    for (final inst in image.instances) {
      if (inst.size == vt.ImageSize.IMAGE_SIZE_LARGE ||
          inst.size == vt.ImageSize.IMAGE_SIZE_DEFAULT ||
          inst.size == vt.ImageSize.IMAGE_SIZE_XLARGE) {
        selected = inst;
        break;
      }
    }
    selected ??= image.instances.last;
    return _cleanImageUrl(selected.flatFile.cdnUrl);
  }

  static String? _cleanImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('spotify:image:')) {
      return 'https://i.scdn.co/image/${url.split(':').last}';
    }
    return url;
  }
}
