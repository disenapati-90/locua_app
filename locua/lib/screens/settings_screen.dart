// settings_screen.dart
// Real Settings screen: profile name, theme switcher, daily reminder,
// sound effects, and the stats dashboard.
//
// CHANGED this session: _soundPackLabel extended with labels for the 2
// new ASMR-derived packs (Soft Tones, Water Chimes) added to
// sound_service.dart. The pack picker itself needed no other change —
// it already builds its chips dynamically from SoundPack.values.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';
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

  Future<void> _editName() async {
    final controller = TextEditingController(text: _appMeta.userName);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Enter your name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _appMeta.userName = result);
      _appMeta.save();
    }
  }

  Future<void> _onReminderToggled(bool value) async {
    if (value) {
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Daily reminders work on the real Android app.')),
          );
        }
        return;
      }
      try {
        final granted = await NotificationService.requestPermission();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification permission was denied — enable it in your device settings to get daily reminders.')),
            );
          }
          return;
        }
        await NotificationService.scheduleDaily(_appMeta.reminderHour, _appMeta.reminderMinute);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't set up reminders on this device right now — try again in a moment.")),
          );
        }
        return;
      }
    } else {
      await NotificationService.cancelAll();
    }
    setState(() => _appMeta.reminderEnabled = value);
    _appMeta.save();
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _appMeta.reminderHour, minute: _appMeta.reminderMinute),
    );
    if (picked == null) return;
    setState(() {
      _appMeta.reminderHour = picked.hour;
      _appMeta.reminderMinute = picked.minute;
    });
    _appMeta.save();
    if (_appMeta.reminderEnabled && !kIsWeb) {
      try {
        await NotificationService.scheduleDaily(picked.hour, picked.minute);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't update the reminder time right now — try again in a moment.")),
          );
        }
      }
    }
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  void _onSoundToggled(bool value) {
    setState(() => _appMeta.soundEnabled = value);
    _appMeta.save();
    if (value) SoundService.playTap();
  }

  void _onSoundPackSelected(SoundPack pack) {
    setState(() => _appMeta.soundPack = pack.name);
    _appMeta.save();
    SoundService.playTap();
  }

  // CHANGED: added labels for the 2 new ASMR-derived packs.
  String _soundPackLabel(SoundPack pack) {
    return switch (pack) {
      SoundPack.keypadTap => 'Keypad Tap',
      SoundPack.waterDrop => 'Water Drop',
      SoundPack.softBell => 'Soft Bell',
      SoundPack.softTones => 'Soft Tones',
      SoundPack.waterChimes => 'Water Chimes',
    };
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final currentPack = SoundService.packFromName(_appMeta.soundPack);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),

        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Your name'),
            subtitle: Text(_appMeta.userName.isEmpty ? 'Not set' : _appMeta.userName),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editName,
          ),
        ),
        const SizedBox(height: 16),

        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Theme'),
                subtitle: Text(themeProvider.current == AppThemeOption.emerald ? 'Emerald & Gold' : 'Midnight & Gold'),
                trailing: Switch(
                  value: themeProvider.current == AppThemeOption.midnight,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Daily reminder'),
                subtitle: const Text('Get a nudge to practice each day'),
                trailing: Switch(value: _appMeta.reminderEnabled, onChanged: _onReminderToggled),
              ),
              if (_appMeta.reminderEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  title: const Text('Reminder time'),
                  subtitle: Text(_formatTime(_appMeta.reminderHour, _appMeta.reminderMinute)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickReminderTime,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sound Effects', style: Theme.of(context).textTheme.titleMedium),
                    Switch(value: _appMeta.soundEnabled, onChanged: _onSoundToggled),
                  ],
                ),
                if (_appMeta.soundEnabled) ...[
                  const SizedBox(height: 8),
                  Text('Sound pack (tap sound only)', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: SoundPack.values.map((pack) {
                      return ChoiceChip(
                        label: Text(_soundPackLabel(pack)),
                        selected: currentPack == pack,
                        onSelected: (_) => _onSoundPackSelected(pack),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

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
                      Wrap(spacing: 6, children: weak.map((p) => Chip(label: Text(p.word))).toList()),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}