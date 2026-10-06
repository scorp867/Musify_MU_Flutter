import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/statement/data_requirement.dart';
import 'package:musify_mu/core/kodiak/statement/data_statement.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:musify_mu/features/home_feed/data/eagerload/eagerload_payload_builder.dart';
import 'package:musify_mu/features/home_feed/data/elements/image_link_card_data_element.dart';
import 'package:musify_mu/features/home_feed/data/elements/preview_card_data_element.dart';
import 'package:musify_mu/features/home_feed/data/extended_metadata_fetcher.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';

void main() {
  group('Kodiak DataStatement & DataRequirement', () {
    test('ImageLinkCardDataElement declares 1 required and 5 optional traits', () {
      final stmt = ImageLinkCardDataElement.statement;
      expect(stmt.requirements.length, equals(6));
      expect(stmt.requiredRequirements.length, equals(1));
      expect(stmt.optionalRequirements.length, equals(5));

      // Level 1 required trait: SIMPLE_TRAIT (97)
      final l1 = stmt.requiredRequirements.first;
      expect(l1.extensionKindValue, equals(97));
      expect(l1.traitType, equals(SimpleCardTrait));

      // Level 2 optional traits: 178, 179, 31, 52, 64
      final l2Kinds = stmt.optionalRequirements.map((r) => r.extensionKindValue).toSet();
      expect(l2Kinds, containsAll([178, 179, 31, 52, 64]));
    });

    test('PreviewCardDataElement declares required and optional traits', () {
      final stmt = PreviewCardDataElement.statement;
      expect(stmt.requiredRequirements.map((r) => r.extensionKindValue), containsAll([118, 116]));
      expect(stmt.optionalRequirements.map((r) => r.extensionKindValue), containsAll([178, 179, 181, 31]));
    });
  });

  group('Kodiak DataPool', () {
    late DataPool dataPool;

    setUp(() {
      dataPool = DataPool();
    });

    tearDown(() {
      dataPool.dispose();
    });

    test('ingestTraits stores and retrieves traits correctly', () {
      const uri = 'spotify:album:12345';
      const simple = SimpleCardTrait(title: 'Album Title', subtitle: 'Artist');
      const identity = IdentityTrait(name: 'Identity Title');

      dataPool.ingestTraits(uri, {
        'SimpleCardTrait': simple,
        'IdentityTrait': identity,
      });

      expect(dataPool.getTrait<SimpleCardTrait>(uri)?.title, equals('Album Title'));
      expect(dataPool.getTrait<IdentityTrait>(uri)?.title, equals('Identity Title'));
      expect(dataPool.getTrait<VisualIdentityTrait>(uri), isNull);
    });

    test('hasRequiredTraits correctly checks DataStatement satisfaction', () {
      const uri = 'spotify:album:test';
      final stmt = ImageLinkCardDataElement.statement;

      // Before ingestion -> missing required (SimpleCardTrait)
      expect(dataPool.hasRequiredTraits(uri, stmt), isFalse);

      // Ingest required trait
      dataPool.ingestTraits(uri, {
        'SimpleCardTrait': const SimpleCardTrait(title: 'T', subtitle: 'S'),
      });

      expect(dataPool.hasRequiredTraits(uri, stmt), isTrue);
    });

    test('watchEntity emits current and updated traits', () async {
      const uri = 'spotify:playlist:test';
      const simple = SimpleCardTrait(title: 'Initial', subtitle: '');
      dataPool.ingestTraits(uri, {'SimpleCardTrait': simple});

      final emissions = <Map<String, Trait>>[];
      final sub = dataPool.watchEntity(uri).listen((traits) {
        emissions.add(traits);
      });

      // Update with Level 2 optional trait
      dataPool.ingestTraits(uri, {
        'IdentityTrait': const IdentityTrait(name: 'Enriched'),
      });

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();

      expect(emissions.isNotEmpty, isTrue);
      expect(emissions.last['IdentityTrait'], isNotNull);
    });

    test('loadBatch records resolved kinds and skips subsequent queries for optional traits', () async {
      final mockFetcher = _MockExtendedMetadataFetcher();
      final pool = DataPool(fetcher: mockFetcher);

      const uri = 'spotify:album:cached_test';
      final stmt = ImageLinkCardDataElement.statement;

      // First load: queries all 6 kinds
      await pool.loadBatch(uris: [uri], statement: stmt);
      expect(mockFetcher.callCount, equals(1));
      expect(mockFetcher.lastQueries[uri], containsAll([97, 178, 179, 31, 52, 64]));

      // Verify that even though traits 179, 31, 52, 64 were not returned by backend,
      // DataPool marked them as resolved
      expect(pool.isKindResolved(uri, 31), isTrue);
      expect(pool.isKindResolved(uri, 52), isTrue);
      expect(pool.isKindResolved(uri, 64), isTrue);

      // Second load: same section comes into viewport again
      await pool.loadBatch(uris: [uri], statement: stmt);

      // NO redundant network request made!
      expect(mockFetcher.callCount, equals(1));
    });
  });

  group('EagerloadPayloadBuilder', () {
    test('build generates valid Base64 JSON containing section mappings', () {
      final base64String = EagerloadPayloadBuilder.build();
      expect(base64String.isNotEmpty, isTrue);

      final jsonString = utf8.decode(base64Decode(base64String));
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(decoded.containsKey('mapping'), isTrue);
      final mapping = decoded['mapping'] as Map<String, dynamic>;

      // Shortcuts (section 2) should be present
      expect(mapping.containsKey('2'), isTrue);
      final sec2 = mapping['2'] as Map<String, dynamic>;
      expect(sec2['1'], contains(119));

      // ImageLink (section 3) must NEVER be in eagerload mapping (Spotify rule)
      expect(mapping.containsKey('3'), isFalse);

      // Showcase (section 17) should be present
      expect(mapping.containsKey('17'), isTrue);

      // Video Promo (section 18) should be present
      expect(mapping.containsKey('18'), isTrue);
    });
  });
}

class _MockExtendedMetadataFetcher implements ExtendedMetadataFetcher {
  int callCount = 0;
  Map<String, List<int>> lastQueries = {};

  @override
  Future<Map<String, Map<String, Trait>>> fetchEntityTraits(
    Map<String, List<int>> entityQueries,
  ) async {
    callCount++;
    lastQueries = entityQueries;
    final res = <String, Map<String, Trait>>{};
    for (final uri in entityQueries.keys) {
      res[uri] = {
        'SimpleCardTrait': const SimpleCardTrait(title: 'Album', subtitle: 'Artist'),
        'IdentityTrait': const IdentityTrait(name: 'Album'),
      };
    }
    return res;
  }

  @override
  Future<Map<String, SimpleCardTrait>> fetchTraits(List<String> uris) async => {};
}
