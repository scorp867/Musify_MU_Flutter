import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/home_feed/domain/usecases/load_home_feed.dart';

// ═══════════════════════════════════════════════════════════════════
// Events
// ═══════════════════════════════════════════════════════════════════

sealed class HomeFeedEvent {
  const HomeFeedEvent();
}

/// Initial load — triggers SWR (cache then network).
class HomeFeedLoadRequested extends HomeFeedEvent {
  const HomeFeedLoadRequested();
}

/// Manual pull-to-refresh — network only, no cache.
class HomeFeedRefreshRequested extends HomeFeedEvent {
  const HomeFeedRefreshRequested();
}

// ═══════════════════════════════════════════════════════════════════
// States
// ═══════════════════════════════════════════════════════════════════

sealed class HomeFeedState {
  const HomeFeedState();
}

/// First load, no data available yet.
class HomeFeedLoading extends HomeFeedState {
  const HomeFeedLoading();
}

/// Data available — either from cache or network.
class HomeFeedLoaded extends HomeFeedState {
  final HomeViewData data;
  final bool isRefreshing;

  const HomeFeedLoaded(this.data, {this.isRefreshing = false});
}

/// Error with optional stale data to still show.
class HomeFeedError extends HomeFeedState {
  final String message;
  final HomeViewData? staleData;

  const HomeFeedError(this.message, {this.staleData});
}

// ═══════════════════════════════════════════════════════════════════
// BLoC
// ═══════════════════════════════════════════════════════════════════

class HomeFeedBloc extends Bloc<HomeFeedEvent, HomeFeedState> {
  final LoadHomeFeed _loadHomeFeed;
  bool _isLoading = false;

  HomeFeedBloc({required LoadHomeFeed loadHomeFeed})
      : _loadHomeFeed = loadHomeFeed,
        super(const HomeFeedLoading()) {
    on<HomeFeedLoadRequested>(_onLoad);
    on<HomeFeedRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    HomeFeedLoadRequested event,
    Emitter<HomeFeedState> emit,
  ) async {
    if (_isLoading) return;
    _isLoading = true;
    emit(const HomeFeedLoading());

    await emit.forEach(
      _loadHomeFeed(),
      onData: (data) => HomeFeedLoaded(data),
      onError: (error, _) => HomeFeedError(error.toString()),
    );
    _isLoading = false;
  }

  Future<void> _onRefresh(
    HomeFeedRefreshRequested event,
    Emitter<HomeFeedState> emit,
  ) async {
    // If we already have data, show it with a refreshing indicator.
    final currentData = switch (state) {
      HomeFeedLoaded(:final data) => data,
      HomeFeedError(:final staleData) => staleData,
      _ => null,
    };

    if (currentData != null) {
      emit(HomeFeedLoaded(currentData, isRefreshing: true));
    }

    final fresh = await _loadHomeFeed.refresh();
    if (fresh != null) {
      emit(HomeFeedLoaded(fresh));
    } else if (currentData != null) {
      emit(HomeFeedLoaded(currentData));
    } else {
      emit(const HomeFeedError('Failed to load home feed'));
    }
  }
}
