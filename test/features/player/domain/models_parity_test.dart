import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/player/data/queue/context_track_extensions.dart';
import 'package:musify_mu/features/player/domain/commands/play_command.dart';
import 'package:musify_mu/features/player/domain/models/context.dart';
import 'package:musify_mu/features/player/domain/models/context_page.dart';
import 'package:musify_mu/features/player/domain/models/context_track.dart';
import 'package:musify_mu/features/player/domain/models/player_options.dart';
import 'package:musify_mu/features/player/domain/models/player_queue.dart';
import 'package:musify_mu/features/player/domain/models/player_state.dart';
import 'package:musify_mu/features/player/domain/models/play_origin.dart';
import 'package:musify_mu/features/player/domain/models/restrictions.dart';

void main() {
  group('Spotify Core Models AutoValue & Parity Tests', () {
    test('ContextTrack: builder and metadata access parity', () {
      final track = ContextTrack.builder('spotify:track:123')
          .uid('custom_uid')
          .provider('context')
          .metadata({
            ContextTrackMetadata.keyTitle: 'Blinding Lights',
            ContextTrackMetadata.keyArtistName: 'The Weeknd',
            ContextTrackMetadata.keyAlbumTitle: 'After Hours',
            ContextTrackMetadata.keyDuration: '200000',
            ContextTrackMetadata.keyIsQueued: 'true',
          })
          .build();

      expect(track.uri, 'spotify:track:123');
      expect(track.uid, 'custom_uid');
      expect(track.provider, 'context');
      expect(track.title, 'Blinding Lights');
      expect(track.artist, 'The Weeknd');
      expect(track.album, 'After Hours');
      expect(track.isQueued, true);
      expect(track.duration, const Duration(milliseconds: 200000));
    });

    test('PlayerQueue: immutability, builder, and equality', () {
      final track = ContextTrack.builder('spotify:track:abc').build();
      final queue1 = PlayerQueue.builder()
          .revision('rev_1')
          .track(track)
          .nextTracks([track])
          .build();

      final queue2 = PlayerQueue.builder()
          .revision('rev_1')
          .track(track)
          .nextTracks([track])
          .build();

      expect(queue1, equals(queue2));
      expect(queue1.hashCode, equals(queue2.hashCode));
      expect(queue1.revision, 'rev_1');
      expect(queue1.nextTracks.length, 1);
    });

    test('PlayerOptions: defaults and builder parity', () {
      final options = PlayerOptions.builder()
          .shufflingContext(true)
          .repeatingContext(false)
          .repeatingTrack(true)
          .build();

      expect(options.shufflingContext, true);
      expect(options.repeatingContext, false);
      expect(options.repeatingTrack, true);
    });

    test('Restrictions: disallow flags parity', () {
      final restrictions = Restrictions.builder()
          .disallowPausingReasons({'banned'})
          .disallowSeekingReasons({'live_stream'})
          .build();

      expect(restrictions.disallowPausingReasons, contains('banned'));
      expect(restrictions.disallowSeekingReasons, contains('live_stream'));
    });

    test('Context and ContextPage: hierarchy parity', () {
      final track = ContextTrack.builder('spotify:track:xyz').build();
      final page = ContextPage.builder()
          .pageUrl('spotify:page:1')
          .tracks([track])
          .build();

      final context = Context.builder('spotify:album:123')
          .pages([page])
          .build();

      expect(context.uri, 'spotify:album:123');
      expect(context.pages?.first.tracks?.first.uri, 'spotify:track:xyz');
    });

    test('PlayCommand: AutoValue builder with context and play options', () {
      final context = Context.builder('spotify:playlist:123').build();
      const origin = PlayOrigin(featureIdentifier: 'musify');
      final command = PlayCommand.builder(context, origin)
          .build();

      expect(command.context.uri, 'spotify:playlist:123');
      expect(command.playOrigin.featureIdentifier, 'musify');
    });
  });
}
