library;

import '../logging/ubi_logger.dart';

/// 1:1 replica of Spotify `p199p.rlk0` (Tab bar root UBI element).
class TabBarUbiElement extends UbiInteractionElement {
  const TabBarUbiElement({
    super.actionName = 'hit',
    super.uri,
  }) : super(elementPath: 'tab_bar');
}

/// 1:1 replica of Spotify `p199p.nlk0` (Home tab UBI element).
class HomeTabUbiElement extends UbiInteractionElement {
  const HomeTabUbiElement.navigate({
    String destination = 'spotify:home',
  }) : super(
          elementPath: 'tab_bar/home_tab',
          actionName: 'ui_navigate',
          uri: destination,
        );

  const HomeTabUbiElement.quickScroll()
      : super(
          elementPath: 'tab_bar/home_tab',
          actionName: 'quick_scroll',
        );
}

/// 1:1 replica of Spotify `p199p.plk0` (Search tab UBI element).
class SearchTabUbiElement extends UbiInteractionElement {
  const SearchTabUbiElement.navigate({
    String destination = 'spotify:search',
  }) : super(
          elementPath: 'tab_bar/search_tab',
          actionName: 'ui_navigate',
          uri: destination,
        );

  const SearchTabUbiElement.quickScroll()
      : super(
          elementPath: 'tab_bar/search_tab',
          actionName: 'quick_scroll',
        );
}

/// 1:1 replica of Spotify `p199p.qlk0` (Your Library tab UBI element).
class YourLibraryTabUbiElement extends UbiInteractionElement {
  const YourLibraryTabUbiElement.navigate({
    String destination = 'spotify:yourlibrary',
  }) : super(
          elementPath: 'tab_bar/your_library_tab',
          actionName: 'ui_navigate',
          uri: destination,
        );

  const YourLibraryTabUbiElement.quickScroll()
      : super(
          elementPath: 'tab_bar/your_library_tab',
          actionName: 'quick_scroll',
        );
}

/// Canonical Spotify Now Playing Bar expand navigation element (spec 1339).
class NowPlayingBarExpandUbiElement extends UbiInteractionElement {
  const NowPlayingBarExpandUbiElement({
    String destination = 'spotify:nowplaying',
  }) : super(
          elementPath: 'nowplaying/nowplayingbar',
          actionName: 'ui_navigate',
          uri: destination,
        );
}
