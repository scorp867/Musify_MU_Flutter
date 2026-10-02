import 'package:shared_preferences/shared_preferences.dart';

/// Encapsulates reading/writing the online-vs-offline mode preference.
///
/// Registered in [setupInjection] so that presentation code never touches
/// [SharedPreferences] directly.
class ModePersistence {
  static const _kModeKey = 'app_mode_online';

  Future<bool?> loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kModeKey);
  }

  Future<void> saveMode(bool isOnline) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kModeKey, isOnline);
  }
}
