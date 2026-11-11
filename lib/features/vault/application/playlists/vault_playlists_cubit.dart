import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/vault/application/playlists/vault_playlists_state.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';

export 'vault_playlists_state.dart';

/// Application controller governing private playlist fetching, filtering, and mutations.
class VaultPlaylistsCubit extends Cubit<VaultPlaylistsState> {
  final IVaultStorageRepository _storageRepository;

  VaultPlaylistsCubit({
    required IVaultStorageRepository storageRepository,
    VaultPlaylistsState? initialState,
  })  : _storageRepository = storageRepository,
        super(initialState ?? const VaultPlaylistsInitialState());

  /// Loads and decrypts all private playlists from encrypted Drift storage.
  Future<void> loadPlaylists() async {
    emit(const VaultPlaylistsLoadingState());
    final result = await _storageRepository.getPlaylists();
    switch (result) {
      case VaultSuccess(:final data):
        emit(VaultPlaylistsLoadedState(allPlaylists: data));
      case VaultFailureResult(:final failure):
        emit(VaultPlaylistsErrorState(message: failure.message));
    }
  }

  /// Filters loaded playlists by name substring in real time.
  void filterPlaylists(String query) {
    if (state is VaultPlaylistsLoadedState) {
      final loaded = state as VaultPlaylistsLoadedState;
      emit(loaded.copyWith(searchQuery: query));
    }
  }

  /// Creates a new private playlist and refreshes list.
  Future<VaultResult<PrivatePlaylist>> createPlaylist({
    required String name,
    required String description,
    String? coverUri,
  }) async {
    final result = await _storageRepository.createPlaylist(
      name: name,
      description: description,
      coverUri: coverUri,
    );
    if (result case VaultSuccess()) {
      await loadPlaylists();
    }
    return result;
  }

  /// Deletes a private playlist by [playlistId] and refreshes list.
  Future<VaultResult<void>> deletePlaylist(String playlistId) async {
    final result = await _storageRepository.deletePlaylist(playlistId);
    if (result case VaultSuccess()) {
      await loadPlaylists();
    }
    return result;
  }
}
