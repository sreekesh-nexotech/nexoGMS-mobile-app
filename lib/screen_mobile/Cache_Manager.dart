// cache_manager.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CacheManager {
  // List of all cache boxes used in the app
  static const List<String> _allBoxes = [
    'auth',           // Authentication tokens
    'authBox',        // Profile data
    'home_cache',     // Home screen data
    'membership_plans_cache',  // Membership plans
    'payment_cache',  // Payment history
    'vitalsData',     // Health metrics
    'workoutData',    // Workout data
    'profile_data',   // Profile service data
  ];

  // Initialize all cache boxes
  static Future<void> initAllBoxes() async {
    await Future.wait(
      _allBoxes.map((boxName) => Hive.openBox(boxName).catchError((_) {})),
    );
  }

  // Clear all cached data
  static Future<void> clearAllCache() async {
  try {
    // Close all boxes first to ensure they're not locked
    await Future.wait(
      _allBoxes.map((boxName) async {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          if (!box.isOpen) return;
          await box.close();
        }
      }),
    );
    
    // Clear each box
    await Future.wait(
      _allBoxes.map((boxName) async {
        try {
          if (Hive.isBoxOpen(boxName)) {
            await Hive.box(boxName).clear();
          } else {
            final box = await Hive.openBox(boxName);
            await box.clear();
            await box.close();
          }
        } catch (e) {
          debugPrint('Error clearing box $boxName: $e');
        }
      }),
    );
      
      // Clear image cache if using cached_network_image
      await _clearImageCache();
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      // If clearing fails, try deleting boxes completely
      await _nuclearClear();
    }
  }

  static Future<void> _clearImageCache() async {
    try {
      // If using cached_network_image package
      await DefaultCacheManager().emptyCache();
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }

  static Future<void> _nuclearClear() async {
    try {
      await Future.wait(
        _allBoxes.map((boxName) async {
          if (Hive.isBoxOpen(boxName)) {
            await Hive.box(boxName).deleteFromDisk();
          } else {
            await Hive.deleteBoxFromDisk(boxName);
          }
        }),
      );
    } catch (e) {
      debugPrint('Nuclear clear failed: $e');
    }
  }
}