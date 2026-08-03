// storage_service.dart
// Handles all local storage setup (Hive) — opening boxes, registering
// adapters. Called once at app startup from main.dart.
import 'package:hive_flutter/hive_flutter.dart';
import '../models/progress.dart';
import '../models/mnemonic.dart';
import '../models/app_meta.dart';

class StorageService {
  static const String progressBoxName = 'progressBox';
  static const String mnemonicBoxName = 'mnemonicBox';
  static const String appMetaBoxName = 'appMetaBox';

  // AppMeta always lives under this single fixed key — there is only
  // ever one record in this box (app-level data, not per-word).
  static const String appMetaKey = 'appMeta';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ProgressAdapter());
    Hive.registerAdapter(MnemonicAdapter());
    Hive.registerAdapter(AppMetaAdapter());
    await Hive.openBox<Progress>(progressBoxName);
    await Hive.openBox<Mnemonic>(mnemonicBoxName);
    await Hive.openBox<AppMeta>(appMetaBoxName);
  }

  static Box<Progress> get progressBox => Hive.box<Progress>(progressBoxName);
  static Box<Mnemonic> get mnemonicBox => Hive.box<Mnemonic>(mnemonicBoxName);
  static Box<AppMeta> get appMetaBox => Hive.box<AppMeta>(appMetaBoxName);

  // Returns the single AppMeta record, creating it on first-ever app open.
  static AppMeta getOrCreateAppMeta() {
    final existing = appMetaBox.get(appMetaKey);
    if (existing != null) return existing;
    final fresh = AppMeta();
    appMetaBox.put(appMetaKey, fresh);
    return fresh;
  }
}