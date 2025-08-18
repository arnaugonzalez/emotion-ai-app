import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_profile.dart';
import '../../../data/models/therapy_context.dart';
import '../../../data/services/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>((ref) {
      final profileService = ref.watch(profileServiceProvider);
      return ProfileNotifier(profileService);
    });

final therapyContextProvider =
    StateNotifierProvider<TherapyContextNotifier, AsyncValue<TherapyContext?>>((
      ref,
    ) {
      final profileService = ref.watch(profileServiceProvider);
      return TherapyContextNotifier(profileService);
    });

final profileStatusProvider =
    StateNotifierProvider<ProfileStatusNotifier, AsyncValue<ProfileStatus?>>((
      ref,
    ) {
      final profileService = ref.watch(profileServiceProvider);
      return ProfileStatusNotifier(profileService);
    });

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final ProfileService _profileService;

  ProfileNotifier(this._profileService) : super(const AsyncValue.loading());

  Future<UserProfile?> getUserProfile() async {
    try {
      state = const AsyncValue.loading();
      final profile = await _profileService.getUserProfile();
      state = AsyncValue.data(profile);
      return profile;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  Future<UserProfile> createOrUpdateProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      state = const AsyncValue.loading();
      final profile = await _profileService.createOrUpdateProfile(profileData);
      state = AsyncValue.data(profile);
      return profile;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void clearProfile() {
    state = const AsyncValue.data(null);
  }
}

class TherapyContextNotifier
    extends StateNotifier<AsyncValue<TherapyContext?>> {
  final ProfileService _profileService;

  TherapyContextNotifier(this._profileService)
    : super(const AsyncValue.loading());

  Future<TherapyContext?> getTherapyContext() async {
    try {
      state = const AsyncValue.loading();
      final context = await _profileService.getTherapyContext();
      state = AsyncValue.data(context);
      return context;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  Future<TherapyContext> updateTherapyContext(
    Map<String, dynamic> contextData,
  ) async {
    try {
      state = const AsyncValue.loading();
      final context = await _profileService.updateTherapyContext(contextData);
      state = AsyncValue.data(context);
      return context;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<bool> clearTherapyContext() async {
    try {
      final success = await _profileService.clearTherapyContext();
      if (success) {
        state = const AsyncValue.data(null);
      }
      return success;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}

class ProfileStatusNotifier extends StateNotifier<AsyncValue<ProfileStatus?>> {
  final ProfileService _profileService;

  ProfileStatusNotifier(this._profileService)
    : super(const AsyncValue.loading());

  Future<ProfileStatus> getProfileStatus() async {
    try {
      state = const AsyncValue.loading();
      final status = await _profileService.getProfileStatus();
      state = AsyncValue.data(status);
      return status;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
