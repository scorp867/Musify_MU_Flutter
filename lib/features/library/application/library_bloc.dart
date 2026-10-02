import 'package:flutter_bloc/flutter_bloc.dart';
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

// ─── States ──────────────────────────────────────────────────────────

sealed class LibraryState {
  const LibraryState();
}

final class LibraryLoading extends LibraryState {
  const LibraryLoading();
}

final class LibraryLoaded extends LibraryState {
  final LibraryViewData data;
  final bool isRefreshing;

  const LibraryLoaded({required this.data, this.isRefreshing = false});
}

final class LibraryError extends LibraryState {
  final String message;
  final LibraryViewData? staleData;

  const LibraryError({required this.message, this.staleData});
}

// ─── BLoC ────────────────────────────────────────────────────────────

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final LoadLibrary _loadLibrary;

  LibraryBloc({required LoadLibrary loadLibrary})
      : _loadLibrary = loadLibrary,
        super(const LibraryLoading()) {
    on<LibraryLoadRequested>(_onLoad);
    on<LibraryRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    LibraryLoadRequested event,
    Emitter<LibraryState> emit,
  ) async {
    emit(const LibraryLoading());

    // SWR: stream yields cached first, then fresh.
    await emit.forEach<LibraryViewData>(
      _loadLibrary(),
      onData: (data) => LibraryLoaded(data: data),
      onError: (error, stackTrace) => LibraryError(message: 'Failed to load library: $error'),
    );
  }

  Future<void> _onRefresh(
    LibraryRefreshRequested event,
    Emitter<LibraryState> emit,
  ) async {
    final currentData = state is LibraryLoaded
        ? (state as LibraryLoaded).data
        : null;

    if (currentData != null) {
      emit(LibraryLoaded(data: currentData, isRefreshing: true));
    }

    try {
      // Refresh skips cache, fetches fresh only.
      final data = await _loadLibrary.refresh();
      if (data != null) {
        emit(LibraryLoaded(data: data));
      } else {
        emit(LibraryError(
          message: 'Failed to refresh library',
          staleData: currentData,
        ));
      }
    } catch (e) {
      emit(LibraryError(
        message: 'Failed to refresh library: $e',
        staleData: currentData,
      ));
    }
  }
}
