import 'package:drift/drift.dart' as drift;
import 'package:musify_mu/features/local_music/data/database/app_database.dart';

class LocalTracksStore {
  final AppDatabase _database;

  LocalTracksStore(this._database);

  Future<List<LocalTrack>> getAll() => _database.getAllTracks();

  Stream<List<LocalTrack>> watchAll() => _database.watchAllTracks();

  Future<void> insertAll(List<LocalTracksCompanion> tracks) {
    return _database.insertTracks(tracks);
  }

  Future<void> replace(LocalTracksCompanion track) {
    return _database.update(_database.localTracks).replace(track);
  }

  Future<void> deleteBySongIds(Set<int> songIds) {
    return (_database.delete(
      _database.localTracks,
    )..where((track) => track.songId.isIn(songIds))).go();
  }

  LocalTracksCompanion companionFor(SongModelData song) {
    return LocalTracksCompanion.insert(
      songId: song.songId,
      title: song.title,
      artist: drift.Value(song.artist),
      album: drift.Value(song.album),
      dataPath: song.dataPath,
      duration: drift.Value(song.duration),
      dateModified: drift.Value(song.dateModified),
    );
  }
}

class SongModelData {
  final int songId;
  final String title;
  final String? artist;
  final String? album;
  final String dataPath;
  final int? duration;
  final int? dateModified;

  const SongModelData({
    required this.songId,
    required this.title,
    required this.artist,
    required this.album,
    required this.dataPath,
    required this.duration,
    required this.dateModified,
  });
}
