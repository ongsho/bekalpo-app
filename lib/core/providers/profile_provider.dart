import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../repositories/profile_repository.dart';
import 'auth_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

class ProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    return fetchProfile();
  }

  Future<Profile?> fetchProfile() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(profileRepositoryProvider);
      final profile = await repo.getProfile();
      state = AsyncValue.data(profile);

      // Sync with auth provider
      ref
          .read(authProvider.notifier)
          .updateProfile(userName: profile.name, avatar: profile.avatar);
      return profile;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(profileRepositoryProvider);
      final updatedProfile = await repo.updateProfile(data);

      // Merge with existing profile to preserve fields not returned by API
      final currentProfile = state.value;
      final mergedProfile = Profile(
        name: updatedProfile.name,
        username: updatedProfile.username ?? currentProfile?.username,
        dateOfBirth: updatedProfile.dateOfBirth ?? currentProfile?.dateOfBirth,
        gender: updatedProfile.gender ?? currentProfile?.gender,
        bio: updatedProfile.bio ?? currentProfile?.bio,
        avatar: updatedProfile.avatar ?? currentProfile?.avatar,
      );

      state = AsyncValue.data(mergedProfile);

      // Sync with auth provider
      ref
          .read(authProvider.notifier)
          .updateProfile(
            userName: mergedProfile.name,
            avatar: mergedProfile.avatar,
          );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> uploadAvatar(File file) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(profileRepositoryProvider);
      final updatedProfile = await repo.uploadAvatar(file);

      // Merge with existing profile to preserve fields not returned by API
      final currentProfile = state.value;
      final mergedProfile = Profile(
        name: updatedProfile.name,
        username: updatedProfile.username ?? currentProfile?.username,
        dateOfBirth: updatedProfile.dateOfBirth ?? currentProfile?.dateOfBirth,
        gender: updatedProfile.gender ?? currentProfile?.gender,
        bio: updatedProfile.bio ?? currentProfile?.bio,
        avatar: updatedProfile.avatar ?? currentProfile?.avatar,
      );

      state = AsyncValue.data(mergedProfile);

      // Sync with auth provider
      ref
          .read(authProvider.notifier)
          .updateProfile(
            userName: mergedProfile.name,
            avatar: mergedProfile.avatar,
          );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, Profile?>(
  ProfileNotifier.new,
);
