import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';

/// 1:1 with Spotify's com.spotify.player.model.ContextTrack
///
/// Contains track URI, unique instance uid, provider ('queue' | 'context' | 'autoplay'),
/// queued flag, and metadata map.
class ContextTrack extends Equatable {
  static const String delimiterMeta = 'spotify:meta:delimiter';
  static const String delimiterStandard = 'spotify:delimiter';

  static const List<String> delimiters = [
    delimiterMeta,
    delimiterStandard,
  ];

  final String uri;
  final String uid; // Session-unique instance identifier
  final String provider; // 'queue' | 'context' | 'autoplay'
  final bool isQueued;
  final Map<String, String> metadata;

  const ContextTrack({
    required this.uri,
    required this.uid,
    this.provider = 'context',
    this.isQueued = false,
    this.metadata = const {},
  });

  bool get isDelimiter => delimiters.contains(uri);

  String get title => metadata['title'] ?? '';
  String get artist => metadata['artist_name'] ?? metadata['artist'] ?? '';
  String get album => metadata['album_title'] ?? metadata['album'] ?? '';
  String? get imageUrl => metadata['image_url'] ?? metadata['artwork'];
  Duration? get duration {
    final msStr = metadata['duration_ms'] ?? metadata['duration'];
    if (msStr == null) return null;
    final ms = int.tryParse(msStr);
    return ms != null ? Duration(milliseconds: ms) : null;
  }

  /// Create ContextTrack from an AudioService MediaItem
  factory ContextTrack.fromMediaItem(MediaItem item, {String? uid, bool? isQueued}) {
    final effectiveUid = uid ?? item.extras?['uid']?.toString() ?? item.id;
    final effectiveIsQueued = isQueued ??
        (item.extras?['is_queued'] == true || item.extras?['is_queued'] == 'true');
    final provider = item.extras?['provider']?.toString() ??
        (effectiveIsQueued ? 'queue' : 'context');

    final meta = <String, String>{
      'title': item.title,
      'artist_name': item.artist ?? '',
      'album_title': item.album ?? '',
      if (item.artUri != null) 'image_url': item.artUri.toString(),
      if (item.duration != null) 'duration_ms': item.duration!.inMilliseconds.toString(),
      'is_queued': effectiveIsQueued.toString(),
    };

    if (item.extras != null) {
      item.extras!.forEach((k, v) {
        if (v != null) meta[k] = v.toString();
      });
    }

    return ContextTrack(
      uri: item.id,
      uid: effectiveUid,
      provider: provider,
      isQueued: effectiveIsQueued,
      metadata: meta,
    );
  }

  static final Expando<MediaItem> _mediaItemCache =
      Expando<MediaItem>('ContextTrackMediaItem');

  /// Convert ContextTrack to AudioService MediaItem (memoized for 120fps list scrolling)
  MediaItem toMediaItem() {
    try {
      final cached = _mediaItemCache[this];
      if (cached != null) return cached;
    } catch (_) {}

    final extras = <String, dynamic>{
      ...metadata,
      'uid': uid,
      'is_queued': isQueued,
      'provider': provider,
    };

    final songIdStr = metadata['songId'];
    if (songIdStr != null) {
      final parsedSongId = int.tryParse(songIdStr);
      if (parsedSongId != null) extras['songId'] = parsedSongId;
    }

    final dateModifiedStr = metadata['dateModified'];
    if (dateModifiedStr != null) {
      final parsedDate = int.tryParse(dateModifiedStr);
      if (parsedDate != null) extras['dateModified'] = parsedDate;
    }

    final artworkVersionStr = metadata['artworkVersion'];
    if (artworkVersionStr != null) {
      final parsedVersion = int.tryParse(artworkVersionStr);
      if (parsedVersion != null) extras['artworkVersion'] = parsedVersion;
    }

    final item = MediaItem(
      id: uri,
      title: title.isNotEmpty ? title : 'Unknown Track',
      artist: artist.isNotEmpty ? artist : 'Unknown Artist',
      album: album,
      artUri: imageUrl != null ? Uri.tryParse(imageUrl!) : null,
      duration: duration,
      extras: extras,
    );

    try {
      _mediaItemCache[this] = item;
    } catch (_) {}

    return item;
  }

  ContextTrack copyWith({
    String? uri,
    String? uid,
    String? provider,
    bool? isQueued,
    Map<String, String>? metadata,
  }) {
    final effectiveIsQueued = isQueued ?? this.isQueued;
    final updatedMeta = metadata != null
        ? Map<String, String>.from(metadata)
        : Map<String, String>.from(this.metadata);
    updatedMeta['is_queued'] = effectiveIsQueued.toString();

    return ContextTrack(
      uri: uri ?? this.uri,
      uid: uid ?? this.uid,
      provider: provider ?? this.provider,
      isQueued: effectiveIsQueued,
      metadata: updatedMeta,
    );
  }

  Map<String, dynamic> toJson() => {
        'uri': uri,
        'uid': uid,
        'provider': provider,
        'is_queued': isQueued,
        'metadata': metadata,
      };

  factory ContextTrack.fromJson(Map<String, dynamic> json) => ContextTrack(
        uri: json['uri'] as String? ?? '',
        uid: json['uid'] as String? ?? '',
        provider: json['provider'] as String? ?? 'context',
        isQueued: json['is_queued'] == true || json['is_queued'] == 'true',
        metadata: (json['metadata'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ??
            const {},
      );

  @override
  List<Object?> get props => [uri, uid, provider, isQueued, metadata];
}
