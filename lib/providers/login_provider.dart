import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_model.dart';
import '../repositories/auth_repository.dart';

final loginProvider = StateNotifierProvider<LoginController, AsyncValue<AuthModel?>>(
  (ref) => LoginController(AuthRepository()),
);

class LoginController extends StateNotifier<AsyncValue<AuthModel?>> {
  final AuthRepository _repository;

  LoginController(this._repository) : super(const AsyncValue.data(null)) {
  Future.microtask(() => _loadCached()); // ensures it runs asynchronously
}

  Future<void> _loadCached() async {
  final cached = await _repository.getCachedAuth();
  if (cached != null) {
    state = AsyncValue.data(cached);
  }
}

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final auth = await _repository.login(email, password);
      state = AsyncValue.data(auth);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}
