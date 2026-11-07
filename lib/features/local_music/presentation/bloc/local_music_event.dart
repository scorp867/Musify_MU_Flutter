import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class LocalMusicEvent extends Equatable {
  const LocalMusicEvent();

  @override
  List<Object?> get props => const [];
}

final class LoadLocalTracks extends LocalMusicEvent {
  const LoadLocalTracks();
}
