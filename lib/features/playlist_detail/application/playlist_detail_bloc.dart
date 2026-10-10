import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musify_mu/core/color/artwork_color_scheme.dart';
import 'package:musify_mu/core/color/color_extraction_service.dart';
import 'package:musify_mu/core/color/eased_gradient.dart';
import 'package:musify_mu/features/library/domain/models/library_item.dart';

// ─── Events ──────────────────────────────────────────────────────────

sealed class PlaylistDetailEvent {
  const PlaylistDetailEvent();
}

/// Load playlist detail and extract color from artwork.
final class PlaylistDetailLoadRequested extends PlaylistDetailEvent {
  final LibraryItem item;
  const PlaylistDetailLoadRequested(this.item);
}

/// Re-extract color when artwork changes (e.g. after library refresh).
final class PlaylistDetailArtworkChanged extends PlaylistDetailEvent {
  final LibraryItem updatedItem;
  const PlaylistDetailArtworkChanged(this.updatedItem);
}

// ─── States ──────────────────────────────────────────────────────────

sealed class PlaylistDetailState extends Equatable {
  const PlaylistDetailState();

  @override
  List<Object?> get props => [];
}

final class PlaylistDetailLoading extends PlaylistDetailState {
  const PlaylistDetailLoading();
}

final class PlaylistDetailLoaded extends PlaylistDetailState {
  final LibraryItem item;
  final Gradient gradient;
  final ArtworkColorScheme colorScheme;
  final bool isExtracting;

  const PlaylistDetailLoaded({
    required this.item,
    required this.gradient,
    required this.colorScheme,
    this.isExtracting = false,
  });

  @override
  List<Object?> get props => [item, colorScheme, isExtracting];
}

final class PlaylistDetailError extends PlaylistDetailState {
  final String message;
  const PlaylistDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── BLoC ────────────────────────────────────────────────────────────

class PlaylistDetailBloc
    extends Bloc<PlaylistDetailEvent, PlaylistDetailState> {
  final ColorExtractionService _colorService;

  /// Tracks the current artwork key to detect changes reactively.
  String? _currentArtworkKey;

  PlaylistDetailBloc({
    required ColorExtractionService colorService,
  })  : _colorService = colorService,
        super(const PlaylistDetailLoading()) {
    on<PlaylistDetailLoadRequested>(_onLoad);
    on<PlaylistDetailArtworkChanged>(_onArtworkChanged);
  }

  Future<void> _onLoad(
    PlaylistDetailLoadRequested event,
    Emitter<PlaylistDetailState> emit,
  ) async {
    final item = event.item;
    final artworkKey = _resolveArtworkKey(item);

    if (artworkKey == null) {
      emit(PlaylistDetailLoaded(
        item: item,
        gradient: EasedGradient.build(
          topColor: ArtworkColorScheme.neutral.primary,
        ),
        colorScheme: ArtworkColorScheme.neutral,
      ));
      return;
    }

    _currentArtworkKey = artworkKey;

    // Emit immediately with placeholder gradient while extracting
    emit(PlaylistDetailLoaded(
      item: item,
      gradient: EasedGradient.build(
        topColor: ArtworkColorScheme.neutral.primary,
      ),
      colorScheme: ArtworkColorScheme.neutral,
      isExtracting: true,
    ));

    // Extract color (supports full 2x2 mosaic compositing or single image)
    final scheme = await _colorService.extract(
      imageUrl: item.imageUrl,
      mosaicUrls: item.mosaicImageUrls,
    );

    emit(PlaylistDetailLoaded(
      item: item,
      gradient: EasedGradient.build(topColor: scheme.primary),
      colorScheme: scheme,
    ));
  }

  Future<void> _onArtworkChanged(
    PlaylistDetailArtworkChanged event,
    Emitter<PlaylistDetailState> emit,
  ) async {
    final item = event.updatedItem;
    final artworkKey = _resolveArtworkKey(item);

    // Only re-extract if artwork key actually changed
    if (artworkKey == _currentArtworkKey) {
      if (state is PlaylistDetailLoaded) {
        final current = state as PlaylistDetailLoaded;
        emit(PlaylistDetailLoaded(
          item: item,
          gradient: current.gradient,
          colorScheme: current.colorScheme,
        ));
      }
      return;
    }

    _currentArtworkKey = artworkKey;

    if (artworkKey == null) {
      emit(PlaylistDetailLoaded(
        item: item,
        gradient: EasedGradient.build(
          topColor: ArtworkColorScheme.neutral.primary,
        ),
        colorScheme: ArtworkColorScheme.neutral,
      ));
      return;
    }

    if (state is PlaylistDetailLoaded) {
      final current = state as PlaylistDetailLoaded;
      emit(PlaylistDetailLoaded(
        item: item,
        gradient: current.gradient,
        colorScheme: current.colorScheme,
        isExtracting: true,
      ));
    }

    final scheme = await _colorService.extract(
      imageUrl: item.imageUrl,
      mosaicUrls: item.mosaicImageUrls,
    );

    emit(PlaylistDetailLoaded(
      item: item,
      gradient: EasedGradient.build(topColor: scheme.primary),
      colorScheme: scheme,
    ));
  }

  /// Unique key identifying the artwork state.
  /// For mosaics: combines the first 4 track URLs.
  /// For custom covers: returns the cover URL.
  String? _resolveArtworkKey(LibraryItem item) {
    if (item.mosaicImageUrls.length >= 4) {
      return 'mosaic:${item.mosaicImageUrls.take(4).join('|')}';
    }
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return item.imageUrl;
    }
    return null;
  }
}
