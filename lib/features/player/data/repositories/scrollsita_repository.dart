import 'dart:async';

import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/features/player/data/datasources/scrollsita_client.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';
import 'package:musify_mu/features/player/domain/repositories/scrollsita_repository.dart';

/// Concrete repository implementation coordinating Now Playing scroll section layout.
class ScrollSitaRepositoryImpl implements ScrollSitaRepository {
  final ScrollSitaClient? client;
  final DataPool? dataPool;

  const ScrollSitaRepositoryImpl({
    this.client,
    this.dataPool,
  });

  @override
  Future<List<ScrollCardDescriptor>> getScrollCards([String? trackId]) async {
    return _buildOfflineFallback(trackId);
  }

  List<ScrollCardDescriptor> _buildOfflineFallback([String? trackId]) {
    final trackUri = _resolveTrackUri(trackId) ?? 'spotify:track:default';

    return [
      LyricsCardDescriptor(entityUri: trackUri),
      const CreatorBioCardDescriptor(
        creatorUri: '',
        title: 'About the artist',
      ),
      CreditsCardDescriptor(
        entityUri: trackUri,
        contributorUris: const [],
      ),
    ];
  }

  String? _resolveTrackUri(String? trackId) {
    if (trackId == null || trackId.isEmpty) return null;
    if (trackId.startsWith('spotify:track:')) return trackId;
    return 'spotify:track:$trackId';
  }
}
