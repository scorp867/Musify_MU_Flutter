import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/core/network/status/network_monitor_service.dart';
import 'package:musify_mu/core/network/status/network_status.dart';

// ─── Events ──────────────────────────────────────────────────────────

sealed class NetworkStatusEvent extends Equatable {
  const NetworkStatusEvent();

  @override
  List<Object?> get props => [];
}

final class NetworkStatusChanged extends NetworkStatusEvent {
  final NetworkStatus status;

  const NetworkStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}

final class DismissRestoredStatus extends NetworkStatusEvent {
  const DismissRestoredStatus();
}

// ─── State ───────────────────────────────────────────────────────────

final class NetworkStatusState extends Equatable {
  final NetworkStatus status;
  final String? message;

  const NetworkStatusState({
    required this.status,
    this.message,
  });

  const NetworkStatusState.initial()
      : status = NetworkStatus.online,
        message = null;

  bool get isVisible => status != NetworkStatus.online;

  @override
  List<Object?> get props => [status, message];
}

// ─── BLoC ────────────────────────────────────────────────────────────

class NetworkStatusBloc extends Bloc<NetworkStatusEvent, NetworkStatusState> {
  final NetworkMonitorService _monitorService;
  StreamSubscription<NetworkStatus>? _statusSubscription;
  Timer? _restoredDismissTimer;

  NetworkStatusBloc({
    required NetworkMonitorService monitorService,
    NetworkStatusState initialState = const NetworkStatusState.initial(),
  })  : _monitorService = monitorService,
        super(initialState) {
    on<NetworkStatusChanged>(_onStatusChanged);
    on<DismissRestoredStatus>(_onDismissRestored);

    _statusSubscription = _monitorService.statusStream.listen((status) {
      add(NetworkStatusChanged(status));
    });

    // Sync initial state if not online and default initial state was used
    if (initialState == const NetworkStatusState.initial() &&
        _monitorService.currentStatus != NetworkStatus.online) {
      add(NetworkStatusChanged(_monitorService.currentStatus));
    }
  }

  void _onStatusChanged(
    NetworkStatusChanged event,
    Emitter<NetworkStatusState> emit,
  ) {
    _restoredDismissTimer?.cancel();

    switch (event.status) {
      case NetworkStatus.offline:
        emit(const NetworkStatusState(
          status: NetworkStatus.offline,
          message: 'No internet connection',
        ));
      case NetworkStatus.slow:
        emit(const NetworkStatusState(
          status: NetworkStatus.slow,
          message: 'Slow connection',
        ));
      case NetworkStatus.restored:
        emit(const NetworkStatusState(
          status: NetworkStatus.restored,
          message: 'Back online',
        ));
        _restoredDismissTimer = Timer(const Duration(milliseconds: 2000), () {
          if (!isClosed) {
            add(const DismissRestoredStatus());
          }
        });
      case NetworkStatus.online:
        emit(const NetworkStatusState(
          status: NetworkStatus.online,
          message: null,
        ));
    }
  }

  void _onDismissRestored(
    DismissRestoredStatus event,
    Emitter<NetworkStatusState> emit,
  ) {
    if (state.status == NetworkStatus.restored) {
      emit(const NetworkStatusState(
        status: NetworkStatus.online,
        message: null,
      ));
    }
  }

  @override
  Future<void> close() {
    _restoredDismissTimer?.cancel();
    _statusSubscription?.cancel();
    return super.close();
  }
}
