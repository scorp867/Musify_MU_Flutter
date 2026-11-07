/// Pure domain abstraction for native OS-level window security and screenshot prevention.
abstract interface class INativeSecurityChannel {
  Future<void> setFlagSecure({required bool enabled});
}
