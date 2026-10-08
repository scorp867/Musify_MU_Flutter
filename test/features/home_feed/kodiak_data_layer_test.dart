import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool.dart';
import 'package:musify_mu/core/kodiak/dataloader/data_pool_impl.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/batched_extension_response_parser.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_data_source.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/extended_metadata_plugin_registry.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/kodiak_cell_mapper.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/plugins/builtin_plugins.dart';
import 'package:musify_mu/core/protocol/generated/spotify/contentagnostic/v2/identity_trait.pb.dart' as it_pb;
import 'package:musify_mu/core/protocol/generated/spotify/entity_extension_data.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extension_kind.pbenum.dart';
import 'package:protobuf/well_known_types/google/protobuf/any.pb.dart' as pb_any;
import 'package:musify_mu/core/kodiak/table/cell_key.dart';
import 'package:musify_mu/core/kodiak/table/data_source_result.dart';
import 'package:musify_mu/core/kodiak/table/table_key.dart';
import 'package:musify_mu/features/home_feed/data/eagerload/eagerload_payload_builder.dart';
import 'package:musify_mu/features/home_feed/data/elements/image_link_card_data_element.dart';
import 'package:musify_mu/features/home_feed/data/elements/podcast_preview_data_element.dart';
import 'package:musify_mu/features/home_feed/data/elements/preview_card_data_element.dart';
import 'package:musify_mu/features/home_feed/domain/models/home_view_data.dart';
import 'package:musify_mu/features/home_feed/domain/models/spotify_entity.dart';
import 'package:musify_mu/features/home_feed/domain/models/traits.dart';
import 'package:musify_mu/features/home_feed/presentation/section_registry.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/podcast_preview_section.dart';
import 'package:musify_mu/features/home_feed/presentation/widgets/sections/preview_feed_section.dart';

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

    test('PodcastPreviewDataElement declares required and optional traits', () {
      final stmt = PodcastPreviewDataElement.statement;
      expect(stmt.optionalRequirements.map((r) => r.extensionKindValue),
          containsAll([118, 116, 178, 179, 181, 12, 97, 31]));
    });

    test('SectionRegistry decouples preview from immersivePreview', () {
      const registry = SectionRegistry();
      final previewSection = registry.buildSection(
        const HomeSection(title: 'Similar to your interests', sectionType: 'preview'),
      );
      expect(previewSection, isA<PodcastPreviewSection>());

      final immersiveSection = registry.buildSection(
        const HomeSection(title: 'Based on your recent listening', sectionType: 'immersivePreview'),
      );
      expect(immersiveSection, isA<PreviewFeedSection>());
    });
  });

  group('Kodiak DataPool & ExtendedMetadataDataSourceImpl (1:1 Spotify)', () {
    late DataPool dataPool;
    late ExtendedMetadataDataSourceImpl dataSource;

    setUp(() {
      dataSource = ExtendedMetadataDataSourceImpl();
      dataPool = DataPoolImpl(dataSource: dataSource);
    });

    tearDown(() {
      dataPool.dispose();
      dataSource.dispose();
    });

    test('ingestCells (t1w.f) warms up cache synchronously without network delay', () {
      const uri = 'spotify:album:eager123';
      final simple = const SimpleCardTrait(title: 'Eager Title', subtitle: 'Eager Subtitle');
      final identity = const IdentityTrait(name: 'Identity Title');

      final cell1 = CellKey(const TableKey<SimpleCardTrait>(), uri);
      final cell2 = CellKey(const TableKey<IdentityTrait>(), uri);

      // Warm up Kodiak cache exactly like ResolvedHome parser (z510.java:125 -> t1w.f)
      dataPool.ingestCells({
        cell1: simple,
        cell2: identity,
      });

      // Data is immediately available (Available) without network call
      final r1 = dataSource.getCached({cell1})[cell1];
      expect(r1, isA<Available>());
      expect((r1 as Available).value, equals(simple));

      expect(dataPool.getTrait<SimpleCardTrait>(uri)?.title, equals('Eager Title'));
      expect(dataPool.getTrait<IdentityTrait>(uri)?.title, equals('Identity Title'));
      expect(dataPool.getTrait<VisualIdentityTrait>(uri), isNull);
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
  });

  group('BatchedExtensionResponseParser & KodiakCellMapper', () {
    test('KodiakCellMapper maps nested map to flat CellKey map (p.aba1.r)', () {
      final registry = ExtendedMetadataPluginRegistry(createDefaultExtendedMetadataPlugins());
      expect(registry.pluginForKind(97), isA<SimpleCardTraitPlugin>());
      expect(registry.pluginForKind(10), isA<TrackV4Plugin>());

      final traitsMap = {
        'spotify:album:xyz': {
          SimpleCardTrait: const SimpleCardTrait(title: 'Test Album', subtitle: 'Artist'),
        },
      };

      final cells = KodiakCellMapper.map(traitsMap);
      expect(cells.length, equals(1));

      final key = CellKey(const TableKey<SimpleCardTrait>(), 'spotify:album:xyz');
      expect(cells.containsKey(key), isTrue);
      expect((cells[key] as SimpleCardTrait).title, equals('Test Album'));
    });

    test('IdentityTrait parses payload with contributors and parent without error', () {
      final registry = ExtendedMetadataPluginRegistry(createDefaultExtendedMetadataPlugins());
      final identityPlugin = registry.pluginForKind(178);
      expect(identityPlugin, isNotNull);

      final proto = it_pb.IdentityTrait(
        type: 'track',
        name: 'Bohemian Rhapsody',
        description: '',
        contentHierarchyParent: it_pb.EntityReference(
          name: 'A Night at the Opera',
          uri: 'spotify:album:2cCuohwVvzbD398tCaBiW2',
        ),
        contributors: [
          it_pb.ContributorReference(
            name: 'Queen',
            uri: 'spotify:artist:1dfeR4HaWDbWqFsssgavss',
          ),
        ],
      );

      final payloadBytes = proto.writeToBuffer();
      final parsedTrait = identityPlugin!.parse(Uint8List.fromList(payloadBytes)) as IdentityTrait;

      expect(parsedTrait.name, equals('Bohemian Rhapsody'));
      expect(parsedTrait.type, equals('track'));
      expect(parsedTrait.parentName, equals('A Night at the Opera'));
      expect(parsedTrait.parentUri, equals('spotify:album:2cCuohwVvzbD398tCaBiW2'));
      expect(parsedTrait.contributors, equals(['Queen']));

      // Test via BatchedExtensionResponseParser
      final batchResponse = BatchedExtensionResponse(
        extendedMetadata: [
          EntityExtensionDataArray(
            extensionKind: ExtensionKind.IDENTITY_TRAIT,
            extensionData: [
              EntityExtensionData(
                entityUri: 'spotify:track:07mgrIfzVe5YIgl7bioa9q',
                header: EntityExtensionDataHeader(statusCode: 200),
                extensionData: pb_any.Any(value: payloadBytes),
              ),
            ],
          ),
        ],
      );

      final parsedMap = BatchedExtensionResponseParser.parseProtobuf(batchResponse, registry);
      expect(parsedMap.containsKey('spotify:track:07mgrIfzVe5YIgl7bioa9q'), isTrue);
      final entityTraits = parsedMap['spotify:track:07mgrIfzVe5YIgl7bioa9q']!;
      expect(entityTraits.containsKey(IdentityTrait), isTrue);
      final idTrait = entityTraits[IdentityTrait] as IdentityTrait;
      expect(idTrait.name, equals('Bohemian Rhapsody'));
      expect(idTrait.contributors, contains('Queen'));

      // Check SpotifyEntity cardSubtitle fallback to contributors
      final entity = SpotifyEntity(
        uri: 'spotify:track:07mgrIfzVe5YIgl7bioa9q',
        type: ContentType.track,
        traits: {
          'IdentityTrait': idTrait,
        },
      );
      expect(entity.cardTitle, equals('Bohemian Rhapsody'));
      expect(entity.cardSubtitle, equals('Queen'));
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
