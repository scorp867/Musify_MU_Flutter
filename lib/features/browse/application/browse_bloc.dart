import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';
import 'package:musify_mu/features/browse/domain/usecases/load_browse.dart';

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

/// Screen left or inactive — cancel in-flight network requests.
class BrowseCancelRequested extends BrowseEvent {
  const BrowseCancelRequested();
}

/// Screen became active / resumed — revalidate if data is stale.
class BrowseActivated extends BrowseEvent {
  const BrowseActivated();
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
  final LoadBrowse _loadBrowse;
  final NetworkMonitorService? _networkMonitor;
  StreamSubscription<NetworkStatus>? _networkSubscription;
  CancelToken? _cancelToken;
  bool _isActive = true;
  bool _needsRevalidation = false;

  BrowseBloc({
    required LoadBrowse loadBrowse,
    NetworkMonitorService? networkMonitor,
  })  : _loadBrowse = loadBrowse,
        _networkMonitor = networkMonitor,
        super(const BrowseLoading()) {
    on<BrowseLoadRequested>(_onLoad);
    on<BrowseRefreshRequested>(_onRefresh);
    on<BrowseCancelRequested>(_onCancel);
    on<BrowseActivated>(_onActivated);

    _networkSubscription = _networkMonitor?.statusStream.listen((status) {
      if (status == NetworkStatus.restored ||
          (status == NetworkStatus.online && _needsRevalidation)) {
        if (_isActive) {
          add(const BrowseRefreshRequested());
        } else {
          _needsRevalidation = true;
        }
      }
    });
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel('BrowseBloc closed');
    _networkSubscription?.cancel();
    return super.close();
  }

  void _onActivated(
    BrowseActivated event,
    Emitter<BrowseState> emit,
  ) {
    _isActive = true;
    if (_needsRevalidation &&
        _networkMonitor?.currentStatus != NetworkStatus.offline) {
      add(const BrowseRefreshRequested());
    }
  }

  void _onCancel(
    BrowseCancelRequested event,
    Emitter<BrowseState> emit,
  ) {
    _isActive = false;
    _cancelToken?.cancel('User left browse screen');
    _cancelToken = null;
    if (state is BrowseLoaded) {
      final current = state as BrowseLoaded;
      if (current.isRefreshing) {
        emit(BrowseLoaded(current.data, isRefreshing: false));
      }
    }
  }

  Future<void> _onLoad(
    BrowseLoadRequested event,
    Emitter<BrowseState> emit,
  ) async {
    _isActive = true;
    _cancelToken?.cancel('Superseded by new load request');
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    // 1. SWR: Load from local cache immediately
    final cached = await _loadBrowse.loadCached();
    if (cancelToken.isCancelled) return;

    if (cached != null) {
      emit(BrowseLoaded(cached));
    } else if (state is! BrowseLoading) {
      emit(const BrowseLoading());
    }

    // 2. Dispatch network fetch (fail-fast read directly against socket)
    try {
      final data = await _loadBrowse(cancelToken: cancelToken);
      if (cancelToken.isCancelled) return;

      if (data != null) {
        _needsRevalidation = false;
        emit(BrowseLoaded(data));
      } else {
        _needsRevalidation = true;
        if (cached == null) {
          emit(const BrowseError("You're offline. Please check your connection."));
        }
      }
    } catch (e) {
      if (cancelToken.isCancelled) return;
      _needsRevalidation = true;
      if (cached == null) {
        emit(const BrowseError("You're offline. Please check your connection."));
      }
    }
  }

  Future<void> _onRefresh(
    BrowseRefreshRequested event,
    Emitter<BrowseState> emit,
  ) async {
    _isActive = true;
    _cancelToken?.cancel('Superseded by refresh request');
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    final currentData = switch (state) {
      BrowseLoaded(:final data) => data,
      BrowseError(:final staleData) => staleData,
      _ => null,
    };

    if (currentData != null) {
      emit(BrowseLoaded(currentData, isRefreshing: true));
    }

    try {
      final fresh = await _loadBrowse(cancelToken: cancelToken);
      if (cancelToken.isCancelled) {
        if (currentData != null) {
          emit(BrowseLoaded(currentData, isRefreshing: false));
        }
        return;
      }

      if (fresh != null) {
        _needsRevalidation = false;
        emit(BrowseLoaded(fresh));
      } else if (currentData != null) {
        _needsRevalidation = true;
        emit(BrowseLoaded(currentData, isRefreshing: false));
        emit(BrowseError(
          "You're offline. Content will update when connected.",
          staleData: currentData,
        ));
      } else {
        _needsRevalidation = true;
        emit(const BrowseError('Could not refresh categories. Tap to retry.'));
      }
    } catch (e) {
      if (cancelToken.isCancelled) {
        if (currentData != null) {
          emit(BrowseLoaded(currentData, isRefreshing: false));
        }
        return;
      }
      _needsRevalidation = true;
      if (currentData != null) {
        emit(BrowseLoaded(currentData, isRefreshing: false));
        emit(BrowseError(
          "You're offline. Content will update when connected.",
          staleData: currentData,
        ));
      } else {
        emit(BrowseError(e.toString()));
      }
    }
  }
}
