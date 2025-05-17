import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class UserProfileService {
  static const String _userProfileKey = 'user_profile';

  Future<void> saveProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile.toMap());
      await prefs.setString(_userProfileKey, profileJson);
      logger.i('User profile saved successfully');
    } catch (e) {
      logger.e('Failed to save user profile: $e');
      throw Exception('Failed to save user profile');
    }
  }

  Future<UserProfile?> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userProfileKey);

      if (profileJson == null) {
        logger.i('No user profile found');
        return null;
      }

      final profileMap = jsonDecode(profileJson) as Map<String, dynamic>;
      return UserProfile.fromMap(profileMap);
    } catch (e) {
      logger.e('Failed to get user profile: $e');
      return null;
    }
  }
}

// Provider for UserProfileService
final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

// StateNotifierProvider for UserProfile
class UserProfileNotifier extends StateNotifier<UserProfile?> {
  final UserProfileService _service;

  UserProfileNotifier(this._service) : super(null) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _service.getProfile();
    state = profile;
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _service.saveProfile(profile);
    state = profile;
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
      final service = ref.watch(userProfileServiceProvider);
      return UserProfileNotifier(service);
    });
