import 'package:hive_flutter/hive_flutter.dart';

/// Remembers whether the welcome screen has been shown. First launch only.
class WelcomeStore {
  static const boxName = 'app_meta_box';
  static const _seenKey = 'welcomeSeen';

  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  static bool get hasSeenWelcome {
    if (!Hive.isBoxOpen(boxName)) return true;
    return (Hive.box(boxName).get(_seenKey, defaultValue: false) as bool?) ?? false;
  }

  static Future<void> markSeen() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    await Hive.box(boxName).put(_seenKey, true);
  }
}
