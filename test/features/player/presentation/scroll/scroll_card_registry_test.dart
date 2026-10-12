import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/domain/models/scroll_card_descriptor.dart';
import 'package:musify_mu/features/player/presentation/scroll/scroll_card_registry.dart';

void main() {
  group('ScrollCardRegistry', () {
    test('registers and builds widgets for descriptors correctly', () {
      // Arrange
      final registry = ScrollCardRegistry();
      registry.register<CreatorBioCardDescriptor>((context, desc) {
        return const SizedBox(key: Key('creator_bio_widget'));
      });

      const descriptor = CreatorBioCardDescriptor(creatorUri: 'spotify:artist:abc');

      // Act
      final widget = registry.buildCard(
        // Using null-safe mockup context for testing pure builder lookup
        _MockBuildContext(),
        descriptor,
      );

      // Assert
      expect(widget, isNotNull);
      expect((widget as SizedBox).key, const Key('creator_bio_widget'));
    });

    test('returns null for unregistered descriptor type', () {
      // Arrange
      final registry = ScrollCardRegistry();
      const descriptor = LyricsCardDescriptor(entityUri: 'spotify:track:123');

      // Act
      final widget = registry.buildCard(_MockBuildContext(), descriptor);

      // Assert
      expect(widget, isNull);
    });
  });
}

class _MockBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
