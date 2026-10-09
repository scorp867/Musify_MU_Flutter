import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';
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

/// Screen left or inactive — cancel in-flight network requests.
class HomeFeedCancelRequested extends HomeFeedEvent {
  const HomeFeedCancelRequested();
}

/// Screen became active / resumed — revalidate if data is stale.
class HomeFeedActivated extends HomeFeedEvent {
  const HomeFeedActivated();
}

// ═══════════════════════════════════════════════════════════════════
// States
// ═══════════════════════════════════════════════════════════════════

sealed class HomeFeedState extends Equatable {
  const HomeFeedState();

  @override
  List<Object?> get props => [];
}

/// First load, no data available yet.
class HomeFeedLoading extends HomeFeedState {
  final HomeFacet activeFacet;
  const HomeFeedLoading({this.activeFacet = HomeFacet.all});

  @override
  List<Object?> get props => [activeFacet];
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

  @override
  List<Object?> get props => [data, isRefreshing, activeFacet];
}

/// Error with optional stale data to still show.
class HomeFeedError extends HomeFeedState {
  final String message;
  final HomeViewData? staleData;

  const HomeFeedError(this.message, {this.staleData});

  @override
  List<Object?> get props => [message, staleData];
}

// ═══════════════════════════════════════════════════════════════════
// BLoC
// ═══════════════════════════════════════════════════════════════════

class HomeFeedBloc extends Bloc<HomeFeedEvent, HomeFeedState> {
  final LoadHomeFeed _loadHomeFeed;
  final NetworkMonitorService? _networkMonitor;
  StreamSubscription<NetworkStatus>? _networkSubscription;
  CancelToken? _cancelToken;
  bool _isLoading = false;
  bool _isActive = true;
  bool _needsRevalidation = false;
  HomeFacet _activeFacet = HomeFacet.all;

  HomeFeedBloc({
    required LoadHomeFeed loadHomeFeed,
    NetworkMonitorService? networkMonitor,
  })  : _loadHomeFeed = loadHomeFeed,
        _networkMonitor = networkMonitor,
        super(const HomeFeedLoading()) {
    on<HomeFeedLoadRequested>(_onLoad);
    on<HomeFeedRefreshRequested>(_onRefresh);
    on<HomeFeedFacetChanged>(_onFacetChanged);
    on<HomeFeedCancelRequested>(_onCancel);
    on<HomeFeedActivated>(_onActivated);

    _networkSubscription = _networkMonitor?.statusStream.listen((status) {
      if (status == NetworkStatus.restored ||
          (status == NetworkStatus.online && _needsRevalidation)) {
        if (_isActive) {
          add(const HomeFeedRefreshRequested());
        } else {
          _needsRevalidation = true;
        }
      }
    });
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel('HomeFeedBloc closed');
    _networkSubscription?.cancel();
    return super.close();
  }

  void _onActivated(
    HomeFeedActivated event,
    Emitter<HomeFeedState> emit,
  ) {
    _isActive = true;
    if (_needsRevalidation &&
        _networkMonitor?.currentStatus != NetworkStatus.offline) {
      add(const HomeFeedRefreshRequested());
    }
  }

  void _onCancel(
    HomeFeedCancelRequested event,
    Emitter<HomeFeedState> emit,
  ) {
    _isActive = false;
    _cancelToken?.cancel('User left home screen');
    _cancelToken = null;
    _isLoading = false;
    if (state is HomeFeedLoaded) {
      final current = state as HomeFeedLoaded;
      if (current.isRefreshing) {
        emit(HomeFeedLoaded(
          current.data,
          isRefreshing: false,
          activeFacet: current.activeFacet,
        ));
      }
    }
  }

