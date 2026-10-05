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

/// User tapped a facet chip (All / Music / Podcasts & Shows).
class HomeFeedFacetChanged extends HomeFeedEvent {
  final HomeFacet facet;
  const HomeFeedFacetChanged(this.facet);
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
  final HomeFacet activeFacet;

  const HomeFeedLoaded(
    this.data, {
    this.isRefreshing = false,
    this.activeFacet = HomeFacet.all,
  });
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
  HomeFacet _activeFacet = HomeFacet.all;

  HomeFeedBloc({required LoadHomeFeed loadHomeFeed})
      : _loadHomeFeed = loadHomeFeed,
        super(const HomeFeedLoading()) {
    on<HomeFeedLoadRequested>(_onLoad);
    on<HomeFeedRefreshRequested>(_onRefresh);
    on<HomeFeedFacetChanged>(_onFacetChanged);
  }

  Future<void> _onLoad(
    HomeFeedLoadRequested event,
    Emitter<HomeFeedState> emit,
  ) async {
    if (_isLoading) return;
    _isLoading = true;
    emit(const HomeFeedLoading());

    await emit.forEach(
      _loadHomeFeed(facet: _activeFacet),
      onData: (data) => HomeFeedLoaded(data, activeFacet: _activeFacet),
      onError: (error, _) => HomeFeedError(error.toString()),
    );
    _isLoading = false;
  }

  Future<void> _onRefresh(
    HomeFeedRefreshRequested event,
    Emitter<HomeFeedState> emit,
  ) async {
    final currentData = switch (state) {
      HomeFeedLoaded(:final data) => data,
      HomeFeedError(:final staleData) => staleData,
      _ => null,
    };

    if (currentData != null) {
      emit(HomeFeedLoaded(currentData, isRefreshing: true, activeFacet: _activeFacet));
    }

    final fresh = await _loadHomeFeed.refresh(facet: _activeFacet);
    if (fresh != null) {
      emit(HomeFeedLoaded(fresh, activeFacet: _activeFacet));
    } else if (currentData != null) {
      emit(HomeFeedLoaded(currentData, activeFacet: _activeFacet));
    } else {
      emit(const HomeFeedError('Failed to load home feed'));
    }
  }

  /// Optimistic SWR: show cached facet instantly, then refresh in background.
  Future<void> _onFacetChanged(
    HomeFeedFacetChanged event,
    Emitter<HomeFeedState> emit,
  ) async {
    if (event.facet == _activeFacet) return;
    _activeFacet = event.facet;

    // Try to show cached data for this facet immediately
    final currentData = switch (state) {
      HomeFeedLoaded(:final data) => data,
      HomeFeedError(:final staleData) => staleData,
      _ => null,
    };

    // Emit refreshing state with current data while we fetch
    if (currentData != null) {
      emit(HomeFeedLoaded(currentData, isRefreshing: true, activeFacet: _activeFacet));
    } else {
      emit(const HomeFeedLoading());
    }

    // SWR: stream cached then fresh for the new facet
    await emit.forEach(
      _loadHomeFeed(facet: _activeFacet),
      onData: (data) => HomeFeedLoaded(data, activeFacet: _activeFacet),
      onError: (error, _) {
        if (currentData != null) {
          return HomeFeedLoaded(currentData, activeFacet: _activeFacet);
        }
        return HomeFeedError(error.toString());
      },
    );
  }
}
