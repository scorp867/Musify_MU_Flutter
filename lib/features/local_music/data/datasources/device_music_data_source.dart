import 'dart:developer' as dev;
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';

abstract interface class DeviceMusicDataSource {
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<List<SongModel>> querySongs();
  Stream<void> get changes;
}

class OnAudioQueryDeviceMusicDataSource implements DeviceMusicDataSource {
  static const _mediaStoreChannel = EventChannel(
    'musify_mu/mediastore_observer',
  );

  final OnAudioQuery _audioQuery;

  OnAudioQueryDeviceMusicDataSource(this._audioQuery);

  @override
  Future<bool> hasPermission() => _audioQuery.permissionsStatus();

  @override
  Future<bool> requestPermission() async {
    try {
      return await _audioQuery.permissionsRequest();
    } catch (e) {
      // on_audio_query PluginProvider may not be initialized yet.
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
  Stream<void> get changes =>
      _mediaStoreChannel.receiveBroadcastStream().map<void>((_) {});
}
