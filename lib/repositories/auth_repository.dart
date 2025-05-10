import 'package:hive_flutter/hive_flutter.dart';
import '../models/auth_model.dart';
import '../services/api_service.dart';
import 'dart:convert';

class AuthRepository {
  final _apiService = ApiService();
  final _boxName = 'auth';

  Future<Box> _getAuthBox() async => await Hive.openBox(_boxName);

  Future<AuthModel> login(String email, String password) async {
    final response = await _apiService.authenticatedPost(
      'auth/login',
      body: {'email': email, 'password': password},
    );
  print('🔐 Login response: ${response.statusCode}');
  print('🔐 Response body: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final auth = AuthModel.fromJson(data);

      final box = await _getAuthBox();
      await box.put('access_token', auth.accessToken);
      await box.put('refresh_token', auth.refreshToken);
      await box.put('customer_name', auth.customerName);

      return auth;
    } else {
      throw Exception('Invalid credentials');
    }
  }

  Future<AuthModel?> getCachedAuth() async {
    final box = await _getAuthBox();
    if (!box.containsKey('access_token')) return null;
    return AuthModel(
      accessToken: box.get('access_token'),
      refreshToken: box.get('refresh_token'),
      customerName: box.get('customer_name') ?? 'User',
    );
  }

  Future<void> logout() async {
    final box = await _getAuthBox();
    await box.clear();
  }
}
