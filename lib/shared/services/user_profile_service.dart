import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'package:logger/logger.dart';

final logger = Logger();

// Isolate function for profile serialization
Future<String> _serializeProfileInIsolate(UserProfile profile) async {
  return jsonEncode(profile.toMap());
}

// Isolate function for profile deserialization
Future<UserProfile?> _deserializeProfileInIsolate(String? profileJson) async {
  if (profileJson == null) return null;
  final profileMap = jsonDecode(profileJson) as Map<String, dynamic>;
  return UserProfile.fromMap(profileMap);
}

class UserProfileService {
  static const String _userProfileKey = 'user_profile';
  static const String _profileCompleteKey = 'profile_complete';
  final _logger = Logger();

  Future<void> saveProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Serialize profile in isolate
      final profileJson = await compute(_serializeProfileInIsolate, profile);

      // Save profile data
      await prefs.setString(_userProfileKey, profileJson);

      // Save individual fields for quick access
      await prefs.setString('user_name', profile.name ?? '');
      await prefs.setString('user_age', profile.age?.toString() ?? '');
      await prefs.setString('user_gender', profile.gender ?? '');
      await prefs.setString('user_job', profile.job ?? '');
      await prefs.setString('user_country', profile.country ?? '');
      await prefs.setString(
        'user_personality_type',
        profile.personalityType ?? '',
      );
      await prefs.setString(
        'user_relaxation_time',
        profile.relaxationTime ?? '',
      );
      await prefs.setString(
        'user_selfcare_frequency',
        profile.selfcareFrequency ?? '',
      );

      if (profile.relaxationTools != null) {
        await prefs.setStringList(
          'user_relaxation_tools',
          profile.relaxationTools!,
        );
      }

      await prefs.setBool(
        'user_has_previous_mental_health_app_experience',
        profile.hasPreviousMentalHealthAppExperience ?? false,
      );

      await prefs.setString(
        'user_therapy_chat_history_preference',
        profile.therapyChatHistoryPreference ?? 'No history needed',
      );

      // Mark profile as complete if it meets requirements
      await prefs.setBool(_profileCompleteKey, profile.isComplete());

      _logger.i('Profile saved successfully');
    } catch (e) {
      _logger.e('Error saving profile: $e');
      throw Exception('Failed to save profile: $e');
    }
  }

  Future<UserProfile?> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userProfileKey);

      if (profileJson == null) {
        _logger.i('No profile found');
        return null;
      }

      // Deserialize profile in isolate
      final profile = await compute(_deserializeProfileInIsolate, profileJson);
      _logger.i('Profile loaded successfully');
      return profile;
    } catch (e) {
      _logger.e('Error loading profile: $e');
      return null;
    }
  }

  Future<bool> hasProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isComplete = prefs.getBool(_profileCompleteKey) ?? false;
      final hasProfileData = prefs.getString(_userProfileKey) != null;
      return isComplete && hasProfileData;
    } catch (e) {
      _logger.e('Error checking profile existence: $e');
      return false;
    }
  }

  Future<void> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileKey);
      await prefs.remove(_profileCompleteKey);
      await prefs.remove('user_name');
      await prefs.remove('user_age');
      await prefs.remove('user_gender');
      await prefs.remove('user_job');
      await prefs.remove('user_country');
      await prefs.remove('user_personality_type');
      await prefs.remove('user_relaxation_time');
      await prefs.remove('user_selfcare_frequency');
      await prefs.remove('user_relaxation_tools');
      await prefs.remove('user_has_previous_mental_health_app_experience');
      await prefs.remove('user_therapy_chat_history_preference');
      _logger.i('Profile cleared successfully');
    } catch (e) {
      _logger.e('Error clearing profile: $e');
      throw Exception('Failed to clear profile: $e');
    }
  }
}

// Provider for UserProfileService
final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  final UserProfileService _service;

  UserProfileNotifier(this._service) : super(null);

  Future<void> updateProfile(UserProfile profile) async {
    await _service.saveProfile(profile);
    state = profile;
  }
}

// Provider for current user profile
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
      final service = ref.watch(userProfileServiceProvider);
      return UserProfileNotifier(service);
    });

// Provider to track profile completion status
final profileCompleteProvider = FutureProvider<bool>((ref) async {
  final profileService = ref.watch(userProfileServiceProvider);
  return await profileService.hasProfile();
});
