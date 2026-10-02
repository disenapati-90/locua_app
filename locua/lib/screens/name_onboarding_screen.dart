// name_onboarding_screen.dart
// One-time "what should we call you" screen, shown on first launch only
// (when AppMeta.userName is empty). No login/auth involved — just a
// local Hive field, editable later from Settings.

import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class NameOnboardingScreen extends StatefulWidget {
  final VoidCallback onSaved;
  const NameOnboardingScreen({super.key, required this.onSaved});

  @override
  State<NameOnboardingScreen> createState() => _NameOnboardingScreenState();
}

class _NameOnboardingScreenState extends State<NameOnboardingScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final meta = StorageService.getOrCreateAppMeta();
    meta.userName = name;
    meta.save();
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome to Locua', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('What should we call you?', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Your name'),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _save, child: const Text('Continue')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}