import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static Future<Box> openBox(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) {
      try {
        return await Hive.openBox(boxName);
      } catch (e) {
        // If error, delete box and recreate
        await Hive.deleteBoxFromDisk(boxName);
        return await Hive.openBox(boxName);
      }
    } else {
      return Hive.box(boxName);
    }
  }

  static Box getBox(String boxName) {
    return Hive.box(boxName);
  }

  static Future<void> clearBox(String boxName) async {
    final box = Hive.box(boxName);
    await box.clear();
  }

  static Future<void> closeBox(String boxName) async {
    final box = Hive.box(boxName);
    await box.close();
  }
}
