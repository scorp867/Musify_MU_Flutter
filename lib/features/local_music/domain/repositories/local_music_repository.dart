import 'package:musify_mu/features/local_music/domain/models/local_file.dart';

abstract interface class LocalMusicRepository {
  Stream<List<LocalFile>> getLocalTracks();
  Future<bool> requestPermissions();
}
