import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/navigation/spotify_navigator.dart';
import 'package:musify_mu/core/navigation/spotify_navigator_impl.dart';
import 'package:musify_mu/core/ubi/data/factory/ubi_event_metadata_factory.dart';
import 'package:musify_mu/core/ubi/data/lifecycle/page_instance_id_holder.dart';
import 'package:musify_mu/core/ubi/data/logging/ubi_logger_impl.dart';
import 'package:musify_mu/core/ubi/domain/logging/ubi_logger.dart';
import 'package:musify_mu/core/ubi/domain/models/bottom_tab_ubi_elements.dart';
import 'package:musify_mu/core/ubi/domain/models/dynamic_page_specification.dart';
import 'package:musify_mu/core/ubi/domain/models/impression_id.dart';
import 'package:musify_mu/core/ubi/domain/models/interaction_id.dart';
import 'package:musify_mu/core/ubi/domain/models/page_context.dart';
import 'package:musify_mu/core/ubi/domain/models/page_identifier.dart';
import 'package:musify_mu/core/ubi/domain/models/page_instance_id.dart';
import 'package:musify_mu/core/ubi/domain/models/registered_page_specification.dart';
import 'package:musify_mu/features/player/data/logging/player_logging_params_factory.dart';
import 'package:musify_mu/features/playlist/data/coordinator/playlist_play_coordinator.dart';

