import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/library/domain/models/library_item.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file_uri.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_entity.dart';
import 'package:musify_mu/features/playlist/domain/models/playlist_item.dart';
import 'package:musify_mu/features/playlist/presentation/extensions/track_item_metadata_presentation.dart';

/// Sealed polymorphic model for entities surfaced in [MoreOptionsBottomSheet].
@immutable
sealed class MoreOptionsEntity extends Equatable {
  const MoreOptionsEntity();

  String get title;
  String get subtitle;
  String? get artworkUrl;
  String get uri;
}

/// Spotify track representation in [MoreOptionsBottomSheet].
final class SpotifyTrackOptionsEntity extends MoreOptionsEntity {
  final PlaylistItem item;

  const SpotifyTrackOptionsEntity(this.item);

  @override
  String get title => item.title;

  @override
  String get subtitle => item.subtitle;

  @override
  String? get artworkUrl => item.thumbnailUrl;

  @override
  String get uri => item.uri;

  @override
  List<Object?> get props => [item.uri];
}

/// Local device audio file representation in [MoreOptionsBottomSheet].
final class LocalTrackOptionsEntity extends MoreOptionsEntity {
  final LocalFile file;

  const LocalTrackOptionsEntity(this.file);

  @override
  String get title => switch (file.metadata?.title) {
        final t? when t.trim().isNotEmpty => t,
        _ => file.path.split('/').last,
      };

  @override
  String get subtitle => switch (file.metadata?.artist) {
        final a? when a.trim().isNotEmpty => a,
        _ => 'Local File',
      };

  @override
  String? get artworkUrl =>
      LocalFileUri.toLocalFileImageUri(LocalFileUri.fromLocalFile(file));

  @override
  String get uri => file.path;

  @override
  List<Object?> get props => [file.path];
}

/// Spotify playlist representation in [MoreOptionsBottomSheet].
final class SpotifyPlaylistOptionsEntity extends MoreOptionsEntity {
  final PlaylistEntity playlist;

  const SpotifyPlaylistOptionsEntity(this.playlist);

  @override
  String get title => playlist.name;

  @override
  String get subtitle => '${playlist.items.length} tracks';

  @override
  String? get artworkUrl => playlist.pictureUrl;

  @override
  String get uri => playlist.uri;

  @override
  List<Object?> get props => [playlist.uri];
}

/// Local playlist representation in [MoreOptionsBottomSheet].
final class LocalPlaylistOptionsEntity extends MoreOptionsEntity {
  final String playlistName;
  final List<LocalFile> files;
  final String? coverArtworkUrl;

  const LocalPlaylistOptionsEntity({
    required this.playlistName,
    required this.files,
    this.coverArtworkUrl,
  });

  @override
  String get title => playlistName;

  @override
  String get subtitle => '${files.length} local tracks';

  @override
  String? get artworkUrl => coverArtworkUrl;

  @override
  String get uri =>
      'musify:local_playlist:${playlistName.toLowerCase().replaceAll(' ', '_')}';

  @override
  List<Object?> get props => [playlistName, files];
}

/// Generic Library item representation in [MoreOptionsBottomSheet].
final class LibraryItemOptionsEntity extends MoreOptionsEntity {
  final LibraryItem item;

  const LibraryItemOptionsEntity(this.item);

  @override
  String get title => item.name;

  @override
  String get subtitle => switch (item.ownerName) {
        final o? when o.trim().isNotEmpty => o,
        _ => item.type,
      };

  @override
  String? get artworkUrl => item.imageUrl;

  @override
  String get uri => item.uri;

  @override
  List<Object?> get props => [item.uri];
}
