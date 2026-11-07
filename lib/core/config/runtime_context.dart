import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter_timezone/flutter_timezone.dart';

/// Device identity profiles for Spotify API communication.
///
/// Each profile carries the platform string, app version, and user-agent
/// that the corresponding Spotify client would send. Transports select
/// the appropriate profile and read these values instead of hardcoding them.
enum DeviceProfile {
  webPlayer(
    appPlatform: 'WebPlayer',
    appVersion: '1.2.87.215.g6e7e7fc2',
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36',
  ),
  android(
    appPlatform: 'Android',
    appVersion: '9.1.76.2045',
    userAgent: 'Spotify/9.1.76.2045 Android/29 (Pixel 4 XL)',
  );

  final String appPlatform;
  final String appVersion;
  final String userAgent;

  const DeviceProfile({
    required this.appPlatform,
    required this.appVersion,
    required this.userAgent,
  });
}

/// Centralized runtime context for locale, market, device identity,
/// and header policy.
///
/// Populated at startup from system settings (timezone, locale), then
/// updated with live values from the Spotify profile after login
/// (country, catalogue tier). All repositories, transports, and metadata
/// fetchers read from this single source instead of hardcoding values.
class RuntimeContext {
  String country;
  String catalogue;
  String timezone;
  TimezoneInfo? timezoneInfo;
  String acceptLanguage;

  final Set<void Function()> _changeListeners = <void Function()>{};

  RuntimeContext({
    this.country = 'US',
    this.catalogue = 'free',
    this.timezone = 'UTC',
    this.timezoneInfo,
    this.acceptLanguage = 'en-US',
  });

  void addChangeListener(void Function() listener) {
    _changeListeners.add(listener);
  }

  void removeChangeListener(void Function() listener) {
    _changeListeners.remove(listener);
  }

  void _notifyChanged() {
    final snapshot = List<void Function()>.of(_changeListeners);
    for (final listener in snapshot) {
      listener();
    }
  }

  /// Detects system timezone and locale. Call once at app startup
  /// before any network requests are made.
  Future<void> init() async {
    try {
      final tz = await FlutterTimezone.getLocalTimezone();
      timezoneInfo = tz;
      timezone = tz.identifier;
    } catch (e) {
      dev.log(
        'RuntimeContext: timezone detection unavailable, retaining $timezone: $e',
        name: 'RuntimeContext',
      );
    }
    try {
      final raw = Platform.localeName;
      if (raw.isNotEmpty) {
        acceptLanguage = raw.replaceAll('_', '-');
      }
    } catch (e) {
      dev.log(
        'RuntimeContext: locale detection unavailable, retaining $acceptLanguage: $e',
        name: 'RuntimeContext',
      );
    }
  }

  /// Updates market-specific values from the authenticated Spotify profile.
  /// Called after login when the profile response provides country and product.
  void updateFromProfile({String? userCountry, String? product}) {
    var changed = false;
    if (userCountry != null && userCountry.isNotEmpty && country != userCountry) {
      country = userCountry;
      changed = true;
    }
    if (product != null && product.isNotEmpty && catalogue != product) {
      catalogue = product;
      changed = true;
    }
    if (changed) {
      _notifyChanged();
    }
  }
}