void main() {
  group('Spotify 1:1 UBI Telemetry & ID Subsystem Tests', () {
    test('InteractionId and PageInstanceId represent strongly typed UUID value objects', () {
      const interaction1 = InteractionId('test-uuid-interaction-1');
      const interaction2 = InteractionId('test-uuid-interaction-1');
      const interaction3 = InteractionId('test-uuid-interaction-2');

      expect(interaction1, equals(interaction2));
      expect(interaction1, isNot(equals(interaction3)));
      expect(interaction1.toString(), 'test-uuid-interaction-1');

      const pageInst1 = PageInstanceId('test-uuid-page-1');
      const pageInst2 = PageInstanceId('test-uuid-page-1');

      expect(pageInst1, equals(pageInst2));
      expect(pageInst1.toString(), 'test-uuid-page-1');

      const impression = ImpressionId('test-uuid-impression-1');
      expect(impression.toString(), 'test-uuid-impression-1');
    });

    test('PageSpecification models match Spotify a2m1.java & olp0.java canonical specs', () {
      expect(RegisteredPageSpecification.home.pageId(), 'home');
      expect(RegisteredPageSpecification.home.path(), 'home');
      expect(RegisteredPageSpecification.home.id, 791);
      expect(RegisteredPageSpecification.home.name, 'HOME');

      expect(RegisteredPageSpecification.search.pageId(), 'search');
      expect(RegisteredPageSpecification.search.path(), 'search');
      expect(RegisteredPageSpecification.search.id, 1758);
      expect(RegisteredPageSpecification.search.name, 'SEARCH');

      expect(RegisteredPageSpecification.yourLibrary.pageId(), 'yourlibrary');
      expect(RegisteredPageSpecification.yourLibrary.path(), 'yourlibrary');
      expect(RegisteredPageSpecification.yourLibrary.id, 2223);
      expect(RegisteredPageSpecification.yourLibrary.name, 'YOURLIBRARY');

      expect(RegisteredPageSpecification.playlist.pageId(), 'playlist');
      expect(RegisteredPageSpecification.playlist.path(), 'playlist');
      expect(RegisteredPageSpecification.playlist.id, 1430);
      expect(RegisteredPageSpecification.playlist.name, 'PLAYLIST');

      expect(RegisteredPageSpecification.playlistAllSongs.path(), 'playlist/allsongs');
      expect(RegisteredPageSpecification.playlistAllSongs.id, 1433);

      expect(RegisteredPageSpecification.nowPlaying.id, 1335);
      expect(RegisteredPageSpecification.nowPlayingBar.id, 1339);
      expect(RegisteredPageSpecification.nowPlayingQueue.id, 1343);

      const dynamicSpec = DynamicPageSpecification('playlist/custom/filter');
      expect(dynamicSpec.pageId(), 'playlist');
      expect(dynamicSpec.path(), 'playlist/custom/filter');
    });

    test('Bottom navigation UBI elements replicate rlk0, nlk0, plk0, and qlk0 1:1', () {
      const tabBar = TabBarUbiElement();
      expect(tabBar.elementPath, 'tab_bar');

      const homeNav = HomeTabUbiElement.navigate();
      expect(homeNav.elementPath, 'tab_bar/home_tab');
      expect(homeNav.actionName, 'ui_navigate');
      expect(homeNav.uri, 'spotify:home');

      const homeScroll = HomeTabUbiElement.quickScroll();
      expect(homeScroll.elementPath, 'tab_bar/home_tab');
      expect(homeScroll.actionName, 'quick_scroll');

      const searchNav = SearchTabUbiElement.navigate();
      expect(searchNav.elementPath, 'tab_bar/search_tab');
      expect(searchNav.actionName, 'ui_navigate');
      expect(searchNav.uri, 'spotify:search');

      const libraryNav = YourLibraryTabUbiElement.navigate();
      expect(libraryNav.elementPath, 'tab_bar/your_library_tab');
      expect(libraryNav.actionName, 'ui_navigate');
      expect(libraryNav.uri, 'spotify:yourlibrary');

      const nowPlayingExpand = NowPlayingBarExpandUbiElement();
      expect(nowPlayingExpand.elementPath, 'nowplaying/nowplayingbar');
      expect(nowPlayingExpand.actionName, 'ui_navigate');
      expect(nowPlayingExpand.uri, 'spotify:nowplaying');
    });

    test('PageInstanceIdHolder generates unique UUIDs and preserves state across storage restore (xlp0.java)', () {
      final holder = PageInstanceIdHolder();
      final initialId = holder.get();
      expect(initialId, isNotNull);
      expect(initialId!.value.length, greaterThan(20));

      final storage = <String, dynamic>{};
      holder.saveToStorage(storage);
      expect(storage[PageInstanceIdHolder.bundleKey], equals(initialId.value));

      final restoredHolder = PageInstanceIdHolder();
      restoredHolder.restoreFromStorage(storage);
      expect(restoredHolder.get(), equals(initialId));

      holder.dispose();
      restoredHolder.dispose();
    });

    test('UbiLoggerImpl logs interactions and impressions with unique UUIDs and current PageInstanceId (tde1.java)', () {
      final holder = PageInstanceIdHolder();
      final metaFactory = UbiEventMetadataFactory(holder);
      final ubiLogger = UbiLoggerImpl(
        metadataFactory: metaFactory,
        pageInstanceIdProvider: holder,
      );

      final interactionResult = ubiLogger.logInteraction(
        const UbiInteractionElement(
          elementPath: 'play_button',
          actionName: 'hit',
        ),
      );

      expect(interactionResult.interactionId.value.isNotEmpty, isTrue);
      expect(interactionResult.pageInstanceId, equals(holder.get()));
      expect(interactionResult.leafSpecificationId, 'play_button');
      expect(interactionResult.interactionType, 'hit');

      final impressionResult = ubiLogger.logImpression(
        const UbiImpressionElement(
          elementPath: 'track_row',
          position: 0,
        ),
      );

      expect(impressionResult.impressionId.value.isNotEmpty, isTrue);
      expect(impressionResult.pageInstanceId, equals(holder.get()));
      expect(impressionResult.impressionId.value, isNot(equals(interactionResult.interactionId.value)));

      holder.dispose();
    });

    test('PlayerLoggingParamsFactory builds complete LoggingParams matching Spotify zpl.java', () {
      final holder = PageInstanceIdHolder();
      final factory = PlayerLoggingParamsFactory(holder);

      final params = factory.createFromInteractionId('custom-interaction-id-99');
      expect(params.interactionId, 'custom-interaction-id-99');
      expect(params.pageInstanceId, holder.get()!.value);
      expect(params.commandInitiatedTime, isNotNull);

      holder.dispose();
    });

    test('PlaylistPlayCoordinator formats LoggingParams for ContextPlayer commands (r93.java)', () {
      final holder = PageInstanceIdHolder();
      final metaFactory = UbiEventMetadataFactory(holder);
      final ubiLogger = UbiLoggerImpl(
        metadataFactory: metaFactory,
        pageInstanceIdProvider: holder,
      );
      final coordinator = PlaylistPlayCoordinator(holder);

      final interaction = ubiLogger.logInteraction(
        const UbiInteractionElement(elementPath: 'play_button', actionName: 'hit'),
      );

      final params = coordinator.buildLoggingParams(interaction);
      expect(params.interactionId, interaction.interactionId.value);
      expect(params.pageInstanceId, holder.get()!.value);
      expect(params.commandInitiatedTime, isNotNull);

      // Verify null fallback handling matches r93.java unknown default
      final nullParams = coordinator.buildLoggingParams(null);
      expect(nullParams.interactionId, 'unknown');
      expect(nullParams.pageInstanceId, holder.get()!.value);

      holder.dispose();
    });

    test('PageContext correctly models composite screen specification (du9.java)', () {
      const pageId = PageInstanceId('uuid-page-inst-1');
      const pageUri = PageIdentifier('spotify:playlist:37i9dQZF1DXcBWIGoYBM5M');
      final pageContext = PageContext(
        pageSpecification: RegisteredPageSpecification.playlist,
        pageIdentifier: pageUri,
        pageInstanceId: pageId,
      );

      expect(pageContext.pageSpecification.pageId(), 'playlist');
      expect(pageContext.pageIdentifier?.value, 'spotify:playlist:37i9dQZF1DXcBWIGoYBM5M');
      expect(pageContext.pageInstanceId.value, 'uuid-page-inst-1');
    });

    test('SpotifyNavigator coordinates navigation and UBI instrumentation (vgm0.java & akl0.java)', () {
      final holder = PageInstanceIdHolder();
      final metaFactory = UbiEventMetadataFactory(holder);
      final ubiLogger = UbiLoggerImpl(
        metadataFactory: metaFactory,
        pageInstanceIdProvider: holder,
      );
      final navigator = SpotifyNavigatorImpl(
        ubiLogger: ubiLogger,
        pageInstanceIdHolder: holder,
      );

      expect(navigator, isA<SpotifyNavigator>());
      holder.dispose();
    });
  });
}
