import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CacheManager {
  static final List<String> _boxNames = [
    'auth',
    'home_cache',
    'membership_plans_cache',
    'payment_cache',
    'vitalsData',
    'workoutData',
    'profile_data',
  ];

  /// Call this once during app startup (in `main()`)
  static Future<void> initializeAll() async {
    for (final name in _boxNames) {
      try {
        if (!Hive.isBoxOpen(name)) {
          await Hive.openBox(name);
        }
      } catch (e) {
        debugPrint('Failed to open box $name: $e');
      }
    }
  }

  /// Clear all Hive cache + network image cache
  static Future<void> clearAll() async {
    try {
      for (final name in _boxNames) {
        try {
          if (Hive.isBoxOpen(name)) {
            await Hive.box(name).clear();
          } else {
            final box = await Hive.openBox(name);
            await box.clear();
          }
        } catch (e) {
          debugPrint('Error clearing $name: $e');
        }
      }

      await DefaultCacheManager().emptyCache();
    } catch (e) {
      debugPrint('⚠️ Error clearing all cache: $e');
    }
  }

  /// Optional: use this to wipe everything from disk (only if necessary)
  static Future<void> nukeAll() async {
    for (final name in _boxNames) {
      try {
        if (Hive.isBoxOpen(name)) {
          await Hive.box(name).deleteFromDisk();
        } else {
          await Hive.deleteBoxFromDisk(name);
        }
      } catch (e) {
        debugPrint('Nuke failed for $name: $e');
      }
    }
  }
}
