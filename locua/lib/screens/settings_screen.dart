// settings_screen.dart
// Real Settings screen: theme switcher (Emerald/Midnight), a daily
// reminder toggle with real scheduling (added this session), and the
// Remove Ads purchase button wired to IapService.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/ad_provider.dart';
import '../services/iap_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../models/app_meta.dart';
import '../providers/progress_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppMeta _appMeta;

  @override
  void initState() {
    super.initState();
    _appMeta = StorageService.getOrCreateAppMeta();
  }

  Future<void> _onReminderToggled(bool value) async {
    if (value) {
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Daily reminders work on the real Android app.'),
            ),
          );
        }
        return;
      }

      final granted = await NotificationService.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Notification permission was denied — enable it in your device settings to get daily reminders.'),
            ),
          );
        }
        return; // Don't flip the toggle on if permission wasn't granted.
      }

      await NotificationService.scheduleDaily(
          _appMeta.reminderHour, _appMeta.reminderMinute);
    } else {
      await NotificationService.cancelAll();
    }

    setState(() => _appMeta.reminderEnabled = value);
    _appMeta.save();
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: _appMeta.reminderHour, minute: _appMeta.reminderMinute),
    );
    if (picked == null) return;

    setState(() {
      _appMeta.reminderHour = picked.hour;
      _appMeta.reminderMinute = picked.minute;
    });
    _appMeta.save();

    if (_appMeta.reminderEnabled && !kIsWeb) {
      await NotificationService.scheduleDaily(picked.hour, picked.minute);
    }
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final adProvider = context.watch<AdProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),

        // ---- Theme switcher ----
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Theme'),
                subtitle: Text(themeProvider.current == AppThemeOption.emerald
                    ? 'Emerald & Gold'
                    : 'Midnight & Gold'),
                trailing: Switch(
                  value: themeProvider.current == AppThemeOption.midnight,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
              ),
              const Divider(height: 1),
              // ---- Daily reminder toggle ----
              ListTile(
                title: const Text('Daily reminder'),
                subtitle: const Text('Get a nudge to practice each day'),
                trailing: Switch(
                  value: _appMeta.reminderEnabled,
                  onChanged: _onReminderToggled,
                ),
              ),
              if (_appMeta.reminderEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  title: const Text('Reminder time'),
                  subtitle: Text(_formatTime(
                      _appMeta.reminderHour, _appMeta.reminderMinute)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickReminderTime,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ---- Stats dashboard ----
        Consumer<ProgressProvider>(
          builder: (context, progressProvider, _) {
            final weak = progressProvider.weakWords;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Stats', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Text('Words mastered: ${progressProvider.wordsLearnedCount}'),
                    const SizedBox(height: 4),
                    Text('Overall accuracy: ${progressProvider.overallAccuracy.round()}%'),
                    const SizedBox(height: 4),
                    Text('Words to review more: ${weak.length}'),
                    if (weak.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: weak
                            .map((p) => Chip(label: Text(p.word)))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // ---- Remove Ads ----
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GO PREMIUM',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 6),
                Text('Remove Ads', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text(
                    'One-time purchase. Support Locua and enjoy an uninterrupted learning flow.'),
                const SizedBox(height: 12),
                if (adProvider.isAdFree)
                  const Text('✓ Ads removed — thank you for your support!')
                else
                  ElevatedButton(
                    onPressed: () => IapService.buyRemoveAds(),
                    child: const Text('Remove Ads'),
                  ),
                TextButton(
                  onPressed: () => IapService.restorePurchases(),
                  child: const Text('Restore Purchase'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}