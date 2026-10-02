// app_root.dart
// Decides what to show first: the one-time name onboarding (if
// AppMeta.userName is still empty) or the main app shell.

import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../screens/name_onboarding_screen.dart';
import 'main_shell.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late bool _needsOnboarding;

  @override
  void initState() {
    super.initState();
    _needsOnboarding = StorageService.getOrCreateAppMeta().userName.trim().isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_needsOnboarding) {
      return NameOnboardingScreen(onSaved: () => setState(() => _needsOnboarding = false));
    }
    return const MainShell();
  }
}