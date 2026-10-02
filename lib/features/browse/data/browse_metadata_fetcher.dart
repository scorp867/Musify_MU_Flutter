import 'dart:developer' as dev;
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/identity_trait.pb.dart'
    as id_trait;
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/visual_identity_trait.pb.dart'
    as vis_trait;
import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/config/runtime_context.dart';
import 'package:musify_mu/core/network/spotify/transport/spotify_transport.dart';

/// Resolved browse item data from IdentityTrait + VisualIdentityTrait.
class BrowseCardData {
  final String name;
  final String type;
  final String? imageUrl;
  final int? bgColorArgb;

  const BrowseCardData({
    this.name = '',
    this.type = '',
    this.imageUrl,
    this.bgColorArgb,
  });
}

/// Fetches IdentityTrait (178) + VisualIdentityTrait (179) for browse item URIs.
///
/// This is the exact trait combination Spotify requests after the browsita response.
/// - IdentityTrait provides: name, type, description
/// - VisualIdentityTrait provides: square cover image, curated background color
class BrowseMetadataFetcher {
  final SpotifyTransport _client;
  final RuntimeContext _ctx;

  BrowseMetadataFetcher({
    required SpotifyTransport client,
    required RuntimeContext ctx,
  })  : _client = client,
        _ctx = ctx;

  /// Fetches browse card data for each URI.
  /// Returns uri -> BrowseCardData map.
  Future<Map<String, BrowseCardData>> fetchBrowseTraits(
    List<String> uris,
  ) async {
    if (uris.isEmpty) return {};

    try {
      final payload = _buildRequest(uris);
      final response = await _client.post(
        '/extended-metadata/v0/extended-metadata',
        Uint8List.fromList(payload),
      );
      if (response == null) return {};

      return await Isolate.run(() => _parseResponse(response));
    } catch (e) {
      dev.log('BrowseMetadataFetcher error: $e', name: 'Browse');
      return {};
    }
  }

  List<int> _buildRequest(List<String> uris) {
    final taskId = List<int>.generate(16, (_) => Random().nextInt(256));

    final request = BatchedEntityRequest()
      ..header = (BatchedEntityRequestHeader()
        ..country = _ctx.country
        ..catalogue = _ctx.catalogue
        ..taskId = taskId);

    for (final uri in uris) {
      final entityReq = EntityRequest()..entityUri = uri;
      // Request both trait types -- exactly what the Spotify app does
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

  static Map<String, BrowseCardData> _parseResponse(Uint8List data) {
    final results = <String, BrowseCardData>{};
    final response = BatchedExtensionResponse.fromBuffer(data);

    // Collect per-URI data across both trait types
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
          dev.log('Browse trait parse failed: $e');
        }
      }
    }

    // Merge into BrowseCardData
    final allUris = {
      ...names.keys,
      ...types.keys,
      ...images.keys,
      ...colors.keys,
    };

    for (final uri in allUris) {
      results[uri] = BrowseCardData(
        name: names[uri] ?? '',
        type: types[uri] ?? '',
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

    // Extract image URL from square_cover_image
    if (trait.hasSquareCoverImage() &&
        trait.squareCoverImage.instances.isNotEmpty) {
      final instance = trait.squareCoverImage.instances.first;
      if (instance.hasFlatFile() && instance.flatFile.cdnUrl.isNotEmpty) {
        images[uri] = instance.flatFile.cdnUrl;
      }
    }

    // Extract background color from curated_color or extracted_color_set
    if (trait.hasCuratedColor()) {
      final colorArgb = _extractBgColor(trait.curatedColor);
      if (colorArgb != null) colors[uri] = colorArgb;
    } else if (trait.hasSquareCoverImage() &&
        trait.squareCoverImage.hasExtractedColorSet()) {
      final colorArgb =
          _extractBgColor(trait.squareCoverImage.extractedColorSet);
      if (colorArgb != null) colors[uri] = colorArgb;
    }
  }

  static int? _extractBgColor(
    dynamic colorSetContrastOptions,
  ) {
    // Try min_contrast first (that's what browse cards use)
    if (colorSetContrastOptions.hasMinContrast()) {
      final bg = colorSetContrastOptions.minContrast.backgroundBase;
      if (bg != null) {
        return _rgbaToArgb(bg.r, bg.g, bg.b, bg.a);
      }
    }
    return null;
  }

  static int _rgbaToArgb(int r, int g, int b, int a) {
    final alpha = a > 0 ? a : 255;
    return (alpha << 24) | (r << 16) | (g << 8) | b;
  }
}
