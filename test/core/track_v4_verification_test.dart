import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/kodiak/extendedmetadataimpl/plugins/track_v4_plugin.dart';
import 'package:musify_mu/core/protocol/generated/spotify/extended_metadata.pb.dart';

void main() {
  test('TrackV4Plugin parses real Spotify ExtendedMetadata payload', () {
    final file = File('scratch/trait_10_response(291026)');
    expect(file.existsSync(), isTrue);

    final bytes = file.readAsBytesSync();
    final batch = BatchedExtensionResponse.fromBuffer(bytes);

    const plugin = TrackV4Plugin();
    int parsedTrackCount = 0;

    for (final array in batch.extendedMetadata) {
      if (array.extensionKind.value == 10) {
        for (final item in array.extensionData) {
          if (item.hasExtensionData()) {
            final trait = plugin.parse(Uint8List.fromList(item.extensionData.value));
            parsedTrackCount++;

            expect(trait.title.isNotEmpty, isTrue);
            expect(trait.durationMs > 0, isTrue);
            // Verify Vorbis head file is extracted (1:1 from field 12)
            expect(trait.fileId.length, equals(40));
            expect(trait.headUrl.startsWith('https://heads-fa-tls13.spotifycdn.com/head/'), isTrue);
            // Verify TrackV4 leaves full-track aacFileId empty (full playback is resolved by PlaybackTrait 212)
            expect(trait.aacFileId.isEmpty, isTrue);
          }
        }
      }
    }

    expect(parsedTrackCount, equals(52));
  });
}
