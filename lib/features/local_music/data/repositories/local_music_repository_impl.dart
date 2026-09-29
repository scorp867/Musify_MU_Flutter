import 'dart:async';

import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/local_music/data/datasources/device_music_data_source.dart';
import 'package:musify_mu/features/local_music/data/datasources/local_tracks_store.dart';
import 'package:musify_mu/features/local_music/data/services/local_music_sync_service.dart';
import 'package:musify_mu/features/local_music/domain/entities/domain_track.dart';
import 'package:musify_mu/features/local_music/domain/repositories/local_music_repository.dart';

class LocalMusicRepositoryImpl implements LocalMusicRepository {
  final DeviceMusicDataSource _deviceMusic;
  final LocalTracksStore _store;
  final LocalMusicSyncService _syncService;
  late final StreamSubscription _changesSub;

  LocalMusicRepositoryImpl({
    required DeviceMusicDataSource deviceMusic,
    required LocalTracksStore store,
    required LocalMusicSyncService syncService,
  }) : _deviceMusic = deviceMusic,
       _store = store,
       _syncService = syncService {
    _changesSub = _deviceMusic.changes.listen((_) => unawaited(_syncService.sync()));
  }

  void dispose() {
    _changesSub.cancel();
  }

  @override
  Future<bool> requestPermissions() async {
    if (await _deviceMusic.hasPermission()) return true;
    return _deviceMusic.requestPermission();
  }

  @override
  Stream<List<DomainTrack>> getLocalTracks() async* {
    if (!await requestPermissions()) {
      yield const [];
      return;
    }

    unawaited(_syncService.sync());
    yield* _store.watchAll().map(
      (tracks) => tracks.map(_toDomainTrack).toList(growable: false),
    );
  }

  DomainTrack _toDomainTrack(LocalTrack track) {
    return DomainTrack(
      id: track.id.toString(),
      title: track.title,
      artist: track.artist ?? 'Unknown Artist',
      album: track.album,
      duration: track.duration,
      dataPath: track.dataPath,
      songId: track.songId,
      dateModified: track.dateModified == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(track.dateModified! * 1000),
      isLocal: true,
    );
  }
}
