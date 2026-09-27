import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/core/protocol/generated/spotify/traits/simple_card_trait.pb.dart'
    as sct;
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';
import 'package:musify_mu/features/spotify_client/spotify_client.dart';

/// Fetches SimpleCardTrait for URIs not covered by the Casita eagerload.
///
/// Endpoint: POST /extended-metadata/v0/extended-metadata
/// Protocol: BatchedEntityRequest → BatchedExtensionResponse (protobuf)
///
/// This is the same call Spotify makes after parsing the Casita response.
/// The eagerload config only covers certain section types (shortcuts, etc).
/// All remaining URIs need their SimpleCardTrait fetched via this API.
class ExtendedMetadataFetcher {
  final SpotifyClient _client;

  ExtendedMetadataFetcher({required SpotifyClient client}) : _client = client;

  /// Fetches SimpleCardTrait for each URI. Returns uri → SimpleCardTrait map.
  Future<Map<String, SimpleCardTrait>> fetchTraits(List<String> uris) async {
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
      print('❌ ExtendedMetadataFetcher: $e');
      return {};
    }
  }

  List<int> _buildRequest(List<String> uris) {
    final taskId = List<int>.generate(16, (_) => Random().nextInt(256));

    final request = BatchedEntityRequest()
      ..header = (BatchedEntityRequestHeader()
        ..country = 'IN'
        ..catalogue = 'free'
        ..taskId = taskId);

    for (final uri in uris) {
      final entityReq = EntityRequest()..entityUri = uri;
      entityReq.query.add(
        ExtensionQuery()..extensionKind = ExtensionKind.SIMPLE_TRAIT,
      );
      request.entityRequest.add(entityReq);
    }

    return request.writeToBuffer();
  }

  static Map<String, SimpleCardTrait> _parseResponse(Uint8List data) {
    final results = <String, SimpleCardTrait>{};
    final response = BatchedExtensionResponse.fromBuffer(data);

    for (final array in response.extendedMetadata) {
      for (final extData in array.extensionData) {
        final uri = extData.entityUri;
        if (uri.isEmpty || !extData.hasExtensionData()) continue;

        final payload = extData.extensionData.value;
        if (payload.isEmpty) continue;

        try {
          final trait = sct.SimpleCardTrait.fromBuffer(payload);
          if (trait.title.isEmpty && trait.imageUri.isEmpty) continue;

          String? imageUrl;
          final image = trait.imageUri;
          if (image.isNotEmpty) {
            if (image.startsWith('spotify:image:')) {
              imageUrl = 'https://i.scdn.co/image/${image.split(':').last}';
            } else if (image.startsWith('http')) {
              imageUrl = image;
            }
          }

          results[uri] = SimpleCardTrait(
            title: trait.title,
            subtitle: trait.subtitle,
            imageUrl: imageUrl,
            navigationUri: trait.navigationUri,
            accessibility: trait.accessibility,
          );
        } catch (_) {}
      }
    }

    print('✅ ExtendedMetadata: ${results.length} traits resolved');
    return results;
  }
}
