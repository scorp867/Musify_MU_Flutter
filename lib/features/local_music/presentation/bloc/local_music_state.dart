import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:musify_mu/features/local_music/domain/models/local_file.dart';

@immutable
sealed class LocalMusicState extends Equatable {
  const LocalMusicState();

  @override
  List<Object?> get props => const [];
}

final class LocalMusicInitial extends LocalMusicState {
  const LocalMusicInitial();
}

final class LocalMusicLoading extends LocalMusicState {
  const LocalMusicLoading();
}

final class LocalMusicLoaded extends LocalMusicState {
  final List<LocalFile> tracks;

  LocalMusicLoaded(List<LocalFile> tracks)
      : tracks = UnmodifiableListView<LocalFile>(tracks);

  @override
  List<Object?> get props => [tracks];
}

final class LocalMusicError extends LocalMusicState {
  final String message;

  const LocalMusicError(this.message);

  @override
  List<Object?> get props => [message];
}
