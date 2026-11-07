import 'dart:async';

import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/local_music/data/datasources/device_music_data_source.dart';
import 'package:musify_mu/features/local_music/data/datasources/local_tracks_store.dart';
import 'package:musify_mu/features/local_music/data/services/local_music_sync_service.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file_image_state.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file_metadata.dart';
import 'package:musify_mu/features/local_music/domain/repositories/local_music_repository.dart';

class LocalMusicRepositoryImpl implements LocalMusicRepository {
  final DeviceMusicDataSource _deviceMusic;
  final LocalTracksStore _store;
  final LocalMusicSyncService _syncService;
  StreamSubscription<void>? _changesSub;

  LocalMusicRepositoryImpl({
    required DeviceMusicDataSource deviceMusic,
    required LocalTracksStore store,
    required LocalMusicSyncService syncService,
  }) : _deviceMusic = deviceMusic,
       _store = store,
       _syncService = syncService {
    _changesSub = _deviceMusic.changes.listen(
      (_) => unawaited(_syncService.sync()),
    );
  }

  void dispose() {
    final sub = _changesSub;
    _changesSub = null;
    if (sub != null) {
      unawaited(sub.cancel());
    }
  }

  @override
  Future<bool> requestPermissions() async {
    if (await _deviceMusic.hasPermission()) return true;
    return _deviceMusic.requestPermission();
  }

  @override
  Stream<List<LocalFile>> getLocalTracks() async* {
    if (!await requestPermissions()) {
      yield const <LocalFile>[];
      return;
    }

    unawaited(_syncService.sync());
    yield* _store.watchAll().map(
      (tracks) => List<LocalFile>.unmodifiable(tracks.map(_toLocalFile)),
    );
  }

  LocalFile _toLocalFile(LocalTrack track) {
    final durationSeconds = switch (track.duration) {
      final d? when d > 0 => d ~/ 1000,
      _ => 0,
    };
    return LocalFile(
      path: track.dataPath,
      metadata: LocalFileMetadata(
        title: track.title,
        album: switch (track.album) {
          final al? => al,
          null => '',
        },
        artist: switch (track.artist) {
          final ar? => ar,
          null => '',
        },
        duration: durationSeconds,
        imageState: LocalFileImageState.unknown,
      ),
    );
  }
}
