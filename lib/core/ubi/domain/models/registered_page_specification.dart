library;

import 'package:equatable/equatable.dart';
import 'page_specification.dart';

/// 1:1 replica of Spotify `p199p.olp0` (RegisteredPageSpecification).
class RegisteredPageSpecification extends Equatable
    implements PageSpecification, Comparable<RegisteredPageSpecification> {
  final String name;
  final int id;
  final String specPath;
  final String specPageId;

  const RegisteredPageSpecification({
    required this.name,
    required this.id,
    required this.specPath,
    required this.specPageId,
  });

  /// Canonical Spotify Home Page Specification matching `a2m1.java` (ID 791).
  static const RegisteredPageSpecification home =
      RegisteredPageSpecification(
    name: 'HOME',
    id: 791,
    specPath: 'home',
    specPageId: 'home',
  );

  /// Canonical Spotify Search Page Specification matching `a2m1.java` (ID 1758).
  static const RegisteredPageSpecification search =
      RegisteredPageSpecification(
    name: 'SEARCH',
    id: 1758,
    specPath: 'search',
    specPageId: 'search',
  );

  /// Canonical Spotify Your Library Page Specification matching `a2m1.java` (ID 2223).
  static const RegisteredPageSpecification yourLibrary =
      RegisteredPageSpecification(
    name: 'YOURLIBRARY',
    id: 2223,
    specPath: 'yourlibrary',
    specPageId: 'yourlibrary',
  );

  /// Canonical Spotify Playlist Page Specifications matching `a2m1.java`:
  /// - `PLAYLIST` (1430, "playlist", "playlist")
  /// - `PLAYLIST_ALLSONGS` (1433, "playlist/allsongs", "playlist")
  /// - `PLAYLIST_ADDTOPLAYLIST` (1431, "playlist/addtoplaylist", "playlist")
  static const RegisteredPageSpecification playlist =
      RegisteredPageSpecification(
    name: 'PLAYLIST',
    id: 1430,
    specPath: 'playlist',
    specPageId: 'playlist',
  );

  static const RegisteredPageSpecification playlistAllSongs =
      RegisteredPageSpecification(
    name: 'PLAYLIST_ALLSONGS',
    id: 1433,
    specPath: 'playlist/allsongs',
    specPageId: 'playlist',
  );

  static const RegisteredPageSpecification playlistAddToPlaylist =
      RegisteredPageSpecification(
    name: 'PLAYLIST_ADDTOPLAYLIST',
    id: 1431,
    specPath: 'playlist/addtoplaylist',
    specPageId: 'playlist',
  );

  static const RegisteredPageSpecification nowPlaying =
      RegisteredPageSpecification(
    name: 'NOWPLAYING',
    id: 1335,
    specPath: 'nowplaying',
    specPageId: 'nowplaying',
  );

  static const RegisteredPageSpecification nowPlayingBar =
      RegisteredPageSpecification(
    name: 'NOWPLAYING_NOWPLAYINGBAR',
    id: 1339,
    specPath: 'nowplaying/nowplayingbar',
    specPageId: 'nowplaying',
  );

  static const RegisteredPageSpecification nowPlayingQueue =
      RegisteredPageSpecification(
    name: 'NOWPLAYING_QUEUE',
    id: 1343,
    specPath: 'nowplaying/queue',
    specPageId: 'nowplaying',
  );

  @override
  String pageId() => specPageId;

  @override
  String path() => specPath;

  @override
  int compareTo(RegisteredPageSpecification other) => id.compareTo(other.id);

  @override
  List<Object?> get props => [name, id, specPath, specPageId];

  @override
  String toString() => "{pageIdentifier='$specPath'}";
}
