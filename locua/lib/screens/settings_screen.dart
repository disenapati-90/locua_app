// settings_screen.dart
// Real Settings screen: theme switcher (Emerald/Midnight), a daily
// reminder toggle (placeholder logic for now — real notifications come
// later), and the Remove Ads purchase button wired to IapService.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/ad_provider.dart';
import '../services/iap_service.dart';
import '../providers/progress_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _reminderEnabled = true; // placeholder — real scheduling comes later

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
                  value: _reminderEnabled,
                  onChanged: (value) => setState(() => _reminderEnabled = value),
                ),
              ),
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