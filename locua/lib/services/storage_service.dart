// storage_service.dart
// Handles all local storage setup (Hive) — opening boxes, registering
// adapters. Called once at app startup from main.dart.

import 'package:hive_flutter/hive_flutter.dart';
import '../models/progress.dart';
import '../models/mnemonic.dart';

class StorageService {
  static const String progressBoxName = 'progressBox';
  static const String mnemonicBoxName = 'mnemonicBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ProgressAdapter());
    Hive.registerAdapter(MnemonicAdapter());
    await Hive.openBox<Progress>(progressBoxName);
    await Hive.openBox<Mnemonic>(mnemonicBoxName);
  }

  static Box<Progress> get progressBox => Hive.box<Progress>(progressBoxName);
  static Box<Mnemonic> get mnemonicBox => Hive.box<Mnemonic>(mnemonicBoxName);
}