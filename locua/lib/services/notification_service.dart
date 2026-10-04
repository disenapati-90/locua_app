// notification_service.dart
// Wraps flutter_local_notifications for the daily practice reminder.
// kIsWeb-guarded throughout — scheduling doesn't work reliably (or at all)
// on Flutter Web, matching the same pattern used for record/IAP/ads.
//
// CHANGED: init() at app startup (main.dart) is wrapped in a 5-second
// timeout there, to stop a slow native timezone lookup from ever hanging
// the whole app on launch. But that meant on any device where the lookup
// genuinely takes longer than 5s, the plugin silently never finished
// initializing — so every later scheduleDaily()/requestPermission() call
// quietly failed with no visible error, which is exactly what testers
// reported ("notifications don't work"). Fixed with an ensureInit() guard
// that both entry points call first, retrying initialization at that
// later, foreground, user-initiated moment (no startup time pressure this
// time) instead of relying solely on the one attempt made at cold start.
// Failures here are no longer swallowed — they propagate so the caller
// (Settings) can show the user something actionable.
//
// CHANGED (this fix): root cause of "Couldn't set up reminders" found.
// flutter_timezone can return a deprecated/legacy IANA name on some real
// devices (e.g. "Asia/Calcutta" instead of the current "Asia/Kolkata" —
// both are the same zone, but Android's underlying ICU data still reports
// the old name on some OEM builds). The bundled `timezone` Dart package
// database does not always include these legacy aliases, so
// tz.getLocation() throws "could not find a time zone" — this exception
// was happening BEFORE any permission dialog, which is why the error
// appeared instantly with no system prompt shown. Fixed by normalizing a
// short list of known legacy/renamed zone identifiers to their current
// name before the lookup, with a safe UTC fallback if the name is still
// unrecognized rather than letting the whole init fail.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyReminderId = 1001;

  static bool _initialized = false;
  static Future<void>? _initFuture;

  /// Some Android/ICU builds still report a deprecated IANA zone name.
  /// The `timezone` package's bundled database doesn't always carry these
  /// old aliases, so a direct tz.getLocation() lookup can throw even
  /// though the zone is perfectly valid. Map the ones we know about to
  /// their current name before looking up.
  static const Map<String, String> _legacyZoneAliases = {
    'Asia/Calcutta': 'Asia/Kolkata',
    'Asia/Saigon': 'Asia/Ho_Chi_Minh',
    'Asia/Rangoon': 'Asia/Yangon',
    'Asia/Katmandu': 'Asia/Kathmandu',
    'Asia/Dacca': 'Asia/Dhaka',
    'Asia/Macao': 'Asia/Macau',
    'America/Indianapolis': 'America/Indiana/Indianapolis',
    'Pacific/Ponape': 'Pacific/Pohnpei',
    'Pacific/Truk': 'Pacific/Chuuk',
  };

  /// Call once at app startup (main.dart). Kept as a thin wrapper around
  /// ensureInit() so main.dart's existing try/catch + timeout doesn't need
  /// to change — this just delegates to the same shared init logic.
  static Future<void> init() => ensureInit();

  /// Guarantees the plugin is actually initialized before use. Safe to
  /// call repeatedly — if init already succeeded, returns immediately；
  /// if a previous attempt failed (e.g. timed out at startup), retries
  /// here instead of leaving the plugin permanently uninitialized.
  /// Throws on failure so callers can surface a real error instead of
  /// silently no-op'ing forever.
  static Future<void> ensureInit() {
    if (kIsWeb) return Future.value();
    if (_initialized) return Future.value();
    // Avoid kicking off multiple concurrent init attempts if called from
    // more than one place around the same time.
    return _initFuture ??= _doInit().then((_) {
      _initialized = true;
      _initFuture = null;
    }).catchError((e) {
      _initFuture = null; // allow a future retry attempt
      throw e;
    });
  }

  /// Resolves a timezone location robustly: tries the name as-is, then a
  /// known legacy-alias mapping, then falls back to UTC rather than
  /// letting the whole notification feature fail over a timezone lookup.
  /// Falling back to UTC means scheduled times may be off until the next
  /// successful lookup — acceptable, since "reminders work but may need a
  /// retry to get the exact local time right" is a much smaller problem
  /// than "reminders don't work at all."
  static tz.Location _resolveLocation(String locationName) {
    try {
      return tz.getLocation(locationName);
    } catch (_) {
      final mapped = _legacyZoneAliases[locationName];
      if (mapped != null) {
        try {
          return tz.getLocation(mapped);
        } catch (_) {
          // fall through to UTC below
        }
      }
      return tz.getLocation('UTC');
    }
  }

  static Future<void> _doInit() async {
    tz_data.initializeTimeZones();
    final locationName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(_resolveLocation(locationName));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(initSettings);
  }

  /// Requests the Android 13+ runtime notification permission.
  /// Returns true if granted (or not required on this platform/OS version).
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await ensureInit(); // CHANGED: retry init here if the startup attempt failed

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    final IOSFlutterLocalNotificationsPlugin? iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    return true;
  }

  /// Schedules (or reschedules) the daily reminder at [hour]:[minute],
  /// repeating every day. Cancels any existing one first so toggling the
  /// time never results in duplicate notifications stacking up.
  static Future<void> scheduleDaily(int hour, int minute) async {
    if (kIsWeb) return;
    await ensureInit(); // CHANGED: retry init here if the startup attempt failed

    await cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'Time to practice',
      'A few minutes with Locua keeps your streak alive.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminder',
          channelDescription: 'Daily nudge to practice in Locua',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancel(_dailyReminderId);
  }
}