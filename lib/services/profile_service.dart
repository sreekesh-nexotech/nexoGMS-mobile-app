import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/profile_model.dart';
import 'api_service.dart';

class ProfileService {
  static final _authBoxName = 'authBox';

  static Future<ProfileModel> getProfile({bool forceRefresh = false}) async {
    final box = await Hive.openBox(_authBoxName);
    if (!forceRefresh && box.containsKey('profile')) {
      final cached = box.get('profile');
      return ProfileModel.fromJson(jsonDecode(cached));
    }

    final response = await ApiService().authenticatedGet('customer/profile');
    final data = jsonDecode(response.body);
    final profile = ProfileModel.fromJson(data);

    await box.put('profile', jsonEncode(profile.toJson()));
    return profile;
  }

  static Future<String?> changePassword(String oldPwd, String newPwd) async {
    final response = await ApiService().authenticatedPost(
      'customer/change-password',
      body: {
        'old_password': oldPwd,
        'new_password': newPwd,
      },
    );

    if (response.statusCode == 200) {
      return null; // success
    } else {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Failed to change password';
    }
  }
}
