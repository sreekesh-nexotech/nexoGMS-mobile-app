// lib/providers/logout_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/cache_utils.dart';
import 'home_provider.dart';
import 'profile_provider.dart';
import 'workout_provider.dart';
import 'vital_provider.dart';
import 'token_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

final logoutProvider = Provider((ref) => LogoutService(ref));

class LogoutService {
  final Ref ref;

  LogoutService(this.ref);

  Future<void> logoutAll() async {
    await CacheManager.nukeAll();
    await Hive.deleteBoxFromDisk('auth');
    await Hive.deleteBoxFromDisk('authBox');

    ref.invalidate(homeProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(workoutProvider);
    ref.invalidate(vitalProvider);
    ref.invalidate(tokenProvider);
  }
}
