// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'widgets/app_root.dart';
import 'widgets/tap_feedback_wrapper.dart';
import 'services/storage_service.dart';
import 'providers/progress_provider.dart';
import 'providers/nav_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  try {
    await NotificationService.init().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('NotificationService.init() failed or timed out: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => NavProvider()),
      ],
      child: const LocuaApp(),
    ),
  );
}

class LocuaApp extends StatelessWidget {
  const LocuaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Locua',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      builder: (context, child) => TapFeedbackWrapper(child: child ?? const SizedBox.shrink()),
      // CHANGED: was MainShell() directly — now AppRoot decides whether
      // to show the one-time name onboarding first.
      home: const AppRoot(),
    );
  }
}