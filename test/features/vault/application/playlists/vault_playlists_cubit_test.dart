import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/application/playlists/vault_playlists_cubit.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_vault_storage_repository.dart';

class FakeVaultStorageRepository implements IVaultStorageRepository {
  final List<PrivatePlaylist> playlists = [];
  bool failNextLoad = false;
  String failureMessage = 'Storage error';

  @override
  Future<VaultResult<List<PrivatePlaylist>>> getPlaylists() async {
    if (failNextLoad) {
      return VaultResult.failure(VaultStorageFailure(failureMessage));
    }
    return VaultResult.success(List.unmodifiable(playlists));
  }

  @override
  Future<VaultResult<PrivatePlaylist>> createPlaylist({
    required String name,
    required String description,
    String? coverUri,
  }) async {
    final newPlaylist = PrivatePlaylist(
      id: 'pl_${playlists.length + 1}',
      name: name,
      description: description,
      coverUri: coverUri,
      totalDurationMs: 0,
      createdAtEpochMs: 1000,
      updatedAtEpochMs: 1000,
      trackRefs: const [],
    );
    playlists.add(newPlaylist);
    return VaultResult.success(newPlaylist);
  }

  @override
  Future<VaultResult<void>> deletePlaylist(String playlistId) async {
    playlists.removeWhere((p) => p.id == playlistId);
    return const VaultResult.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('VaultPlaylistsCubit Tests', () {
    late FakeVaultStorageRepository storageRepo;
    late VaultPlaylistsCubit cubit;

    final playlist1 = PrivatePlaylist(
      id: 'pl_1',
      name: 'Gym Workout',
      description: 'Heavy bass',
      totalDurationMs: 120000,
      createdAtEpochMs: 1000,
      updatedAtEpochMs: 1000,
      trackRefs: const [],
    );

    final playlist2 = PrivatePlaylist(
      id: 'pl_2',
      name: 'Late Night Chill',
      description: 'Lofi beats',
      totalDurationMs: 240000,
      createdAtEpochMs: 2000,
      updatedAtEpochMs: 2000,
      trackRefs: const [],
    );

    setUp(() {
      storageRepo = FakeVaultStorageRepository();
      cubit = VaultPlaylistsCubit(storageRepository: storageRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state is VaultPlaylistsInitialState', () {
      expect(cubit.state, isA<VaultPlaylistsInitialState>());
      expect(cubit.state.props, isEmpty);
    });

    test('loadPlaylists emits [Loading, Loaded] on success', () async {
      storageRepo.playlists.addAll([playlist1, playlist2]);

      final states = <VaultPlaylistsState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadPlaylists();
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<VaultPlaylistsLoadingState>());
      expect(states[1], isA<VaultPlaylistsLoadedState>());

      final loaded = states[1] as VaultPlaylistsLoadedState;
      expect(loaded.allPlaylists.length, 2);
      expect(loaded.filteredPlaylists.length, 2);
      expect(loaded.searchQuery, isEmpty);
      expect(loaded.allPlaylists[0].name, 'Gym Workout');
      expect(loaded.allPlaylists[1].name, 'Late Night Chill');

      await sub.cancel();
    });

    test('loadPlaylists emits [Loading, Error] on storage failure', () async {
      storageRepo.failNextLoad = true;
      storageRepo.failureMessage = 'Decryption failed';

      final states = <VaultPlaylistsState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadPlaylists();
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<VaultPlaylistsLoadingState>());
      expect(states[1], isA<VaultPlaylistsErrorState>());

      final error = states[1] as VaultPlaylistsErrorState;
      expect(error.message, 'Decryption failed');
      expect(error.props, ['Decryption failed']);

      await sub.cancel();
    });

    test('filterPlaylists filters loaded playlists case-insensitively', () async {
      storageRepo.playlists.addAll([playlist1, playlist2]);
      await cubit.loadPlaylists();

      cubit.filterPlaylists('gym');
      expect(cubit.state, isA<VaultPlaylistsLoadedState>());
      var loaded = cubit.state as VaultPlaylistsLoadedState;
      expect(loaded.searchQuery, 'gym');
      expect(loaded.filteredPlaylists.length, 1);
      expect(loaded.filteredPlaylists.first.id, 'pl_1');

      cubit.filterPlaylists('NIGHT');
      loaded = cubit.state as VaultPlaylistsLoadedState;
      expect(loaded.filteredPlaylists.length, 1);
      expect(loaded.filteredPlaylists.first.id, 'pl_2');

      cubit.filterPlaylists('nonexistent');
      loaded = cubit.state as VaultPlaylistsLoadedState;
      expect(loaded.filteredPlaylists, isEmpty);
      expect(loaded.allPlaylists.length, 2);

      cubit.filterPlaylists('');
      loaded = cubit.state as VaultPlaylistsLoadedState;
      expect(loaded.filteredPlaylists.length, 2);
    });

    test('createPlaylist calls storage and reloads playlist dataset', () async {
      final states = <VaultPlaylistsState>[];
      final sub = cubit.stream.listen(states.add);

      final result = await cubit.createPlaylist(
        name: 'Study Session',
        description: 'Deep focus',
      );

      expect(result, isA<VaultSuccess<PrivatePlaylist>>());
      final created = (result as VaultSuccess<PrivatePlaylist>).data;
      expect(created.name, 'Study Session');
      expect(storageRepo.playlists.length, 1);

      expect(cubit.state, isA<VaultPlaylistsLoadedState>());
      final loaded = cubit.state as VaultPlaylistsLoadedState;
      expect(loaded.allPlaylists.length, 1);
      expect(loaded.allPlaylists.first.name, 'Study Session');

      await sub.cancel();
    });

    test('deletePlaylist calls storage and reloads playlist dataset', () async {
      storageRepo.playlists.add(playlist1);
      await cubit.loadPlaylists();

      expect((cubit.state as VaultPlaylistsLoadedState).allPlaylists.length, 1);

      final result = await cubit.deletePlaylist('pl_1');
      expect(result, isA<VaultSuccess<void>>());
      expect(storageRepo.playlists, isEmpty);

      expect(cubit.state, isA<VaultPlaylistsLoadedState>());
      expect((cubit.state as VaultPlaylistsLoadedState).allPlaylists, isEmpty);
    });

    test('VaultPlaylistsState copyWith and Equatable structural equality', () {
      final state1 = VaultPlaylistsLoadedState(
        allPlaylists: [playlist1],
        searchQuery: 'gym',
      );

      final state2 = state1.copyWith();
      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));

      final state3 = state1.copyWith(searchQuery: 'new');
      expect(state1 == state3, isFalse);
    });
  });
}
