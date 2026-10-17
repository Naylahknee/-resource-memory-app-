import 'package:hive_flutter/hive_flutter.dart';
import 'welcome_store.dart';

/// Local presentation preferences. Original memories are never deleted here.
abstract final class MemorySurfaceStore {
  static String _key(String id) => 'resurfaceUntil:$id';
  static bool eligible(String id, DateTime now) {
    final raw = Hive.box(WelcomeStore.boxName).get(_key(id)) as String?;
    final until = raw == null ? null : DateTime.tryParse(raw);
    return until == null || !until.isAfter(now);
  }
  static Future<void> later(String id, {bool lessOften = false}) =>
      Hive.box(WelcomeStore.boxName).put(_key(id),
        DateTime.now().add(Duration(days: lessOften ? 14 : 1)).toIso8601String());
}
