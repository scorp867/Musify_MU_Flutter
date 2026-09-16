import 'package:musify_mu/features/local_music/domain/entities/domain_track.dart';

abstract interface class LocalMusicRepository {
  Stream<List<DomainTrack>> getLocalTracks();
  Future<bool> requestPermissions();
}
