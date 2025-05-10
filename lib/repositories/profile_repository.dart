import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';

class ProfileRepository {
  final _boxName = 'profile_data';

  Future<ProfileModel> fetchProfile({bool forceRefresh = false}) async {
    final box = await Hive.openBox(_boxName);
    final hasCached = box.containsKey('profile') && box.get('profile') != null;
    if (!forceRefresh && hasCached) {
      return ProfileModel.fromJson(jsonDecode(box.get('profile')));
    }

    final profile = await ProfileService.getProfile(forceRefresh: true);
    await box.put('profile', jsonEncode(profile.toJson()));
    return profile;
  }

  Future<void> clearCache() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
  }

  Future<String?> changePassword(String oldPwd, String newPwd) async {
    return await ProfileService.changePassword(oldPwd, newPwd);
  }
}
