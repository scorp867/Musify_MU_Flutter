import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:musify_mu/features/browse/data/browse_cache.dart';
import 'package:musify_mu/features/browse/data/browse_metadata_fetcher.dart';
import 'package:musify_mu/features/browse/data/browsita_parser.dart';
import 'package:musify_mu/features/browse/domain/models/browse_view_data.dart';
import 'package:musify_mu/features/spotify_client/spotify_client.dart';

/// Repository for browse tab data.
///
/// Implements Spotify's actual caching strategy (reverse-engineered):
///   - Individual item traits are cached per-URI (not the whole response)
///   - On load: fetch browsita (lightweight structure), then only query
///     extended-metadata for URIs NOT already in the local cache (delta)
///   - This means if 70/79 URIs are cached, only 9 get fetched
///
/// Loading strategies (from decompiled bq70 enum):
///   - CACHE_FIRST: show cached, then revalidate
///   - REVALIDATE: force network fetch
class BrowseRepository {
  final SpotifyClient _client;
  final BrowseTraitCache _traitCache;

  BrowseRepository({
    required SpotifyClient client,
    BrowseTraitCache? traitCache,
  })  : _client = client,
        _traitCache = traitCache ?? BrowseTraitCache();

  /// Fetches browse data with delta trait resolution.
  Future<BrowseViewData?> fetchBrowse() async {
    try {
      // Step 1: Always fetch browsita structure (it's lightweight)
      final bytes = await _fetchBrowsita();
      if (bytes == null || bytes.isEmpty) {
        dev.log('BrowseRepo: Empty browsita response', name: 'Browse');
        return null;
      }

      dev.log('BrowseRepo: Got ${bytes.length} bytes', name: 'Browse');

      // Step 2: Parse the protobuf -> sections with item URIs
      final parser = BrowsitaParser(bytes);
      final browseData = await parser.parse();

      if (browseData.sections.isEmpty) {
        dev.log('BrowseRepo: No sections parsed', name: 'Browse');
        return null;
      }

      // Step 3: Collect all item URIs
      final allUris = <String>[];
      for (final section in browseData.sections) {
        for (final item in section.items) {
          if (item.uri.isNotEmpty) {
            allUris.add(item.uri);
          }
        }
      }

      if (allUris.isEmpty) return browseData;

      // Step 4: Partition into cached vs. delta
      final (:cached, :missing) = await _traitCache.partition(allUris);

      // Step 5: Only fetch traits for missing URIs (the delta)
      var allCards = Map<String, BrowseCardData>.from(cached);

      if (missing.isNotEmpty) {
        dev.log(
          'BrowseRepo: Fetching delta: ${missing.length} URIs '
          '(${cached.length} from cache)',
          name: 'Browse',
        );

        final fetcher = BrowseMetadataFetcher(client: _client);
        final freshCards = await fetcher.fetchBrowseTraits(missing);

        // Cache the fresh results
        await _traitCache.putAll(freshCards);

        allCards.addAll(freshCards);
      } else {
        dev.log(
          'BrowseRepo: All ${cached.length} URIs from cache (no network)',
          name: 'Browse',
        );
      }

      // Step 6: Hydrate items with traits
      final hydratedSections = browseData.sections.map((section) {
        final hydratedItems = section.items.map((item) {
          final card = allCards[item.uri];
          if (card == null) return item;

          return item.copyWith(
            title: card.name.isNotEmpty ? card.name : null,
            imageUrl: card.imageUrl,
            backgroundColor: card.bgColorArgb,
          );
        }).toList();

        return BrowseSection(
          sectionId: section.sectionId,
          sectionType: section.sectionType,
          title: section.title,
          iconName: section.iconName,
          items: hydratedItems,
          navigateUri: section.navigateUri,
        );
      }).toList();

      return BrowseViewData(sections: hydratedSections);
    } catch (e, stack) {
      dev.log('BrowseRepo error: $e\n$stack', name: 'Browse');
      return null;
    }
  }

  /// GET /browsita/v1/browse
  Future<Uint8List?> _fetchBrowsita() {
    return _client.get('/browsita/v1/browse?timezone=Asia/Calcutta');
  }
}
