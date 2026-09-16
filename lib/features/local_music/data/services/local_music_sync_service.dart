import 'package:drift/drift.dart' as drift;
import 'package:on_audio_query/on_audio_query.dart';
import 'package:musify_mu/features/local_music/data/database/app_database.dart';
import 'package:musify_mu/features/local_music/data/datasources/device_music_data_source.dart';
import 'package:musify_mu/features/local_music/data/datasources/local_tracks_store.dart';

class LocalMusicSyncService {
  final DeviceMusicDataSource _deviceMusic;
  final LocalTracksStore _store;

  LocalMusicSyncService({
    required DeviceMusicDataSource deviceMusic,
    required LocalTracksStore store,
  }) : _deviceMusic = deviceMusic,
       _store = store;

  Future<void> sync() async {
    final cachedTracks = await _store.getAll();
    final deviceTracks = await _deviceMusic.querySongs();

    final cachedBySongId = {
      for (final track in cachedTracks) track.songId: track,
    };
    final deviceBySongId = {for (final track in deviceTracks) track.id: track};
    final removedSongIds = cachedBySongId.keys.toSet().difference(
      deviceBySongId.keys.toSet(),
    );

    final tracksToInsert = <LocalTracksCompanion>[];
    final tracksToUpdate = <LocalTracksCompanion>[];

    for (final deviceTrack in deviceTracks) {
      final cachedTrack = cachedBySongId[deviceTrack.id];
      final companion = _store.companionFor(_toData(deviceTrack));

      if (cachedTrack == null) {
        tracksToInsert.add(companion);
      } else if (_hasMetadataChanged(cachedTrack, deviceTrack)) {
        tracksToUpdate.add(companion.copyWith(id: drift.Value(cachedTrack.id)));
      }
    }

    if (removedSongIds.isNotEmpty) {
      await _store.deleteBySongIds(removedSongIds);
    }
    if (tracksToInsert.isNotEmpty) {
      await _store.insertAll(tracksToInsert);
    }
    for (final track in tracksToUpdate) {
      await _store.replace(track);
    }
  }

  bool _hasMetadataChanged(LocalTrack cachedTrack, SongModel deviceTrack) {
    return cachedTrack.title != deviceTrack.title ||
        cachedTrack.artist != deviceTrack.artist ||
        cachedTrack.album != deviceTrack.album ||
        cachedTrack.dataPath != deviceTrack.data ||
        cachedTrack.duration != deviceTrack.duration ||
        cachedTrack.dateModified != deviceTrack.dateModified;
  }

  SongModelData _toData(SongModel song) {
    return SongModelData(
      songId: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      dataPath: song.data,
      duration: song.duration,
      dateModified: song.dateModified,
    );
  }
}
