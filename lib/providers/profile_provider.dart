import 'package:flutter_riverpod/flutter_riverpod.dart';
//import '../models/profile_model.dart';
import '../repositories/profile_repository.dart';
import '../models/profile_state.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(ProfileRepository())..loadProfile(),
);

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;

  ProfileNotifier(this._repository) : super(ProfileState.initial());

  Future<void> loadProfile({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      final profile = await _repository.fetchProfile(forceRefresh: forceRefresh);
      if (profile == null) {
      throw Exception("Profile not available");
    }
      state = ProfileState(isLoading: false, profile: profile);
    } catch (e) {
      state = ProfileState(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshProfile() => loadProfile(forceRefresh: true);
  Future<void> clearCache() => _repository.clearCache();

  Future<String?> changePassword(String oldPwd, String newPwd) async {
    try {
      return await _repository.changePassword(oldPwd, newPwd);
    } catch (e) {
      return e.toString();
    }
  }
}
