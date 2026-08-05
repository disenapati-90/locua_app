// main.dart
// Entry point of the Locua app.
// Sets up the ThemeProvider so the whole app can react to theme changes,
// and loads MainShell — the bottom-nav shell with all 6 screens.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'widgets/main_shell.dart';
import 'services/storage_service.dart';
import 'package:provider/provider.dart';
import 'providers/progress_provider.dart';
import 'providers/nav_provider.dart';
import 'providers/ad_provider.dart';
import 'services/iap_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // required before any async setup pre-runApp
  await StorageService.init(); // opens Hive boxes before the app builds
  // Note: this needs a reference to AdProvider, so full wiring happens
  // via a small helper after MultiProvider is built — see LocuaApp below.
  await NotificationService.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProvider(create: (_) => AdProvider()),
      ],
      child: const LocuaApp(),
    ),
  );
}

class LocuaApp extends StatefulWidget {
  const LocuaApp({super.key});

  @override
  State<LocuaApp> createState() => _LocuaAppState();
}

class _LocuaAppState extends State<LocuaApp> {
  @override
  void initState() {
    super.initState();
    // Listens for purchase completion and flips the isAdFree flag globally.
    IapService.initialize(
      onRemoveAdsPurchased: () {
        context.read<AdProvider>().setAdFree(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Locua',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      home: const MainShell(),
    );
  }
}