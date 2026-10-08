enum NetworkStatus {
  /// Normal active internet connectivity.
  online,

  /// High latency (> 2500ms) or consecutive request timeouts detected.
  slow,

  /// No network connection detected on any device interface.
  offline,

  /// Transient state when transitioning from offline/slow back to online.
  restored,
}
