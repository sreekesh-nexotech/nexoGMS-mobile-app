import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../services/api_service.dart';

final tokenVerificationProvider = FutureProvider<bool>((ref) async {
  final authBox = await Hive.openBox('auth');
  final accessToken = authBox.get('access_token');
  final refreshToken = authBox.get('refresh_token');

  if (accessToken == null || refreshToken == null) {
    await authBox.clear();
    throw Exception('Token missing. Please log in again.');
  }

  final apiService = ApiService();
  final response = await apiService.authenticatedGet('auth/verify-token');

  if (response.statusCode == 200) {
    return true;
  } else {
    await authBox.clear();
    throw Exception('Session expired. Please log in again.');
  }
});
final tokenProvider = StateNotifierProvider<TokenNotifier, void>(
  (ref) => TokenNotifier(),
);

class TokenNotifier extends StateNotifier<void> {
  TokenNotifier() : super(null);

  Future<void> clearToken() async {
    final authBox = await Hive.openBox('auth');
    await authBox.clear();
  }
}