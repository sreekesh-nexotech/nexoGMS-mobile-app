import 'package:flutter/foundation.dart';
import 'profile_model.dart';

@immutable
class ProfileState {
  final bool isLoading;
  final ProfileModel? profile;
  final String? error;

  const ProfileState({
    this.isLoading = false,
    this.profile,
    this.error,
  });

  ProfileState copyWith({
    bool? isLoading,
    ProfileModel? profile,
    String? error,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      error: error,
    );
  }

  factory ProfileState.initial() => const ProfileState(isLoading: true);
}
