import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';
import 'package:musify_mu/features/library/domain/usecases/load_library.dart';

// ─── Events ──────────────────────────────────────────────────────────

sealed class LibraryEvent {
  const LibraryEvent();
}

final class LibraryLoadRequested extends LibraryEvent {
  const LibraryLoadRequested();
}

final class LibraryRefreshRequested extends LibraryEvent {
  const LibraryRefreshRequested();
}

/// Screen left or inactive — cancel in-flight network requests.
final class LibraryCancelRequested extends LibraryEvent {
  const LibraryCancelRequested();
}

/// Screen became active / resumed — revalidate if data is stale.
final class LibraryActivated extends LibraryEvent {
  const LibraryActivated();
}

// ─── States ──────────────────────────────────────────────────────────

sealed class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object?> get props => [];
}

final class LibraryLoading extends LibraryState {
  const LibraryLoading();
}

final class LibraryLoaded extends LibraryState {
  final LibraryViewData data;
  final bool isRefreshing;

  const LibraryLoaded({required this.data, this.isRefreshing = false});

  @override
  List<Object?> get props => [data, isRefreshing];
}

final class LibraryError extends LibraryState {
  final String message;
  final LibraryViewData? staleData;

  const LibraryError({required this.message, this.staleData});

  @override
  List<Object?> get props => [message, staleData];
}

// ─── BLoC ────────────────────────────────────────────────────────────

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final LoadLibrary _loadLibrary;
  final NetworkMonitorService? _networkMonitor;
  StreamSubscription<NetworkStatus>? _networkSubscription;
  CancelToken? _cancelToken;
  bool _isActive = true;
  bool _needsRevalidation = false;

  LibraryBloc({
    required LoadLibrary loadLibrary,
    NetworkMonitorService? networkMonitor,
  })  : _loadLibrary = loadLibrary,
        _networkMonitor = networkMonitor,
        super(const LibraryLoading()) {
    on<LibraryLoadRequested>(_onLoad);
    on<LibraryRefreshRequested>(_onRefresh);
    on<LibraryCancelRequested>(_onCancel);
    on<LibraryActivated>(_onActivated);

    _networkSubscription = _networkMonitor?.statusStream.listen((status) {
      if (status == NetworkStatus.restored ||
          (status == NetworkStatus.online && _needsRevalidation)) {
        if (_isActive) {
          add(const LibraryRefreshRequested());
        } else {
          _needsRevalidation = true;
        }
      }
    });
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel('LibraryBloc closed');
    _networkSubscription?.cancel();
    return super.close();
  }

  void _onActivated(
    LibraryActivated event,
    Emitter<LibraryState> emit,
  ) {
    _isActive = true;
    if (_needsRevalidation &&
        _networkMonitor?.currentStatus != NetworkStatus.offline) {
      add(const LibraryRefreshRequested());
    }
  }

  void _onCancel(
    LibraryCancelRequested event,
    Emitter<LibraryState> emit,
  ) {
    _isActive = false;
    _cancelToken?.cancel('User left library screen');
    _cancelToken = null;
    if (state is LibraryLoaded) {
      final current = state as LibraryLoaded;
      if (current.isRefreshing) {
        emit(LibraryLoaded(data: current.data, isRefreshing: false));
      }
    }
  }

  Future<void> _onLoad(
    LibraryLoadRequested event,
    Emitter<LibraryState> emit,
  ) async {
    _isActive = true;
    _cancelToken?.cancel('Superseded by new load request');
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    if (state is! LibraryLoading) {
      emit(const LibraryLoading());
    }

    LibraryViewData? loadedData;
    bool hasData = false;
    bool receivedFresh = false;

    try {
      await emit.forEach<LibraryViewData>(
        _loadLibrary(cancelToken: cancelToken),
        onData: (data) {
          hasData = true;
          if (loadedData != null) {
            receivedFresh = true;
          }
          loadedData = data;
          return LibraryLoaded(data: data);
        },
        onError: (error, _) => LibraryError(
          message: 'Failed to load library',
          staleData: loadedData,
        ),
      );
    } catch (_) {
      // Cancellation or stream error
    }

    if (cancelToken.isCancelled) return;

    _needsRevalidation = !receivedFresh;

    if (!hasData) {
      emit(const LibraryError(message: "You're offline. Please check your connection."));
    }
  }

  Future<void> _onRefresh(
    LibraryRefreshRequested event,
    Emitter<LibraryState> emit,
  ) async {
    _isActive = true;
    _cancelToken?.cancel('Superseded by refresh request');
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    final currentData = state is LibraryLoaded
        ? (state as LibraryLoaded).data
        : (state is LibraryError ? (state as LibraryError).staleData : null);

    if (currentData != null) {
      emit(LibraryLoaded(data: currentData, isRefreshing: true));
    }

    try {
      final data = await _loadLibrary.refresh(cancelToken: cancelToken);
      if (cancelToken.isCancelled) {
        if (currentData != null) {
          emit(LibraryLoaded(data: currentData, isRefreshing: false));
        }
        return;
      }

      if (data != null) {
        _needsRevalidation = false;
        emit(LibraryLoaded(data: data));
      } else if (currentData != null) {
        _needsRevalidation = true;
        emit(LibraryLoaded(data: currentData, isRefreshing: false));
        emit(LibraryError(
          message: "You're offline. Content will update when connected.",
          staleData: currentData,
        ));
      } else {
        _needsRevalidation = true;
        emit(const LibraryError(message: 'Could not load library. Tap to retry.'));
      }
    } catch (e) {
      if (cancelToken.isCancelled) {
        if (currentData != null) {
          emit(LibraryLoaded(data: currentData, isRefreshing: false));
        }
        return;
      }
      _needsRevalidation = true;
      if (currentData != null) {
        emit(LibraryLoaded(data: currentData, isRefreshing: false));
        emit(LibraryError(
          message: "You're offline. Content will update when connected.",
          staleData: currentData,
        ));
      } else {
        emit(LibraryError(message: e.toString()));
      }
    }
  }
}
