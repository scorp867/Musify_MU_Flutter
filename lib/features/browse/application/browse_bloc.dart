import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/browse/data/browse_repository.dart';
import 'package:musify_mu/features/browse/domain/models/browse_view_data.dart';

// ═══════════════════════════════════════════════════════════════════
// Events
// ═══════════════════════════════════════════════════════════════════

sealed class BrowseEvent extends Equatable {
  const BrowseEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load.
class BrowseLoadRequested extends BrowseEvent {
  const BrowseLoadRequested();
}

/// Pull-to-refresh.
class BrowseRefreshRequested extends BrowseEvent {
  const BrowseRefreshRequested();
}

// ═══════════════════════════════════════════════════════════════════
// States
// ═══════════════════════════════════════════════════════════════════

sealed class BrowseState extends Equatable {
  const BrowseState();

  @override
  List<Object?> get props => [];
}

class BrowseLoading extends BrowseState {
  const BrowseLoading();
}

class BrowseLoaded extends BrowseState {
  final BrowseViewData data;
  final bool isRefreshing;

  const BrowseLoaded(this.data, {this.isRefreshing = false});

  @override
  List<Object?> get props => [data, isRefreshing];
}

class BrowseError extends BrowseState {
  final String message;
  final BrowseViewData? staleData;

  const BrowseError(this.message, {this.staleData});

  @override
  List<Object?> get props => [message, staleData];
}

// ═══════════════════════════════════════════════════════════════════
// BLoC
// ═══════════════════════════════════════════════════════════════════

class BrowseBloc extends Bloc<BrowseEvent, BrowseState> {
  final BrowseRepository _repository;

  BrowseBloc({required BrowseRepository repository})
      : _repository = repository,
        super(const BrowseLoading()) {
    on<BrowseLoadRequested>(_onLoad);
    on<BrowseRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    BrowseLoadRequested event,
    Emitter<BrowseState> emit,
  ) async {
    emit(const BrowseLoading());

    try {
      final data = await _repository.fetchBrowse();
      if (data != null) {
        emit(BrowseLoaded(data));
      } else {
        emit(const BrowseError('Failed to load browse'));
      }
    } catch (e) {
      emit(BrowseError(e.toString()));
    }
  }

  Future<void> _onRefresh(
    BrowseRefreshRequested event,
    Emitter<BrowseState> emit,
  ) async {
    final currentData = switch (state) {
      BrowseLoaded(:final data) => data,
      BrowseError(:final staleData) => staleData,
      _ => null,
    };

    if (currentData != null) {
      emit(BrowseLoaded(currentData, isRefreshing: true));
    }

    try {
      final fresh = await _repository.fetchBrowse();
      if (fresh != null) {
        emit(BrowseLoaded(fresh));
      } else if (currentData != null) {
        emit(BrowseLoaded(currentData));
      } else {
        emit(const BrowseError('Failed to refresh browse'));
      }
    } catch (e) {
      if (currentData != null) {
        emit(BrowseLoaded(currentData));
      } else {
        emit(BrowseError(e.toString()));
      }
    }
  }
}
