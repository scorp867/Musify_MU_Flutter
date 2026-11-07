import 'dart:developer' as dev;
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/network/priority/network_priority.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/identity_trait.pb.dart'
    as id_trait;
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/visual_identity_trait.pb.dart'
    as vis_trait;
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/visual_types.pb.dart'
    as vt;
import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/browse/data/browse_card_data.dart';

export 'browse_card_data.dart';

/// Fetches `IdentityTrait` (178) + `VisualIdentityTrait` (179) for browse item URIs.
class BrowseMetadataFetcher {
  final SpotifyTransport _client;
  final RuntimeContext _ctx;

  BrowseMetadataFetcher({
    required SpotifyTransport client,
    required RuntimeContext ctx,
  }) : _client = client,
       _ctx = ctx;

  /// Fetches browse card data and raw `BatchedExtensionResponse` protobuf bytes.
  Future<({Map<String, BrowseCardData> cards, Uint8List? rawResponse})>
  fetchBrowseTraitsRaw(List<String> uris) async {
    if (uris.isEmpty) {
      return (cards: const <String, BrowseCardData>{}, rawResponse: null);
    }

    final payload = _buildRequest(uris);
    final response = await _client.post(
      '/extended-metadata/v0/extended-metadata',
      Uint8List.fromList(payload),
      priority: NetworkPriority.background,
      tag: 'browse_metadata_traits',
      ttl: const Duration(seconds: 45),
    );
    if (response == null || response.isEmpty) {
      return (cards: const <String, BrowseCardData>{}, rawResponse: null);
    }

    final cards = await Isolate.run(() => parseResponse(response));
    return (cards: cards, rawResponse: response);
  }

  /// Convenience wrapper returning only parsed `BrowseCardData`.
  Future<Map<String, BrowseCardData>> fetchBrowseTraits(
    List<String> uris,
  ) async {
    final (:cards, rawResponse: _) = await fetchBrowseTraitsRaw(uris);
    return cards;
  }

  List<int> _buildRequest(List<String> uris) {
    final random = Random();
    final taskId = List<int>.generate(16, (_) => random.nextInt(256));

    final request = BatchedEntityRequest()
      ..header = (BatchedEntityRequestHeader()
        ..country = _ctx.country
        ..catalogue = _ctx.catalogue
        ..taskId = taskId);

    for (final uri in uris) {
      final entityReq = EntityRequest()..entityUri = uri;
      entityReq.query.add(
        ExtensionQuery()..extensionKind = ExtensionKind.VISUAL_IDENTITY_TRAIT,
      );
      entityReq.query.add(
        ExtensionQuery()..extensionKind = ExtensionKind.IDENTITY_TRAIT,
      );
      request.entityRequest.add(entityReq);
    }

    return request.writeToBuffer();
  }

  static Map<String, BrowseCardData> parseResponse(Uint8List data) {
    final results = <String, BrowseCardData>{};
    final response = BatchedExtensionResponse.fromBuffer(data);

    final names = <String, String>{};
    final types = <String, String>{};
    final images = <String, String>{};
    final colors = <String, int>{};

    for (final array in response.extendedMetadata) {
      final kind = array.extensionKind;

      for (final extData in array.extensionData) {
        final uri = extData.entityUri;
        if (uri.isEmpty || !extData.hasExtensionData()) continue;

        final payload = extData.extensionData.value;
        if (payload.isEmpty) continue;

        try {
          if (kind == ExtensionKind.IDENTITY_TRAIT) {
            _parseIdentityTrait(uri, payload, names, types);
          } else if (kind == ExtensionKind.VISUAL_IDENTITY_TRAIT) {
            _parseVisualIdentityTrait(uri, payload, images, colors);
          }
        } catch (e) {
          dev.log('Browse trait parse failed: $e', name: 'Browse');
        }
      }
    }

    final allUris = <String>{
      ...names.keys,
      ...types.keys,
      ...images.keys,
      ...colors.keys,
    };

    for (final uri in allUris) {
      final nameVal = names[uri];
      final typeVal = types[uri];
      results[uri] = BrowseCardData(
        name: nameVal != null ? nameVal : '',
        type: typeVal != null ? typeVal : '',
        imageUrl: images[uri],
        bgColorArgb: colors[uri],
      );
    }

    dev.log(
      'BrowseMetadata: ${results.length} cards resolved',
      name: 'Browse',
    );
    return results;
  }

  static void _parseIdentityTrait(
    String uri,
    List<int> payload,
    Map<String, String> names,
    Map<String, String> types,
  ) {
    final trait = id_trait.IdentityTrait.fromBuffer(payload);
    if (trait.name.isNotEmpty) {
      names[uri] = trait.name;
    }
    if (trait.type.isNotEmpty) {
      types[uri] = trait.type;
    }
  }

  static void _parseVisualIdentityTrait(
    String uri,
    List<int> payload,
    Map<String, String> images,
    Map<String, int> colors,
  ) {
    final trait = vis_trait.VisualIdentityTrait.fromBuffer(payload);

    if (trait.hasSquareCoverImage() &&
        trait.squareCoverImage.instances.isNotEmpty) {
      final instance = trait.squareCoverImage.instances.first;
      if (instance.hasFlatFile() && instance.flatFile.cdnUrl.isNotEmpty) {
        images[uri] = instance.flatFile.cdnUrl;
      }
    }

    if (trait.hasCuratedColor()) {
      final colorArgb = _extractBgColor(trait.curatedColor);
      if (colorArgb != null) colors[uri] = colorArgb;
    } else if (trait.hasSquareCoverImage() &&
        trait.squareCoverImage.hasExtractedColorSet()) {
      final colorArgb = _extractBgColor(
        trait.squareCoverImage.extractedColorSet,
      );
      if (colorArgb != null) colors[uri] = colorArgb;
    }
  }

  static int? _extractBgColor(
    vt.ColorSetContrastOptions colorSetContrastOptions,
  ) {
    if (colorSetContrastOptions.hasMinContrast() &&
        colorSetContrastOptions.minContrast.hasBackgroundBase()) {
      final bg = colorSetContrastOptions.minContrast.backgroundBase;
      return _rgbaToArgb(bg.r, bg.g, bg.b, bg.a);
    }
    return null;
  }

  static int _rgbaToArgb(int r, int g, int b, int a) {
    final alpha = a > 0 ? a : 255;
    return ((alpha & 0xFF) << 24) |
        ((r & 0xFF) << 16) |
        ((g & 0xFF) << 8) |
        (b & 0xFF);
  }
}
