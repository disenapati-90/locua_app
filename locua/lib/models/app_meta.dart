// app_meta.dart
// App-level metadata: streak, reminders, voice/TTS, sound effects, and
// (added this session) the user's chosen display name for Home's greeting.
import 'package:hive/hive.dart';
part 'app_meta.g.dart';

@HiveType(typeId: 2)
class AppMeta extends HiveObject {
  @HiveField(0)
  int currentStreak;

  @HiveField(1)
  int longestStreak;

  @HiveField(2)
  DateTime? lastOpenDate;

  @HiveField(3, defaultValue: false)
  bool reminderEnabled;

  @HiveField(4, defaultValue: 20)
  int reminderHour;

  @HiveField(5, defaultValue: 0)
  int reminderMinute;

  @HiveField(6, defaultValue: true)
  bool ttsEnabled;

  @HiveField(7, defaultValue: 'en-US')
  String ttsAccentLocale;

  @HiveField(8, defaultValue: 0.45)
  double ttsRate;

  @HiveField(9, defaultValue: true)
  bool soundEnabled;

  @HiveField(10, defaultValue: 'chime')
  String soundPack;

  // ADDED this session: next free index (11). Empty string means the
  // one-time name onboarding hasn't been completed yet — see
  // app_root.dart for how this is checked.
  @HiveField(11, defaultValue: '')
  String userName;

  AppMeta({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastOpenDate,
    this.reminderEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.ttsEnabled = true,
    this.ttsAccentLocale = 'en-US',
    this.ttsRate = 0.45,
    this.soundEnabled = true,
    this.soundPack = 'chime',
    this.userName = '',
  });
}