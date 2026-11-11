import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';

/// Sealed state hierarchy governing private playlists collection and filtering.
@immutable
sealed class VaultPlaylistsState extends Equatable {
  const VaultPlaylistsState();

  @override
  List<Object?> get props => [];
}

/// Initial state prior to executing encrypted storage query.
@immutable
final class VaultPlaylistsInitialState extends VaultPlaylistsState {
  const VaultPlaylistsInitialState();
}

/// Loading state while Drift SQLite decrypts playlist records.
@immutable
final class VaultPlaylistsLoadingState extends VaultPlaylistsState {
  const VaultPlaylistsLoadingState();
}

/// Decrypted playlists successfully loaded in memory.
@immutable
final class VaultPlaylistsLoadedState extends VaultPlaylistsState {
  final List<PrivatePlaylist> allPlaylists;
  final String searchQuery;
  final List<PrivatePlaylist> filteredPlaylists;

  VaultPlaylistsLoadedState({
    required List<PrivatePlaylist> allPlaylists,
    this.searchQuery = '',
    List<PrivatePlaylist>? filteredPlaylists,
  })  : allPlaylists = List.unmodifiable(allPlaylists),
        filteredPlaylists = List.unmodifiable(
          filteredPlaylists ?? _filter(allPlaylists, searchQuery),
        );

  static List<PrivatePlaylist> _filter(List<PrivatePlaylist> playlists, String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return playlists;
    return playlists.where((p) => p.name.toLowerCase().contains(clean)).toList();
  }

  VaultPlaylistsLoadedState copyWith({
    List<PrivatePlaylist>? allPlaylists,
    String? searchQuery,
    List<PrivatePlaylist>? filteredPlaylists,
  }) {
    final newAll = allPlaylists ?? this.allPlaylists;
    final newQuery = searchQuery ?? this.searchQuery;
    return VaultPlaylistsLoadedState(
      allPlaylists: newAll,
      searchQuery: newQuery,
      filteredPlaylists: filteredPlaylists ?? _filter(newAll, newQuery),
    );
  }

  @override
  List<Object?> get props => [allPlaylists, searchQuery, filteredPlaylists];
}

/// Failure state when database decryption or I/O encounters an error.
@immutable
final class VaultPlaylistsErrorState extends VaultPlaylistsState {
  final String message;

  const VaultPlaylistsErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}
