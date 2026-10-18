import 'dart:developer' as dev;
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

abstract interface class DeviceMusicDataSource {
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<List<SongModel>> querySongs();
  Future<Uint8List?> queryArtwork(int songId, {int size});
  Stream<void> get changes;
}

class OnAudioQueryDeviceMusicDataSource implements DeviceMusicDataSource {
  static const _mediaStoreChannel = EventChannel(
    'musify_mu/mediastore_observer',
  );

  final OnAudioQuery _audioQuery;

  OnAudioQueryDeviceMusicDataSource(this._audioQuery);

  @override
  Future<bool> hasPermission() async {
    final audio = await Permission.audio.status;
    if (audio.isGranted || audio.isLimited) return true;
    final storage = await Permission.storage.status;
    return storage.isGranted || storage.isLimited;
  }

  @override
  Future<bool> requestPermission() async {
    try {
      if (await hasPermission()) return true;

      final audioStatus = await Permission.audio.request();
      if (audioStatus.isGranted || audioStatus.isLimited) return true;

      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted || storageStatus.isLimited;
    } catch (e) {
      dev.log('Permission request failed: $e');
      return false;
    }
  }

  @override
  Future<List<SongModel>> querySongs() {
    return _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
  }

  @override
  Future<Uint8List?> queryArtwork(int songId, {int size = 80}) {
    return _audioQuery.queryArtwork(
      songId,
      ArtworkType.AUDIO,
      size: size,
    );
  }

  @override
  Stream<void> get changes =>
      _mediaStoreChannel.receiveBroadcastStream().map<void>((_) {});
}