  Future<void> _onLoad(
    HomeFeedLoadRequested event,
    Emitter<HomeFeedState> emit,
  ) async {
    _isActive = true;
    if (_isLoading) return;
    _isLoading = true;

    _cancelToken?.cancel('Superseded by new load request');
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    if (state is! HomeFeedLoading) {
      emit(HomeFeedLoading(activeFacet: _activeFacet));
    }

    HomeViewData? loadedData;
    bool hasData = false;
    bool receivedFresh = false;

    try {
      await emit.forEach<HomeViewData>(
        _loadHomeFeed(facet: _activeFacet, cancelToken: cancelToken),
        onData: (data) {
          hasData = true;
          if (loadedData != null) {
            receivedFresh = true;
          }
          loadedData = data;
          return HomeFeedLoaded(data, activeFacet: _activeFacet);
        },
        onError: (error, _) {
          return HomeFeedError(
            'Failed to load home feed',
            staleData: loadedData,
          );
        },
      );
    } catch (_) {
      // Cancellation or stream exception
    }

    _isLoading = false;
    if (cancelToken.isCancelled) return;

    _needsRevalidation = !receivedFresh;

    if (!hasData) {
      emit(const HomeFeedError("You're offline. Please check your connection."));
    }
  }

  Future<void> _onRefresh(
    HomeFeedRefreshRequested event,
    Emitter<HomeFeedState> emit,
  ) async {
    _isActive = true;
    _cancelToken?.cancel('Superseded by refresh request');
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    final currentData = switch (state) {
      HomeFeedLoaded(:final data) => data,
      HomeFeedError(:final staleData) => staleData,
      _ => null,
    };

    if (currentData != null) {
      emit(HomeFeedLoaded(currentData, isRefreshing: true, activeFacet: _activeFacet));
    }

    try {
      final fresh = await _loadHomeFeed.refresh(facet: _activeFacet, cancelToken: cancelToken);
      if (cancelToken.isCancelled) {
        if (currentData != null) {
          emit(HomeFeedLoaded(
            currentData,
            isRefreshing: false,
            activeFacet: _activeFacet,
          ));
        }
        return;
      }

      if (fresh != null) {
        _needsRevalidation = false;
        emit(HomeFeedLoaded(fresh, activeFacet: _activeFacet));
      } else if (currentData != null) {
        _needsRevalidation = true;
        emit(HomeFeedLoaded(
          currentData,
          isRefreshing: false,
          activeFacet: _activeFacet,
        ));
        emit(HomeFeedError(
          "You're offline. Content will update when connected.",
          staleData: currentData,
        ));
      } else {
        _needsRevalidation = true;
        emit(const HomeFeedError('Could not load home feed. Tap to retry.'));
      }
    } catch (e) {
      if (cancelToken.isCancelled) {
        if (currentData != null) {
          emit(HomeFeedLoaded(
            currentData,
            isRefreshing: false,
            activeFacet: _activeFacet,
          ));
        }
        return;
      }
      _needsRevalidation = true;
      if (currentData != null) {
        emit(HomeFeedLoaded(
          currentData,
          isRefreshing: false,
          activeFacet: _activeFacet,
        ));
        emit(HomeFeedError(
          "You're offline. Content will update when connected.",
          staleData: currentData,
        ));
      } else {
        emit(HomeFeedError(e.toString()));
      }
    }
  }

  /// Optimistic SWR: show cached facet instantly, then refresh in background.
  Future<void> _onFacetChanged(
    HomeFeedFacetChanged event,
    Emitter<HomeFeedState> emit,
  ) async {
    if (event.facet == _activeFacet) return;
    _activeFacet = event.facet;

    _cancelToken?.cancel('Facet changed');
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    emit(HomeFeedLoading(activeFacet: _activeFacet));

    HomeViewData? loadedData;
    bool hasData = false;

    try {
      await emit.forEach<HomeViewData>(
        _loadHomeFeed(facet: _activeFacet, cancelToken: cancelToken),
        onData: (data) {
          hasData = true;
          loadedData = data;
          return HomeFeedLoaded(data, activeFacet: _activeFacet);
        },
        onError: (error, _) => HomeFeedError(
          'Failed to load home feed',
          staleData: loadedData,
        ),
      );
    } catch (_) {
      // Cancellation or stream exception
    }

    if (cancelToken.isCancelled) return;

    if (!hasData) {
      emit(const HomeFeedError("You're offline. Please check your connection."));
    }
  }
}
